import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sky_high/core/services/api_service.dart';
import 'package:sky_high/data/models/exam_category_model.dart';
import 'package:sky_high/data/models/job_model.dart';
import 'package:sky_high/pages/courses/study_layers_page.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'package:sky_high/core/services/localization_service.dart';
import 'package:sky_high/core/utils/localization_helper.dart';

// ─────────────────────────────────────────────
//  CONSTANTS
// ─────────────────────────────────────────────
const _kPurple = Color(0xFF6C63FF);
const _kPurpleLight = Color(0xFFEEEDFE);
const _kDark = Color(0xFF1A1D2E);
const _kGrey = Color(0xFF9CA3AF);
const _kSurface = Color(0xFFF7F8FC);
const _kWhite = Colors.white;

// ─────────────────────────────────────────────
//  MAIN PAGE
// ─────────────────────────────────────────────
class CompanyDetailsPage extends StatefulWidget {
  final ExamItemModel company;
  const CompanyDetailsPage({super.key, required this.company});

  @override
  State<CompanyDetailsPage> createState() => _CompanyDetailsPageState();
}

class _CompanyDetailsPageState extends State<CompanyDetailsPage> {
  final Dio _dio = ApiService().dio;
  List<JobModel> _jobs = [];
  List<JobModel> _filteredJobs = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  List<dynamic> _subJobs = [];

  // Which job card is currently expanded (null = none)
  int? _expandedJobIndex;

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _subPostsKey = GlobalKey();

  Map<String, dynamic>? _lastStudiedSubJob;
  final LocalizationService _l10n = LocalizationService();
  Map<String, dynamic>? _entityDetails;
  String? _wikiLogoUrl;
  bool _loadingWikiLogo = false;
  bool _showLogo = true;
  bool _logoLoadedSuccessfully = false;
  Timer? _logoTimer;

  @override
  void initState() {
    super.initState();
    _fetchJobs();
    _fetchEntityDetails();
    _loadLastStudied();
    _fetchWikiLogo();
    _startLogoTimeoutTimer();
  }

  Future<void> _fetchEntityDetails() async {
    try {
      final response = await _dio.get(
        '${ApiService.baseUrl}/entity-details',
        queryParameters: {'type': 'company', 'id': widget.company.id},
      );
      if (response.statusCode == 200 && response.data != null) {
        setState(() {
          _entityDetails = response.data;
        });
      }
    } catch (e) {
      print('CompanyDetailsPage: Error fetching entity details: $e');
    }
  }

  Future<void> _fetchWikiLogo() async {
    final companyName = widget.company.name;
    if (companyName.isEmpty) return;

    if (mounted) {
      setState(() {
        _loadingWikiLogo = true;
      });
    }

    try {
      final response = await _dio.get(
        'https://en.wikipedia.org/w/api.php',
        queryParameters: {
          'action': 'query',
          'format': 'json',
          'generator': 'search',
          'gsrnamespace': '0',
          'gsrsearch': companyName,
          'gsrlimit': '1',
          'prop': 'pageimages',
          'pithumbsize': '200',
          'origin': '*',
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final query = response.data['query'];
        if (query != null && query['pages'] != null) {
          final pages = query['pages'] as Map<String, dynamic>;
          if (pages.isNotEmpty) {
            final firstPage = pages.values.first;
            final thumbnail = firstPage['thumbnail'];
            if (thumbnail != null && thumbnail['source'] != null) {
              if (mounted) {
                setState(() {
                  _wikiLogoUrl = thumbnail['source'];
                  _loadingWikiLogo = false;
                });
                return;
              }
            }
          }
        }
      }
    } catch (e) {
      print('CompanyDetailsPage: Error fetching logo from Wikipedia: $e');
    }

    if (mounted) {
      setState(() {
        _loadingWikiLogo = false;
      });
    }
  }

  void _startLogoTimeoutTimer() {
    _logoTimer = Timer(const Duration(seconds: 10), () {
      if (mounted && !_logoLoadedSuccessfully) {
        setState(() {
          _showLogo = false;
        });
      }
    });
  }

  String _getAboutText() {
    if (_entityDetails != null) {
      final localizedAbout = LocalizationHelper.getLocalized(
        _entityDetails!,
        'about',
      );
      if (localizedAbout.isNotEmpty) {
        return localizedAbout;
      }
    }
    return widget.company.description?.isNotEmpty == true
        ? widget.company.description!
        : _l10n.tr('company_default_desc');
  }

  Future<void> _loadLastStudied() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('last_studied_${widget.company.id}');
    if (data != null) {
      setState(() {
        _lastStudiedSubJob = jsonDecode(data);
      });
    }
  }

  Future<void> _fetchJobs() async {
    try {
      final response = await _dio.get(
        '${ApiService.baseUrl}/admin/posted-jobs',
        queryParameters: {'company_id': widget.company.id},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final allJobs = data.map((json) => JobModel.fromJson(json)).toList();

        final subRes = await _dio.get(
          '${ApiService.baseUrl}/admin/sub-posted-jobs',
          queryParameters: {'company_id': widget.company.id},
        );
        if (subRes.statusCode == 200) {
          _subJobs = subRes.data;
        }

        setState(() {
          _jobs = allJobs.where((j) => j.title.toUpperCase() != 'GET').toList();
          _filteredJobs = _jobs;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (_) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterJobs(String query) {
    setState(() {
      _filteredJobs = query.isEmpty
          ? _jobs
          : _jobs
                .where(
                  (j) => j.title.toLowerCase().contains(query.toLowerCase()),
                )
                .toList();
    });
  }

  Future<void> _saveStudyProgress(dynamic subJob) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'last_studied_${widget.company.id}',
      jsonEncode({
        'id': subJob['id'],
        'title': subJob['title'],
        'timestamp': DateTime.now().toIso8601String(),
      }),
    );
    setState(() {
      _lastStudiedSubJob = subJob;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _logoTimer?.cancel();
    super.dispose();
  }

  // ── Icon helpers ──────────────────────────────
  IconData _jobIcon(int index) {
    const icons = [
      Icons.train_rounded,
      Icons.school_rounded,
      Icons.build_rounded,
      Icons.groups_rounded,
      Icons.engineering_rounded,
    ];
    return icons[index % icons.length];
  }

  Color _jobAccent(int index) {
    const accents = [
      Color(0xFF6C63FF),
      Color(0xFF10B981),
      Color(0xFFF59E0B),
      Color(0xFFEC4899),
      Color(0xFF3B82F6),
    ];
    return accents[index % accents.length];
  }

  // ── Build ─────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;

    return Scaffold(
      backgroundColor: _kSurface,
      body: SafeArea(
        top: false,
        child: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        _buildTopBar(),
        SliverToBoxAdapter(child: _buildHeroSection()),
        SliverToBoxAdapter(child: _buildMobileHeroImage()),
        if (_lastStudiedSubJob != null)
          SliverToBoxAdapter(child: _buildContinueLearningSection()),
        SliverToBoxAdapter(child: _buildAboutSection()),
        SliverToBoxAdapter(child: _buildOpportunitiesSection()),
        if (_expandedJobIndex != null)
          SliverToBoxAdapter(
            key: _subPostsKey,
            child: _buildExpandedSubPosts(),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }

  Widget _buildMobileHeroImage() {
    final heroImg = _entityDetails?['hero_image']?.toString();
    if (heroImg == null || heroImg.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: CachedNetworkImage(
          imageUrl: heroImg,
          height: 180,
          width: double.infinity,
          fit: BoxFit.cover,
          placeholder: (context, url) => Shimmer.fromColors(
            baseColor: const Color(0xFFE2E8F0),
            highlightColor: const Color(0xFFF8FAFC),
            child: Container(
              height: 180,
              width: double.infinity,
              color: Colors.white,
            ),
          ),
          errorWidget: (context, url, error) => const SizedBox.shrink(),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    final heroImg = _entityDetails?['hero_image']?.toString();
    final aboutText = _getAboutText();

    return SingleChildScrollView(
      controller: _scrollController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dark Header Container
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white70,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Back',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero image container (left side)
                    if (heroImg != null && heroImg.isNotEmpty)
                      Container(
                        width: 380,
                        height: 240,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: CachedNetworkImage(
                            imageUrl: heroImg,
                            fit: BoxFit.cover,
                            placeholder: (c, u) => Shimmer.fromColors(
                              baseColor: const Color(0xFF1E293B),
                              highlightColor: const Color(0xFF334155),
                              child: Container(color: Colors.white),
                            ),
                            errorWidget: (c, u, e) => Container(
                              color: const Color(0xFF1E293B),
                              child: const Icon(
                                Icons.image_not_supported_rounded,
                                color: Colors.white24,
                                size: 48,
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      Container(
                        width: 380,
                        height: 240,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.business_rounded,
                          color: Colors.white24,
                          size: 64,
                        ),
                      ),
                    const SizedBox(width: 48),
                    // Details container (right side)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.company.name,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'About',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            aboutText,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14.5,
                              color: Colors.white70,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Main content section below header
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 80,
                  vertical: 40,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_lastStudiedSubJob != null) ...[
                      _buildContinueLearningSection(),
                      const SizedBox(height: 32),
                    ],
                    // Opportunities Title Section
                    Text(
                      'Departmental Openings',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: _kDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Parent departments and their specialized training paths',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: _kGrey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 24),

                    if (_isLoading)
                      _buildDesktopShimmer()
                    else if (_filteredJobs.isEmpty)
                      _buildEmptyState()
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _filteredJobs.length,
                        itemBuilder: (context, i) {
                          final job = _filteredJobs[i];
                          final accent = _jobAccent(i);
                          final matchingSubs = _subJobs
                              .where((sj) => sj['parent_job_id'] == job.id)
                              .toList();
                          final isSelected = _expandedJobIndex == i;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? accent
                                    : const Color(0xFFE5E7EB),
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                // Expandable header row
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      _expandedJobIndex = isSelected ? null : i;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(18),
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            color: accent.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Icon(
                                            _jobIcon(i),
                                            color: accent,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 20),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    job.title,
                                                    style:
                                                        GoogleFonts.plusJakartaSans(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color: _kDark,
                                                        ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 3,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: accent.withOpacity(
                                                        0.1,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            6,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      'DEPARTMENT',
                                                      style:
                                                          GoogleFonts.plusJakartaSans(
                                                            color: accent,
                                                            fontSize: 9,
                                                            fontWeight:
                                                                FontWeight.w800,
                                                          ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                '${matchingSubs.length} SPECIALIZED SUB-POSTS AVAILABLE',
                                                style:
                                                    GoogleFonts.plusJakartaSans(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: accent,
                                                      letterSpacing: 0.5,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Icon(
                                          isSelected
                                              ? Icons.keyboard_arrow_up_rounded
                                              : Icons
                                                    .keyboard_arrow_down_rounded,
                                          color: _kGrey,
                                          size: 24,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // Expandable content row
                                if (isSelected)
                                  Container(
                                    padding: const EdgeInsets.fromLTRB(
                                      24,
                                      0,
                                      24,
                                      24,
                                    ),
                                    child: Column(
                                      children: [
                                        const Divider(
                                          height: 1,
                                          color: Color(0xFFF1F5F9),
                                        ),
                                        const SizedBox(height: 20),
                                        if (matchingSubs.isEmpty)
                                          _SubJobEmptyCard(
                                            accent: accent,
                                            company: widget.company,
                                            jobId: job.id,
                                          )
                                        else
                                          ...matchingSubs.asMap().entries.map((
                                            entry,
                                          ) {
                                            final idx = entry.key;
                                            final sj = entry.value;
                                            return _SubJobTile(
                                              subJob: sj,
                                              accent: accent,
                                              company: widget.company,
                                              index: idx,
                                              onTap: () =>
                                                  _saveStudyProgress(sj),
                                            );
                                          }),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Top Bar ───────────────────────────────────
  Widget _buildTopBar() {
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      backgroundColor: _kWhite,
      surfaceTintColor: _kWhite,
      leading: GestureDetector(
        onTap: () {
          if (_isSearching) {
            setState(() {
              _isSearching = false;
              _searchController.clear();
              _filterJobs('');
            });
          } else {
            Navigator.pop(context);
          }
        },
        child: Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 16,
            color: _kDark,
          ),
        ),
      ),
      title: _isSearching
          ? TextField(
              controller: _searchController,
              onChanged: _filterJobs,
              autofocus: true,
              style: GoogleFonts.plusJakartaSans(fontSize: 14, color: _kDark),
              decoration: InputDecoration(
                hintText: _l10n.tr('search_opportunities'),
                hintStyle: GoogleFonts.plusJakartaSans(
                  color: _kGrey,
                  fontSize: 14,
                ),
                border: InputBorder.none,
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  // ── Hero Section ──────────────────────────────
  Widget _buildHeroSection() {
    return Container(
      color: _kWhite,
      padding: const EdgeInsets.fromLTRB(20, 8, 0, 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // (Verified badge removed)
                // Logo + Name row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (_showLogo) ...[
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: _kWhite,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: _buildLogoWidget(),
                        ),
                      ).animate().scale(duration: 400.ms),
                      const SizedBox(width: 14),
                    ],
                    Expanded(
                      child: Text(
                        widget.company.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: _kDark,
                          height: 1.2,
                          letterSpacing: -0.5,
                        ),
                      ).animate().fadeIn(delay: 150.ms).slideX(begin: -0.05),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _l10n.tr('build_career_serve'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: _kGrey,
                    fontWeight: FontWeight.w500,
                  ),
                ).animate().fadeIn(delay: 200.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueLearningSection() {
    if (_lastStudiedSubJob == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _l10n.tr('continue_learning'),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _kDark,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFFE5E7EB).withOpacity(0.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                // Icon Box
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B80F8),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                // Middle Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _lastStudiedSubJob!['title'] ??
                            _l10n.tr('resume_course'),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: _kDark,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: 0.68,
                                minHeight: 6,
                                backgroundColor: const Color(0xFFF1F1FE),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFF6C63FF),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '68%',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _kDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _l10n.tr('last_studied_yesterday'),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: const Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Resume Button
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StudyLayersPage(
                          company: widget.company,
                          jobId: _lastStudiedSubJob!['id'],
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B80F8),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.play_arrow_rounded, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        _l10n.tr('resume'),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1);
  }

  // ── About Section ─────────────────────────────
  Widget _buildAboutSection() {
    final desc = _getAboutText();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _l10n.tr('about_organisation'),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _kDark,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _kWhite,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Text(
              desc,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                color: const Color(0xFF6B7280),
                height: 1.7,
              ),
            ),
          ),
        ],
      ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1),
    );
  }

  Widget _buildDesktopShimmer() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE2E8F0),
      highlightColor: const Color(0xFFF8FAFC),
      child: Column(
        children: List.generate(3, (idx) {
          return Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 200,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: 120,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildMobileShimmer() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE2E8F0),
      highlightColor: const Color(0xFFF8FAFC),
      child: SizedBox(
        height: 410,
        child: GridView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(bottom: 8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 190 / 155,
          ),
          itemCount: 4,
          itemBuilder: (context, idx) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 110,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 70,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Top Opportunities (2-row horizontal grid) ──
  Widget _buildOpportunitiesSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _l10n.tr('top_opportunities'),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _kDark,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_isLoading)
            _buildMobileShimmer()
          else if (_filteredJobs.isEmpty)
            _buildEmptyState()
          else
            SizedBox(
              height: 410,
              child: GridView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(bottom: 8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 190 / 155,
                ),
                itemCount: _filteredJobs.length,
                itemBuilder: (context, i) {
                  final job = _filteredJobs[i];
                  final accent = _jobAccent(i);
                  final matchingSubs = _subJobs
                      .where((sj) => sj['parent_job_id'] == job.id)
                      .toList();
                  final isSelected = _expandedJobIndex == i;

                  return GestureDetector(
                        onTap: () {
                          setState(() {
                            _expandedJobIndex = isSelected ? null : i;
                          });
                          if (!isSelected) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (_subPostsKey.currentContext != null) {
                                Scrollable.ensureVisible(
                                  _subPostsKey.currentContext!,
                                  duration: const Duration(milliseconds: 600),
                                  curve: Curves.easeInOutCubic,
                                );
                              }
                            });
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: 155,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _kWhite,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? accent
                                  : const Color(0xFFE5E7EB),
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: [
                              if (isSelected)
                                BoxShadow(
                                  color: accent.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: accent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                child: Icon(
                                  _jobIcon(i),
                                  color: accent,
                                  size: 22,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                job.title,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: _kDark,
                                  height: 1.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: accent.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${matchingSubs.length} ${_l10n.tr('sub_posts')}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    color: accent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: accent.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      isSelected
                                          ? Icons.keyboard_arrow_up_rounded
                                          : Icons.arrow_forward_rounded,
                                      color: accent,
                                      size: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      )
                      .animate(delay: Duration(milliseconds: i * 80))
                      .fadeIn()
                      .slideX(begin: 0.1);
                },
              ),
            ),
        ],
      ),
    );
  }

  // ── Expanded Sub-posts panel ──────────────────
  Widget _buildExpandedSubPosts() {
    if (_expandedJobIndex == null) return const SizedBox.shrink();
    final job = _filteredJobs[_expandedJobIndex!];
    final accent = _jobAccent(_expandedJobIndex!);
    final matchingSubs = _subJobs
        .where((sj) => sj['parent_job_id'] == job.id)
        .toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                job.title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _kDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (matchingSubs.isEmpty)
            _SubJobEmptyCard(
              accent: accent,
              company: widget.company,
              jobId: job.id,
            )
          else
            ...matchingSubs.asMap().entries.map((entry) {
              final i = entry.key;
              final sj = entry.value;
              return _SubJobTile(
                subJob: sj,
                accent: accent,
                company: widget.company,
                index: i,
                onTap: () => _saveStudyProgress(sj),
              );
            }),
        ],
      ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.05),
    );
  }

  // ── Empty State ───────────────────────────────
  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _kPurpleLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_stories_outlined,
              size: 40,
              color: _kPurple,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _l10n.tr('no_opportunities_yet'),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _kDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _l10n.tr('check_back_soon_openings'),
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: _kGrey,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoWidget() {
    if (_loadingWikiLogo) {
      return Shimmer.fromColors(
        baseColor: const Color(0xFFE2E8F0),
        highlightColor: const Color(0xFFF8FAFC),
        child: Container(color: Colors.white),
      );
    }

    final logoUrl = widget.company.fullLogoUrl.isNotEmpty
        ? widget.company.fullLogoUrl
        : _wikiLogoUrl;

    if (logoUrl != null && logoUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: logoUrl,
        fit: BoxFit.cover,
        imageBuilder: (context, imageProvider) {
          if (!_logoLoadedSuccessfully) {
            _logoLoadedSuccessfully = true;
            _logoTimer?.cancel();
          }
          return Container(
            decoration: BoxDecoration(
              image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
            ),
          );
        },
        placeholder: (c, u) => Shimmer.fromColors(
          baseColor: const Color(0xFFE2E8F0),
          highlightColor: const Color(0xFFF8FAFC),
          child: Container(color: Colors.white),
        ),
        errorWidget: (c, u, e) => _buildFallbackIcon(),
      );
    }

    return _buildFallbackIcon();
  }

  Widget _buildFallbackIcon() {
    return Container(
      color: _kSurface,
      child: const Center(
        child: Icon(Icons.business_rounded, size: 28, color: _kGrey),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Sub-job Tile
// ─────────────────────────────────────────────
class _SubJobTile extends StatelessWidget {
  final dynamic subJob;
  final Color accent;
  final ExamItemModel company;
  final int index;
  final VoidCallback onTap;

  const _SubJobTile({
    required this.subJob,
    required this.accent,
    required this.company,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.rocket_launch_rounded,
                  color: accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subJob['title'] ?? 'Sub Post',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1D2E),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 12,
                      children: [
                        _badge(Icons.play_circle_outline_rounded, 'Video'),
                        _badge(Icons.description_outlined, 'Notes'),
                        _badge(Icons.emoji_events_outlined, 'Mock Test'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () {
                  onTap();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StudyLayersPage(
                        company: company,
                        jobId: subJob['id'],
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Start',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        )
        .animate(delay: Duration(milliseconds: index * 80))
        .fadeIn()
        .slideY(begin: 0.1);
  }

  Widget _badge(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: const Color(0xFF9CA3AF)),
        const SizedBox(width: 3),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            color: const Color(0xFF9CA3AF),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  Sub-job Empty Card (when no sub-posts)
// ─────────────────────────────────────────────
class _SubJobEmptyCard extends StatefulWidget {
  final Color accent;
  final ExamItemModel company;
  final dynamic jobId;

  const _SubJobEmptyCard({
    required this.accent,
    required this.company,
    required this.jobId,
  });

  @override
  State<_SubJobEmptyCard> createState() => _SubJobEmptyCardState();
}

class _SubJobEmptyCardState extends State<_SubJobEmptyCard> {
  final Dio _dio = ApiService().dio;
  bool _loading = true;
  String _syllabusContent = '';

  @override
  void initState() {
    super.initState();
    _fetchSyllabus();
  }

  Future<void> _fetchSyllabus() async {
    try {
      final response = await _dio.get(
        '/admin/study-layers',
        queryParameters: {
          'company_id': widget.company.id,
          'sub_job_id': widget.jobId,
        },
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final syllabusLayer = data.firstWhere(
          (l) => l['layer'].toString().toLowerCase() == 'syllabus',
          orElse: () => null,
        );
        setState(() {
          _syllabusContent = syllabusLayer != null
              ? (syllabusLayer['content_en'] ??
                    syllabusLayer['content_hi'] ??
                    'Syllabus coming soon...')
              : 'Detailed syllabus will be available shortly.';
          _loading = false;
        });
      }
    } catch (_) {
      setState(() {
        _syllabusContent = 'Failed to load. Please try again.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: _loading
          ? Shimmer.fromColors(
              baseColor: const Color(0xFFE2E8F0),
              highlightColor: const Color(0xFFF8FAFC),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 120,
                        height: 15,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.account_tree_rounded,
                      size: 18,
                      color: widget.accent,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Syllabus Overview',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1D2E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: widget.accent.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: widget.accent.withOpacity(0.12)),
                  ),
                  child: Text(
                    _syllabusContent,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: const Color(0xFF475569),
                      height: 1.6,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StudyLayersPage(
                          company: widget.company,
                          jobId: widget.jobId,
                        ),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Start Training',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
