import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sky_high/core/services/localization_service.dart';
import 'package:sky_high/data/models/free_exam_model.dart';
import 'package:sky_high/pages/exams/mock_test_page.dart';

class FreeExamsSection extends StatelessWidget {
  final Future<List<FreeExamModel>>? freeExamsFuture;

  const FreeExamsSection({super.key, required this.freeExamsFuture});

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();

    return FutureBuilder<List<FreeExamModel>>(
      future: freeExamsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildFreeExamSkeleton();
        }

        final exams = snapshot.hasData ? snapshot.data! : <FreeExamModel>[];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  const SizedBox(width: 0),
                  Text(
                    l10n.tr('free_exams'),
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'FREE',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                  ),
                ],
              ).animate(),
            ),
            const SizedBox(height: 15),
            if (snapshot.hasError || exams.isEmpty)
              _buildEmptyState('No mock tests available')
            else
              SizedBox(
                height: 250, // Increased height to prevent bottom overflow
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: exams.length,
                  itemBuilder: (context, index) {
                    return _buildFreeExamCard(context, exams[index], index);
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildFreeExamCard(
    BuildContext context,
    FreeExamModel exam,
    int index,
  ) {
    final configs = [
      {
        'color': const Color(0xFF3B82F6),
        'bg': const Color(0xFFF0F6FF),
        'tagBg': const Color(0xFFDCEAFD),
        'tagFg': const Color(0xFF1D4ED8),
      },
      {
        'color': const Color(0xFF8B5CF6),
        'bg': const Color(0xFFF5F3FF),
        'tagBg': const Color(0xFFEDE9FE),
        'tagFg': const Color(0xFF6D28D9),
      },
      {
        'color': const Color(0xFF059669),
        'bg': const Color(0xFFF0FDF8),
        'tagBg': const Color(0xFFD1FAE5),
        'tagFg': const Color(0xFF065F46),
      },
      {
        'color': const Color(0xFFF59E0B),
        'bg': const Color(0xFFFFFBEB),
        'tagBg': const Color(0xFFFEF3C7),
        'tagFg': const Color(0xFF92400E),
      },
      {
        'color': const Color(0xFFEF4444),
        'bg': const Color(0xFFFFF5F5),
        'tagBg': const Color(0xFFFEE2E2),
        'tagFg': const Color(0xFF991B1B),
      },
    ];

    final cfg = configs[index % configs.length];
    final color = cfg['color'] as Color;
    final bgColor = cfg['bg'] as Color;
    final tagBg = cfg['tagBg'] as Color;
    final tagFg = cfg['tagFg'] as Color;

    IconData examIcon = Icons.quiz_outlined;
    if (exam.setName.contains('ALP')) {
      examIcon = Icons.train_outlined;
    } else if (exam.setName.contains('NTPC')) {
      examIcon = Icons.directions_railway_outlined;
    } else if (exam.setName.contains('SSC')) {
      examIcon = Icons.account_balance_outlined;
    } else if (exam.setName.contains('UPSC')) {
      examIcon = Icons.gavel_outlined;
    }

    return SizedBox(
      width: 180, // Fixed width instead of percentage to prevent weird scaling
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        child: _HoverCard(
          color: color,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: color.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Icon(examIcon, color: color, size: 20),
                      ),
                      const SizedBox(height: 10),
                      // Removed SizedBox with hardcoded width, let it flex inside the card
                      Text(
                        exam.setName,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E293B),
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFE2E8F0),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: tagBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              exam.displayCategory,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: tagFg,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(
                                Icons.help_outline_rounded,
                                size: 12,
                                color: Color(0xFF94A3B8),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '${exam.formattedCount} Qs',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                width: 3,
                                height: 3,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFCBD5E1),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Free',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF059669),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: _ShimmerButton(
                              color: color,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        MockTestPage(setName: exam.setName),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(delay: (60 + 100 * index).ms, duration: 350.ms)
        .slideY(begin: 0.15, curve: Curves.easeOutCubic);
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      height: 140,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE9E4FF)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              left: -30,
              top: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              right: -20,
              bottom: 20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFFE9E4FF).withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              left: 20,
              top: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  width: 80,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 5,
                        left: 25,
                        right: 25,
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: const Color(0xFFC4B5FD),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            3,
                            (i) => Container(
                              margin: const EdgeInsets.symmetric(
                                vertical: 4,
                                horizontal: 12,
                              ),
                              height: 6,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F3FF),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: i == 0
                                  ? Row(
                                      children: [
                                        Container(
                                          width: 6,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFC4B5FD),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ],
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: -5,
                        bottom: 20,
                        child: Transform.rotate(
                          angle: -0.5,
                          child: Container(
                            width: 12,
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              right: 40,
              top: 0,
              bottom: 0,
              child: Center(
                child: Opacity(
                  opacity: 0.6,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 60,
                        height: 45,
                        decoration: BoxDecoration(
                          color: const Color(0xFFC4B5FD),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              top: -10,
                              left: 5,
                              child: Transform.rotate(
                                angle: 0.5,
                                child: Container(
                                  width: 30,
                                  height: 20,
                                  color: const Color(0xFFDDD6FE),
                                ),
                              ),
                            ),
                            Positioned(
                              top: -10,
                              right: 5,
                              child: Transform.rotate(
                                angle: -0.5,
                                child: Container(
                                  width: 30,
                                  height: 20,
                                  color: const Color(0xFFDDD6FE),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 110, right: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1E293B),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Check back later for new updates',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms);
  }

  Widget _buildSkeletonBox({
    double width = double.infinity,
    double height = 14,
    double borderRadius = 8,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }

  Widget _buildFreeExamSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              _buildSkeletonBox(width: 36, height: 36, borderRadius: 10),
              const SizedBox(width: 12),
              _buildSkeletonBox(width: 140, height: 20),
              const Spacer(),
              _buildSkeletonBox(width: 60, height: 24, borderRadius: 20),
            ],
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 160,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              return Container(
                    width: 240,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSkeletonBox(width: 160, height: 16),
                        const SizedBox(height: 8),
                        _buildSkeletonBox(width: 100, height: 12),
                        const Spacer(),
                        Row(
                          children: [
                            _buildSkeletonBox(
                              width: 70,
                              height: 24,
                              borderRadius: 8,
                            ),
                            const Spacer(),
                            _buildSkeletonBox(width: 50, height: 10),
                          ],
                        ),
                      ],
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat())
                  .shimmer(duration: 1200.ms, color: const Color(0xFFF8FAFC));
            },
          ),
        ),
      ],
    );
  }
}

// ── Hover lift card ────────────────────────────────────────────────────────────
class _HoverCard extends StatefulWidget {
  final Widget child;
  final Color color;
  const _HoverCard({required this.child, required this.color});

  @override
  State<_HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<_HoverCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _lift;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _lift = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _ctrl.forward(),
      onExit: (_) => _ctrl.reverse(),
      child: GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) => _ctrl.reverse(),
        onTapCancel: () => _ctrl.reverse(),
        child: AnimatedBuilder(
          animation: _lift,
          builder: (_, child) => Transform.translate(
            offset: Offset(0, -5 * _lift.value),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(0.15 * _lift.value),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: child,
            ),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

// ── Shimmer start button ───────────────────────────────────────────────────────
class _ShimmerButton extends StatefulWidget {
  final Color color;
  final VoidCallback? onTap;

  const _ShimmerButton({required this.color, this.onTap});

  @override
  State<_ShimmerButton> createState() => _ShimmerButtonState();
}

class _ShimmerButtonState extends State<_ShimmerButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _shimmer = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _shimmer,
        builder: (_, __) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: FractionalTranslation(
                      translation: Offset(-2 + _shimmer.value * 4, 0),
                      child: Transform.rotate(
                        angle: -0.4,
                        child: Container(
                          width: 36,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.white.withOpacity(0.22),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.play_circle_outline_rounded,
                      color: Colors.white,
                      size: 15,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Start Now',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
