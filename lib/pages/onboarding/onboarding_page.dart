import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sky_high/core/services/storage_service.dart';
import 'package:get_it/get_it.dart';
import 'package:sky_high/pages/dashboard/dashboard_page.dart';
import 'dart:math' as math;
import 'package:sky_high/core/services/localization_service.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final LocalizationService _l10n = LocalizationService();

  late final List<OnboardingItem> _items;

  @override
  void initState() {
    super.initState();
    _items = [
      OnboardingItem(
        image: 'assets/Images/spalsh1.svg',
        title: _l10n.tr('onboarding_title_1'),
        description: _l10n.tr('onboarding_desc_1'),
        highlight: _l10n.tr('onboarding_highlight_1'),
        color: const Color(0xFF6C63FF),
        accent: const Color(0xFFFFB347),
      ),
      OnboardingItem(
        image: 'assets/Images/spalsh2.svg',
        title: _l10n.tr('onboarding_title_2'),
        description: _l10n.tr('onboarding_desc_2'),
        highlight: _l10n.tr('onboarding_highlight_2'),
        color: const Color(0xFF4CAF50),
        accent: const Color(0xFF00BCD4),
      ),
      OnboardingItem(
        image: 'assets/Images/spalsh3.svg',
        title: _l10n.tr('onboarding_title_3'),
        description: _l10n.tr('onboarding_desc_3'),
        highlight: _l10n.tr('onboarding_highlight_3'),
        color: const Color(0xFFE91E63),
        accent: const Color(0xFFFFC107),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFD),
      body: Stack(
        children: [
          // Elegant Background Decorations
          const Positioned.fill(child: _BackgroundDecor()),

          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      return OnboardingSlide(item: _items[index]);
                    },
                  ),
                ),
                // Navigation UI
                Padding(
                  padding: const EdgeInsets.fromLTRB(30, 20, 30, 30),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _items.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            margin: const EdgeInsets.symmetric(horizontal: 5),
                            height: 6,
                            width: _currentPage == index ? 32 : 12,
                            decoration: BoxDecoration(
                              color: _currentPage == index
                                  ? _items[_currentPage].color
                                  : Colors.grey.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          if (_currentPage != _items.length - 1)
                            Expanded(
                              child: TextButton(
                                onPressed: () => _finishOnboarding(),
                                child: Text(
                                  _l10n.tr('skip'),
                                  style: GoogleFonts.inter(
                                    color: Colors.grey[400],
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          Expanded(
                            flex: 2,
                            child: GestureDetector(
                              onTap: () {
                                if (_currentPage == _items.length - 1) {
                                  _finishOnboarding();
                                } else {
                                  _pageController.nextPage(
                                    duration: const Duration(milliseconds: 600),
                                    curve: Curves.easeInOut,
                                  );
                                }
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                height: 64,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      _items[_currentPage].color,
                                      _items[_currentPage].color.withOpacity(
                                        0.8,
                                      ),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _items[_currentPage].color
                                          .withOpacity(0.3),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  _currentPage == _items.length - 1
                                      ? _l10n.tr('get_started')
                                      : _l10n.tr('next_step'),
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ).animate().moveY(begin: 30, end: 0),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _finishOnboarding() async {
    await GetIt.I<StorageService>().setIsFirstTime(false);
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const DashboardPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }
}

class _BackgroundDecor extends StatelessWidget {
  const _BackgroundDecor();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Top Left Circle
        Positioned(
          top: -100,
          left: -50,
          child:
              Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB347).withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat())
                  .moveX(
                    begin: 0,
                    end: 20,
                    duration: 4.seconds,
                    curve: Curves.easeInOut,
                  )
                  .moveY(
                    begin: 0,
                    end: 20,
                    duration: 5.seconds,
                    curve: Curves.easeInOut,
                  ),
        ),
        // Bottom Right Circle
        Positioned(
          bottom: -150,
          right: -100,
          child:
              Container(
                    width: 400,
                    height: 400,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF).withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat())
                  .moveX(
                    begin: 0,
                    end: -30,
                    duration: 6.seconds,
                    curve: Curves.easeInOut,
                  )
                  .moveY(
                    begin: 0,
                    end: -20,
                    duration: 4.seconds,
                    curve: Curves.easeInOut,
                  ),
        ),
        // Scatter dots
        ...List.generate(10, (index) {
          final random = math.Random(index);
          return Positioned(
                top: random.nextDouble() * 800,
                left: random.nextDouble() * 400,
                child: Icon(
                  Icons.circle,
                  size: random.nextDouble() * 8 + 4,
                  color: Colors.grey.withOpacity(0.1),
                ),
              )
              .animate(onPlay: (c) => c.repeat())
              .fadeOut(delay: 2.seconds, duration: 2.seconds);
        }),
      ],
    );
  }
}

class OnboardingSlide extends StatelessWidget {
  final OnboardingItem item;

  const OnboardingSlide({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 40.0,
                vertical: 20.0,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // stylized image container
                  Container(
                    height: 320,
                    alignment: Alignment.center,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                              width: 280,
                              height: 280,
                              decoration: BoxDecoration(
                                color: item.color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(40),
                                boxShadow: [
                                  BoxShadow(
                                    color: item.color.withOpacity(0.05),
                                    blurRadius: 40,
                                    spreadRadius: 10,
                                  ),
                                ],
                              ),
                            )
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .rotate(
                              begin: -0.05,
                              end: 0.05,
                              duration: 4.seconds,
                            ),

                        SvgPicture.asset(item.image, height: 260)
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .moveY(
                              begin: -15,
                              end: 15,
                              duration: 3.seconds,
                              curve: Curves.easeInOut,
                            )
                            .scale(
                              begin: const Offset(1, 1),
                              end: const Offset(1.05, 1.05),
                              duration: 3.seconds,
                            ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  Column(
                    children: [
                      Text(
                        item.title,
                        style: GoogleFonts.inter(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1A1A2E),
                          height: 1.1,
                          letterSpacing: -1,
                        ),
                        textAlign: TextAlign.center,
                      ).animate().moveY(begin: 30, end: 0),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: item.accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          item.highlight.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: item.accent,
                            letterSpacing: 2,
                          ),
                        ),
                      ).animate().scale(),
                      const SizedBox(height: 24),
                      Text(
                            item.description,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: Colors.blueGrey[400],
                              height: 1.6,
                              fontWeight: FontWeight.w400,
                            ),
                            textAlign: TextAlign.center,
                          )
                          .animate()
                          .fadeIn(delay: 500.ms)
                          .moveY(begin: 20, end: 0),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class OnboardingItem {
  final String image;
  final String title;
  final String description;
  final String highlight;
  final Color color;
  final Color accent;

  OnboardingItem({
    required this.image,
    required this.title,
    required this.description,
    required this.highlight,
    required this.color,
    required this.accent,
  });
}
