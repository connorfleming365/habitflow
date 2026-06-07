import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../theme.dart';

/// Full-screen video splash shown once on cold start.
/// Uses splash_video.mp4 which has ocean-wave audio baked in,
/// so a single VideoPlayerController handles both video and sound.
class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const SplashScreen({super.key, required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _video;
  Timer? _fallbackTimer;
  bool _videoReady = false;
  bool _done = false;

  // Fallback fade-in for the logo if video fails
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _initVideo();
  }

  Future<void> _initVideo() async {
    if (kIsWeb) {
      _fadeCtrl.forward();
      await Future.delayed(const Duration(milliseconds: 500));
      _finish();
      return;
    }
    try {
      final ctrl = VideoPlayerController.asset('assets/splash_video.mp4');
      await ctrl.initialize();
      if (!mounted) { ctrl.dispose(); return; }
      ctrl.setVolume(1.0); // audio is baked into the video
      ctrl.setLooping(false);
      ctrl.addListener(_onVideoUpdate);
      setState(() { _video = ctrl; _videoReady = true; });
      await ctrl.play();
      _fadeCtrl.forward();
      // Hard fallback: advance even if the video listener stalls
      _fallbackTimer = Timer(const Duration(seconds: 12), _finish);
    } catch (_) {
      _fadeCtrl.forward();
      await Future.delayed(const Duration(milliseconds: 500));
      _finish();
    }
  }

  void _onVideoUpdate() {
    final ctrl = _video;
    if (ctrl == null || _done) return;
    final pos = ctrl.value.position;
    final dur = ctrl.value.duration;
    if (dur.inMilliseconds > 0 &&
        pos.inMilliseconds >= dur.inMilliseconds - 2200) {
      _finish();
    }
  }

  void _finish() {
    if (_done) return;
    _done = true;
    _fallbackTimer?.cancel();
    if (mounted) widget.onComplete();
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    _video?.removeListener(_onVideoUpdate);
    _video?.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDeepOcean,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Video (or black fallback)
          if (_videoReady && _video != null)
            FadeTransition(
              opacity: _fadeAnim,
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _video!.value.size.width,
                  height: _video!.value.size.height,
                  child: VideoPlayer(_video!),
                ),
              ),
            ),

          // Fallback: ocean gradient when video isn't ready
          if (!_videoReady)
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF8ED4EF),
                    Color(0xFF2A8DB5),
                    Color(0xFF0B4F74),
                    Color(0xFF041C2C),
                  ],
                  stops: [0.0, 0.28, 0.60, 1.0],
                ),
              ),
              child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const SizedBox(width: 90, height: 108,
                      child: CustomPaint(painter: HabitFlowLogoPainter())),
                  const SizedBox(height: 20),
                  const Text('habitflow',
                    style: TextStyle(color: Colors.white, fontSize: 40,
                        fontWeight: FontWeight.w700, letterSpacing: -1)),
                  const SizedBox(height: 8),
                  Text('Drop by drop, build your ocean.',
                    style: TextStyle(color: kSeaFoam, fontSize: 13)),
                ]),
              ),
            ),
        ],
      ),
    );
  }
}

// ── HabitFlow brand mark ──────────────────────────────────
class HabitFlowLogoPainter extends CustomPainter {
  const HabitFlowLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final stroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.065
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final drop = Path();
    drop.moveTo(w * 0.50, h * 0.02);
    drop.cubicTo(w * 0.84, h * 0.22, w * 0.97, h * 0.52, w * 0.97, h * 0.68);
    drop.arcToPoint(Offset(w * 0.03, h * 0.68),
        radius: Radius.circular(w * 0.47), clockwise: false);
    drop.cubicTo(w * 0.03, h * 0.52, w * 0.16, h * 0.22, w * 0.50, h * 0.02);
    drop.close();
    canvas.drawPath(drop, stroke);

    final check = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.075
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final tick = Path();
    tick.moveTo(w * 0.22, h * 0.60);
    tick.lineTo(w * 0.42, h * 0.82);
    tick.lineTo(w * 0.80, h * 0.42);
    canvas.drawPath(tick, check);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
