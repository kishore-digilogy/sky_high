import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sky_high/core/services/storage_service.dart';
import 'package:sky_high/core/services/exam_service.dart';
import 'package:sky_high/core/services/localization_service.dart';
import 'package:sky_high/core/services/notification_service.dart';
import 'package:sky_high/core/services/deeplink_service.dart';
import 'package:sky_high/core/services/payment_service.dart';
import 'package:sky_high/data/models/exam_category_model.dart';
import 'package:sky_high/data/models/free_exam_model.dart';
import 'package:sky_high/data/models/study_material_model.dart';
import 'package:sky_high/data/models/testimonial_model.dart';

// Sub-widgets imports
import 'package:sky_high/pages/dashboard/widgets/dashboard_header.dart';
import 'package:sky_high/pages/dashboard/widgets/dashboard_search_bar.dart';
import 'package:sky_high/pages/dashboard/widgets/banner_carousel.dart';
import 'package:sky_high/pages/dashboard/widgets/quick_actions_grid.dart';
import 'package:sky_high/pages/dashboard/widgets/continue_studying_section.dart';
import 'package:sky_high/pages/dashboard/widgets/courses_section.dart';
import 'package:sky_high/pages/dashboard/widgets/free_exams_section.dart';
import 'package:sky_high/pages/dashboard/widgets/study_materials_section.dart';
import 'package:sky_high/pages/dashboard/widgets/whatsapp_section.dart';
import 'package:sky_high/pages/dashboard/widgets/testimonials_section.dart';
import 'package:sky_high/pages/dashboard/widgets/about_us_section.dart';
import 'package:sky_high/pages/dashboard/widgets/profile_tab.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentIndex = 0;
  final Color primaryColor = const Color(0xFFF9A826);
  final Color bgColor = const Color(0xFFF9F9FB);
  final _l10n = LocalizationService();
  List<Map<String, dynamic>> _recentStudies = [];

  Future<List<ExamCategoryModel>>? _categoriesFuture;
  Future<List<TestimonialModel>>? _testimonialsFuture;
  Future<List<FreeExamModel>>? _freeExamsFuture;
  Future<List<StudyMaterialModel>>? _studyMaterialsFuture;
  int _notificationCount = 0;
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    final selectedLang = GetIt.I<StorageService>().getSelectedLanguage();
    _categoriesFuture = ExamService().getCategories();
    _testimonialsFuture = ExamService().getTestimonials();
    _freeExamsFuture = ExamService().getFreeExams(language: selectedLang);
    _studyMaterialsFuture = ExamService().getStudyMaterials(
      language: selectedLang,
    );
    _loadNotificationCount();
    _loadRecentStudy();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DeeplinkService().setAppInitialized();
      PaymentService().checkAndVerifyPendingPayment();
    });
  }

  void _loadRecentStudy() {
    setState(() {
      _recentStudies = GetIt.I<StorageService>().getRecentStudies();
    });
  }

  Future<void> _refreshData() async {
    PaymentService().checkAndVerifyPendingPayment();
    setState(() {
      final selectedLang = GetIt.I<StorageService>().getSelectedLanguage();
      _categoriesFuture = ExamService().getCategories();
      _testimonialsFuture = ExamService().getTestimonials();
      _freeExamsFuture = ExamService().getFreeExams(language: selectedLang);
      _studyMaterialsFuture = ExamService().getStudyMaterials(
        language: selectedLang,
      );
      _loadNotificationCount();
      _loadRecentStudy();
    });
  }

  Future<void> _loadNotificationCount() async {
    final count = await _notificationService.getNotificationCount();
    if (mounted) {
      setState(() {
        _notificationCount = count;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildDashboardTab(),
          Center(
            child: Text(
              '${_l10n.tr('study_materials')} Tab under construction',
            ),
          ),
          Center(
            child: Text('${_l10n.tr('free_exams')} Tab under construction'),
          ),
          ProfileTab(onAuthStatusChanged: _refreshData),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
      extendBody: true,
    );
  }

  Widget _buildDashboardTab() {
    final storage = GetIt.I<StorageService>();
    final user = storage.getUserData();
    final userName = user?['name'] ?? 'User';

    return RefreshIndicator(
      onRefresh: _refreshData,
      color: primaryColor,
      backgroundColor: Colors.white,
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DashboardHeader(
                  userName: userName,
                  notificationCount: _notificationCount,
                  onLanguageChanged: _refreshData,
                ),
                const SizedBox(height: 4),
                DashboardSearchBar(categoriesFuture: _categoriesFuture),
                BannerCarousel(categoriesFuture: _categoriesFuture),
                const SizedBox(height: 12),
                // QuickActionsGrid(categoriesFuture: _categoriesFuture),
                ContinueStudyingSection(
                  recentStudies: _recentStudies,
                  onStudiesChanged: _loadRecentStudy,
                ),
                const SizedBox(height: 30),
                CoursesSection(categoriesFuture: _categoriesFuture),
                FreeExamsSection(freeExamsFuture: _freeExamsFuture),
                StudyMaterialsSection(
                  studyMaterialsFuture: _studyMaterialsFuture,
                ),
                const SizedBox(height: 15),
                const WhatsAppSection(),
                const SizedBox(height: 15),
                TestimonialsSection(
                  testimonialsFuture: _testimonialsFuture,
                  onRefresh: _refreshData,
                ),
                const AboutUsSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildNavItem(0, 'assets/Icons/home_icon.svg', 'Home'),
                  const SizedBox(width: 12),
                  _buildNavItem(3, 'assets/Icons/profile_icon.svg', 'Profile'),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().moveY(begin: 30, end: 0);
  }

  Widget _buildNavItem(int index, String assetPath, String label) {
    final isSelected = _currentIndex == index;
    final activeColor = const Color(0xFF6366F1);
    final inactiveColor = const Color(0xFF94A3B8);

    return InkWell(
      onTap: () {
        setState(() => _currentIndex = index);
        if (index == 0) _loadRecentStudy();
      },
      borderRadius: BorderRadius.circular(30),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            SvgPicture.asset(
              assetPath,
              colorFilter: ColorFilter.mode(
                isSelected ? activeColor : inactiveColor,
                BlendMode.srcIn,
              ),
              width: 24,
              height: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: activeColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
