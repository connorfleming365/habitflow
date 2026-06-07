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

              // Pages — physics: ClampingScrollPhysics so swipes reach the parent
              Expanded(
                child: PageView.builder(
                  controller: _ctrl,
                  physics: const ClampingScrollPhysics(),
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
            // Logo at top — same size and position on every page
            Image.asset(
              'assets/habitflow_logo_white.png',
              width: page.isWelcome ? 200 : 170,
              height: page.isWelcome ? 200 : 170,
            ),
            const SizedBox(height: 24),
            if (page.isWelcome) ...[
              // Page 1: "Welcome to" is the title, larger and lighter weight
              const Text(
                'Welcome to',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                page.body,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 16,
                  height: 1.65,
                ),
              ),
            ] else ...[
              // Standard pages: title then body, same sizes across all
              Text(
                page.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
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
                  fontSize: 16,
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

// ── Journey page with swipeable stage carousel ───────────
class _JourneyPage extends StatefulWidget {
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
  State<_JourneyPage> createState() => _JourneyPageState();
}

class _JourneyPageState extends State<_JourneyPage> {
  late PageController _carouselCtrl;

  @override
  void initState() {
    super.initState();
    _carouselCtrl = PageController(initialPage: widget.stageIndex);
  }

  @override
  void didUpdateWidget(_JourneyPage old) {
    super.didUpdateWidget(old);
    // Sync controller if parent changed index via arrows
    if (widget.stageIndex != old.stageIndex &&
        _carouselCtrl.hasClients &&
        (_carouselCtrl.page?.round() ?? 0) != widget.stageIndex) {
      _carouselCtrl.animateToPage(
        widget.stageIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _carouselCtrl.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    _carouselCtrl.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    widget.onStageChanged(index);
  }

  @override
  Widget build(BuildContext context) {
    final idx = widget.stageIndex;
    final count = widget.stages.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
      child: Column(
        children: [
          // Logo — same size and position as other pages
          Image.asset('assets/habitflow_logo_white.png', width: 170, height: 170),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              widget.page.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: Text(
              widget.page.body,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.75),
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ),

          const Spacer(),

          // Carousel: arrows + swipeable PageView
          Row(
            children: [
              // Left arrow
              GestureDetector(
                onTap: idx > 0 ? () => _goTo(idx - 1) : null,
                child: AnimatedOpacity(
                  opacity: idx > 0 ? 1.0 : 0.2,
                  duration: const Duration(milliseconds: 200),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text('‹',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w300)),
                  ),
                ),
              ),

              // Swipeable stage cards
              Expanded(
                child: SizedBox(
                  height: 190,
                  child: PageView.builder(
                    controller: _carouselCtrl,
                    physics: const ClampingScrollPhysics(),
                    itemCount: count,
                    onPageChanged: widget.onStageChanged,
                    itemBuilder: (_, i) {
                      final (emoji, name, days, desc) = widget.stages[i];
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(
                            vertical: 20, horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E3A5F), // solid navy
                          border: Border.all(
                              color: Colors.white.withOpacity(0.2), width: 1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Text(emoji, style: const TextStyle(fontSize: 36)),
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
                              color: kCoralPrimary.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(days,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                          ),
                          const SizedBox(height: 10),
                          Text(desc,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.85),
                                  fontSize: 13,
                                  height: 1.5)),
                        ]),
                      );
                    },
                  ),
                ),
              ),

              // Right arrow
              GestureDetector(
                onTap: idx < count - 1 ? () => _goTo(idx + 1) : null,
                child: AnimatedOpacity(
                  opacity: idx < count - 1 ? 1.0 : 0.2,
                  duration: const Duration(milliseconds: 200),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text('›',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w300)),
                  ),
                ),
              ),
            ],
          ),

          // Carousel progress dots
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(count, (i) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == idx ? 16 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == idx
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
