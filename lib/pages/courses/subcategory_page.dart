import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sky_high/data/models/exam_category_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sky_high/pages/courses/company_details_page.dart';

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

  @override
  void initState() {
    super.initState();
    _filteredSubcategories = widget.category.subcategories;
    _filteredItems = widget.category.items;
  }

  void _filterResults(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredSubcategories = widget.category.subcategories;
        _filteredItems = widget.category.items;
      } else {
        _filteredSubcategories = widget.category.subcategories
            .where((sub) => sub.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
        _filteredItems = widget.category.items
            .where((item) => item.name.toLowerCase().contains(query.toLowerCase()))
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
                  style: GoogleFonts.outfit(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search companies...',
                    hintStyle:
                        GoogleFonts.outfit(color: const Color(0xFF94A3B8)),
                    prefixIcon: const Icon(Icons.search,
                        color: Color(0xFF94A3B8), size: 20),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              )
            : Text(
                widget.category.title,
                style: GoogleFonts.outfit(
                  color: const Color(0xFF1E293B),
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
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
      body: (_filteredSubcategories.isEmpty && _filteredItems.isEmpty)
          ? _buildEmptyState()
          : _buildItemsList(),
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
          ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1),
          const SizedBox(height: 20),
          Text(
            'No items available',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 10),
          Text(
            'Check back later for new content in this category.',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: const Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 400.ms),
        ],
      ),
    );
  }

  Widget _buildItemsList() {
    final totalCount = _filteredSubcategories.length + _filteredItems.length;
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
                type: sub.type,
                section: sub.section,
                color: sub.color,
                icon: sub.thumbnailImage,
                items: sub.items,
                subcategories: [], // Assuming no further nesting
              );
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      SubcategoryPage(category: mappedCategory),
                ),
              );
            },
            child: _buildListTile(sub.name, sub.type, sub.fullLogoUrl, index),
          );
        } else {
          final itemIndex = index - _filteredSubcategories.length;
          final item = _filteredItems[itemIndex];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CompanyDetailsPage(company: item),
                ),
              );
            },
            child: _buildListTile(
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

  Widget _buildListTile(String name, String? type, String logoUrl, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildLogo(name, logoUrl, type),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (type != null && type.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Color(widget.category.displayColorValue).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      type.toUpperCase(),
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(widget.category.displayColorValue),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: Color(0xFF94A3B8),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (20 * index).ms).slideX(begin: 0.1);
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
        child: CachedNetworkImage(
          imageUrl: logoUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          errorWidget: (context, url, error) => _buildFallbackLogo(name, type),
        ),
      ),
    );
  }
}
