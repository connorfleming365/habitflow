import 'package:flutter/material.dart';
import '../theme.dart';

// Gradient: dark navy → ocean blue → light mist (top to bottom)
const _kGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    Color(0xFF1E3A5F), // kCoralNavy
    Color(0xFF0E6FA6), // kOceanBlue
    Color(0xFFEAF6FC), // kMist
  ],
  stops: [0.0, 0.55, 1.0],
);

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
      title: 'Welcome to',
      body:
          'The habit tracker that keeps it simple.\n\n'
          'Just your habits, tracked daily — drop by drop.',
      isWelcome: true,
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
          '180 days of consistent habits and you\'ll have filled your ocean.',
      isJourney: true,
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

  // Journey stage data for the carousel
  static const _stages = [
    ('💧', 'Drop',   'Days 1–6',    'Your journey begins.'),
    ('💦', 'Puddle', 'Days 7–20',   'Something real is forming.'),
    ('🌱', 'Spring', 'Days 21–44',  'Your habits are springing to life.'),
    ('🌊', 'Stream', 'Days 45–89',  'You\'re a flowing stream of action.'),
    ('🏄', 'Tide',   'Days 90–179', 'The ocean is within reach.'),
    ('🌅', 'Ocean',  'Day 180+',    'You are the ocean.'),
  ];

  int _stageIndex = 0;

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
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: _kGradient),
        child: SafeArea(
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
                  itemBuilder: (_, i) => _pages[i].isJourney
                      ? _JourneyPage(
                          page: _pages[i],
                          stages: _stages,
                          stageIndex: _stageIndex,
                          onStageChanged: (s) => setState(() => _stageIndex = s),
                        )
                      : _PageContent(page: _pages[i]),
                ),
              ),

              // Page indicator dots
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

              // CTA button
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
      ),
    );
  }
}

// ── Data model ────────────────────────────────────────────
class _OnboardPage {
  final String title, body;
  final bool isWelcome;
  final bool isJourney;
  const _OnboardPage({
    required this.title,
    required this.body,
    this.isWelcome = false,
    this.isJourney = false,
  });
}

// ── Standard page ─────────────────────────────────────────
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
            if (page.isWelcome) ...[
              // Page 1: "Welcome to" → logo → "habitflow" → body
              const SizedBox(height: 20),
              const Text(
                'Welcome to',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 20),
              Image.asset(
                'assets/habitflow_logo_white.png',
                width: 160,
                height: 160,
              ),
              const SizedBox(height: 16),
              const Text(
                'habitflow',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                page.body,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                  height: 1.65,
                ),
              ),
            ] else ...[
              // Standard: logo → title → body
              Image.asset(
                'assets/habitflow_logo_white.png',
                width: 140,
                height: 140,
              ),
              const SizedBox(height: 20),
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
          ],
        ),
      ),
    );
  }
}

// ── Journey page with stage carousel ─────────────────────
class _JourneyPage extends StatelessWidget {
  final _OnboardPage page;
  final List<(String, String, String, String)> stages;
  final int stageIndex;
  final ValueChanged<int> onStageChanged;

  const _JourneyPage({
    required this.page,
    required this.stages,
    required this.stageIndex,
    required this.onStageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final (emoji, name, days, desc) = stages[stageIndex];

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
      child: Column(
        children: [
          // Logo + title + intro text
          Image.asset('assets/habitflow_logo_white.png', width: 100, height: 100),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              page.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: Text(
              page.body,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.75),
                fontSize: 12,
                height: 1.6,
              ),
            ),
          ),

          const Spacer(),

          // Stage carousel
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                // Left arrow
                GestureDetector(
                  onTap: stageIndex > 0
                      ? () => onStageChanged(stageIndex - 1)
                      : null,
                  child: AnimatedOpacity(
                    opacity: stageIndex > 0 ? 1.0 : 0.2,
                    duration: const Duration(milliseconds: 200),
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('‹',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w300)),
                    ),
                  ),
                ),
                // Stage card
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Container(
                      key: ValueKey(stageIndex),
                      padding: const EdgeInsets.symmetric(
                          vertical: 20, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.13),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.25), width: 1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(emoji,
                            style: const TextStyle(fontSize: 36)),
                        const SizedBox(height: 8),
                        Text(name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(height: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 3),
                          decoration: BoxDecoration(
                            color: kCoralPrimary.withOpacity(0.35),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(days,
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(height: 10),
                        Text(desc,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.78),
                                fontSize: 13,
                                height: 1.5)),
                      ]),
                    ),
                  ),
                ),
                // Right arrow
                GestureDetector(
                  onTap: stageIndex < stages.length - 1
                      ? () => onStageChanged(stageIndex + 1)
                      : null,
                  child: AnimatedOpacity(
                    opacity: stageIndex < stages.length - 1 ? 1.0 : 0.2,
                    duration: const Duration(milliseconds: 200),
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('›',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w300)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Carousel progress dots
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(stages.length, (i) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == stageIndex ? 16 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == stageIndex
                      ? kCoralPrimary
                      : Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
