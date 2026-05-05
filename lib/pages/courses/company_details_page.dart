import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sky_high/data/models/exam_category_model.dart';
import 'package:sky_high/data/models/job_model.dart';
import 'package:sky_high/pages/courses/study_layers_page.dart';
import 'package:sky_high/pages/courses/sub_posted_jobs_page.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
  List<dynamic> _subJobs = []; // To store sub-posted jobs

  @override
  void initState() {
    super.initState();
    _fetchJobs();
  }

  Future<void> _fetchJobs() async {
    try {
      final response = await _dio.get(
        'https://skyhighapi.digilogy.dev/api/admin/posted-jobs',
        queryParameters: {'company_id': widget.company.id},
      );
      // print("res:${response.data}");
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final allJobs = data.map((json) => JobModel.fromJson(json)).toList();

        // Fetch Sub-posted jobs
        final subRes = await _dio.get(
          'https://skyhighapi.digilogy.dev/api/admin/sub-posted-jobs',
          queryParameters: {'company_id': widget.company.id},
        );
        if (subRes.statusCode == 200) {
          _subJobs = subRes.data;
        }

        setState(() {
          _jobs = allJobs
              .where((job) => job.title.toUpperCase() != "GET")
              .toList();
          _filteredJobs = _jobs;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load jobs';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Something went wrong';
        _isLoading = false;
      });
    }
  }

  void _filterJobs(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredJobs = _jobs;
      } else {
        _filteredJobs = _jobs
            .where(
              (job) => job.title.toLowerCase().contains(query.toLowerCase()),
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
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(child: _buildFlexibleHeader()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAboutCard()
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .slideY(begin: 0.2),
                  const SizedBox(height: 24),
                  const SizedBox(height: 24),
                  _isLoading
                      ? _buildLoadingState()
                      : Column(
                          children: [
                            _filteredJobs.isEmpty
                                ? _buildEmptyState().animate().fadeIn()
                                : _buildJobsList(),
                          ],
                        ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF1E293B),
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Colors.white,
          size: 20,
        ),
        onPressed: () {
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
      ),
      title: _isSearching
          ? Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _filterJobs,
                autofocus: true,
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search jobs...',
                  hintStyle: GoogleFonts.outfit(color: Colors.white60),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Colors.white70,
                    size: 18,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            )
          : Text(
              widget.company.name,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
      actions: [
        if (!_isSearching)
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () => setState(() => _isSearching = true),
          ),
      ],
    );
  }

  Widget _buildFlexibleHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E293B), Color(0xFF334155)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -50,
            top: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: widget.company.fullLogoUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: widget.company.fullLogoUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                Container(color: Colors.grey[100]),
                            errorWidget: (context, url, error) =>
                                _buildFallbackIcon(),
                          )
                        : _buildFallbackIcon(),
                  ),
                ).animate().scale(duration: 400.ms, curve: Curves.easeInOut),
                const SizedBox(height: 20),
                Text(
                  widget.company.name,
                  style: GoogleFonts.outfit(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildInfoBadge(Icons.location_on_outlined, 'Worldwide'),
                    _buildInfoBadge(
                      Icons.work_outline_rounded,
                      '${_jobs.length} Openings',
                    ),
                  ],
                ).animate().fadeIn(delay: 300.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white70),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.outfit(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF97316).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFFF97316),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'About the Company',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.company.description != null &&
                    widget.company.description!.isNotEmpty
                ? widget.company.description!
                : 'This prestigious organization is one of the leading entities in its sector, dedicated to excellence and innovation in all its operations.',
            style: GoogleFonts.outfit(
              fontSize: 15,
              color: const Color(0xFF64748B),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            count.toString(),
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildJobsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredJobs.length,
      padding: EdgeInsets.zero,
      itemBuilder: (context, index) {
        final job = _filteredJobs[index];
        return _buildJobCard(job, index);
      },
    );
  }

  Widget _buildJobCard(JobModel job, int index) {
    final colors = [
      const Color(0xFF6366F1),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFFEC4899),
    ];
    final color = colors[index % colors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          // Check if this job has sub-posts
          final matchingSubJobs = _subJobs
              .where((sj) => sj['parent_job_id'] == job.id)
              .toList();

          if (matchingSubJobs.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SubPostedJobsPage(
                  parentJob: job,
                  subJobs: matchingSubJobs,
                  company: widget.company,
                ),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    StudyLayersPage(company: widget.company, jobId: job.id),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(Icons.stars_rounded, color: color, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.title,
                          style: GoogleFonts.outfit(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.schedule,
                              size: 14,
                              color: Color(0xFF94A3B8),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Updated Recently',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                color: const Color(0xFF94A3B8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: Color(0xFFCBD5E1),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.rocket_launch_rounded,
                        color: Color(0xFF6366F1),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Start Learning Path',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6366F1),
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: const Color(0xFF6366F1).withOpacity(0.5),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: (100 * index).ms).slideY(begin: 0.1);
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_stories_outlined,
              size: 48,
              color: const Color(0xFF6366F1).withOpacity(0.3),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Explore Study Materials',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'No specialized job paths posted yet, but you can explore our full collection of materials.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: const Color(0xFF64748B),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        StudyLayersPage(company: widget.company),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E293B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                'Browse Materials',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40.0),
        child: CircularProgressIndicator(color: Color(0xFF6366F1)),
      ),
    );
  }

  Widget _buildFallbackIcon() {
    return Container(
      color: const Color(0xFFF1F5F9),
      child: const Center(
        child: Icon(Icons.business_rounded, size: 32, color: Color(0xFF94A3B8)),
      ),
    );
  }
}
