import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sky_high/core/services/exam_service.dart';
import 'package:sky_high/core/services/storage_service.dart';
import 'package:sky_high/core/services/api_service.dart';
import 'package:sky_high/data/models/exam_category_model.dart';
import 'package:sky_high/data/models/study_layer_model.dart';
import 'package:sky_high/data/models/mock_test_set_model.dart';
import 'package:sky_high/data/models/mcq_set_model.dart';
import 'package:sky_high/core/services/localization_service.dart';
import 'package:flutter_svg/flutter_svg.dart';

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

  final String _currentLangCode = 'en';

  List<MockTestSetModel> _mockTests = [];
  bool _isMockLoading = false;

  List<McqSetModel> _mcqSets = [];
  bool _isMcqLoading = false;
  bool _isTitleExpanded = false;
  final ExamService _examService = ExamService();
  final LocalizationService _l10n = LocalizationService();

  late final List<Map<String, dynamic>> _moduleGroups;

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
      if (progressValue is num) {
        setState(() {
          _progress = progressValue / 100.0;
        });
      }
      if (completedList is List && mounted) {
        final completed = <int>{};
        for (final moduleId in completedList) {
          final idx = _moduleKeys.indexOf(moduleId.toString());
          if (idx != -1) completed.add(idx);
        }
        setState(() {
          _completedModuleIndices
            ..clear()
            ..addAll(completed);
        });
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
          moduleGroups: _moduleGroups,
          selectedModuleIndex: _selectedModuleIndex,
          completedModuleIndices: _completedModuleIndices,
          isPaidUser: _isPaidUser,
          isLoggedIn: _isLoggedIn,
          l10n: _l10n,
          onModuleSelected: (index, group) {
            _switchToModule(index, group);
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

  void _switchToModule(int index, Map<String, dynamic> group) {
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
    if (Navigator.canPop(context)) {
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

  Widget _buildCompleteAndNextButton() {
    final bool isLastModule = _selectedModuleIndex == _moduleGroups.length - 1;
    final Color color = const Color(0xFF6366F1);

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () {
            final completedIdx = _selectedModuleIndex;
            setState(() {
              _completedModuleIndices.add(_selectedModuleIndex);

              if (!isLastModule) {
                final int nextIndex = _selectedModuleIndex + 1;

                if (nextIndex >= 3) {
                  if (!_isLoggedIn) {
                    StudyLayersDialogs.showLoginRequiredDialog(
                      context: context,
                      l10n: _l10n,
                      onLoginSuccess: () {
                        setState(() {
                          _checkSubscription();
                          _fetchApiLayers();
                        });
                      },
                    );
                    return;
                  }
                  if (!_isPaidUser) {
                    StudyLayersDialogs.showLockedDialog(
                      context: context,
                      l10n: _l10n,
                      storage: _storage,
                      onLoginSuccess: () {
                        setState(() {
                          _checkSubscription();
                          _fetchApiLayers();
                        });
                      },
                    );
                    return;
                  }
                }

                _selectedModuleIndex = nextIndex;
                _selectedChapterName = null;

                if (_selectedModuleIndex == 4) {
                  _fetchMcqSets('pyq');
                } else if (_selectedModuleIndex == 5) {
                  _fetchMcqSets('mcq');
                } else if (_selectedModuleIndex == 7 && _mockTests.isEmpty) {
                  _fetchMockTests();
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_l10n.tr('all_modules_completed')),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            });
            _updateProgressOnServer(completedIdx);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
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
                isLastModule
                    ? _l10n.tr('finish_journey')
                    : _l10n.tr('complete_next_module'),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                isLastModule
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
