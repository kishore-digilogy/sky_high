import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sky_high/data/models/exam_category_model.dart';
import 'package:sky_high/pages/courses/all_categories_page.dart';

class DashboardSearchBar extends StatelessWidget {
  final Future<List<ExamCategoryModel>>? categoriesFuture;

  const DashboardSearchBar({
    super.key,
    required this.categoriesFuture,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Row(
          children: [
            const SizedBox(width: 20),
            const Icon(
              Icons.search_rounded,
              color: Color(0xFF94A3B8),
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                onTap: () async {
                  if (categoriesFuture != null) {
                    final categories = await categoriesFuture;
                    if (categories != null && context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AllCategoriesPage(
                            categories: categories,
                            initialIsSearching: true,
                          ),
                        ),
                      );
                    }
                  }
                },
                readOnly: true,
                decoration: InputDecoration(
                  hintText: 'Search courses, tests, subjects...',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF94A3B8),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}
