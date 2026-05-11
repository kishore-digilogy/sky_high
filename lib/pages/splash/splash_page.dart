import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get_it/get_it.dart';
import 'package:sky_high/core/services/storage_service.dart';
import 'package:sky_high/pages/dashboard/dashboard_page.dart';
import 'package:sky_high/pages/onboarding/onboarding_page.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  void _navigateToNext() async {
    // Show splash for 2.5 seconds
    await Future.delayed(const Duration(milliseconds: 2500));

    if (!mounted) return;

    final storageService = GetIt.I<StorageService>();
    final isFirstTime = storageService.getIsFirstTime();

    if (isFirstTime) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OnboardingPage()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo
            Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6C63FF).withOpacity(0.1),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: SvgPicture.asset(
                    'assets/Images/app_logo.svg',
                    width: 140,
                    height: 140,
                  ),
                )
                .animate()
                .fadeIn(duration: 800.ms)
                .scale(delay: 200.ms, duration: 600.ms, curve: Curves.easeInOut)
                .shimmer(delay: 1200.ms, duration: 1500.ms),

            const SizedBox(height: 30),

            // App Name
            Text(
                  'SKY HIGH',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                    color: const Color(0xFF0F172A),
                  ),
                )
                .animate()
                .fadeIn(delay: 600.ms)
                .slideY(begin: 0.3, curve: Curves.easeOutQuad),

            const SizedBox(height: 10),

            // Tagline
            Text(
              'Reach for the stars',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
                letterSpacing: 1.5,
              ),
            ).animate().fadeIn(delay: 1000.ms),
          ],
        ),
      ),
    );
  }
}
