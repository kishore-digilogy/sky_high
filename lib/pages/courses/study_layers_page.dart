import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:sky_high/core/services/exam_service.dart';
import 'package:sky_high/core/services/storage_service.dart';
import 'package:sky_high/data/models/exam_category_model.dart';
import 'package:sky_high/data/models/study_layer_model.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sky_high/pages/auth/login_page.dart';
import 'package:sky_high/pages/subscription/payment_screen.dart';
import 'package:sky_high/pages/study_materials/pdf_viewer_page.dart';
import 'package:sky_high/data/models/mock_test_set_model.dart';
import 'package:sky_high/data/models/mcq_set_model.dart';
import 'package:sky_high/pages/exams/mock_test_page.dart';
import 'package:sky_high/pages/courses/video_player_page.dart';

class StudyLayersPage extends StatefulWidget {
  final ExamItemModel company;
  final int? jobId;

  const StudyLayersPage({super.key, required this.company, this.jobId});

  @override
  State<StudyLayersPage> createState() => _StudyLayersPageState();
}

class _StudyLayersPageState extends State<StudyLayersPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final Dio _dio = Dio();
  final StorageService _storage = GetIt.I<StorageService>();

  List<StudyLayerModel> _apiLayers = [];
  int _selectedModuleIndex = 0;
  bool _isLoading = true;
  bool _isPaidUser = false;
  bool _isLoggedIn = false;
  String _currentLangCode = 'en'; // Default to English

  List<MockTestSetModel> _mockTests = [];
  bool _isMockLoading = false;

  List<McqSetModel> _mcqSets = [];
  bool _isMcqLoading = false;
  final ExamService _examService = ExamService();

  final List<Map<String, dynamic>> _moduleGroups = [
    {
      'type': 'basic_info',
      'title': 'Basic Information',
      'icon': Icons.info_outline_rounded,
    },
    {'type': 'syllabus', 'title': 'Syllabus', 'icon': Icons.menu_book_rounded},
    {
      'type': 'preparation_plan',
      'title': 'Preparation Plan',
      'icon': Icons.track_changes_rounded,
    },
    {
      'type': 'notes',
      'title': 'Chapter-wise / Topic-wise Notes',
      'icon': Icons.article_outlined,
    },
    {
      'type': 'pyq',
      'title': 'Chapter-wise / Topic-wise Previous Year Questions',
      'icon': Icons.history_rounded,
    },
    {
      'type': 'mcq',
      'title': 'Chapter-wise / Topic-wise MCQ',
      'icon': Icons.quiz_outlined,
    },
    {
      'type': 'video',
      'title': 'Chapter-wise / Topic-wise Video Lessons',
      'icon': Icons.videocam_rounded,
    },
    {
      'type': 'mock_test',
      'title': 'Online Test Series',
      'icon': Icons.quiz_outlined,
    },
  ];

  @override
  void initState() {
    super.initState();
    _checkSubscription();
    _fetchApiLayers();
  }

  void _checkSubscription() {
    final userData = _storage.getUserData();
    _isLoggedIn = _storage.getToken() != null;
    if (userData != null) {
      // Assuming 'subscription_status' or similar field
      _isPaidUser =
          userData['subscription_status'] == 'paid' ||
          userData['is_paid'] == true;
    } else {
      _isPaidUser = false;
    }
  }

  Future<void> _fetchApiLayers() async {
    try {
      final queryParams = {'company_id': widget.company.id};
      if (widget.jobId != null) {
        queryParams['sub_job_id'] = widget.jobId!;
      }

      final response = await _dio.get(
        'https://skyhighapi.digilogy.dev/api/admin/study-layers',
        queryParameters: queryParams,
      );
      print(response.data);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        setState(() {
          _apiLayers = data
              .map((json) => StudyLayerModel.fromJson(json))
              .toList();
          _isLoading = false;
        });

        // Open drawer by default after loading
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scaffoldKey.currentState?.openDrawer();
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchMockTests() async {
    setState(() => _isMockLoading = true);
    try {
      final response = await _dio.get(
        'https://skyhighapi.digilogy.dev/api/mock-tests/sets/${widget.company.name}',
        queryParameters: {'company_id': widget.company.id},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        setState(() {
          _mockTests = data
              .map((json) => MockTestSetModel.fromJson(json))
              .toList();
          _isMockLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isMockLoading = false);
    }
  }

  Future<void> _fetchMcqSets(String type) async {
    setState(() => _isMcqLoading = true);
    try {
      final sets = await _examService.getMcqSets(
        companyId: widget.company.id,
        questionType: type,
      );
      setState(() {
        _mcqSets = sets;
        _isMcqLoading = false;
      });
    } catch (e) {
      setState(() => _isMcqLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldPop = await _showExitConfirmation();
        if (shouldPop && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFFF1F5F9),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF64748B),
              size: 20,
            ),
            onPressed: () async {
              if (await _showExitConfirmation()) {
                Navigator.pop(context);
              }
            },
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.company.name,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              Text(
                'LEARNING JOURNEY',
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.menu_open_rounded,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            const SizedBox(width: 8),
          ],
        ),
        drawer: Drawer(
          width: MediaQuery.of(context).size.width * 0.85,
          backgroundColor: Colors.white,
          child: SafeArea(child: _buildSidebar()),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildMainContent(),
      ),
    );
  }

  Widget _buildSidebar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'MODULES',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF94A3B8),
                  letterSpacing: 1.1,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.close_rounded,
                  color: Color(0xFF94A3B8),
                  size: 20,
                ),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _moduleGroups.length,
            itemBuilder: (context, index) {
              final group = _moduleGroups[index];
              final isSelected = _selectedModuleIndex == index;
              // All modules can be clicked, but paid content in MOD 4+ will show lock dialog
              final isLocked = index >= 3 && !_isPaidUser;

              return _buildModuleTile(group, index, isSelected, isLocked);
            },
          ),
        ),
        _buildOverallProgress(),
      ],
    );
  }

  Widget _buildModuleTile(
    Map<String, dynamic> group,
    int index,
    bool isSelected,
    bool isLocked,
  ) {
    final colors = [
      const Color(0xFF6366F1),
      const Color(0xFFEC4899),
      const Color(0xFF06B6D4),
      const Color(0xFF10B981),
      const Color(0xFF94A3B8), // Skip 1
      const Color(0xFF94A3B8), // Skip 2
      const Color(0xFF8B5CF6), // Video
      const Color(0xFF94A3B8), // Skip 3
    ];
    final color = colors[index % colors.length];

    return InkWell(
      onTap: () {
        // First 3 modules are free (index 0, 1, 2)
        // From Mod 4 to 8 (index 3-7), check for login and subscription
        if (index >= 3) {
          if (!_isLoggedIn) {
            _showLoginRequiredDialog();
            return;
          }
          if (!_isPaidUser) {
            _showLockedDialog();
            return;
          }
        }

        setState(() => _selectedModuleIndex = index);
        if (index == 4) {
          _fetchMcqSets('pyq');
        } else if (index == 5) {
          _fetchMcqSets('mcq');
        } else if (index == 7 && _mockTests.isEmpty) {
          _fetchMockTests();
        }
        Navigator.pop(context); // Close drawer
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: color.withOpacity(0.2)) : null,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected ? color : color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isSelected
                    ? group['icon']
                    : (isLocked ? Icons.lock_outline_rounded : group['icon']),
                color: isSelected ? Colors.white : color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MOD ${index + 1}',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? color : const Color(0xFF94A3B8),
                    ),
                  ),
                  Text(
                    group['title'],
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? color : const Color(0xFF1E293B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isLocked)
              const Icon(
                Icons.lock_rounded,
                size: 14,
                color: Color(0xFF94A3B8),
              ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (50 * index).ms).slideX(begin: -0.1);
  }

  IconData _getModuleIcon(int modNum) {
    switch (modNum) {
      case 1:
        return Icons.info_outline_rounded;
      case 2:
        return Icons.menu_book_rounded;
      case 3:
        return Icons.track_changes_rounded;
      case 4:
        return Icons.article_outlined;
      case 8:
        return Icons.quiz_outlined;
      default:
        return Icons.layers_outlined;
    }
  }

  Widget _buildMainContent() {
    final group = _moduleGroups[_selectedModuleIndex];

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildContentHeader(group['title'], index: _selectedModuleIndex),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: _buildMaterialsView(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentHeader(String title, {required int index}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6366F1), Color(0xFF4338CA)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.stars_rounded, color: Colors.white, size: 14),
                const SizedBox(width: 6),
                Text(
                  'MODULE ${index + 1}',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Explore the detailed resources for this module.',
            style: GoogleFonts.outfit(fontSize: 16, color: Colors.white70),
          ),
        ],
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildMaterialsView() {
    final group = _moduleGroups[_selectedModuleIndex];
    final String layerName = group['type'];

    if (layerName == 'skip') {
      return _buildEmptyContent(
        message:
            'This module is currently being integrated.\nPlease check back soon.',
      );
    }

    if (layerName == 'mock_test') {
      return _isMockLoading
          ? const Center(child: CircularProgressIndicator())
          : _mockTests.isEmpty
          ? _buildEmptyContent(message: 'No test series available yet.')
          : _buildMockTestView();
    }

    if (layerName == 'mcq' || layerName == 'pyq') {
      return _isMcqLoading
          ? const Center(child: CircularProgressIndicator())
          : _mcqSets.isEmpty
          ? _buildEmptyContent(
              message: 'No sets available for this module yet.',
            )
          : _buildMcqSetView();
    }

    final filteredItems = _apiLayers
        .where((item) => item.layer.toLowerCase() == layerName.toLowerCase())
        .toList();

    if (filteredItems.isEmpty) {
      return _buildEmptyContent();
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Available Materials',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              Text(
                '${filteredItems.length} items',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: filteredItems.length,
            itemBuilder: (context, index) {
              final item = filteredItems[index];
              return _buildLayerContentCard(item);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLayerContentCard(StudyLayerModel item) {
    final title = item.getLocalizedTitle(_currentLangCode);
    final date = item.getFormattedDate();
    final isLocked = !item.isFree && !_isPaidUser;

    if (item.layer.toLowerCase() == 'basic_info') {
      final content = item.getLocalizedContent(_currentLangCode);
      return _buildBasicInfoCard(title, content, date);
    } else {
      final url = item.getLocalizedUrl(_currentLangCode);
      return _buildResourceCard(item, title, url, date, isLocked);
    }
  }

  Widget _buildBasicInfoCard(String title, String? content, String date) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ),
              Text(
                date,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: const Color(0xFF94A3B8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if (content != null && content.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              content,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: const Color(0xFF64748B),
                height: 1.6,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResourceCard(
    StudyLayerModel item,
    String title,
    String? url,
    String date,
    bool isLocked,
  ) {
    if (url == null && !isLocked) return const SizedBox.shrink();

    final bool isPdf = url?.toLowerCase().endsWith('.pdf') ?? false;
    final bool isVideo = url?.toLowerCase().endsWith('.mp4') ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ),
              Text(
                date,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: const Color(0xFF94A3B8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (isLocked)
            _buildLockPrompt()
          else if (url == null)
            _buildNotAvailablePrompt()
          else
            _buildActionButton(title, url, isPdf, isVideo),
        ],
      ),
    );
  }

  Widget _buildLockPrompt() {
    return InkWell(
      onTap: () => _showLockedDialog(),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            const Icon(Icons.lock_rounded, size: 18, color: Colors.orange),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'This content is locked. Upgrade to unlock.',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange[800],
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 12,
              color: Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotAvailablePrompt() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: Color(0xFF64748B),
          ),
          const SizedBox(width: 12),
          Text(
            'Not available in this language',
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String title,
    String url,
    bool isPdf,
    bool isVideo,
  ) {
    return ElevatedButton(
      onPressed: () {
        if (isPdf) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PdfViewerPage(pdfUrl: url, title: title),
            ),
          );
        } else if (isVideo) {
          // debugPrint('🎯 Watch Video Button Tapped!');
          // debugPrint('🎬 Full Video URL: $url');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  VideoPlayerPage(videoUrl: url, title: title),
            ),
          );
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isPdf
            ? const Color(0xFFEF4444)
            : const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isPdf
                ? Icons.picture_as_pdf_rounded
                : Icons.play_circle_fill_rounded,
            size: 20,
          ),
          const SizedBox(width: 10),
          Text(
            isPdf ? 'View PDF' : 'Watch Video',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _showWIPAlert() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Work in Progress'),
        content: const Text('Video player integration is coming soon.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyContent({String? message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(
              Icons.assignment_outlined,
              size: 48,
              color: Colors.blue.withOpacity(0.3),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Coming Soon!',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message ??
                'Premium materials are being prepared for this module.\nCheck back soon!',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: const Color(0xFF64748B),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallProgress() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.1))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Overall Progress',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
              Text(
                '${(_selectedModuleIndex + 1) * 12}%',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (_selectedModuleIndex + 1) * 0.12,
              backgroundColor: Colors.blue.withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  void _showLockedDialog() {
    final userData = _storage.getUserData();

    if (userData == null) {
      _showLoginRequiredDialog();
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.lock_rounded, color: Colors.orange),
            const SizedBox(width: 10),
            Text(
              'Premium Content',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'This module is part of our Elite Learning Path. Upgrade your subscription to unlock all modules and advanced test series.',
          style: GoogleFonts.outfit(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Maybe Later',
              style: GoogleFonts.outfit(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PaymentScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Upgrade Now',
              style: GoogleFonts.outfit(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: EdgeInsets.zero,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 30),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.account_circle_outlined,
                    size: 40,
                    color: Colors.blue,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    'Login Required',
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Please login to access premium modules and track your progress.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: const Color(0xFF64748B),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Maybe Later',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginPage(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Login Now',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _showExitConfirmation() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.logout_rounded,
                      color: Color(0xFFEF4444),
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Exit Learning Journey?',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your progress for this session will be saved. Are you sure you want to exit?',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: const Color(0xFF64748B),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            'Keep Learning',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
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
                            'Yes, Exit',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ) ??
        false;
  }

  Widget _buildMockTestView() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _mockTests.length,
      itemBuilder: (context, index) {
        final test = _mockTests[index];
        return _buildMockTestCard(test);
      },
    );
  }

  Widget _buildMockTestCard(MockTestSetModel test) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.layers, color: Colors.orange, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CHAPTER',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                      letterSpacing: 1.1,
                    ),
                  ),
                  Text(
                    test.chapterName ?? 'General',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'TOPIC: ${test.topicName?.toUpperCase() ?? 'N/A'}',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MockTestPage(
                    setName: test.setName,
                    companyName: widget.company.name,
                    companyId: widget.company.id,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Icon(
                            Icons.description_outlined,
                            size: 40,
                            color: Colors.grey.withOpacity(0.3),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'MOCK TEST',
                              style: GoogleFonts.outfit(
                                fontSize: 7,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      test.setName ?? 'Untitled',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: Color(0xFF94A3B8),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMcqSetView() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _mcqSets.length,
      itemBuilder: (context, index) {
        final set = _mcqSets[index];
        return _buildMcqSetCard(set);
      },
    );
  }

  Widget _buildMcqSetCard(McqSetModel set) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Chapter Name
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFFFF5F5),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.layers,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CHAPTER',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFEF4444),
                            letterSpacing: 1.1,
                          ),
                        ),
                        Text(
                          set.chapterName ?? 'General',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '1 item',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFEF4444),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'TOPIC: ${set.topicName?.toUpperCase() ?? 'N/A'}',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                InkWell(
                  onTap: () {
                    final group = _moduleGroups[_selectedModuleIndex];
                    final String layerName = group['type']; // 'mcq' or 'pyq'

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MockTestPage(
                          setName: set.setName,
                          companyName: widget.company.name,
                          companyId: widget.company.id,
                          chapterId: set.chapterId,
                          topicId: set.topicId,
                          questionType: layerName,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: Icon(
                                  Icons.track_changes_rounded,
                                  size: 40,
                                  color: Colors.red.withOpacity(0.3),
                                ),
                              ),
                              Positioned(
                                top: 8,
                                left: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'QUIZ',
                                    style: GoogleFonts.outfit(
                                      fontSize: 7,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 8,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${set.questionCount ?? 0} Qs',
                                      style: GoogleFonts.outfit(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            set.setName ?? 'Untitled',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: Color(0xFF94A3B8),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
