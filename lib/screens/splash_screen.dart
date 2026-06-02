import 'package:flutter/material.dart';
import '../theme.dart';

/// Full-screen animated splash shown once on cold start.
///
/// Sequence:
///  1. 💧 drop falls in from above with a bounce        (0 – 700 ms)
///  2. "HabitFlow" + tagline fade + slide up             (600 – 1100 ms)
///  3. Short hold                                        (1100 – 2000 ms)
///  4. Everything scales up & fades out ("whoosh")       (2000 – 2500 ms)
///  5. [onComplete] is called → caller navigates away
class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const SplashScreen({super.key, required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _dropCtrl;
  late AnimationController _textCtrl;
  late AnimationController _exitCtrl;

  late Animation<double> _dropY;
  late Animation<double> _dropOpacity;
  late Animation<double> _textOpacity;
  late Animation<double> _textY;
  late Animation<double> _exitScale;
  late Animation<double> _exitOpacity;

  @override
  void initState() {
    super.initState();

    _dropCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _textCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _exitCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));

    _dropY = Tween<double>(begin: -160, end: 0).animate(
        CurvedAnimation(parent: _dropCtrl, curve: Curves.bounceOut));
    _dropOpacity = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
            parent: _dropCtrl, curve: const Interval(0, 0.25, curve: Curves.easeIn)));

    _textOpacity = CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut);
    _textY = Tween<double>(begin: 18, end: 0).animate(
        CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut));

    _exitScale = Tween<double>(begin: 1.0, end: 1.6).animate(
        CurvedAnimation(parent: _exitCtrl, curve: Curves.easeIn));
    _exitOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(parent: _exitCtrl, curve: Curves.easeIn));

    _runSequence();
  }

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 150));
    await _dropCtrl.forward();                             // drop falls in
    await Future.delayed(const Duration(milliseconds: 50));
    await _textCtrl.forward();                             // text fades in
    await Future.delayed(const Duration(milliseconds: 900)); // hold
    await _exitCtrl.forward();                             // whoosh out
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
      backgroundColor: kDeepOcean,
      body: AnimatedBuilder(
        animation: Listenable.merge([_dropCtrl, _textCtrl, _exitCtrl]),
        builder: (_, __) {
          return Center(
            child: FadeTransition(
              opacity: _exitOpacity,
              child: ScaleTransition(
                scale: _exitScale,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Drop icon ─────────────────────────
                    Transform.translate(
                      offset: Offset(0, _dropY.value),
                      child: Opacity(
                        opacity: _dropOpacity.value.clamp(0.0, 1.0),
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: kOceanBlue.withOpacity(0.18),
                            border: Border.all(
                                color: kReefBlue.withOpacity(0.35), width: 1.5),
                          ),
                          alignment: Alignment.center,
                          child: const Text('💧',
                              style: TextStyle(fontSize: 52)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── App name + tagline ────────────────
                    Transform.translate(
                      offset: Offset(0, _textY.value),
                      child: Opacity(
                        opacity: _textOpacity.value.clamp(0.0, 1.0),
                        child: Column(
                          children: [
                            const Text(
                              'HabitFlow',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 42,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Drop by drop, build your ocean.',
                              style: TextStyle(
                                color: kSeaFoam,
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
