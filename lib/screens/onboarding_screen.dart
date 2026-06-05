import 'package:flutter/material.dart';
import '../theme.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const OnboardingScreen({super.key, required this.onComplete});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _ctrl = PageController();
  int _page = 0;

  static const _pages = [
    _OnboardPage(
      title: 'Welcome to habitflow',
      body:
          'The habit tracker that keeps it simple.\n\n'
          'Just your habits, tracked daily — drop by drop.',
    ),
    _OnboardPage(
      title: 'How it works',
      body:
          'Add the habits you want to build.\n\n'
          'Every day, open the app and tap to check them off. '
          'That\'s it. Small, consistent action is all it takes.\n\n'
          'You can also add the Widget to your Home Screen '
          'to check off habits straight from there!',
    ),
    _OnboardPage(
      title: 'Your Flow Journey',
      body:
          'Every drop counts. Each day you check in, your flow rises.\n\n'
          'Long-term success is built on the consistent, sustained action of '
          'small habits. With habitflow, you build your Flow towards your goals '
          'by showing up every day.\n\n'
          '180 days of consistent habits and you\'ll have filled your ocean. '
          'Reach that milestone and your long-term goals will feel like a walk '
          'in the park — or a swim in the sea. 🌊\n\n'
          '💧 Drop — Days 1 to 6\n'
          'Your journey begins.\n\n'
          '💦 Puddle — Days 7 to 20\n'
          'Something real is forming.\n\n'
          '🌱 Spring — Days 21 to 44\n'
          'Your habits are springing to life.\n\n'
          '🌊 Stream — Days 45 to 89\n'
          'You\'re a flowing stream of action.\n\n'
          '🏄 Tide — Days 90 to 179\n'
          'The ocean is within reach.\n\n'
          '🌅 Ocean — Day 180+\n'
          'You are the ocean.',
    ),
    _OnboardPage(
      title: 'Small habits.\nBig life.',
      body:
          'Every great river began as a single raindrop.\n\n'
          'The secret isn\'t motivation — it\'s showing up. '
          'Build the habit of building habits, '
          'and watch what becomes possible.',
    ),
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < _pages.length - 1) {
      _ctrl.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCoralNavy,
      body: SafeArea(
        child: Column(
          children: [
            // Skip
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 16, 0),
                child: _page < _pages.length - 1
                    ? TextButton(
                        onPressed: widget.onComplete,
                        child: Text('Skip',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.65),
                                fontSize: 13)),
                      )
                    : const SizedBox(height: 36),
              ),
            ),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _ctrl,
                onPageChanged: (p) => setState(() => _page = p),
                itemCount: _pages.length,
                itemBuilder: (_, i) => _PageContent(page: _pages[i]),
              ),
            ),

            // Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _page == i ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _page == i
                        ? kCoralPrimary
                        : Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            const SizedBox(height: 28),

            // Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kCoralPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                    elevation: 0,
                  ),
                  child: Text(
                    _page < _pages.length - 1
                        ? 'Next  →'
                        : 'Start My Journey  💧',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _OnboardPage {
  final String title, body;
  const _OnboardPage({required this.title, required this.body});
}

class _PageContent extends StatelessWidget {
  final _OnboardPage page;
  const _PageContent({super.key, required this.page});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 8, 32, 16),
      child: SingleChildScrollView(
        child: Column(
          children: [
            // ── Logo mark at the top ────────────────────
            Image.asset(
              'assets/habitflow_logo_white.png',
              width: 140,
              height: 140,
            ),
            const SizedBox(height: 20),

            // ── Page title ──────────────────────────────
            Text(
              page.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 18),

            // ── Body text ───────────────────────────────
            Text(
              page.body,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
                height: 1.65,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
