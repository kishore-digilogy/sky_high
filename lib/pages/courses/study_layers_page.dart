import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
import 'package:sky_high/core/services/localization_service.dart';

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
  final Dio _dio = Dio();
  final StorageService _storage = GetIt.I<StorageService>();

  List<StudyLayerModel> _apiLayers = [];
  int _selectedModuleIndex = 0;
  String? _selectedChapterName;
  final Set<int> _completedModuleIndices = {};
  bool _isLoading = true;
  bool _isPaidUser = false;
  bool _isLoggedIn = false;
  String _currentLangCode = 'en';

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

        // Open guide or drawer based on flag
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_storage.isStudyGuideShown) {
            _showInstructionGuide();
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
          toolbarHeight: 85,
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
        drawer: Drawer(
          width: MediaQuery.of(context).size.width * 0.85,
          backgroundColor: Colors.white,
          child: SafeArea(child: _buildSidebar()),
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

  Widget _buildSidebar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 12, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _l10n.tr('modules'),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E293B),
                  letterSpacing: 0.5,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Color(0xFF64748B),
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Progress Card
        _buildProgressCard(),

        // Modules List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 10),
            itemCount: _moduleGroups.length,
            itemBuilder: (context, index) {
              final group = _moduleGroups[index];
              final isSelected = _selectedModuleIndex == index;
              final isLocked = index >= 3 && !_isPaidUser;
              return _buildModuleTile(group, index, isSelected, isLocked);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProgressCard() {
    final double progress =
        _completedModuleIndices.length / _moduleGroups.length;
    final int percentage = (progress * 100).toInt();

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Circular Progress with Rocket
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 70,
                    height: 70,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 6,
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.rocket_launch_rounded,
                      color: Color(0xFF1E293B),
                      size: 24,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              // Progress Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _l10n.tr('your_progress'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _l10n.tr('keep_learning_great'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$percentage%',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleTile(
    Map<String, dynamic> group,
    int index,
    bool isSelected,
    bool isLocked,
  ) {
    // Use black for all text/icons, but we will highlight the left bar if selected
    final Color color = const Color(0xFF1E293B);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? color.withOpacity(0.12)
                : Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
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

            if (index != _selectedModuleIndex &&
                !_completedModuleIndices.contains(_selectedModuleIndex) &&
                !_completedModuleIndices.contains(index)) {
              showDialog(
                context: context,
                builder: (context) => Dialog(
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
                            color: Color(0xFFEEF2FF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_circle_outline_rounded,
                            color: Color(0xFF6366F1),
                            size: 36,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Complete Module?',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'You are about to switch to another module. Would you like to mark the current module as completed to update your progress?',
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
                            onPressed: () {
                              Navigator.pop(context);
                              setState(() {
                                _completedModuleIndices.add(
                                  _selectedModuleIndex,
                                );
                              });
                              _switchToModule(index, group);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'Yes, Mark as Completed',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _switchToModule(index, group);
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF64748B),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: const BorderSide(color: Color(0xFFE2E8F0)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'No, Just Switch',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF94A3B8),
                            minimumSize: const Size(double.infinity, 48),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
              return;
            }

            _switchToModule(index, group);
          },
          borderRadius: BorderRadius.circular(16),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Left Color Bar
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF10B981)
                        : Colors.transparent,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Number Circle
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    (index + 1).toString().padLeft(2, '0'),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Icon Badge
                Container(
                  width: 44,
                  height: 44,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isLocked ? Icons.lock_outline_rounded : group['icon'],
                    color: color,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                // Title Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${_l10n.tr('module_prefix')} ${index + 1}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: color,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        group['title'],
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E293B),
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                // Arrow
                Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: color,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
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
    // Only pop if a drawer or dialog is open
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
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
      case 5:
        return Icons.history_edu_rounded;
      case 6:
        return Icons.fact_check_rounded;
      case 7:
        return Icons.videocam_rounded;
      case 8:
        return Icons.quiz_outlined;
      default:
        return Icons.layers_outlined;
    }
  }

  Widget _buildMainContent() {
    final group = _moduleGroups[_selectedModuleIndex];
    final String layerName = group['type'];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
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
                  // BoxShadow(
                  //   color: Colors.black.withOpacity(0.03),
                  //   blurRadius: 20,
                  //   offset: const Offset(0, 10),
                  // ),
                ],
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
            setState(() {
              _completedModuleIndices.add(_selectedModuleIndex);

              if (!isLastModule) {
                final int nextIndex = _selectedModuleIndex + 1;

                // Safety check for locked modules (consistent with drawer logic)
                if (nextIndex >= 3) {
                  if (!_isLoggedIn) {
                    _showLoginRequiredDialog();
                    return;
                  }
                  if (!_isPaidUser) {
                    _showLockedDialog();
                    return;
                  }
                }

                _selectedModuleIndex = nextIndex;
                _selectedChapterName = null;

                // Fetch data for the newly selected module
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
          // Module Badge Pill
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
          // Title
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
          // Illustration
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
          : _buildMockTestView();
    }

    if (layerName == 'mcq' || layerName == 'pyq') {
      return _isMcqLoading
          ? const Center(child: CircularProgressIndicator())
          : _mcqSets.isEmpty
          ? (_selectedModuleIndex >= 3 && _selectedModuleIndex <= 7
                ? _buildDummyFoldersView()
                : _buildEmptyContent(message: _l10n.tr('no_sets_available')))
          : _buildMcqSetView();
    }

    final filteredItems = _apiLayers
        .where((item) => item.layer.toLowerCase() == layerName.toLowerCase())
        .toList();

    if (filteredItems.isEmpty) {
      return (_selectedModuleIndex >= 3 && _selectedModuleIndex <= 7)
          ? _buildDummyFoldersView()
          : _buildEmptyContent();
    }

    // Check if we should show folders
    final hasChapters = filteredItems.any(
      (item) => item.chapterName != null && item.chapterName!.isNotEmpty,
    );
    if (hasChapters && _selectedChapterName == null) {
      return _buildRealChapterFoldersView(filteredItems);
    }

    final itemsToShow = _selectedChapterName == null
        ? filteredItems
        : filteredItems
              .where(
                (item) => (item.chapterName ?? 'Other') == _selectedChapterName,
              )
              .toList();

    final bool useGrid = layerName.toLowerCase() != 'basic_info';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_selectedChapterName != null)
                InkWell(
                  onTap: () => setState(() => _selectedChapterName = null),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 14,
                          color: Color(0xFF6366F1),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Back to Folders',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF6366F1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedChapterName ?? _l10n.tr('available_materials'),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        _l10n
                            .tr('items_count')
                            .replaceAll(
                              '{count}',
                              itemsToShow.length.toString(),
                            ),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.filter_list_rounded,
                        size: 18,
                        color: Color(0xFF64748B),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: useGrid
              ? GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.78,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: itemsToShow.length + 1, // +1 for the banner
                  itemBuilder: (context, index) {
                    if (index == itemsToShow.length) {
                      return const SizedBox.shrink(); // Handled by Sliver logic if needed, but for now just empty
                    }
                    return _buildLayerContentCard(
                      itemsToShow[index],
                      isGrid: true,
                    );
                  },
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: itemsToShow.length,
                  itemBuilder: (context, index) {
                    return _buildLayerContentCard(
                      itemsToShow[index],
                      isGrid: false,
                    );
                  },
                ),
        ),
        if (useGrid) _buildFooterBanner(),
      ],
    );
  }

  Widget _buildRealChapterFoldersView(List<StudyLayerModel> items) {
    final Map<String, List<StudyLayerModel>> grouped = {};
    for (var item in items) {
      final name = item.chapterName ?? 'Other';
      if (!grouped.containsKey(name)) {
        grouped[name] = [];
      }
      grouped[name]!.add(item);
    }

    final chapterNames = grouped.keys.toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _l10n.tr('available_materials'),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 5 : 2,
              childAspectRatio: MediaQuery.of(context).size.width > 600
                  ? 2.8
                  : 2.1,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: chapterNames.length,
            itemBuilder: (context, index) {
              final name = chapterNames[index];
              final count = grouped[name]!.length;

              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedChapterName = name;
                  });
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
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
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.folder_rounded,
                          color: Color(0xFF6366F1),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              name,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1E293B),
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '$count ${_l10n.tr('items')}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: const Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFFE2E8F0),
                        size: 16,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFooterBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDBEAFE)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.article_rounded,
              color: Color(0xFF3B82F6),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'New materials will be added regularly.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E40AF),
                  ),
                ),
                Text(
                  'Keep learning, keep growing! 🚀',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: const Color(0xFF60A5FA),
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.auto_awesome_rounded,
            color: Color(0xFF93C5FD),
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildLayerContentCard(StudyLayerModel item, {required bool isGrid}) {
    final title = item.getLocalizedTitle(_currentLangCode);
    final date = item.getFormattedDate();
    final isLocked = !item.isFree && !_isPaidUser;
    final url = item.getLocalizedUrl(_currentLangCode);

    if (isGrid) {
      return _buildGridResourceCard(item, title, url, date, isLocked);
    }

    // If it has a URL, treat it as a resource so it can be opened
    if (url != null) {
      return _buildResourceCard(item, title, url, date, isLocked);
    }

    if (item.layer.toLowerCase() == 'basic_info' ||
        item.layer.toLowerCase() == 'syllabus' ||
        item.layer.toLowerCase() == 'preparation_plan') {
      final content = item.getLocalizedContent(_currentLangCode);
      return _buildBasicInfoCard(title, content, date);
    } else {
      return _buildResourceCard(item, title, url, date, isLocked);
    }
  }

  Widget _buildGridResourceCard(
    StudyLayerModel item,
    String title,
    String? url,
    String date,
    bool isLocked,
  ) {
    final bool isPdf = url?.toLowerCase().endsWith('.pdf') ?? false;
    final Color color = const Color(0xFF6366F1);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (isLocked) {
              _showLockedDialog();
            } else if (url != null) {
              if (isPdf) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PdfViewerPage(pdfUrl: url, title: title),
                  ),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        VideoPlayerPage(videoUrl: url, title: title),
                  ),
                );
              }
            }
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                _buildResourceIcon(isPdf),
                const Spacer(),
                // Title
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Date
                Text(
                  date,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: const Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                // View Button
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isPdf ? 'View PDF' : 'Watch Video',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 8,
                        color: color,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResourceIcon(bool isPdf) {
    return Container(
      width: 50,
      height: 65,
      decoration: BoxDecoration(
        color: const Color(0xFFFFE4E6), // Soft pink
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            isPdf
                ? Icons.description_rounded
                : Icons.play_circle_filled_rounded,
            color: const Color(0xFFFB7185),
            size: 32,
          ),
          Positioned(
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFFFB7185),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                isPdf ? 'PDF' : 'VIDEO',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 7,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getFileSize(int id) {
    final sizes = ['1.2 MB', '2.4 MB', '3.1 MB', '1.8 MB', '2.7 MB', '0.9 MB'];
    return sizes[id % sizes.length];
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
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ),
              Text(
                date,
                style: GoogleFonts.inter(
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
              style: GoogleFonts.inter(
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
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ),
              Text(
                date,
                style: GoogleFonts.inter(
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
                _l10n.tr('content_locked_upgrade'),
                style: GoogleFonts.inter(
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
            style: GoogleFonts.inter(
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
            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _showWIPAlert() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset('assets/Icons/coming_soon.svg', height: 120),
              const SizedBox(height: 24),
              Text(
                'Coming Soon!',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'We are working hard to bring this material to you. Please check back later!',
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
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
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
    );
  }

  Widget _buildDummyFoldersView() {
    final List<String> subjects = [
      'Indian History',
      'Indian Economy',
      'Indian Polity & Governance',
      'Indian & World Geography',
      'Indian Constitution',
      'General Science',
      'Current Affairs',
      'General Arithmetic',
      'Quantitative Aptitude',
      'General Intelligence & Reasoning',
      'Electrical Engineering',
      'Mechanical Engineering',
      'Civil Engineering',
      'Electronics & Communication Engineering',
      'Computer Science Engineering',
    ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _l10n.tr('available_materials'),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 5 : 2,
              childAspectRatio: MediaQuery.of(context).size.width > 600
                  ? 2.5
                  : 2.2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: subjects.length,
            itemBuilder: (context, index) {
              return InkWell(
                onTap: () => _showWIPAlert(),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
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
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.folder_rounded,
                          color: Color(0xFFCBD5E1),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          subjects[index],
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF475569),
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFFE2E8F0),
                        size: 16,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
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
              _l10n.tr('premium_content'),
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          _l10n.tr('premium_module_desc'),
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              _l10n.tr('maybe_later'),
              style: GoogleFonts.inter(color: Colors.grey),
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
              _l10n.tr('upgrade_now'),
              style: GoogleFonts.inter(color: Colors.white),
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
                    _l10n.tr('login_required'),
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _l10n.tr('login_module_desc'),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
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
                            _l10n.tr('maybe_later'),
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(context);
                            final success = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const LoginPage(returnToPreviousPage: true),
                              ),
                            );

                            if (success == true) {
                              setState(() {
                                _checkSubscription();
                                // Re-fetch or refresh necessary data
                                _fetchApiLayers();
                              });
                            }
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
                            _l10n.tr('login_now'),
                            style: GoogleFonts.inter(
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
                    _l10n.tr('exit_learning_journey'),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _l10n.tr('exit_confirm_desc'),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
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
                            _l10n.tr('keep_learning_btn'),
                            style: GoogleFonts.plusJakartaSans(
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
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            _l10n.tr('yes_exit'),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
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
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                      letterSpacing: 1.1,
                    ),
                  ),
                  Text(
                    test.chapterName ?? 'General',
                    style: GoogleFonts.inter(
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
                style: GoogleFonts.inter(
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
                              style: GoogleFonts.inter(
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
                      style: GoogleFonts.inter(
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
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFEF4444),
                            letterSpacing: 1.1,
                          ),
                        ),
                        Text(
                          set.chapterName ?? 'General',
                          style: GoogleFonts.inter(
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
                    style: GoogleFonts.inter(
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
                      style: GoogleFonts.inter(
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
                                    style: GoogleFonts.inter(
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
                                      style: GoogleFonts.inter(
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
                            style: GoogleFonts.inter(
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

  void _showInstructionGuide() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _InstructionGuideDialog(
        onGetStarted: () {
          Navigator.pop(context);
          _storage.setStudyGuideShown(true);
        },
      ),
    );
  }
}

class _InstructionGuideDialog extends StatelessWidget {
  final VoidCallback onGetStarted;

  const _InstructionGuideDialog({required this.onGetStarted});

  @override
  Widget build(BuildContext context) {
    final LocalizationService _l10n = LocalizationService();
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
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
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.menu_open_rounded,
                  color: Color(0xFF3B82F6),
                  size: 40,
                ),
              ),
            ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 24),
            Text(
              _l10n.tr('instruction_guide_title'),
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _l10n.tr('instruction_guide_desc'),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF64748B),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            _buildStep(Icons.touch_app_rounded, _l10n.tr('instruction_step_1')),
            const SizedBox(height: 16),
            _buildStep(
              Icons.auto_awesome_rounded,
              _l10n.tr('instruction_step_2'),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onGetStarted,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  _l10n.tr('got_it_lets_go'),
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9));
  }

  Widget _buildStep(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF3B82F6), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF334155),
            ),
          ),
        ),
      ],
    );
  }
}
