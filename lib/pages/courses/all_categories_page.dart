import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sky_high/data/models/exam_category_model.dart';
import 'package:sky_high/pages/courses/subcategory_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
                    hintText: 'Search categories...',
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
            : Text(
                'All Categories',
                style: GoogleFonts.inter(
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
      body: _filteredCategories.isEmpty
          ? _buildEmptyState()
          : GridView.builder(
              padding: const EdgeInsets.all(24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 170 / 210, // Matching the premium card aspect ratio
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),

              itemCount: _filteredCategories.length,
              itemBuilder: (context, index) {
                return CategoryCard(
                  category: _filteredCategories[index],
                  index: index,
                  isTrending: false, // No trending items on all categories page usually
                );
              },

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
            'No categories found',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try searching for something else',
            style: GoogleFonts.inter(color: const Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}
