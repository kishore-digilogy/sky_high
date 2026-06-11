import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sky_high/data/models/exam_category_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sky_high/pages/courses/company_details_page.dart';
import 'package:sky_high/pages/courses/study_layers_page.dart';
import 'package:sky_high/core/services/localization_service.dart';

class SubcategoryPage extends StatefulWidget {
  final ExamCategoryModel category;

  const SubcategoryPage({super.key, required this.category});

  @override
  State<SubcategoryPage> createState() => _SubcategoryPageState();
}

class _SubcategoryPageState extends State<SubcategoryPage> {
  late List<ExamSubcategoryModel> _filteredSubcategories;
  late List<ExamItemModel> _filteredItems;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  final LocalizationService _l10n = LocalizationService();

  @override
  void initState() {
    super.initState();
    _filteredSubcategories = widget.category.subcategories
        .where((sub) => sub.type?.toLowerCase() != 'material')
        .toList();
    _filteredItems = widget.category.items
        .where((item) => item.type?.toLowerCase() != 'material')
        .toList();
  }

  void _filterResults(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredSubcategories = widget.category.subcategories
            .where((sub) => sub.type?.toLowerCase() != 'material')
            .toList();
        _filteredItems = widget.category.items
            .where((item) => item.type?.toLowerCase() != 'material')
            .toList();
      } else {
        _filteredSubcategories = widget.category.subcategories
            .where(
              (sub) =>
                  sub.type?.toLowerCase() != 'material' &&
                  sub.name.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
        _filteredItems = widget.category.items
            .where(
              (item) =>
                  item.type?.toLowerCase() != 'material' &&
                  item.name.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
          ),
          child: Row(
            children: [
              // Back Button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 20,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              // Title & Subtitle
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.category.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1E293B),
                        letterSpacing: -0.5,
                      ),
                      maxLines: 2,
                    ),
                    Text(
                      _l10n.tr('explore_exam_categories'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              // Search Button
              GestureDetector(
                onTap: () => setState(() => _isSearching = !_isSearching),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F3FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: Color(0xFF6366F1),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          if (_isSearching)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchController,
                onChanged: _filterResults,
                autofocus: true,
                style: GoogleFonts.plusJakartaSans(fontSize: 14),
                decoration: InputDecoration(
                  hintText: _l10n.tr('search_categories'),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.search_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          Expanded(
            child: (_filteredSubcategories.isEmpty && _filteredItems.isEmpty)
                ? _buildEmptyState()
                : _buildItemsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 80,
            color: Colors.blueGrey[200],
          ).animate().slideY(begin: 0.1),
          const SizedBox(height: 20),
          Text(
            widget.category.type?.toLowerCase() == 'material'
                ? _l10n.tr('no_materials_available')
                : _l10n.tr('no_companies_available'),
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
            maxLines: 2,
            textAlign: TextAlign.center,
          ).animate(),
          const SizedBox(height: 10),
          Text(
            _l10n.tr('check_back_later'),
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
            maxLines: 3,
          ).animate(),
        ],
      ),
    );
  }

  Widget _buildItemsList() {
    return ListView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      children: [
        // Top Banner
        Container(
          width: double.infinity,
          height: 120,
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Stack(
            children: [
              // Icon Chip
              Positioned(
                left: 20,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.grid_view_rounded,
                      color: Color(0xFF6366F1),
                      size: 28,
                    ),
                  ),
                ),
              ),
              // Text Content
              Positioned(
                left: 90,
                top: 0,
                bottom: 0,
                right: 120,
                child: Center(
                  child: Text(
                    _l10n.tr('find_category_prep'),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                    ),
                    maxLines: 3,
                  ),
                ),
              ),
              // Floating Illustration Placeholder
              Positioned(
                right: 10,
                bottom: 10,
                top: 10,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(60, 10, 0, 20),
                  child: SvgPicture.asset(
                    "assets/Icons/company_categories.svg",
                  ),
                ),
              ),
            ],
          ),
        ),
        // Grid replacement with Wrap for flexibility
        LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = (constraints.maxWidth - 16) / 2;
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                ...List.generate(_filteredSubcategories.length, (index) {
                  final sub = _filteredSubcategories[index];
                  return SizedBox(
                    width: itemWidth,
                    child: _buildPremiumCard(
                      name: sub.name,
                      subtitle: sub.type ?? _l10n.tr('organization'),
                      logoUrl: sub.fullLogoUrl,
                      count: sub.items.length,
                      onTap: () {
                        final mappedCategory = ExamCategoryModel(
                          id: sub.id,
                          title: sub.name,
                          originalTitle: sub.originalName,
                          type: sub.type,
                          section: sub.section,
                          color: sub.color,
                          icon: sub.thumbnailImage,
                          items: sub.items,
                          subcategories: [],
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                SubcategoryPage(category: mappedCategory),
                          ),
                        );
                      },
                      index: index,
                    ),
                  );
                }),
                ...List.generate(_filteredItems.length, (index) {
                  final item = _filteredItems[index];
                  return SizedBox(
                    width: itemWidth,
                    child: _buildPremiumCard(
                      name: item.name,
                      subtitle: item.type ?? _l10n.tr('organization'),
                      logoUrl: item.fullLogoUrl,
                      count: 0,
                      onTap: () {
                        if (item.type?.toLowerCase() == 'material') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  StudyLayersPage(company: item),
                            ),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  CompanyDetailsPage(company: item),
                            ),
                          );
                        }
                      },
                      index: _filteredSubcategories.length + index,
                    ),
                  );
                }),
              ],
            );
          },
          // const SizedBox(height: 40),
        ),
      ],
    );
  }

  Widget _buildPremiumCard({
    required String name,
    required String subtitle,
    required String logoUrl,
    required int count,
    required VoidCallback onTap,
    required int index,
  }) {
    final List<Map<String, Color>> cardThemes = [
      {
        'bg': const Color(0xFFFFF7ED),
        'text': const Color(0xFFF97316),
      }, // Orange
      {'bg': const Color(0xFFFFF1F2), 'text': const Color(0xFFE11D48)}, // Rose
      {
        'bg': const Color(0xFFF0F9FF),
        'text': const Color(0xFF0284C7),
      }, // Light Blue
      {'bg': const Color(0xFFF0FDF4), 'text': const Color(0xFF16A34A)}, // Green
      {
        'bg': const Color(0xFFFAF5FF),
        'text': const Color(0xFF9333EA),
      }, // Purple
    ];
    final theme = cardThemes[index % cardThemes.length];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo Container
                  Container(
                    width: 44,
                    height: 44,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFF1F5F9),
                        width: 1.5,
                      ),
                    ),
                    child: (logoUrl.isNotEmpty && logoUrl.startsWith('http'))
                        ? CachedNetworkImage(
                            imageUrl: logoUrl,
                            fit: BoxFit.contain,
                            placeholder: (context, url) => Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: theme['text'],
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Icon(
                              Icons.business_rounded,
                              color: theme['text'],
                            ),
                          )
                        : Icon(Icons.business_rounded, color: theme['text']),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    name.toUpperCase(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E293B),
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Count Badge
                  if (count > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme['bg'],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$count ${count == 1 ? _l10n.tr('item') : _l10n.tr('companies')}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: theme['text'],
                        ),
                        maxLines: 2,
                      ),
                    ),
                ],
              ),
            ),
            // Floating Arrow Button
            Positioned(
              right: 12,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().scale(
      delay: (index * 50).ms,
      duration: 400.ms,
      curve: Curves.easeOutBack,
    );
  }
}
