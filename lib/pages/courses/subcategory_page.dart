import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sky_high/data/models/exam_category_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sky_high/pages/courses/company_details_page.dart';
import 'package:sky_high/pages/courses/study_layers_page.dart';

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
  bool _isTitleExpanded = false;

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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        // toolbarHeight: 80,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF1E293B),
            size: 20,
          ),
          onPressed: () {
            if (_isSearching) {
              setState(() {
                _isSearching = false;
                _searchController.clear();
                _filterResults('');
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: _isSearching
            ? Container(
                height: 45,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _filterResults,
                  autofocus: true,
                  style: GoogleFonts.inter(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search companies...',
                    hintStyle: GoogleFonts.inter(
                      color: const Color(0xFF94A3B8),
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFF94A3B8),
                      size: 20,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              )
            : GestureDetector(
                onTap: () =>
                    setState(() => _isTitleExpanded = !_isTitleExpanded),
                child: Text(
                  widget.category.title,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF1E293B),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: _isTitleExpanded ? 3 : 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
        actions: [
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.search, color: Color(0xFF1E293B)),
              onPressed: () => setState(() => _isSearching = true),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: (_filteredSubcategories.isEmpty && _filteredItems.isEmpty)
            ? _buildEmptyState()
            : _buildItemsList(),
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
                ? 'No Materials available'
                : 'No Companies available',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ).animate(),
          const SizedBox(height: 10),
          Text(
            'Check back later for new content in this category.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ).animate(),
        ],
      ),
    );
  }

  Widget _buildItemsList() {
    final totalCount = _filteredSubcategories.length + _filteredItems.length;
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.0,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: totalCount,
      itemBuilder: (context, index) {
        final isSubcategory = index < _filteredSubcategories.length;

        if (isSubcategory) {
          final sub = _filteredSubcategories[index];
          return GestureDetector(
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
            child: _buildGridTile(sub.name, sub.type, sub.fullLogoUrl, index),
          );
        } else {
          final itemIndex = index - _filteredSubcategories.length;
          final item = _filteredItems[itemIndex];
          return GestureDetector(
            onTap: () {
              if (item.type?.toLowerCase() == 'material') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StudyLayersPage(company: item),
                  ),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CompanyDetailsPage(company: item),
                  ),
                );
              }
            },
            child: _buildGridTile(
              item.name,
              item.type,
              item.fullLogoUrl,
              index,
            ),
          );
        }
      },
    );
  }

  Widget _buildGridTile(String name, String? type, String logoUrl, int index) {
    return Container(
      padding: const EdgeInsets.all(12),
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildLogo(name, logoUrl, type),
          const SizedBox(height: 12),
          Text(
            name,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (type != null && type.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Color(
                  widget.category.displayColorValue,
                ).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                type.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: Color(widget.category.displayColorValue),
                ),
              ),
            ),
          ],
        ],
      ),
    ).animate().scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack);
  }

  Widget _buildFallbackLogo(String name, String? type) {
    IconData fallbackIcon;
    switch (type?.toLowerCase()) {
      case 'company':
      case 'organization':
        fallbackIcon = Icons.account_balance_outlined;
        break;
      case 'subcategory':
      case 'category':
        fallbackIcon = Icons.category_outlined;
        break;
      case 'material':
      case 'pdf':
      case 'book':
        fallbackIcon = Icons.menu_book_outlined;
        break;
      case 'video':
        fallbackIcon = Icons.play_circle_outline_rounded;
        break;
      case 'test':
      case 'exam':
        fallbackIcon = Icons.quiz_outlined;
        break;
      default:
        fallbackIcon = Icons.business_outlined;
    }

    final colors = [
      const Color(0xFFEF4444), // Red
      const Color(0xFF3B82F6), // Blue
      const Color(0xFF10B981), // Green
      const Color(0xFFF59E0B), // Amber
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFFEC4899), // Pink
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFFF97316), // Orange
    ];
    final colorIndex =
        name.codeUnits.fold(0, (prev, curr) => prev + curr) % colors.length;
    final iconColor = colors[colorIndex];

    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Center(child: Icon(fallbackIcon, size: 28, color: iconColor)),
    );
  }

  Widget _buildLogo(String name, String logoUrl, String? type) {
    if (logoUrl.isEmpty) {
      return _buildFallbackLogo(name, type);
    }

    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CachedNetworkImage(
            imageUrl: logoUrl,
            fit: BoxFit.contain,
            placeholder: (context, url) => const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            errorWidget: (context, url, error) =>
                _buildFallbackLogo(name, type),
          ),
        ),
      ),
    );
  }
}
