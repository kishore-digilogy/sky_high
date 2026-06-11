import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sky_high/core/services/localization_service.dart';
import 'package:sky_high/data/models/free_exam_model.dart';
import 'package:sky_high/pages/exams/widgets/free_exams_table.dart';
import 'package:sky_high/pages/exams/all_free_exams_page.dart';

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
                  Expanded(
                    child: Text(
                      l10n.tr('free_exams'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: l10n.getSelectedLanguage() != 'English'
                            ? 17
                            : 20,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  //  Container(
                  //    padding: const EdgeInsets.symmetric(
                  //      horizontal: 10,
                  //      vertical: 4,
                  //    ),
                  //    decoration: BoxDecoration(
                  //      color: const Color(0xFF10B981).withOpacity(0.1),
                  //      borderRadius: BorderRadius.circular(20),
                  //    ),
                  //    child: Text(
                  //      'FREE',
                  //      style: GoogleFonts.inter(
                  //        fontSize: 11,
                  //        fontWeight: FontWeight.w500,
                  //        color: const Color(0xFF10B981),
                  //      ),
                  //    ),
                  //  ),
                  if (exams.length > 4) ...[
                    const SizedBox(width: 16),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                AllFreeExamsPage(exams: exams),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'See All',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF6366F1),
                        ),
                      ),
                    ),
                  ],
                ],
              ).animate(),
            ),
            const SizedBox(height: 15),
            if (snapshot.hasError || exams.isEmpty)
              _buildEmptyState('No mock tests available')
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FreeExamsTable(
                  exams: exams.length > 4 ? exams.sublist(0, 4) : exams,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.assignment_outlined,
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

  Widget _buildFreeExamSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child:
              Container(
                    width: 150,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  )
                  .animate(onPlay: (controller) => controller.repeat())
                  .shimmer(
                    duration: const Duration(milliseconds: 1500),
                    color: Colors.white54,
                  ),
        ),
        const SizedBox(height: 15),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child:
              Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                  )
                  .animate(onPlay: (controller) => controller.repeat())
                  .shimmer(
                    duration: const Duration(milliseconds: 1500),
                    color: Colors.white54,
                  ),
        ),
      ],
    );
  }
}
