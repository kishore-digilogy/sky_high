import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sky_high/data/models/exam_category_model.dart';
import 'package:sky_high/pages/courses/subcategory_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sky_high/core/services/localization_service.dart';
import 'package:sky_high/widgets/category_icon.dart';
import 'package:sky_high/widgets/category_card.dart';

class AllCategoriesPage extends StatefulWidget {
  final List<ExamCategoryModel> categories;
  final bool initialIsSearching;

  const AllCategoriesPage({
    super.key,
    required this.categories,
    this.initialIsSearching = false,
  });

  @override
  State<AllCategoriesPage> createState() => _AllCategoriesPageState();
}

class _AllCategoriesPageState extends State<AllCategoriesPage> {
  final LocalizationService _l10n = LocalizationService();
  late List<ExamCategoryModel> _filteredCategories;
  final TextEditingController _searchController = TextEditingController();
  late bool _isSearching;

  @override
  void initState() {
    super.initState();
    _filteredCategories = widget.categories;
    _isSearching = widget.initialIsSearching;
  }

  void _filterCategories(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCategories = widget.categories;
      } else {
        _filteredCategories = widget.categories
            .where(
              (category) =>
                  category.title.toLowerCase().contains(query.toLowerCase()),
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
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF1E293B),
            size: 20,
          ),
          onPressed: () {
            if (_isSearching && !widget.initialIsSearching) {
              setState(() {
                _isSearching = false;
                _searchController.clear();
                _filterCategories('');
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
                  onChanged: _filterCategories,
                  autofocus: true,
                  style: GoogleFonts.inter(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: _l10n.tr('search_categories'),
                    hintStyle: GoogleFonts.inter(
                      color: const Color(0xFF94A3B8),
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFF94A3B8),
                      size: 20,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              )
            : Text(
                _l10n.tr('all_categories'),
                style: GoogleFonts.inter(
                  color: const Color(0xFF1E293B),
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
                maxLines: 2,
              ),
        actions: [
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.search, color: Color(0xFF1E293B)),
              onPressed: () => setState(() => _isSearching = true),
            ),
        ],
      ),
      body: _filteredCategories.isEmpty
          ? _buildEmptyState()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final itemWidth = (constraints.maxWidth - 16) / 2;
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: List.generate(_filteredCategories.length, (index) {
                      return SizedBox(
                        width: itemWidth,
                        child: CategoryCard(
                          category: _filteredCategories[index],
                          index: index,
                        ),
                      );
                    }),
                  );
                },
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 80, color: Colors.blueGrey[100]),
          const SizedBox(height: 16),
          Text(
            _l10n.tr('no_categories_found'),
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 8),
          Text(
            _l10n.tr('try_searching_else'),
            style: GoogleFonts.inter(color: const Color(0xFF64748B)),
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}
