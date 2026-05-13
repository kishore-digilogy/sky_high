import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sky_high/data/models/exam_category_model.dart';
import 'package:sky_high/data/models/job_model.dart';
import 'package:sky_high/pages/courses/study_layers_page.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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
  final Dio _dio = Dio();
  List<JobModel> _jobs = [];
  List<JobModel> _filteredJobs = [];
  bool _isLoading = true;
  String? _error;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  List<dynamic> _subJobs = [];

  // Which job card is currently expanded (null = none)
  int? _expandedJobIndex;

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _subPostsKey = GlobalKey();

  Map<String, dynamic>? _lastStudiedSubJob;

  @override
  void initState() {
    super.initState();
    _fetchJobs();
    _loadLastStudied();
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
        'https://skyhighapi.digilogy.dev/api/admin/posted-jobs',
        queryParameters: {'company_id': widget.company.id},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final allJobs = data.map((json) => JobModel.fromJson(json)).toList();

        final subRes = await _dio.get(
          'https://skyhighapi.digilogy.dev/api/admin/sub-posted-jobs',
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
          _error = 'Failed to load jobs';
          _isLoading = false;
        });
      }
    } catch (_) {
      setState(() {
        _error = 'Something went wrong';
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
    return Scaffold(
      backgroundColor: _kSurface,
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            _buildTopBar(),
            SliverToBoxAdapter(child: _buildHeroSection()),
            // SliverToBoxAdapter(child: _buildStartLearningBanner()),
            if (_lastStudiedSubJob != null)
              SliverToBoxAdapter(child: _buildContinueLearningSection()),
            SliverToBoxAdapter(child: _buildAboutSection()),
            SliverToBoxAdapter(child: _buildOpportunitiesSection()),
            if (_expandedJobIndex != null)
              SliverToBoxAdapter(
                key: _subPostsKey,
                child: _buildExpandedSubPosts(),
              ),
            SliverToBoxAdapter(child: _buildQuickAccess()),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
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
                hintText: 'Search opportunities...',
                hintStyle: GoogleFonts.plusJakartaSans(
                  color: _kGrey,
                  fontSize: 14,
                ),
                border: InputBorder.none,
              ),
            )
          : const SizedBox.shrink(),
      // actions: [
      //   if (!_isSearching) ...[
      //     _topActionBtn(
      //       Icons.bookmark_border_rounded,
      //       onTap: () => setState(() => _isSearching = true),
      //     ),
      //     const SizedBox(width: 8),
      //     _topActionBtn(Icons.share_outlined),
      //     const SizedBox(width: 12),
      //   ] else ...[
      //     IconButton(
      //       icon: const Icon(Icons.close, color: _kDark),
      //       onPressed: () {
      //         setState(() {
      //           _isSearching = false;
      //           _searchController.clear();
      //           _filterJobs('');
      //         });
      //       },
      //     ),
      //   ],
      // ],
    );
  }

  Widget _topActionBtn(IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Icon(icon, size: 18, color: _kDark),
      ),
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
                // Verified badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _kSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.shield_outlined,
                        size: 13,
                        color: _kGrey,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Government Organization',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: _kGrey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Icon(
                        Icons.verified_rounded,
                        size: 13,
                        color: _kPurple,
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms),
                const SizedBox(height: 12),
                // Logo + Name row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
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
                        child: widget.company.fullLogoUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: widget.company.fullLogoUrl,
                                fit: BoxFit.fill,
                                placeholder: (c, u) =>
                                    Container(color: _kSurface),
                                errorWidget: (c, u, e) => _buildFallbackIcon(),
                              )
                            : _buildFallbackIcon(),
                      ),
                    ).animate().scale(duration: 400.ms),
                    const SizedBox(width: 14),
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
                  'Build your career. Serve the nation.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: _kGrey,
                    fontWeight: FontWeight.w500,
                  ),
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 16),
                // Meta pills row
                Wrap(
                  spacing: 16,
                  children: [
                    _metaPill(
                      Icons.location_on_outlined,
                      'Worldwide',
                      color: _kGrey,
                    ),
                    _metaPill(
                      Icons.work_outline_rounded,
                      '${_jobs.length} Openings',
                      color: _kGrey,
                    ),
                    _metaPill(
                      Icons.local_fire_department_outlined,
                      'Trending',
                      color: Colors.deepOrange,
                    ),
                  ],
                ).animate().fadeIn(delay: 250.ms),
              ],
            ),
          ),
          // Train image on right
          // SizedBox(
          //   width: 130,
          //   height: 160,
          //   child: Stack(
          //     children: [
          //       Positioned(
          //         right: -10,
          //         top: 0,
          //         child: Container(
          //           width: 120,
          //           height: 120,
          //           decoration: BoxDecoration(
          //             shape: BoxShape.circle,
          //             color: _kPurpleLight,
          //           ),
          //         ),
          //       ),
          // Positioned(
          //   right: 0,
          //   bottom: 0,
          //   child: widget.company.fullLogoUrl.isNotEmpty
          //       ? CachedNetworkImage(
          //           imageUrl: widget.company.fullLogoUrl,
          //           width: 120,
          //           fit: BoxFit.contain,
          //           errorWidget: (c, u, e) => _buildTrainPlaceholder(),
          //         )
          //       : _buildTrainPlaceholder(),
          // ),
          //     ],
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _metaPill(IconData icon, String label, {required Color color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: _kDark,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildTrainPlaceholder() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: _kPurpleLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Icon(Icons.train_rounded, size: 60, color: _kPurple),
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
                'Continue Learning',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _kDark,
                  letterSpacing: -0.3,
                ),
              ),
              // Text(
              //   'View All',
              //   style: GoogleFonts.plusJakartaSans(
              //     fontSize: 13,
              //     color: _kPurple,
              //     fontWeight: FontWeight.w600,
              //   ),
              // ),
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
                        _lastStudiedSubJob!['title'] ?? 'Resume Course',
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
                        'Last studied: Yesterday',
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
                        'Resume',
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
    final desc = widget.company.description?.isNotEmpty == true
        ? widget.company.description!
        : 'One of the world\'s largest railway networks, connecting 7,000+ stations across India — a pillar of national infrastructure and public service excellence.';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About Organisation',
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
                'Top Opportunities',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _kDark,
                  letterSpacing: -0.3,
                ),
              ),
              // Text(
              //   'View All',
              //   style: GoogleFonts.plusJakartaSans(
              //     fontSize: 13,
              //     color: _kPurple,
              //     fontWeight: FontWeight.w600,
              //   ),
              // ),
            ],
          ),
          const SizedBox(height: 14),
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: _kPurple))
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
                                  '${matchingSubs.length} Sub-posts',
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

  // ── Quick Access ──────────────────────────────
  Widget _buildQuickAccess() {
    final items = [
      _QuickItem(Icons.quiz_outlined, 'Mock Tests', const Color(0xFF6C63FF)),
      _QuickItem(
        Icons.menu_book_outlined,
        'Study Material',
        const Color(0xFFEC4899),
      ),
      _QuickItem(
        Icons.history_edu_rounded,
        'Previous Year',
        const Color(0xFF10B981),
      ),
      _QuickItem(
        Icons.format_list_bulleted_rounded,
        'Syllabus',
        const Color(0xFFF59E0B),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Access',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _kDark,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 14),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: items
                .asMap()
                .entries
                .map((e) => _buildQuickItem(e.value, e.key))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickItem(_QuickItem item, int i) {
    return GestureDetector(
          onTap: () => _showComingSoonDialog(item.label, item.icon, item.color),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(item.icon, color: item.color, size: 24),
              ),
              const SizedBox(height: 6),
              Text(
                item.label,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: _kDark,
                ),
              ),
            ],
          ),
        )
        .animate(delay: Duration(milliseconds: i * 60))
        .fadeIn()
        .slideY(begin: 0.1);
  }

  void _showComingSoonDialog(String title, IconData icon, Color color) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _kDark,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'There are no files available for $title at this moment. We are working hard to bring them to you soon!',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: _kGrey,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Got it',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
            'No Opportunities Yet',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _kDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back soon for new openings.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: _kGrey,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StudyLayersPage(company: widget.company),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPurple,
                foregroundColor: _kWhite,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Text(
                'Browse Materials',
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
  final Dio _dio = Dio();
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
        'https://skyhighapi.digilogy.dev/api/admin/study-layers',
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
          ? Center(
              child: CircularProgressIndicator(
                color: widget.accent,
                strokeWidth: 2,
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

// ─────────────────────────────────────────────
//  Quick Access data model
// ─────────────────────────────────────────────
class _QuickItem {
  final IconData icon;
  final String label;
  final Color color;
  const _QuickItem(this.icon, this.label, this.color);
}
