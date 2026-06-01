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
      emoji: '🌊',
      title: 'Welcome to HabitFlow',
      body:
          'The habit tracker that keeps it simple.\n\n'
          'No complex dashboards. No overwhelm. '
          'Just your habits, tracked daily — drop by drop.',
    ),
    _OnboardPage(
      emoji: '💧',
      title: 'How it works',
      body:
          'Add the habits you want to build.\n\n'
          'Every day, open the app and tap to check them off. '
          'That\'s it. Small, consistent action is all it takes.',
    ),
    _OnboardPage(
      emoji: '🌊',
      title: 'Your water journey',
      body:
          'Every drop counts. Each day you check in, your water rises.\n\n'
          '💧 Drop — Days 1 to 6\n'
          'Your journey begins. One drip at a time.\n\n'
          '💦 Puddle — Days 7 to 20\n'
          'A week in. Small but real.\n\n'
          '🏞 Stream — Days 21 to 59\n'
          'A habit is forming. Keep flowing.\n\n'
          '🏔 Lake — Days 60 to 179\n'
          'Two months of consistency. Impressive.\n\n'
          '🌊 Ocean — Day 180+\n'
          'You\'ve built something extraordinary.',
    ),
    _OnboardPage(
      emoji: '🌅',
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
      backgroundColor: kDeepOcean,
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
                        child: const Text('Skip',
                            style: TextStyle(color: kSeaFoam, fontSize: 13)),
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
                        ? kReefBlue
                        : kOceanBlue.withOpacity(0.35),
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
                    backgroundColor: kReefBlue,
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
  final String emoji, title, body;
  const _OnboardPage(
      {required this.emoji, required this.title, required this.body});
}

class _PageContent extends StatelessWidget {
  final _OnboardPage page;
  const _PageContent({super.key, required this.page});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 16, 32, 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Decorative circle behind emoji
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: kOceanBlue.withOpacity(0.18),
              border: Border.all(
                  color: kReefBlue.withOpacity(0.3), width: 1),
            ),
            alignment: Alignment.center,
            child: Text(page.emoji,
                style: const TextStyle(fontSize: 54)),
          ),
          const SizedBox(height: 36),
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
          const SizedBox(height: 20),
          Text(
            page.body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: kSeaFoam,
              fontSize: 15,
              height: 1.65,
            ),
          ),
        ],
      ),
    );
  }
}
