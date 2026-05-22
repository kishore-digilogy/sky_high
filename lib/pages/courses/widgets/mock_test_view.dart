import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sky_high/core/services/localization_service.dart';
import 'package:sky_high/data/models/mock_test_set_model.dart';
import 'package:sky_high/pages/exams/mock_test_page.dart';
import 'chapter_folders_view.dart';

class MockTestView extends StatelessWidget {
  final List<MockTestSetModel> mockTests;
  final String? selectedChapterName;
  final String companyName;
  final int companyId;
  final LocalizationService l10n;
  final Function(String?) onChapterChanged;

  const MockTestView({
    super.key,
    required this.mockTests,
    this.selectedChapterName,
    required this.companyName,
    required this.companyId,
    required this.l10n,
    required this.onChapterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final Map<String, List<MockTestSetModel>> grouped = {};
    for (var test in mockTests) {
      final name = test.chapterName ?? 'General';
      if (!grouped.containsKey(name)) {
        grouped[name] = [];
      }
      grouped[name]!.add(test);
    }

    final chapterNames = grouped.keys.toList();
    final Map<String, int> itemCountMap = grouped.map(
      (key, value) => MapEntry(key, value.length),
    );

    if (selectedChapterName == null && chapterNames.isNotEmpty) {
      return ChapterFoldersView(
        chapterNames: chapterNames,
        itemCountMap: itemCountMap,
        onTap: (name) => onChapterChanged(name),
        l10n: l10n,
      );
    }

    final chapterItems = selectedChapterName == null
        ? mockTests
        : grouped[selectedChapterName] ?? [];

    // Group items by topic within chapter
    final Map<String, List<MockTestSetModel>> topicGrouped = {};
    for (var item in chapterItems) {
      final tName = item.topicName ?? 'General Topics';
      if (!topicGrouped.containsKey(tName)) {
        topicGrouped[tName] = [];
      }
      topicGrouped[tName]!.add(item);
    }

    final topicNames = topicGrouped.keys.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (selectedChapterName != null) _buildBackToFoldersButton(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: topicNames.length,
            itemBuilder: (context, tIndex) {
              final topicName = topicNames[tIndex];
              final sets = topicGrouped[topicName]!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopicHeader(topicName, Colors.orange),
                  ...sets.map((test) => _buildMockTestCard(context, test)),
                  const SizedBox(height: 16),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBackToFoldersButton() {
    return InkWell(
      onTap: () => onChapterChanged(null),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
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

  Widget _buildMockTestCard(BuildContext context, MockTestSetModel test) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
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
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MockTestPage(
                setName: test.setName,
                companyName: companyName,
                companyId: companyId,
                chapterId: test.chapterId,
                topicId: test.topicId,
                subtopicId: test.subtopicId,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        Icons.description_outlined,
                        size: 32,
                        color: Colors.grey.withOpacity(0.3),
                      ),
                    ),
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'MOCK TEST',
                          style: TextStyle(
                            fontSize: 6,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  test.setName ?? 'Untitled',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Color(0xFF94A3B8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
