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
          'Build momentum. One habit at a time.\n\n'
          'The largest of oceans stem from the smallest of Swells. '
          'One tap a day is all it takes — drop by drop, your Swell grows and so do you.',
      isWelcome: true,
    ),
    _OnboardPage(
      title: 'How it works',
      emoji: '💧',
      body:
          'Add the habits you want to build, and how often you want to achieve them '
          '— as many or as few as you like.\n\n'
          'Each day, open the app and tap to check them off. '
          'Show up consistently and the rest takes care of itself.\n\n'
          'Add the homescreen Widget to check off habits '
          'without even opening the app!',
    ),
    _OnboardPage(
      title: 'Your Swell Journey',
      emoji: '🌊',
      body:
          'Ocean swells build momentum just like habits — slowly, powerfully, unstoppably.\n\n'
          'Turning up consistently with small habits delivers big results over time. '
          'Each day you show up, the momentum grows stronger, and eventually your habits '
          'will deliver the success you desire.\n\n'
          'With Swell, as you complete your daily habits, you\'ll move through different '
          'stages of growth on route to 180+ days.\n\n'
          '180 days of consistent action and you\'ll have filled your ocean.',
      isJourney: true,
    ),
    _OnboardPage(
      title: 'Small habits.\nBig Achievements.',
      emoji: '🌅',
      body:
          'The secret isn\'t motivation — it\'s the decision to show up, '
          'one day at a time. Make that decision today. Then make it again tomorrow. '
          'Consistently.\n\n'
          'Eventually, your regular positive habits will deliver powerful results.',
    ),
  ];

  // Journey stage data for the carousel
  static const _stages = [
    ('💧', 'Drop',   'Days 1–6',    'Every journey has small beginnings. Your ocean begins with a single drop.'),
    ('💦', 'Puddle', 'Days 7–20',   'A week in — your habits are forming. What starts small becomes unstoppable.'),
    ('🌱', 'Spring', 'Days 21–44',  'Three weeks. The swell beneath you is real. You\'re doing it.'),
    ('🌊', 'Stream', 'Days 45–89',  'Six weeks of momentum. You\'re flowing!'),
    ('🏄', 'Tide',   'Days 90–179', 'Three months. You\'re not building habits anymore — you\'re riding the swell.'),
    ('🌅', 'Ocean',  'Day 180+',    'You rode the swell all the way. You became the kind of person who never stops.'),
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
  final String emoji;
  final bool isWelcome;
  final bool isJourney;
  const _OnboardPage({
    required this.title,
    required this.body,
    this.emoji = '',
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
              // Page 1: "Welcome to" sits above the logo
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
              Image.asset(
                'assets/swell_logo_white.png',
                width: 280,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 24),
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
              // Standard pages: large emoji at top, then title then body
              Text(page.emoji, style: const TextStyle(fontSize: 96)),
              const SizedBox(height: 24),
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

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
      child: Column(
        children: [
          // Emoji
          Text(widget.page.emoji, style: const TextStyle(fontSize: 72)),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              widget.page.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: Text(
              widget.page.body,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.75),
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),

          const SizedBox(height: 12),

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
                  height: 210,
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
                            vertical: 12, horizontal: 16),
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
