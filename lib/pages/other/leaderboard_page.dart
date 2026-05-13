import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LeaderboardPage extends StatelessWidget {
  const LeaderboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildIllustrationSection(),
            const SizedBox(height: 30),
            _buildStepsSection(),
            const SizedBox(height: 24),
            _buildConsistencyBanner(),
            const SizedBox(height: 40),
            //_buildActionButton(context),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      leadingWidth: 70,
      leading: Padding(
        padding: const EdgeInsets.only(left: 20),
        child: Center(
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.chevron_left_rounded,
                color: Color(0xFF6366F1),
                size: 28,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 2.5,
            decoration: BoxDecoration(
              color: const Color(0xFFC7D2FE),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Leaderboard',
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF1E293B),
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 20,
            height: 2.5,
            decoration: BoxDecoration(
              color: const Color(0xFFC7D2FE),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 20),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: Color(0xFF6366F1),
              size: 22,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIllustrationSection() {
    return Column(
      children: [
        // Podium Illustration using the provided SVG
        Center(
          child: SvgPicture.asset(
            'assets/Icons/leaderboard.svg',
            height: 220,
            placeholderBuilder: (context) => Container(
              height: 220,
              width: 220,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.leaderboard_rounded,
                size: 80,
                color: Color(0xFFC7D2FE),
              ),
            ),
          ),
        ).animate().scale(duration: 600.ms, curve: Curves.easeOut),
        const SizedBox(height: 24),
        Text(
          'No Rankings Yet!',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'The leaderboard is empty for now.\nStart learning and be the first to make it here!',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: const Color(0xFF64748B),
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Climb the leaderboard',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF6366F1),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.trending_up_rounded,
                color: Color(0xFF6366F1),
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildStepItem(
            'Study & Learn',
            'Complete modules and expand your knowledge',
            Icons.menu_book_rounded,
            const Color(0xFFEEF2FF),
            const Color(0xFF6366F1),
            true,
          ),
          _buildStepItem(
            'Take Tests',
            'Attempt tests and improve your score',
            Icons.assignment_turned_in_rounded,
            const Color(0xFFFFF1F2),
            const Color(0xFFFB7185),
            true,
          ),
          _buildStepItem(
            'Earn Points',
            'Score higher and climb the ranks',
            Icons.stars_rounded,
            const Color(0xFFF0FDF4),
            const Color(0xFF22C55E),
            false,
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(
    String title,
    String subtitle,
    IconData icon,
    Color bgColor,
    Color iconColor,
    bool hasPath,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFCBD5E1),
              size: 24,
            ),
          ],
        ),
        if (hasPath)
          Container(
            height: 30,
            margin: const EdgeInsets.only(left: 24),
            child: Column(
              children: List.generate(
                3,
                (index) => Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  width: 2,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildConsistencyBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF5F3FF), Color(0xFFEDE9FE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          Row(
            children: [
              const Text('🔥', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Be consistent today,',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      'Lead the leaderboard tomorrow!',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            right: 0,
            top: 0,
            child: Icon(
              Icons.auto_awesome_rounded,
              color: const Color(0xFF8B5CF6).withOpacity(0.3),
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildActionButton(BuildContext context) {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(horizontal: 24),
  //     child: Container(
  //       width: double.infinity,
  //       height: 64,
  //       decoration: BoxDecoration(
  //         gradient: const LinearGradient(
  //           colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
  //           begin: Alignment.centerLeft,
  //           end: Alignment.centerRight,
  //         ),
  //         borderRadius: BorderRadius.circular(20),
  //         boxShadow: [
  //           BoxShadow(
  //             color: const Color(0xFF6366F1).withOpacity(0.3),
  //             blurRadius: 15,
  //             offset: const Offset(0, 8),
  //           ),
  //         ],
  //       ),
  //       child: Material(
  //         color: Colors.transparent,
  //         child: InkWell(
  //           onTap: () => Navigator.pop(context),
  //           borderRadius: BorderRadius.circular(20),
  //           child: Row(
  //             mainAxisAlignment: MainAxisAlignment.center,
  //             children: [
  //               const Text('🚀', style: TextStyle(fontSize: 22)),
  //               const SizedBox(width: 12),
  //               Text(
  //                 'Back to Dashboard',
  //                 style: GoogleFonts.plusJakartaSans(
  //                   color: Colors.white,
  //                   fontWeight: FontWeight.w800,
  //                   fontSize: 16,
  //                 ),
  //               ),
  //               const SizedBox(width: 12),
  //               const Icon(
  //                 Icons.arrow_forward_rounded,
  //                 color: Colors.white,
  //                 size: 20,
  //               ),
  //             ],
  //           ),
  //         ),
  //       ),
  //     ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
  //   );
  // }
}
