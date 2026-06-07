import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../theme.dart';

/// Full-screen video splash shown once on cold start.
/// Plays intro_video.mp4, then calls onComplete().
/// Falls back to an animated logo sequence if the video fails to load.
class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const SplashScreen({super.key, required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _video;
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
    // video_player requires native platform; skip on web and use timed fallback
    if (kIsWeb) {
      _fadeCtrl.forward();
      await Future.delayed(const Duration(milliseconds: 500));
      _finish();
      return;
    }
    try {
      final ctrl = VideoPlayerController.asset('assets/intro_video.mp4');
      await ctrl.initialize();
      if (!mounted) { ctrl.dispose(); return; }
      ctrl.setVolume(0); // muted — user may have sounds off
      ctrl.setLooping(false);
      ctrl.addListener(_onVideoUpdate);
      setState(() { _video = ctrl; _videoReady = true; });
      await ctrl.play();
      _fadeCtrl.forward();
    } catch (_) {
      // Video failed — run timed fallback
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
    // Finish when video reaches the last 200 ms or playback stops
    if (dur.inMilliseconds > 0 &&
        pos.inMilliseconds >= dur.inMilliseconds - 2200) {
      _finish();
    }
  }

  void _finish() {
    if (_done) return;
    _done = true;
    if (mounted) widget.onComplete();
  }

  @override
  void dispose() {
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
// Water-drop outline with checkmark inside.
// const constructor so it can be used in const widget trees.
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

    // Water-drop outline (pointed tip at top, rounded base)
    final drop = Path();
    drop.moveTo(w * 0.50, h * 0.02);
    drop.cubicTo(w * 0.84, h * 0.22, w * 0.97, h * 0.52, w * 0.97, h * 0.68);
    drop.arcToPoint(Offset(w * 0.03, h * 0.68),
        radius: Radius.circular(w * 0.47), clockwise: false);
    drop.cubicTo(w * 0.03, h * 0.52, w * 0.16, h * 0.22, w * 0.50, h * 0.02);
    drop.close();
    canvas.drawPath(drop, stroke);

    // Checkmark inside
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
