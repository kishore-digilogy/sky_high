import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sky_high/core/services/localization_service.dart';
import 'package:sky_high/data/models/study_layer_model.dart';
import 'package:sky_high/pages/study_materials/pdf_viewer_page.dart';
import 'package:sky_high/pages/courses/video_player_page.dart';
import 'chapter_folders_view.dart';

class StudyMaterialsView extends StatelessWidget {
  final List<StudyLayerModel> apiLayers;
  final String layerName;
  final int selectedModuleIndex;
  final String? selectedChapterName;
  final bool isPaidUser;
  final String currentLangCode;
  final LocalizationService l10n;
  final Function(String?) onChapterChanged;
  final VoidCallback onLockedAlert;
  final Widget emptyContent;
  final Widget dummyFoldersView;

  const StudyMaterialsView({
    super.key,
    required this.apiLayers,
    required this.layerName,
    required this.selectedModuleIndex,
    this.selectedChapterName,
    required this.isPaidUser,
    required this.currentLangCode,
    required this.l10n,
    required this.onChapterChanged,
    required this.onLockedAlert,
    required this.emptyContent,
    required this.dummyFoldersView,
  });

  @override
  Widget build(BuildContext context) {
    final filteredItems = apiLayers
        .where((item) => item.layer.toLowerCase() == layerName.toLowerCase())
        .toList();

    if (filteredItems.isEmpty) {
      return (selectedModuleIndex >= 3 && selectedModuleIndex <= 7)
          ? dummyFoldersView
          : emptyContent;
    }

    // Always show folders first if no chapter is selected (Skip for first 3 modules)
    if (selectedChapterName == null && selectedModuleIndex >= 3) {
      return _buildRealChapterFoldersView(context, filteredItems);
    }

    final itemsToShow = selectedChapterName == null
        ? filteredItems
        : filteredItems
              .where(
                (item) =>
                    (item.chapterName ?? 'General') == selectedChapterName,
              )
              .toList();

    final Map<String, List<StudyLayerModel>> topicGrouped = {};
    for (var item in itemsToShow) {
      final tName = item.topicName ?? 'General Topics';
      if (!topicGrouped.containsKey(tName)) {
        topicGrouped[tName] = [];
      }
      topicGrouped[tName]!.add(item);
    }
    final topicNames = topicGrouped.keys.toList();

    final bool useGrid = layerName.toLowerCase() != 'basic_info';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (selectedChapterName != null)
                InkWell(
                  onTap: () => onChapterChanged(null),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 14,
                          color: Color(0xFF6366F1),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Back to Folders',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF6366F1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      selectedChapterName ?? l10n.tr('available_materials'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1E293B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    children: [
                      Text(
                        l10n
                            .tr('items_count')
                            .replaceAll(
                              '{count}',
                              itemsToShow.length.toString(),
                            ),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.filter_list_rounded,
                        size: 18,
                        color: Color(0xFF64748B),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: topicNames.length,
            itemBuilder: (context, tIndex) {
              final topicName = topicNames[tIndex];
              final items = topicGrouped[topicName]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopicHeader(topicName, const Color(0xFF6366F1)),
                  if (useGrid)
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.78,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        return _buildLayerContentCard(
                          context,
                          items[index],
                          isGrid: true,
                        );
                      },
                    )
                  else
                    Column(
                      children: items
                          .map(
                            (item) =>
                                _buildLayerContentCard(context, item, isGrid: false),
                          )
                          .toList(),
                    ),
                  const SizedBox(height: 24),
                ],
              );
            },
          ),
        ),
        if (useGrid) _buildFooterBanner(),
      ],
    );
  }

  Widget _buildRealChapterFoldersView(
    BuildContext context,
    List<StudyLayerModel> items,
  ) {
    final Map<String, List<StudyLayerModel>> grouped = {};
    for (var item in items) {
      final name = item.chapterName ?? 'General';
      if (!grouped.containsKey(name)) {
        grouped[name] = [];
      }
      grouped[name]!.add(item);
    }

    final chapterNames = grouped.keys.toList();
    final Map<String, int> itemCountMap = grouped.map(
      (key, value) => MapEntry(key, value.length),
    );

    return ChapterFoldersView(
      chapterNames: chapterNames,
      itemCountMap: itemCountMap,
      onTap: (name) => onChapterChanged(name),
      l10n: l10n,
    );
  }

  Widget _buildTopicHeader(String topicName, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 16),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'TOPIC: ${topicName.toUpperCase()}',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDBEAFE)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.article_rounded,
              color: Color(0xFF3B82F6),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'New materials will be added regularly.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E40AF),
                  ),
                ),
                Text(
                  'Keep learning, keep growing! 🚀',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: const Color(0xFF60A5FA),
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.auto_awesome_rounded,
            color: Color(0xFF93C5FD),
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildLayerContentCard(
    BuildContext context,
    StudyLayerModel item, {
    required bool isGrid,
  }) {
    final title = item.getLocalizedTitle(currentLangCode);
    final date = item.getFormattedDate();
    final isLocked = !item.isFree && !isPaidUser;
    final url = item.getLocalizedUrl(currentLangCode);

    if (isGrid) {
      return _buildGridResourceCard(context, item, title, url, date, isLocked);
    }

    if (url != null) {
      return _buildResourceCard(context, item, title, url, date, isLocked);
    }

    if (item.layer.toLowerCase() == 'basic_info' ||
        item.layer.toLowerCase() == 'syllabus' ||
        item.layer.toLowerCase() == 'preparation_plan') {
      final content = item.getLocalizedContent(currentLangCode);
      return _buildBasicInfoCard(item, title, content, date);
    } else {
      return _buildResourceCard(context, item, title, url, date, isLocked);
    }
  }

  Widget _buildGridResourceCard(
    BuildContext context,
    StudyLayerModel item,
    String title,
    String? url,
    String date,
    bool isLocked,
  ) {
    final bool isPdf = url?.toLowerCase().endsWith('.pdf') ?? false;
    final Color color = const Color(0xFF6366F1);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (isLocked) {
              onLockedAlert();
            } else if (url != null) {
              if (isPdf) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PdfViewerPage(pdfUrl: url, title: title),
                  ),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        VideoPlayerPage(videoUrl: url, title: title),
                  ),
                );
              }
            }
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildResourceIcon(isPdf),
                const Spacer(),
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: const Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isPdf ? 'View PDF' : 'Watch Video',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 8,
                        color: color,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResourceIcon(bool isPdf) {
    return Container(
      width: 50,
      height: 65,
      decoration: BoxDecoration(
        color: const Color(0xFFFFE4E6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            isPdf
                ? Icons.description_rounded
                : Icons.play_circle_filled_rounded,
            color: const Color(0xFFFB7185),
            size: 32,
          ),
          Positioned(
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFFFB7185),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                isPdf ? 'PDF' : 'VIDEO',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 7,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoCard(
    StudyLayerModel item,
    String title,
    String? content,
    String date,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                date,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFF94A3B8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if (content != null && content.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              content,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF64748B),
                height: 1.6,
              ),
            ),
          ],
          if (item.imagesGallery.isNotEmpty) ...[
            const SizedBox(height: 20),
            SizedBox(
              height: 120, // Flexible height for images
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: item.imagesGallery.length,
                itemBuilder: (context, idx) {
                  final imgPath = item.imagesGallery[idx];
                  final fullUrl = item.getFullImageUrl(imgPath);
                  return Container(
                    margin: const EdgeInsets.only(right: 12),
                    width: 160,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: const Color(0xFFF1F5F9),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.network(
                      fullUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Center(
                        child: Icon(
                          Icons.broken_image_rounded,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResourceCard(
    BuildContext context,
    StudyLayerModel item,
    String title,
    String? url,
    String date,
    bool isLocked,
  ) {
    if (url == null && !isLocked) return const SizedBox.shrink();

    final bool isPdf = url?.toLowerCase().endsWith('.pdf') ?? false;
    final bool isVideo = url?.toLowerCase().endsWith('.mp4') ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                date,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFF94A3B8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (url != null && !isLocked)
            _buildActionButton(context, title, url, isPdf, isVideo)
          else
            _buildNotAvailablePrompt(),
        ],
      ),
    );
  }

  Widget _buildNotAvailablePrompt() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: Color(0xFF64748B),
          ),
          const SizedBox(width: 12),
          Text(
            'Not available in this language',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String title,
    String url,
    bool isPdf,
    bool isVideo,
  ) {
    return ElevatedButton(
      onPressed: () {
        if (isPdf) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PdfViewerPage(pdfUrl: url, title: title),
            ),
          );
        } else if (isVideo) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  VideoPlayerPage(videoUrl: url, title: title),
            ),
          );
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isPdf
            ? const Color(0xFFEF4444)
            : const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isPdf
                ? Icons.picture_as_pdf_rounded
                : Icons.play_circle_fill_rounded,
            size: 20,
          ),
          const SizedBox(width: 10),
          Text(
            isPdf ? 'View PDF' : 'Watch Video',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
