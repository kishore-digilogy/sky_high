import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sky_high/core/services/storage_service.dart';
import 'package:sky_high/core/services/localization_service.dart';
import 'package:sky_high/data/models/exam_category_model.dart';
import 'package:sky_high/pages/courses/study_layers_page.dart';

class ContinueStudyingSection extends StatelessWidget {
  final List<Map<String, dynamic>> recentStudies;
  final VoidCallback onStudiesChanged;

  const ContinueStudyingSection({
    super.key,
    required this.recentStudies,
    required this.onStudiesChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (recentStudies.isEmpty) return const SizedBox.shrink();
    final l10n = LocalizationService();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.tr('continue_studying'),
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              TextButton(
                onPressed: () {
                  GetIt.I<StorageService>().clearRecentStudies();
                  onStudiesChanged();
                },
                child: Text(
                  l10n.tr('dismiss_all'),
                  style: GoogleFonts.inter(
                    color: const Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 220,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            scrollDirection: Axis.horizontal,
            itemCount: recentStudies.length,
            itemBuilder: (context, index) {
              final study = recentStudies[index];
              try {
                final company = ExamItemModel.fromJson(study['company']);
                final modIndex = study['modIndex'] as int;
                final modTitle = study['modTitle'] as String;

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StudyLayersPage(
                          company: company,
                          initialModuleIndex: modIndex,
                        ),
                      ),
                    ).then((_) => onStudiesChanged());
                  },
                  child: Container(
                    width: 280,
                    margin: const EdgeInsets.only(right: 16, bottom: 8, top: 4),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: company.fullLogoUrl.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: company.fullLogoUrl,
                                      width: 24,
                                      height: 24,
                                      fit: BoxFit.contain,
                                      placeholder: (context, url) => const Text(
                                        '🧠',
                                        style: TextStyle(fontSize: 24),
                                      ),
                                      errorWidget: (context, url, error) =>
                                          const Text(
                                            '🧠',
                                            style: TextStyle(fontSize: 24),
                                          ),
                                    )
                                  : const Text(
                                      '🧠',
                                      style: TextStyle(fontSize: 24),
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          modTitle,
                                          style: GoogleFonts.inter(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF1E293B),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () async {
                                          await GetIt.I<StorageService>()
                                              .removeRecentStudy(company.id);
                                          onStudiesChanged();
                                        },
                                        child: const Icon(
                                          Icons.close_rounded,
                                          size: 16,
                                          color: Color(0xFFCBD5E1),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    company.name,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: const Color(0xFF94A3B8),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l10n.tr('progress'),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF94A3B8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${((modIndex + 1) / 8 * 100).toInt()}%',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: const Color(0xFF1E293B),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: (modIndex + 1) / 8,
                            backgroundColor: const Color(0xFFF1F5F9),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              const Color(0xFF6366F1).withOpacity(0.8),
                            ),
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6366F1).withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Continue lesson',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.1);
              } catch (e) {
                return const SizedBox.shrink();
              }
            },
          ),
        ),
      ],
    );
  }
}
