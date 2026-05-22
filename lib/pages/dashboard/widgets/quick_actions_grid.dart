import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sky_high/core/services/localization_service.dart';
import 'package:sky_high/data/models/exam_category_model.dart';
import 'package:sky_high/pages/courses/all_categories_page.dart';
import 'package:sky_high/pages/study_materials/all_study_materials_page.dart';
import 'package:sky_high/pages/dashboard/widgets/dashboard_dialogs.dart';

class QuickActionsGrid extends StatelessWidget {
  final Future<List<ExamCategoryModel>>? categoriesFuture;

  const QuickActionsGrid({
    super.key,
    required this.categoriesFuture,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 180,
              child: _buildActionCard(
                context,
                l10n.tr('my_courses'),
                l10n.tr('continue_learning_sub'),
                const Color(0xFFF5F3FF),
                const Color(0xFF6366F1),
                Icons.assignment_rounded,
                () async {
                  if (categoriesFuture != null) {
                    final categories = await categoriesFuture;
                    if (categories != null && categories.isNotEmpty && context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              AllCategoriesPage(categories: categories),
                        ),
                      );
                    } else if (context.mounted) {
                      DashboardDialogs.showNoContentDialog(
                        context,
                        'no_courses_available',
                        'check_back_later_courses',
                      );
                    }
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SizedBox(
              height: 180,
              child: _buildActionCard(
                context,
                l10n.tr('study_materials'),
                l10n.tr('notes_pdfs_sub'),
                const Color(0xFFF0FDF4),
                const Color(0xFF10B981),
                Icons.auto_stories_rounded,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AllStudyMaterialsPage(),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    String subtitle,
    Color bgColor,
    Color iconColor,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const Spacer(),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: const Color(0xFF64748B),
                      height: 1.3,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: iconColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 10,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
