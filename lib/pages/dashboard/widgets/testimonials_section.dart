import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get_it/get_it.dart';
import 'package:sky_high/core/services/storage_service.dart';
import 'package:sky_high/core/services/exam_service.dart';
import 'package:sky_high/data/models/testimonial_model.dart';
import 'package:sky_high/pages/dashboard/all_testimonials_page.dart';

class TestimonialsSection extends StatefulWidget {
  final Future<List<TestimonialModel>>? testimonialsFuture;
  final VoidCallback onRefresh;

  const TestimonialsSection({
    super.key,
    required this.testimonialsFuture,
    required this.onRefresh,
  });

  @override
  State<TestimonialsSection> createState() => _TestimonialsSectionState();
}

class _TestimonialsSectionState extends State<TestimonialsSection> {
  int? _activeCardIndex;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<TestimonialModel>>(
      future: widget.testimonialsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildTestimonialSkeleton();
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState('No student feedback yet');
        }

        final testimonials = snapshot.data!;
        final storage = GetIt.I<StorageService>();
        final isLoggedIn = storage.getToken() != null;

        final currentUserIdStr = storage.getUserData()?['id']?.toString();
        final hasReviewed = testimonials.any(
          (t) => t.userId.toString() == currentUserIdStr,
        );

        final displayCount = testimonials.length > 4 ? 4 : testimonials.length;

        // Define Z-index sorting: the active card must be drawn last so it renders on top
        List<int> drawIndices = List.generate(displayCount, (i) => i);
        if (_activeCardIndex != null && _activeCardIndex! < displayCount) {
          drawIndices.remove(_activeCardIndex!);
          drawIndices.add(_activeCardIndex!);
        }

        return Column(
          children: [
            const SizedBox(height: 60),
            // "Our Happy Students" Chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F3FF),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.favorite,
                    color: Color(0xFF6366F1),
                    size: 14,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Our Happy Students',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF6366F1),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Header Title
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E293B),
                ),
                children: [
                  const TextSpan(text: 'What Our '),
                  TextSpan(
                    text: 'Students',
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF6366F1),
                      decoration: TextDecoration.underline,
                      decorationColor: const Color(0xFF6366F1).withOpacity(0.3),
                      decorationThickness: 4,
                    ),
                  ),
                  const TextSpan(text: ' Say'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Our students send us bunch of smiles with our services and we love them. ',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: const Color(0xFF64748B),
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Write a Review Button
            if (isLoggedIn && !hasReviewed)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      final navigator = Navigator.of(context);
                      final scaffoldMessenger = ScaffoldMessenger.of(context);

                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) =>
                            const Center(child: CircularProgressIndicator()),
                      );

                      try {
                        final checkRes = await ExamService().checkTestimonial();
                        if (!context.mounted) return;
                        navigator.pop(); // Dismiss loading

                        if (checkRes['hasSubmitted'] == true) {
                          showDialog(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              backgroundColor: Colors.white,
                              surfaceTintColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              title: Row(
                                children: [
                                  const Icon(
                                    Icons.info_outline_rounded,
                                    color: Color(0xFF6366F1),
                                    size: 28,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Already Submitted',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 20,
                                      color: const Color(0xFF1E293B),
                                    ),
                                  ),
                                ],
                              ),
                              content: Text(
                                'You have already submitted a testimonial. Thank you for your feedback!',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  color: const Color(0xFF64748B),
                                  height: 1.5,
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(dialogContext),
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFF6366F1),
                                    textStyle: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                        } else {
                          _showFeedbackDialog(context);
                        }
                      } catch (e) {
                        if (!context.mounted) return;
                        navigator.pop(); // Dismiss loading
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              'Error: ${e.toString().replaceAll('Exception:', '')}',
                              style: GoogleFonts.inter(),
                            ),
                            backgroundColor: const Color(0xFFEF4444),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(30),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 14,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.edit_outlined,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Write a Review',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 40),
            // Scattered Overlapping Chat Cards Stack
            SizedBox(
              height: 420,
              width: double.infinity,
              child: Stack(
                clipBehavior: Clip.none,
                children: drawIndices.map((index) {
                  final testimonial = testimonials[index];
                  final isActive = _activeCardIndex == index;

                  // Custom rotations & responsive offsets mimicking the reference image
                  double rotationAngle = 0.0;
                  double offsetX = 0.0;
                  double offsetY = 0.0;
                  double scaleVal = 0.95;

                  if (isActive) {
                    rotationAngle = 0.0;
                    offsetX = 0.0;
                    offsetY = 20.0;
                    scaleVal = 1.06;
                  } else {
                    // Scattered pile positions
                    if (index == 0) {
                      rotationAngle = -0.06;
                      offsetX = -35.0;
                      offsetY = 50.0;
                      scaleVal = 0.92;
                    } else if (index == 1) {
                      rotationAngle = 0.05;
                      offsetX = 35.0;
                      offsetY = 15.0;
                      scaleVal = 0.94;
                    } else if (index == 2) {
                      rotationAngle = -0.03;
                      offsetX = -15.0;
                      offsetY = 120.0;
                      scaleVal = 0.92;
                    } else if (index == 3) {
                      rotationAngle = 0.04;
                      offsetX = 20.0;
                      offsetY = 170.0;
                      scaleVal = 0.94;
                    }
                  }

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final double screenWidth = constraints.maxWidth;
                      final double cardWidth = (screenWidth * 0.74).clamp(270.0, 320.0);
                      final double centerX = (screenWidth - cardWidth) / 2;

                      return AnimatedPositioned(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutBack,
                        left: centerX + offsetX,
                        top: offsetY,
                        width: cardWidth,
                        child: AnimatedScale(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOutBack,
                          scale: scaleVal,
                          child: AnimatedRotation(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeOutBack,
                            turns: rotationAngle / (2 * 3.1415926535),
                            child: TestimonialCard(
                              testimonial: testimonial,
                              index: index,
                              isExpandedOverride: isActive,
                              onTap: () {
                                setState(() {
                                  if (isActive) {
                                    _activeCardIndex = null;
                                  } else {
                                    _activeCardIndex = index;
                                  }
                                });
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
            ),
            if (testimonials.length > 4) ...[
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AllTestimonialsPage(
                            testimonials: testimonials,
                          ),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'See All Testimonials',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF6366F1),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  void _showFeedbackDialog(BuildContext context) {
    final storage = GetIt.I<StorageService>();
    final user = storage.getUserData();
    final userName = user?['name'] ?? 'Guest';
    final contentController = TextEditingController();
    int selectedStars = 5;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          title: Column(
            children: [
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Give Feedback',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Hi $userName, how was your experience with SkyHigh?',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final isSelected = index < selectedStars;
                  return GestureDetector(
                    onTap: () {
                      setDialogState(() {
                        selectedStars = index + 1;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        isSelected
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: isSelected
                            ? const Color(0xFFFFB300)
                            : const Color(0xFFE2E8F0),
                        size: 40,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: contentController,
                maxLines: 4,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF1E293B),
                ),
                decoration: InputDecoration(
                  hintText: 'Tell us what you liked or what we can improve...',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF94A3B8),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.all(20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(
                      color: const Color(0xFF6366F1).withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () async {
                        final content = contentController.text.trim();
                        if (content.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter your feedback'),
                            ),
                          );
                          return;
                        }

                        final navigator = Navigator.of(context);
                        final scaffoldMessenger = ScaffoldMessenger.of(context);

                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );

                        try {
                          await ExamService().submitTestimonial(
                            stars: selectedStars,
                            content: content,
                            userName: userName,
                          );
                          if (!context.mounted) return;
                          navigator.pop(); // Dismiss loading
                          navigator.pop(); // Dismiss feedback dialog
                          scaffoldMessenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                'Thank you for your feedback!',
                                style: GoogleFonts.inter(),
                              ),
                              backgroundColor: const Color(0xFF10B981),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                          widget.onRefresh();
                        } catch (e) {
                          if (!context.mounted) return;
                          navigator.pop(); // Dismiss loading
                          scaffoldMessenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                'Error submitting: ${e.toString().replaceAll('Exception:', '')}',
                                style: GoogleFonts.inter(),
                              ),
                              backgroundColor: const Color(0xFFEF4444),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Submit',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 48,
            color: const Color(0xFF94A3B8).withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: GoogleFonts.inter(
              color: const Color(0xFF64748B),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestimonialSkeleton() {
    return Column(
      children: [
        const SizedBox(height: 60),
        _buildSkeletonBox(width: 130, height: 24, borderRadius: 20),
        const SizedBox(height: 20),
        _buildSkeletonBox(width: 250, height: 32, borderRadius: 8),
        const SizedBox(height: 16),
        _buildSkeletonBox(width: 300, height: 16, borderRadius: 8),
        const SizedBox(height: 40),
        SizedBox(
          height: 380,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: 3,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              return Container(
                width: 280,
                margin: const EdgeInsets.only(right: 20),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildSkeletonBox(width: 44, height: 44, borderRadius: 22),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSkeletonBox(width: 100, height: 16),
                            const SizedBox(height: 8),
                            _buildSkeletonBox(width: 60, height: 12),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSkeletonBox(height: 12),
                    const SizedBox(height: 8),
                    _buildSkeletonBox(height: 12),
                    const SizedBox(height: 8),
                    _buildSkeletonBox(width: 180, height: 12),
                    const Spacer(),
                    Row(
                      children: List.generate(
                        5,
                        (i) => Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: _buildSkeletonBox(
                            width: 16,
                            height: 16,
                            borderRadius: 4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate(onPlay: (c) => c.repeat()).shimmer(
                    duration: 1200.ms,
                    color: const Color(0xFFF8FAFC),
                  );
            },
          ),
        ),
      ],
    );
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
}

class TestimonialCard extends StatefulWidget {
  final TestimonialModel testimonial;
  final int index;
  final bool? isExpandedOverride;
  final VoidCallback? onTap;

  const TestimonialCard({
    super.key,
    required this.testimonial,
    required this.index,
    this.isExpandedOverride,
    this.onTap,
  });

  @override
  State<TestimonialCard> createState() => _TestimonialCardState();
}

class _TestimonialCardState extends State<TestimonialCard> {
  bool _localExpanded = false;

  @override
  Widget build(BuildContext context) {
    final List<Color> bgColors = [
      const Color(0xFFEFF6FF), // soft blue
      const Color(0xFFF5F3FF), // soft purple
      const Color(0xFFFDF2F8), // soft pink
      const Color(0xFFF0FDF4), // soft green
    ];
    final Color bgColor = bgColors[widget.index % bgColors.length];
    final Color primaryColor = const Color(0xFF6366F1); // modern accent color
    final bool isExpanded = widget.isExpandedOverride ?? _localExpanded;

    return GestureDetector(
      onTap: widget.onTap ?? () {
        setState(() {
          _localExpanded = !_localExpanded;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isExpanded ? primaryColor.withOpacity(0.5) : const Color(0xFFE2E8F0),
            width: isExpanded ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isExpanded ? primaryColor.withOpacity(0.08) : Colors.black.withOpacity(0.02),
              blurRadius: isExpanded ? 15 : 10,
              offset: Offset(0, isExpanded ? 6 : 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  Icons.format_quote_rounded,
                  size: 28,
                  color: primaryColor.withOpacity(0.2),
                ),
                Text(
                  isExpanded ? 'Tap to Collapse' : 'Tap to Read More',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: primaryColor.withOpacity(0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.testimonial.content,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: const Color(0xFF334155),
                height: 1.6,
                fontWeight: FontWeight.w500,
              ),
              maxLines: isExpanded ? null : 2,
              overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Divider(
              height: 1,
              thickness: 1,
              color: primaryColor.withOpacity(0.08),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: primaryColor.withOpacity(0.15),
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    widget.testimonial.initials,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.testimonial.userName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1E293B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.testimonial.userRole != null &&
                          widget.testimonial.userRole!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.testimonial.userRole!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Row(
                  children: List.generate(5, (i) {
                    return Icon(
                      Icons.star_rounded,
                      size: 14,
                      color: i < widget.testimonial.stars
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFFE2E8F0),
                    );
                  }),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
