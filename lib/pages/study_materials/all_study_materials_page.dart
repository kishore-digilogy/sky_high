import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sky_high/data/models/study_material_model.dart';
import 'package:sky_high/core/services/exam_service.dart';
import 'package:sky_high/pages/study_materials/pdf_viewer_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AllStudyMaterialsPage extends StatefulWidget {
  const AllStudyMaterialsPage({super.key});

  @override
  State<AllStudyMaterialsPage> createState() => _AllStudyMaterialsPageState();
}

class _AllStudyMaterialsPageState extends State<AllStudyMaterialsPage> {
  late Future<List<StudyMaterialModel>> _materialsFuture;
  List<StudyMaterialModel> _allMaterials = [];
  List<StudyMaterialModel> _filteredMaterials = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMaterials();
  }

  void _loadMaterials() {
    _materialsFuture = ExamService().getStudyMaterials();
    _materialsFuture.then((materials) {
      if (mounted) {
        setState(() {
          _allMaterials = materials
              .where((m) => m.visibility.toLowerCase() == 'free')
              .toList();
          _filteredMaterials = _allMaterials;
        });
      }
    });
  }

  void _filterMaterials(String query) {
    setState(() {
      _filteredMaterials = _allMaterials
          .where(
            (m) =>
                m.title.toLowerCase().contains(query.toLowerCase()) ||
                m.displayCategory.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        title: Text(
          'Study Materials',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF1E293B),
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 15, 20, 5),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _filterMaterials,
                style: GoogleFonts.inter(fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Search for books, notes...',
                  hintStyle: GoogleFonts.inter(
                    color: const Color(0xFF94A3B8),
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Color(0xFF94A3B8),
                    size: 22,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<StudyMaterialModel>>(
              future: _materialsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    _allMaterials.isEmpty) {
                  return _buildSkeletonGrid();
                }
                if (snapshot.hasError && _allMaterials.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 48,
                          color: Colors.redAccent,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load materials',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                if ((!snapshot.hasData || snapshot.data!.isEmpty) &&
                    _allMaterials.isEmpty) {
                  return Center(
                    child: Text(
                      'No materials available',
                      style: GoogleFonts.inter(color: const Color(0xFF64748B)),
                    ),
                  );
                }

                if (_filteredMaterials.isEmpty &&
                    _searchController.text.isNotEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No matching materials found',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 20,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: _filteredMaterials.length,
                  itemBuilder: (context, index) {
                    return _buildGridCard(_filteredMaterials[index], index);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridCard(StudyMaterialModel material, int index) {
    final color = index % 2 == 0
        ? const Color(0xFFF9A826)
        : const Color(0xFF4AC2E3);

    return GestureDetector(
          onTap: () {
            if (material.isPdf) {
              PdfViewerPage.open(context, material.fullFileUrl, material.title);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Video player coming soon!')),
              );
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
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
                // Thumbnail Section
                Expanded(
                  flex: 4,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.05),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    child: Center(
                      child:
                          material.thumbnailPath != null &&
                              material.thumbnailPath!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(24),
                              ),
                              child: CachedNetworkImage(
                                imageUrl: material.fullThumbnailUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                placeholder: (context, url) => const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                errorWidget: (context, url, error) =>
                                    _buildIconPlaceholder(color),
                              ),
                            )
                          : _buildIconPlaceholder(color),
                    ),
                  ),
                ),
                // Text Details Section
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            material.displayCategory.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: color,
                              letterSpacing: 0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          material.title,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E293B),
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Icon(
                              material.isVideo
                                  ? Icons.videocam_outlined
                                  : Icons.description_outlined,
                              size: 12,
                              color: const Color(0xFF94A3B8),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              material.isVideo ? 'Video' : 'PDF',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(delay: (index * 50).ms)
        .scale(begin: const Offset(0.9, 0.9));
  }

  Widget _buildIconPlaceholder(Color color) {
    return Padding(
      padding: const EdgeInsets.all(48.0),
      child: SvgPicture.asset(
        'assets/Images/pdf_icon.svg',
        width: 32,
        height: 32,
      ),
    );
  }

  Widget _buildSkeletonGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 20,
        childAspectRatio: 0.75,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(child: CircularProgressIndicator(strokeWidth: 1)),
      ),
    );
  }
}
