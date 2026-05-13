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
                    ),
                    Text(
                      'Explore government exam categories',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              // Search Button
              GestureDetector(
                onTap: () => setState(() => _isSearching = !_isSearching),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F3FF),
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
                  hintText: 'Search categories...',
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
            gradient: const LinearGradient(
              colors: [Color(0xFFEDE9FE), Color(0xFFF5F3FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
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
                    'Find the right category for your exam preparation',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ),
              ),
              // Floating Illustration Placeholder (Simulated with simple drawing)
              Positioned(
                right: 10,
                bottom: 10,
                top: 10,
                child: Container(
                  width: 100,
                  decoration: const BoxDecoration(
                    // Replace with real 3D image later if available
                    image: DecorationImage(
                      image: AssetImage('assets/Icons/study_3d.png'),
                      fit: BoxFit.contain,
                      opacity: 0.8,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.85,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: totalCount,
          itemBuilder: (context, index) {
            final isSubcategory = index < _filteredSubcategories.length;
            if (isSubcategory) {
              final sub = _filteredSubcategories[index];
              return _buildPremiumCard(
                name: sub.name,
                subtitle: sub.type ?? 'Organization',
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
              );
            } else {
              final itemIndex = index - _filteredSubcategories.length;
              final item = _filteredItems[itemIndex];
              return _buildPremiumCard(
                name: item.name,
                subtitle: item.type ?? 'Organization',
                logoUrl: item.fullLogoUrl,
                count:
                    0, // Departments/Items usually don't show nested count here
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
                index: index,
              );
            }
          },
        ),
        const SizedBox(height: 32),
        // Bottom Banner
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFF),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.bookmark_outline_rounded,
                  color: Color(0xFF6366F1),
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Can\'t find what you\'re looking for?',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      'Let us help you find the right category.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.headset_mic_rounded, size: 14),
                label: const Text('Contact Us'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  textStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
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
          borderRadius: BorderRadius.circular(32),
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
            // Grid Background Pattern Placeholder (Subtle dots)
            Positioned(
              right: 15,
              top: 15,
              child: Opacity(
                opacity: 0.1,
                child: Icon(
                  Icons.grid_view_rounded,
                  size: 40,
                  color: theme['text'],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon Chip
                  Container(
                    width: 48,
                    height: 48,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme['bg'],
                      borderRadius: BorderRadius.circular(16),
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
                  const SizedBox(height: 16),
                  Text(
                    name.toUpperCase(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E293B),
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                  const Spacer(),
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
                        '$count ${count == 1 ? 'Item' : 'Companies'}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: theme['text'],
                        ),
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
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: theme['text'],
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
