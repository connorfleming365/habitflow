import 'package:flutter/material.dart';
import '../theme.dart';

/// Animated splash shown once on every cold start.
///
/// Animation sequence
///  0 ms       : blank kDeepOcean screen
///  150 ms     : drop+logo falls in from above (bounceOut, 700 ms)
///  900 ms     : "habitflow" + tagline fade + slide up (500 ms)
///  1 400 ms   : hold
///  2 000 ms   : whoosh exit — scales up & fades out (500 ms)
///  2 500 ms   : onComplete() called → app navigates away
class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const SplashScreen({super.key, required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _dropCtrl;
  late final AnimationController _textCtrl;
  late final AnimationController _exitCtrl;

  late final Animation<double> _dropY;
  late final Animation<double> _dropOpacity;
  late final Animation<double> _textOpacity;
  late final Animation<double> _textY;
  late final Animation<double> _exitScale;
  late final Animation<double> _exitOpacity;

  @override
  void initState() {
    super.initState();

    _dropCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _textCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _exitCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));

    _dropY = Tween<double>(begin: -180, end: 0).animate(
        CurvedAnimation(parent: _dropCtrl, curve: Curves.bounceOut));
    _dropOpacity = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
            parent: _dropCtrl, curve: const Interval(0, 0.2, curve: Curves.easeIn)));
    _textOpacity = CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut);
    _textY = Tween<double>(begin: 20, end: 0).animate(
        CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut));
    _exitScale = Tween<double>(begin: 1.0, end: 1.55).animate(
        CurvedAnimation(parent: _exitCtrl, curve: Curves.easeIn));
    _exitOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(parent: _exitCtrl, curve: Curves.easeIn));

    _run();
  }

  Future<void> _run() async {
    await Future.delayed(const Duration(milliseconds: 150));
    await _dropCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 50));
    await _textCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 900));
    await _exitCtrl.forward();
    if (mounted) widget.onComplete();
  }

  @override
  void dispose() {
    _dropCtrl.dispose();
    _textCtrl.dispose();
    _exitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Ocean gradient: sky blue → ocean surface → deep ocean
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF8ED4EF), // sky
              Color(0xFF2A8DB5), // ocean surface
              Color(0xFF0B4F74), // mid-depth
              Color(0xFF041C2C), // kDeepOcean
            ],
            stops: [0.0, 0.28, 0.60, 1.0],
          ),
        ),
        child: AnimatedBuilder(
        animation: Listenable.merge([_dropCtrl, _textCtrl, _exitCtrl]),
        builder: (_, __) => Center(
          child: FadeTransition(
            opacity: _exitOpacity,
            child: ScaleTransition(
              scale: _exitScale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Drop + checkmark logo ──────────────
                  Transform.translate(
                    offset: Offset(0, _dropY.value),
                    child: Opacity(
                      opacity: _dropOpacity.value.clamp(0.0, 1.0),
                      child: SizedBox(
                        width: 110,
                        height: 130,
                        child: CustomPaint(painter: HabitFlowLogoPainter()),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── "habitflow" + tagline ──────────────
                  Transform.translate(
                    offset: Offset(0, _textY.value),
                    child: Opacity(
                      opacity: _textOpacity.value.clamp(0.0, 1.0),
                      child: Column(children: [
                        // App name — matches the branding image typography
                        const Text(
                          'habitflow',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 44,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -1.0,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Drop by drop, build your ocean.',
                          style: TextStyle(
                            color: kSeaFoam,
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        ), // end AnimatedBuilder
      ), // end Container
    );
  }
}

// ── Shared vector logo (used by splash + onboarding) ──────
//
// Reproduces the HabitFlow brand mark — a teardrop with a
// check inside, rendered as crisp strokes at any density.
class HabitFlowLogoPainter extends CustomPainter {
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

    // ── Water-drop outline ──────────────────────────────
    // Pointed at the top, bulges to a circle at the bottom.
    final drop = Path();
    drop.moveTo(w * 0.50, h * 0.02);          // tip
    drop.cubicTo(
      w * 0.84, h * 0.22,                     // right shoulder
      w * 0.97, h * 0.52,
      w * 0.97, h * 0.68,                     // right side of base circle
    );
    drop.arcToPoint(
      Offset(w * 0.03, h * 0.68),
      radius: Radius.circular(w * 0.47),
      clockwise: false,
    );
    drop.cubicTo(
      w * 0.03, h * 0.52,
      w * 0.16, h * 0.22,
      w * 0.50, h * 0.02,                     // back to tip
    );
    drop.close();
    canvas.drawPath(drop, stroke);

    // ── Checkmark inside ───────────────────────────────
    final check = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.075
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final tick = Path();
    tick.moveTo(w * 0.22, h * 0.60);          // start (left)
    tick.lineTo(w * 0.42, h * 0.82);          // valley
    tick.lineTo(w * 0.80, h * 0.42);          // end (upper right)
    canvas.drawPath(tick, check);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
