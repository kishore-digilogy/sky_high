import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sky_high/core/services/socket_service.dart';
import 'package:sky_high/core/services/exam_service.dart';
import 'package:sky_high/core/services/storage_service.dart';
import 'package:sky_high/core/services/api_service.dart';
import 'package:sky_high/data/models/exam_category_model.dart';
import 'package:sky_high/data/models/study_layer_model.dart';
import 'package:sky_high/data/models/mock_test_set_model.dart';
import 'package:sky_high/data/models/mcq_set_model.dart';
import 'package:sky_high/core/services/localization_service.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sky_high/pages/study_materials/pdf_viewer_page.dart';

// Import our newly created modular sub-widgets
import 'widgets/study_layers_dialogs.dart';
import 'widgets/study_sidebar.dart';
import 'widgets/chapter_folders_view.dart';
import 'widgets/mcq_set_view.dart';
import 'widgets/mock_test_view.dart';
import 'widgets/study_materials_view.dart';

class StudyLayersPage extends StatefulWidget {
  final ExamItemModel company;
  final int? jobId;
  final int? initialModuleIndex;

  const StudyLayersPage({
    super.key,
    required this.company,
    this.jobId,
    this.initialModuleIndex,
  });

  @override
  State<StudyLayersPage> createState() => _StudyLayersPageState();
}

class _StudyLayersPageState extends State<StudyLayersPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final Dio _dio = ApiService().dio;
  final StorageService _storage = GetIt.I<StorageService>();

  List<StudyLayerModel> _apiLayers = [];
  int _selectedModuleIndex = 0;
  String? _selectedChapterName;
  final Set<int> _completedModuleIndices = {};
  bool _isLoading = true;
  bool _isPaidUser = false;
  bool _isLoggedIn = false;
  double _progress = 0.0; // Progress fraction (0.0 - 1.0)
  String? _currentCompletedModule;
  String? _nextModule;

  final String _currentLangCode = 'en';

  List<MockTestSetModel> _mockTests = [];
  bool _isMockLoading = false;

  List<McqSetModel> _mcqSets = [];
  bool _isMcqLoading = false;
  bool _isTitleExpanded = false;
  final ExamService _examService = ExamService();
  final LocalizationService _l10n = LocalizationService();

  late final List<Map<String, dynamic>> _moduleGroups;
  StreamSubscription? _socketSubscription;

  @override
  void initState() {
    super.initState();
    _moduleGroups = [
      {
        'type': 'basic_info',
        'title': _l10n.tr('mod_basic_info'),
        'icon': Icons.info_outline_rounded,
      },
      {
        'type': 'syllabus',
        'title': _l10n.tr('mod_syllabus'),
        'icon': Icons.menu_book_rounded,
      },
      {
        'type': 'preparation_plan',
        'title': _l10n.tr('mod_prep_plan'),
        'icon': Icons.track_changes_rounded,
      },
      {
        'type': 'notes',
        'title': _l10n.tr('mod_notes'),
        'icon': Icons.article_outlined,
      },
      {
        'type': 'pyq',
        'title': _l10n.tr('mod_pyq'),
        'icon': Icons.history_rounded,
      },
      {
        'type': 'mcq',
        'title': _l10n.tr('mod_mcq'),
        'icon': Icons.quiz_outlined,
      },
      {
        'type': 'video',
        'title': _l10n.tr('mod_video_lessons'),
        'icon': Icons.videocam_rounded,
      },
      {
        'type': 'mock_test',
        'title': _l10n.tr('mod_test_series'),
        'icon': Icons.quiz_outlined,
      },
    ];
    _selectedModuleIndex = widget.initialModuleIndex ?? 0;
    _checkSubscription();
    _fetchApiLayers();
    _fetchUserProgress();

    // Trigger initial data fetch based on selected module
    if (_selectedModuleIndex == 4) {
      _fetchMcqSets('pyq');
    } else if (_selectedModuleIndex == 5) {
      _fetchMcqSets('mcq');
    } else if (_selectedModuleIndex == 7) {
      _fetchMockTests();
    }

    // Listen to Socket.IO subscription changes
    _socketSubscription = GetIt.I<SocketService>().onSubscriptionStatusChanged.listen((status) {
      debugPrint('StudyLayersPage: Received socket subscription status update: $status');
      if (mounted) {
        setState(() {
          _checkSubscription();
          _fetchApiLayers();
        });
      }
    });
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    super.dispose();
  }

  void _checkSubscription() {
    final userData = _storage.getUserData();
    _isLoggedIn = _storage.getToken() != null;
    if (userData != null) {
      _isPaidUser =
          userData['subscription_status'] == 'paid' ||
          userData['is_paid'] == true;
    } else {
      _isPaidUser = false;
    }
  }

  // ── Progress Tracking ──────────────────────────────────────────────────

  /// Module key list aligned with _moduleGroups order
  static const List<String> _moduleKeys = [
    'basic_info',
    'syllabus',
    'preparation_plan',
    'notes',
    'pyq',
    'mcq',
    'video',
    'mock_test',
  ];

  int _getModuleIndex(String moduleId) {
    if (moduleId.startsWith('mod')) {
      final numStr = moduleId.substring(3);
      final parsed = int.tryParse(numStr);
      if (parsed != null && parsed >= 1 && parsed <= _moduleKeys.length) {
        return parsed - 1;
      }
    }
    return _moduleKeys.indexOf(moduleId);
  }

  /// Load server-side progress and populate _completedModuleIndices
  Future<void> _fetchUserProgress() async {
    // Always fetch progress regardless of login status
    try {
      final data = await ExamService().getUserProgress(
        companyId: widget.company.id,
        subJobId: widget.jobId,
      );

      final completedList = data['completedList'];
      final progressValue = data['progress'];
      if (mounted) {
        setState(() {
          if (progressValue is num) {
            _progress = progressValue / 100.0;
          }
          _currentCompletedModule = data['currentCompletedModule']?.toString();
          _nextModule = data['nextModule']?.toString();
        });
      }
      if (completedList is List && mounted) {
        final completed = <int>{};
        for (final moduleId in completedList) {
          final idx = _getModuleIndex(moduleId.toString());
          if (idx != -1) completed.add(idx);
        }
        setState(() {
          _completedModuleIndices
            ..clear()
            ..addAll(completed);
        });
      }

      // Open module directly based on response field currentCompletedModule
      final currentCompletedModule = data['currentCompletedModule'];
      if (currentCompletedModule != null && mounted) {
        final targetIndex = _getModuleIndex(currentCompletedModule.toString());
        if (targetIndex != -1 && targetIndex < _moduleGroups.length) {
          _switchToModule(
            targetIndex,
            _moduleGroups[targetIndex],
            closeDrawer: false,
          );
        }
      }
    } catch (e) {
      // Non-critical – progress will stay local
    }
  }

  /// Push a single module completion to the server
  Future<void> _updateProgressOnServer(int moduleIndex) async {
    if (!_isLoggedIn || moduleIndex >= _moduleKeys.length) return;
    try {
      await ExamService().updateUserProgress(
        moduleId: _moduleKeys[moduleIndex],
        isCompleted: 1,
        companyId: widget.company.id,
        subJobId: widget.jobId,
      );
      // Re-fetch user progress to keep the percentage and completed modules synced exactly
      await _fetchUserProgress();
    } catch (e) {
      // Silently ignore – the local state is already updated
    }
  }

  Future<void> _fetchApiLayers() async {
    try {
      final queryParams = {'company_id': widget.company.id};
      if (widget.jobId != null) {
        queryParams['sub_job_id'] = widget.jobId!;
      }

      final response = await _dio.get(
        '${ApiService.baseUrl}/admin/study-layers',
        queryParameters: queryParams,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        setState(() {
          _apiLayers = data
              .map((json) => StudyLayerModel.fromJson(json))
              .toList();
          _isLoading = false;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_storage.isStudyGuideShown) {
            StudyLayersDialogs.showInstructionGuide(
              context: context,
              storage: _storage,
            );
          }
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
        '${ApiService.baseUrl}/mock-tests/sets/${widget.company.name}',
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
        final navigator = Navigator.of(context);
        final shouldPop = await StudyLayersDialogs.showExitConfirmation(
          context: context,
          l10n: _l10n,
        );
        if (shouldPop && mounted) {
          navigator.pop();
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFFF1F5F9),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          toolbarHeight: 85,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF64748B),
              size: 20,
            ),
            onPressed: () async {
              final navigator = Navigator.of(context);
              if (await StudyLayersDialogs.showExitConfirmation(
                context: context,
                l10n: _l10n,
              )) {
                navigator.pop();
              }
            },
          ),
          title: GestureDetector(
            onTap: () => setState(() => _isTitleExpanded = !_isTitleExpanded),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.company.name,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                    height: 1.2,
                  ),
                  maxLines: _isTitleExpanded ? 3 : 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _l10n.tr('learning_journey'),
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Colors.blue,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
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
        drawer: StudySidebar(
          progress: _progress,
          moduleGroups: _moduleGroups,
          selectedModuleIndex: _selectedModuleIndex,
          completedModuleIndices: _completedModuleIndices,
          isPaidUser: _isPaidUser,
          isLoggedIn: _isLoggedIn,
          l10n: _l10n,
          onModuleSelected: (index, group) {
            _switchToModule(index, group, closeDrawer: true);
          },
          onLoginRequired: () => StudyLayersDialogs.showLoginRequiredDialog(
            context: context,
            l10n: _l10n,
            onLoginSuccess: () {
              setState(() {
                _checkSubscription();
                _fetchApiLayers();
              });
            },
          ),
          onLockedAlert: () => StudyLayersDialogs.showLockedDialog(
            context: context,
            l10n: _l10n,
            storage: _storage,
            onLoginSuccess: () {
              setState(() {
                _checkSubscription();
                _fetchApiLayers();
              });
            },
          ),
          onMarkCompleted: (completedIndex) {
            setState(() {
              _completedModuleIndices.add(completedIndex);
            });
            _updateProgressOnServer(completedIndex);
          },
        ),
        body: SafeArea(
          top: false,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildMainContent(),
        ),
      ),
    );
  }

  void _switchToModule(
    int index,
    Map<String, dynamic> group, {
    bool closeDrawer = false,
  }) {
    setState(() {
      _selectedModuleIndex = index;
      _selectedChapterName = null;
    });
    _storage.addRecentStudy({
      'company': widget.company.toJson(),
      'modIndex': index,
      'modTitle': group['title'],
      'timestamp': DateTime.now().toIso8601String(),
    });
    if (index == 4) {
      _fetchMcqSets('pyq');
    } else if (index == 5) {
      _fetchMcqSets('mcq');
    } else if (index == 7 && _mockTests.isEmpty) {
      _fetchMockTests();
    }
    if (closeDrawer && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  Widget _buildMainContent() {
    final group = _moduleGroups[_selectedModuleIndex];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildContentHeader(group['title'], index: _selectedModuleIndex),
              const SizedBox(height: 24),
              if (_isLoggedIn) ...[
                // Progress indicator showing percentage from API
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: _progress,
                        backgroundColor: const Color(0xFFE5E7EB),
                        color: const Color(0xFF6366F1),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "${(_progress * 100).toInt()}%",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: _buildMaterialsView(),
                  ),
                ),
              ),
              _buildCompleteAndNextButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentHeader(String title, {required int index}) {
    final Color color = const Color(0xFF6366F1);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.stars_rounded,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${_l10n.tr('mod_prefix')} ${index + 1}',
                  style: GoogleFonts.plusJakartaSans(
                    color: color,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
                height: 1.2,
              ),
              maxLines: 2,
              softWrap: true,
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset('assets/Icons/books.jpg', fit: BoxFit.contain),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: 0.1);
  }

  Widget _buildMaterialsView() {
    final group = _moduleGroups[_selectedModuleIndex];
    final String layerName = group['type'];

    if (layerName == 'skip') {
      return _buildEmptyContent(message: _l10n.tr('module_integrated_soon'));
    }

    if (layerName == 'mock_test') {
      return _isMockLoading
          ? const Center(child: CircularProgressIndicator())
          : _mockTests.isEmpty
          ? (_selectedModuleIndex >= 3 && _selectedModuleIndex <= 7
                ? _buildDummyFoldersView()
                : _buildEmptyContent(message: _l10n.tr('no_test_series')))
          : MockTestView(
              mockTests: _mockTests,
              selectedChapterName: _selectedChapterName,
              companyName: widget.company.name,
              companyId: widget.company.id,
              l10n: _l10n,
              onChapterChanged: (name) {
                setState(() {
                  _selectedChapterName = name;
                });
              },
            );
    }

    if (layerName == 'mcq' || layerName == 'pyq') {
      return _isMcqLoading
          ? const Center(child: CircularProgressIndicator())
          : _mcqSets.isEmpty
          ? (_selectedModuleIndex >= 3 && _selectedModuleIndex <= 7
                ? _buildDummyFoldersView()
                : _buildEmptyContent(message: _l10n.tr('no_sets_available')))
          : McqSetView(
              mcqSets: _mcqSets,
              selectedChapterName: _selectedChapterName,
              companyName: widget.company.name,
              companyId: widget.company.id,
              questionType: layerName,
              l10n: _l10n,
              onChapterChanged: (name) {
                setState(() {
                  _selectedChapterName = name;
                });
              },
            );
    }

    return StudyMaterialsView(
      apiLayers: _apiLayers,
      layerName: layerName,
      selectedModuleIndex: _selectedModuleIndex,
      selectedChapterName: _selectedChapterName,
      isPaidUser: _isPaidUser,
      currentLangCode: _currentLangCode,
      l10n: _l10n,
      onChapterChanged: (name) {
        setState(() {
          _selectedChapterName = name;
        });
      },
      onLockedAlert: () => StudyLayersDialogs.showLockedDialog(
        context: context,
        l10n: _l10n,
        storage: _storage,
        onLoginSuccess: () {
          setState(() {
            _checkSubscription();
            _fetchApiLayers();
          });
        },
      ),
      emptyContent: _buildEmptyContent(),
      dummyFoldersView: _buildDummyFoldersView(),
    );
  }

  Widget _buildDummyFoldersView() {
    return ChapterFoldersView(
      isDummy: true,
      l10n: _l10n,
      onDummyTap: () => StudyLayersDialogs.showWIPAlert(context),
    );
  }

  Widget _buildEmptyContent({String? message}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/Icons/coming_soon.svg',
              width: MediaQuery.of(context).size.width * 0.7,
            ),
            const SizedBox(height: 32),
            Text(
              message ??
                  'This module is currently being integrated.\nPlease check back soon.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                color: const Color(0xFF64748B),
                height: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateCertificate() async {
    // Show a beautiful, non-dismissible loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            backgroundColor: Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Generating Certificate...',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF111844),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We are creating your official course certificate. Please wait a moment...',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    try {
      final response = await _dio.post(
        '/certificates/generate',
        data: {
          'categoryId': widget.company.id,
          'job_id': null,
          'sub_job_id': widget.jobId?.toString(),
        },
      );

      // Dismiss the loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      if (response.statusCode == 200 && response.data != null) {
        final success = response.data['success'] ?? false;
        if (success) {
          final rawPdfUrl = response.data['pdfUrl'] ?? '';
          final code = response.data['code'] ?? '';
          final message = response.data['message'] ?? 'Certificate generated successfully!';

          // Standardize http to https for ATS/Cleartext security
          String pdfUrl = rawPdfUrl;
          if (pdfUrl.startsWith('http://')) {
            pdfUrl = pdfUrl.replaceFirst('http://', 'https://');
          }

          if (mounted) {
            _showCertificateSuccessDialog(pdfUrl, code, message);
          }
          return;
        }
      }

      throw Exception('Failed to generate certificate');
    } catch (e) {
      // Dismiss the loading dialog if it's still showing
      if (mounted) {
        Navigator.pop(context);
      }
      
      // Show elegant error dialog
      if (mounted) {
        _showCertificateErrorDialog();
      }
    }
  }

  void _showCertificateSuccessDialog(String pdfUrl, String code, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: Colors.white,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Gold Premium Icon
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFEF3C7), // Light gold
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      color: Color(0xFFD97706),
                      size: 48,
                    ),
                  ).animate().scale(delay: 200.ms, duration: 400.ms, curve: Curves.elasticOut),
                  const SizedBox(height: 24),
                  Text(
                    'Congratulations!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF111844),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your certificate has been successfully generated.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Certificate Code Card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Certificate Code: ',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        Text(
                          code,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Options
                  Row(
                    children: [
                      // View PDF
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context); // Close dialog
                            // Open in PdfViewerPage
                            PdfViewerPage.open(
                              this.context,
                              pdfUrl,
                              'Course Certificate',
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF111844)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'View PDF',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: const Color(0xFF111844),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      // Download PDF (opens in default external browser/app for downloading)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(context); // Close dialog
                            final Uri uri = Uri.parse(pdfUrl);
                            try {
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              } else {
                                throw 'Could not launch $pdfUrl';
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  SnackBar(
                                    content: Text('Could not open download link: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981), // Green download button
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Download PDF',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
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
        );
      },
    );
  }

  void _showCertificateErrorDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEE2E2), // Light red
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    color: Color(0xFFEF4444),
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Generation Failed',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF111844),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'We were unable to generate your certificate at this time. Please check your network connection and try again.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: const Color(0xFF64748B),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF111844),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Close',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompleteAndNextButton() {
    final bool isLastModule = _selectedModuleIndex == _moduleGroups.length - 1;
    final Color color = const Color(0xFF6366F1);
    final bool showGetCertificate =
        (_currentCompletedModule == 'mod8' && _nextModule == null) ||
        _progress >= 1.0;
    final Color buttonColor = showGetCertificate
        ? const Color(0xFF10B981)
        : color;

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: buttonColor.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () async {
            if (showGetCertificate) {
              await _generateCertificate();
              return;
            }

            // Check if they are on the last module but haven't achieved 100% progress
            if (isLastModule) {
              if (_progress < 1.0) {
                if (!mounted) return;
                showDialog(
                  context: context,
                  builder: (context) => Dialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    backgroundColor: Colors.white,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(
                                color: Color(0xFFFEF3C7), // Light gold/amber
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.warning_amber_rounded,
                                color: Color(0xFFD97706), // Amber
                                size: 36,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Course Incomplete',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Please complete every module to get your course certificate.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                color: const Color(0xFF64748B),
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 32),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => Navigator.pop(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1E293B),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  'Got it!',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
                return;
              }
            }

            final completedIdx = _selectedModuleIndex;

            // Mark completed locally first
            setState(() {
              _completedModuleIndices.add(completedIdx);
            });

            // If logged in, update progress on server immediately!
            if (_isLoggedIn) {
              await _updateProgressOnServer(completedIdx);
            }

            // Helper to handle advancing to the next module
            void advanceToNext() {
              if (isLastModule) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_l10n.tr('all_modules_completed')),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }

              final int nextIndex = completedIdx + 1;
              setState(() {
                _selectedModuleIndex = nextIndex;
                _selectedChapterName = null;

                if (_selectedModuleIndex == 4) {
                  _fetchMcqSets('pyq');
                } else if (_selectedModuleIndex == 5) {
                  _fetchMcqSets('mcq');
                } else if (_selectedModuleIndex == 7 && _mockTests.isEmpty) {
                  _fetchMockTests();
                }
              });
            }

            // Check if next module requires login or subscription
            if (!isLastModule && (completedIdx + 1) >= 3) {
              if (!_isLoggedIn) {
                if (!mounted) return;
                StudyLayersDialogs.showLoginRequiredDialog(
                  context: context,
                  l10n: _l10n,
                  onLoginSuccess: () async {
                    // Update state after login
                    setState(() {
                      _checkSubscription();
                      _fetchApiLayers();
                    });

                    // Now that they are logged in, save the progress of the module they just completed!
                    await _updateProgressOnServer(completedIdx);

                    if (!mounted) return;
                    // If subscription is paid, advance
                    if (_isPaidUser) {
                      advanceToNext();
                    } else {
                      // If not paid, show locked dialog
                      StudyLayersDialogs.showLockedDialog(
                        context: context,
                        l10n: _l10n,
                        storage: _storage,
                        onLoginSuccess: () {
                          setState(() {
                            _checkSubscription();
                            _fetchApiLayers();
                          });
                          advanceToNext();
                        },
                      );
                    }
                  },
                );
                return;
              }

              if (!_isPaidUser) {
                if (!mounted) return;
                StudyLayersDialogs.showLockedDialog(
                  context: context,
                  l10n: _l10n,
                  storage: _storage,
                  onLoginSuccess: () {
                    setState(() {
                      _checkSubscription();
                      _fetchApiLayers();
                    });
                    advanceToNext();
                  },
                );
                return;
              }
            }

            // Finally, advance to next module
            advanceToNext();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 64),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                showGetCertificate
                    ? 'Get Course Certificate'
                    : isLastModule
                    ? _l10n.tr('finish_journey')
                    : _l10n.tr('complete_next_module'),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                showGetCertificate
                    ? Icons.workspace_premium_rounded
                    : isLastModule
                    ? Icons.celebration_rounded
                    : Icons.arrow_forward_rounded,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
