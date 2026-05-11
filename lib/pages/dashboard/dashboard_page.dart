import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sky_high/pages/exams/exam_list_page.dart';
import 'package:get_it/get_it.dart';
import 'package:sky_high/core/services/storage_service.dart';
import 'package:sky_high/pages/auth/login_page.dart';
import 'package:sky_high/core/services/exam_service.dart';
import 'package:sky_high/data/models/exam_category_model.dart';
import 'package:sky_high/data/models/testimonial_model.dart';
import 'package:sky_high/data/models/free_exam_model.dart';
import 'package:sky_high/data/models/study_material_model.dart';
import 'package:sky_high/pages/courses/all_categories_page.dart';
import 'package:sky_high/pages/courses/subcategory_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sky_high/widgets/category_icon.dart';
import 'package:sky_high/pages/study_materials/pdf_viewer_page.dart';
import 'package:sky_high/pages/exams/mock_test_page.dart';
import 'package:sky_high/pages/subscription/payment_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sky_high/pages/dashboard/notification_page.dart';
import 'package:sky_high/core/services/notification_service.dart';
import 'package:sky_high/pages/study_materials/all_study_materials_page.dart';
import 'package:sky_high/pages/courses/study_layers_page.dart';
import 'package:sky_high/core/services/localization_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentIndex = 0;
  final Color primaryColor = const Color(0xFFF9A826);
  final Color secondaryColor = const Color(0xFF4AC2E3);
  final Color bgColor = const Color(0xFFF9F9FB);
  final _l10n = LocalizationService();
  List<Map<String, dynamic>> _recentStudies = [];

  Future<List<ExamCategoryModel>>? _categoriesFuture;
  Future<List<TestimonialModel>>? _testimonialsFuture;
  Future<List<FreeExamModel>>? _freeExamsFuture;
  Future<List<StudyMaterialModel>>? _studyMaterialsFuture;
  int _notificationCount = 0;
  final NotificationService _notificationService = NotificationService();
  final FocusNode _searchFocusNode = FocusNode();
  final PageController _bannerController = PageController(
    initialPage: 300,
  ); // High multiple of _banners.length
  int _currentBannerPage = 0;
  Timer? _bannerTimer;
  final Set<int> _expandedBanners = {};

  final List<Map<String, dynamic>> _banners = [
    {
      'title': 'Master Modern Tech',
      'subtitle': 'Curated industry paths',
      'detail': 'Learn Python, Cloud, AI & more with hands-on labs.',
      'btnText': 'Start',
      'colors': [const Color(0xFF0EA5E9), const Color(0xFF2DD4BF)],
      'image': 'assets/Icons/banner2.png',
    },
    {
      'title': 'Perfect Score',
      'subtitle': '500+ mock tests',
      'detail': 'Detailed analysis and daily practice sets for exam success.',
      'btnText': 'Try Now',
      'colors': [const Color(0xFFF59E0B), const Color(0xFFEF4444)],
      'image': 'assets/Icons/banner3.png',
    },
    {
      'title': 'Upgrade Your Skills',
      'subtitle': 'Unlock Your Future today',
      'detail': 'Top-rated industry experts and real-world projects.',
      'btnText': 'Explore',
      'colors': [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
      'image': 'assets/Icons/banner1.png',
    },
  ];

  @override
  void initState() {
    super.initState();
    _categoriesFuture = ExamService().getCategories();
    _testimonialsFuture = ExamService().getTestimonials();
    _freeExamsFuture = ExamService().getFreeExams();
    _studyMaterialsFuture = ExamService().getStudyMaterials();
    _loadNotificationCount();
    _startBannerTimer();
    _loadRecentStudy();
  }

  void _loadRecentStudy() {
    setState(() {
      _recentStudies = GetIt.I<StorageService>().getRecentStudies();
    });
  }

  void _startBannerTimer() {
    _bannerTimer?.cancel();
    _bannerTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_bannerController.hasClients) {
        _bannerController.animateToPage(
          _bannerController.page!.toInt() + 1,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  Future<void> _refreshData() async {
    setState(() {
      _categoriesFuture = ExamService().getCategories();
      _testimonialsFuture = ExamService().getTestimonials();
      _freeExamsFuture = ExamService().getFreeExams();
      _studyMaterialsFuture = ExamService().getStudyMaterials();
      _loadNotificationCount();
      _loadRecentStudy();
    });
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _bannerTimer?.cancel();
    _bannerController.dispose();
    super.dispose();
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
              _l10n.tr('study_materials') + ' Tab under construction',
            ),
          ),
          Center(
            child: Text(_l10n.tr('free_exams') + ' Tab under construction'),
          ),
          _buildProfileTab(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
      extendBody: true,
    );
  }

  void _showLanguageSelection() {
    final languages = [
      {'name': 'English', 'native': 'English', 'icon': '🇺🇸'},
      {'name': 'Tamil', 'native': 'தமிழ்', 'icon': '🇮🇳'},
      {'name': 'Telugu', 'native': 'తెలుగు', 'icon': '🇮🇳'},
      {'name': 'Hindi', 'native': 'हिन्दी', 'icon': '🇮🇳'},
      {'name': 'Malayalam', 'native': 'മലയാളം', 'icon': '🇮🇳'},
      {'name': 'Kannada', 'native': 'ಕನ್ನಡ', 'icon': '🇮🇳'},
    ];

    final currentLang = GetIt.I<StorageService>().getSelectedLanguage();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _l10n.tr('settings'),
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 24),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: languages.length,
                  itemBuilder: (context, index) {
                    final lang = languages[index];
                    final isSelected = currentLang == lang['name'];

                    return GestureDetector(
                      onTap: () async {
                        await GetIt.I<StorageService>().setSelectedLanguage(
                          lang['name']!,
                        );
                        Navigator.pop(context);
                        _refreshData(); // Refresh API data with new language
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? primaryColor.withOpacity(0.1)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? primaryColor
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              lang['icon']!,
                              style: const TextStyle(fontSize: 24),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    lang['native']!,
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1E293B),
                                    ),
                                  ),
                                  Text(
                                    lang['name']!,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle_rounded,
                                color: primaryColor,
                                size: 24,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDashboardTab() {
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
                _buildHeader(),
                const SizedBox(height: 25),
                _buildSearchBar(),
                const SizedBox(height: 25),
                _buildBannerCarousel(),
                const SizedBox(height: 25),
                _buildContinueStudyingSection(),
                const SizedBox(height: 30),
                _buildCoursesSection(),
                const SizedBox(height: 30),
                _buildFreeExamsSection(),
                const SizedBox(height: 0),
                _buildStudyMaterialsSection(),
                const SizedBox(height: 30),
                // _buildTestimonialsSection(),
                _buildWhatsAppSection(),
                const SizedBox(height: 40),
                // _buildWhatsAppSection(),
                _buildTestimonialsSection(),
                const SizedBox(height: 00),
                _buildAboutUsSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileTab() {
    final storage = GetIt.I<StorageService>();
    final token = storage.getToken();
    final user = storage.getUserData();
    final isLoggedIn = token != null && token.isNotEmpty;
    final userName = user?['name'] ?? 'User';
    final userRole = user?['role'] ?? 'Student';

    // Capitalize role
    final displayRole = userRole.toString().isEmpty
        ? 'Student'
        : '${userRole.toString()[0].toUpperCase()}${userRole.toString().substring(1)}';

    if (!isLoggedIn) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.withOpacity(0.1)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF9A826).withOpacity(0.1),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person_search_rounded,
                  size: 50,
                  color: Color(0xFF94A3B8),
                ),
              ).animate().scale(duration: 600.ms, curve: Curves.easeInOut),
              const SizedBox(height: 32),
              Text(
                'Identity Required',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ).animate().slideY(begin: 0.2),
              const SizedBox(height: 12),
              Text(
                'Sign in to sync your progress, access premium certificates, and join the elite community.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF64748B),
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ).animate().slideY(begin: 0.2),
              const SizedBox(height: 40),
              GestureDetector(
                onTap: () async {
                  final success = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const LoginPage(returnToPreviousPage: true),
                    ),
                  );
                  if (success == true) {
                    setState(() {});
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF9A826), Color(0xFFF59E0B)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF9A826).withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'SIGN IN NOW',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ).animate().slideY(begin: 0.2),
            ],
          ),
        ),
      );
    }

    // Authenticated Profile View
    return SingleChildScrollView(
      child: Column(
        children: [
          // 1. Ultra-Premium Header (Teal Background + Avatar)
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                height: 180,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFF00897B), // Premium Teal
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(40),
                  ),
                ),
              ),

              Positioned(
                bottom: -50,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                    image: const DecorationImage(
                      image: AssetImage('assets/Images/dashboard2.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 60),

          // 2. Identity Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Text(
                  userName,
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                Text(
                  user?['email'] ?? 'student@skyhigh.com',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 8),
                _buildSubscriptionBanner(),
                // const SizedBox(height: 24),

                // Stats Row
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                //   children: [
                //     _buildStatItem('Purchased', '1 Plan'),
                //     _buildStatDivider(),
                //     _buildStatItem('Achieved', '12 Courses'),
                //     _buildStatDivider(),
                //     _buildStatItem('Certificates', '5 Earned'),
                //   ],
                // ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // 3. Action List (Settings Style)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _l10n.tr('settings'),
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 16),
                _buildSettingsItem(
                  Icons.person_outline_rounded,
                  _l10n.tr('edit_profile'),
                  () => _showWIPAlert(context, 'Edit Profile'),
                ),

                _buildSettingsItem(
                  Icons.workspace_premium_outlined,
                  _l10n.tr('premium_status'),
                  () {
                    if (user?['subscription_status'] == 'paid') {
                      _showPlanDetailsSheet(context);
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PaymentScreen(),
                        ),
                      );
                    }
                  },
                  isPremium: true,
                  premiumStatus: user?['subscription_status'] ?? 'free',
                ),
                _buildSettingsItem(
                  Icons.logout_rounded,
                  'Logout',
                  () => _showLogoutDialog(context),
                  isDestructive: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: 120), // padding for bottom nav
        ],
      ).animate(),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value.split(' ')[0],
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(height: 30, width: 1, color: const Color(0xFFE2E8F0));
  }

  Widget _buildSettingsItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isPremium = false,
    String premiumStatus = 'free',
    bool isDestructive = false,
    Widget? trailing,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDestructive ? Colors.red : const Color(0xFF64748B),
              size: 22,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDestructive ? Colors.red : const Color(0xFF1E293B),
                ),
              ),
            ),
            if (isPremium)
              Text(
                premiumStatus == 'paid' ? 'Active' : 'Inactive',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: premiumStatus == 'paid' ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            if (trailing != null) trailing,
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.grey[300],
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  void _showWIPAlert(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF9A826).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.construction_rounded,
                color: Color(0xFFF9A826),
                size: 50,
              ),
            ).animate().shake(duration: 500.ms),
            const SizedBox(height: 24),
            Text(
              'Work in Progress',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'The "$feature" feature is currently under development to give you the best experience.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
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
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Back',
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
    );
  }

  Widget _buildProfileCard(
    IconData icon,
    String title,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ),
    ).animate().scale(delay: 100.ms);
  }

  void _showPlanDetailsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.7,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: ListView(
            controller: controller,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00897B), Color(0xFF00796B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00897B).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.workspace_premium_rounded,
                      color: Colors.white,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Sky High Elite',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'One Year Unlimited Access',
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Current Plan Details',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 16),
              _buildPlanDetailRow(
                Icons.calendar_today_rounded,
                'Duration',
                '365 Days',
              ),
              _buildPlanDetailRow(
                Icons.payments_outlined,
                'Price Paid',
                '₹1,180.00',
              ),
              _buildPlanDetailRow(
                Icons.check_circle_outline_rounded,
                'Status',
                'Active',
              ),
              const SizedBox(height: 32),
              Text(
                'Plan Benefits',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 16),
              _buildBenefitItem('Access to all Premium Learning Modules'),
              _buildBenefitItem('Unlimited Mock Tests & PYQs'),
              _buildBenefitItem('Priority Customer Support'),
              _buildBenefitItem('Downloadable Study Materials'),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF1F5F9),
                    foregroundColor: const Color(0xFF475569),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Close',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF64748B)),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.inter(
              color: const Color(0xFF64748B),
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.inter(
              color: const Color(0xFF1E293B),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(String benefit) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(Icons.check_rounded, color: Color(0xFF10B981), size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              benefit,
              style: GoogleFonts.inter(
                color: const Color(0xFF475569),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Logout',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to log out?',
            style: GoogleFonts.inter(),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                GetIt.I<StorageService>().setToken(null);
                GetIt.I<StorageService>().setUserData(null);
                setState(() {}); // Refresh to show login screen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Logout',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showLoginDialog(BuildContext context) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final otpController = TextEditingController();
    bool isLoading = false;
    bool isOtpLogin = false;
    bool otpSent = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFFEAEBF0),
            surfaceTintColor: Colors.transparent,
            contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            titlePadding: const EdgeInsets.only(left: 24, top: 20, right: 16),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Login Required',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                    color: const Color(0xFF1A1A2E),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: Color(0xFF64748B),
                    size: 22,
                  ),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 20,
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Text(
                    'Please sign in to proceed with your\npayment.',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF64748B),
                      fontSize: 14,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: emailController,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: const Color(0xFF1E293B),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Email Address',
                      hintStyle: GoogleFonts.inter(
                        color: const Color(0xFF64748B),
                        fontSize: 15,
                      ),
                      prefixIcon: const Icon(
                        Icons.mail_outline_rounded,
                        color: Color(0xFF64748B),
                        size: 20,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF94A3B8),
                          width: 0.5,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF94A3B8),
                          width: 0.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFF9A826),
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!isOtpLogin)
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: const Color(0xFF1E293B),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Password',
                        hintStyle: GoogleFonts.inter(
                          color: const Color(0xFF64748B),
                          fontSize: 15,
                        ),
                        prefixIcon: const Icon(
                          Icons.lock_outline_rounded,
                          color: Color(0xFF64748B),
                          size: 20,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF94A3B8),
                            width: 0.5,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF94A3B8),
                            width: 0.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFF9A826),
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                      ),
                    )
                  else if (otpSent)
                    TextField(
                      controller: otpController,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: const Color(0xFF1E293B),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter 6-digit OTP',
                        hintStyle: GoogleFonts.inter(
                          color: const Color(0xFF64748B),
                          fontSize: 15,
                        ),
                        prefixIcon: const Icon(
                          Icons.security_rounded,
                          color: Color(0xFF64748B),
                          size: 20,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF94A3B8),
                            width: 0.5,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF94A3B8),
                            width: 0.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFF9A826),
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      setDialogState(() {
                        isOtpLogin = !isOtpLogin;
                        otpSent = false;
                      });
                    },
                    child: Text(
                      isOtpLogin ? 'Use Password Login' : 'Login with OTP',
                      style: GoogleFonts.inter(
                        color: const Color(0xFFF9A826),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF9A826),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: isLoading
                          ? null
                          : () async {
                              if (isOtpLogin) {
                                if (otpSent) {
                                  // Verify OTP
                                  if (otpController.text.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Please enter the OTP'),
                                      ),
                                    );
                                    return;
                                  }
                                  setDialogState(() => isLoading = true);
                                  try {
                                    final dio = Dio();
                                    final response = await dio.post(
                                      'https://skyhighapi.digilogy.dev/api/auth/verify-otp',
                                      data: {
                                        'email': emailController.text.trim(),
                                        'otp': otpController.text.trim(),
                                        'device_fingerprint':
                                            'SkyHighApp_Mobile_Client_v1.0',
                                      },
                                    );
                                    if (response.statusCode == 200) {
                                      final verifyData = response.data;
                                      final resetToken =
                                          verifyData['resetToken'];

                                      if (resetToken != null) {
                                        // Step 2: Login with OTP using the resetToken
                                        final loginResponse = await dio.post(
                                          'https://skyhighapi.digilogy.dev/api/auth/login-with-otp',
                                          data: {
                                            'email': emailController.text
                                                .trim(),
                                            'resetToken': resetToken,
                                            'device_fingerprint':
                                                'SkyHighApp_Mobile_Client_v1.0',
                                          },
                                        );

                                        if (loginResponse.statusCode == 200) {
                                          final data = loginResponse.data;
                                          final token = data['token'];
                                          final user = data['user'];

                                          if (token != null) {
                                            final storage =
                                                GetIt.I<StorageService>();
                                            await storage.setToken(token);
                                            if (user != null) {
                                              await storage.setUserData(user);
                                            }

                                            if (context.mounted) {
                                              Navigator.pop(context);
                                              setState(() {});
                                            }
                                          }
                                        }
                                      }
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Invalid OTP or verification failed.',
                                          ),
                                        ),
                                      );
                                    }
                                  } finally {
                                    if (context.mounted)
                                      setDialogState(() => isLoading = false);
                                  }
                                } else {
                                  // Send OTP
                                  if (emailController.text.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Please enter your email',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  setDialogState(() => isLoading = true);
                                  try {
                                    final dio = Dio();
                                    await dio.post(
                                      'https://skyhighapi.digilogy.dev/api/auth/send-otp',
                                      data: {
                                        'email': emailController.text.trim(),
                                      },
                                    );
                                    setDialogState(() => otpSent = true);
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Failed to send OTP'),
                                        ),
                                      );
                                    }
                                  } finally {
                                    if (context.mounted)
                                      setDialogState(() => isLoading = false);
                                  }
                                }
                              } else {
                                // Password Login
                                if (emailController.text.isEmpty ||
                                    passwordController.text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please enter email and password',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                setDialogState(() => isLoading = true);

                                try {
                                  final dio = Dio();
                                  final response = await dio.post(
                                    'https://skyhighapi.digilogy.dev/api/auth/login',
                                    data: {
                                      'email': emailController.text.trim(),
                                      'password': passwordController.text,
                                    },
                                  );

                                  if (response.statusCode == 200) {
                                    final token = response.data['token'];
                                    final user = response.data['user'];

                                    final storage = GetIt.I<StorageService>();
                                    await storage.setToken(token);
                                    await storage.setUserData(user);

                                    if (context.mounted) {
                                      Navigator.pop(context); // Close dialog
                                      setState(() {});
                                    }
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Invalid credentials'),
                                      ),
                                    );
                                  }
                                } finally {
                                  if (context.mounted) {
                                    setDialogState(() => isLoading = false);
                                  }
                                }
                              }
                            },
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              isOtpLogin
                                  ? (otpSent ? 'Verify & Login' : 'Send OTP')
                                  : 'Sign In',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSubscriptionBanner() {
    final user = GetIt.I<StorageService>().getUserData();
    final status = user?['subscription_status'] as String?;
    if (status == 'paid') {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PaymentScreen()),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(left: 24, right: 24, top: 30),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1B2A47), // Dark blue like the design
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1B2A47).withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9A826).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: const Color(0xFFF9A826).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.workspace_premium_outlined,
                          color: Color(0xFFF9A826),
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'BESTVALUE',
                          style: GoogleFonts.inter(
                            color: const Color(0xFFF9A826),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Total All India PSU',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Single Combo • All India PSU Exams Covered',
                    style: GoogleFonts.inter(
                      color: Colors.blueGrey[300],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '₹999',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'oneYear',
                  style: GoogleFonts.inter(
                    color: Colors.blueGrey[300],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().slideY(begin: 0.1);
  }

  Widget _buildHeader() {
    final user = GetIt.I<StorageService>().getUserData();
    final userName = user?['name'] ?? 'User';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          // Left side: Greeting and Subtext
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        'Hi, $userName ',
                        style: GoogleFonts.outfit(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                          letterSpacing: -0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    const Text('👋', style: TextStyle(fontSize: 24)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Find a source you want to learn!',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Right side: Actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (GetIt.I<StorageService>().getToken() == null ||
                  GetIt.I<StorageService>().getToken()!.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginPage(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryColor, primaryColor.withOpacity(0.8)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        _l10n.tr('login'),
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),

              GestureDetector(
                onTap: _showLanguageSelection,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.translate_rounded,
                        color: Color(0xFF334155),
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        GetIt.I<StorageService>()
                            .getSelectedLanguage()
                            .substring(0, 2)
                            .toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 12),

              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationPage(),
                    ),
                  ).then((_) => _loadNotificationCount());
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(
                        Icons.notifications_none_rounded,
                        color: Color(0xFF334155),
                        size: 24,
                      ),
                      if (_notificationCount > 0)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444), // Modern red
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Center(
                              child: Text(
                                '$_notificationCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        )
                      else
                        Positioned(
                          right: 2,
                          top: 2,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: secondaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
            ],
          ),
        ],
      ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.02),
    );
  }

  Widget _buildBannerCarousel() {
    final bannerIndex = _currentBannerPage % _banners.length;
    final isExpanded = _expandedBanners.contains(bannerIndex);

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          height: isExpanded ? 200 : 150,
          child: PageView.builder(
            controller: _bannerController,
            onPageChanged: (index) {
              setState(() {
                _currentBannerPage = index;
              });
              _startBannerTimer(); // Reset timer on manual or auto scroll
            },
            itemBuilder: (context, index) {
              final bIndex = index % _banners.length;
              return _buildBannerCard(_banners[bIndex], bIndex);
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _banners.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 6,
              width: _currentBannerPage == index ? 24 : 6,
              decoration: BoxDecoration(
                color: _currentBannerPage == index
                    ? primaryColor
                    : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBannerCard(Map<String, dynamic> banner, int index) {
    final isExpanded = _expandedBanners.contains(index);

    return GestureDetector(
      onTap: () {
        _showWIPAlert(context, banner['title'] as String);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: banner['colors'] as List<Color>,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: (banner['colors'] as List<Color>)[0].withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Full Size Background Image
              Positioned.fill(
                child: Opacity(
                  opacity: 0.35,
                  child: Image.asset(
                    banner['image'] as String,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // Gradient Overlay for readability
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        (banner['colors'] as List<Color>)[0].withOpacity(0.8),
                        (banner['colors'] as List<Color>)[1].withOpacity(0.4),
                      ],
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 7,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            banner['title'] as String,
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            banner['subtitle'] as String,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final detailText = banner['detail'] as String;
                              final textStyle = GoogleFonts.inter(
                                fontSize: 10,
                                color: Colors.white.withOpacity(0.8),
                                fontWeight: FontWeight.w400,
                              );

                              // Detect overflow
                              final tp = TextPainter(
                                text: TextSpan(
                                  text: detailText,
                                  style: textStyle,
                                ),
                                maxLines: 2,
                                textDirection: TextDirection.ltr,
                              )..layout(maxWidth: constraints.maxWidth);

                              final hasOverflow = tp.didExceedMaxLines;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    detailText,
                                    style: textStyle,
                                    maxLines: isExpanded ? 10 : 2,
                                    overflow: isExpanded
                                        ? TextOverflow.visible
                                        : TextOverflow.ellipsis,
                                  ),
                                  if (hasOverflow)
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          if (isExpanded) {
                                            _expandedBanners.remove(index);
                                          } else {
                                            _expandedBanners.add(index);
                                          }
                                        });
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text(
                                          isExpanded
                                              ? 'Read Less'
                                              : 'Read More',
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                    const Spacer(flex: 3),
                  ],
                ),
              ),
              // Floating Right Bottom Image
              Positioned(
                right: -15,
                bottom: -15,
                child:
                    Image.asset(
                          banner['image'] as String,
                          height: 140,
                          width: 140,
                          fit: BoxFit.contain,
                        )
                        .animate()
                        .scale(
                          begin: const Offset(0.7, 0.7),
                          curve: Curves.easeOutBack,
                        )
                        .move(
                          begin: const Offset(30, 30),
                          duration: 800.ms,
                          curve: Curves.easeOutCubic,
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GestureDetector(
        onTap: () async {
          final categories = await _categoriesFuture;
          if (categories != null && mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AllCategoriesPage(
                  categories: categories,
                  initialIsSearching: true,
                ),
              ),
            );
          }
        },
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 20,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 20),
              const Icon(
                Icons.search_rounded,
                color: Color(0xFF94A3B8),
                size: 22,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  _l10n.tr('search_hint'),
                  style: GoogleFonts.inter(
                    color: const Color(0xFF94A3B8),
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
          ),
        ).animate().slideX(begin: -0.1),
      ),
    );
  }

  Widget _buildSectionTitle(String title, String action) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1E293B),
            ),
          ),
          Text(
            action,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ],
      ).animate().fadeIn(delay: 300.ms),
    );
  }

  Widget _buildCategories() {
    final categories = [
      {
        'name': 'Business',
        'icon': Icons.lightbulb_outline,
        'color': const Color(0xFFFDE68A),
        'iconColor': const Color(0xFFD97706),
      },
      {
        'name': 'Marketing',
        'icon': Icons.campaign_outlined,
        'color': const Color(0xFFDDD6FE),
        'iconColor': const Color(0xFF7C3AED),
      },
      {
        'name': 'Design',
        'icon': Icons.brush_outlined,
        'color': const Color(0xFFFECACA),
        'iconColor': const Color(0xFFDC2626),
      },
    ];

    return SizedBox(
      height: 48,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ExamListPage(categoryName: cat['name'] as String),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
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
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: cat['color'] as Color,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      cat['icon'] as IconData,
                      size: 14,
                      color: cat['iconColor'] as Color,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    cat['name'] as String,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ).animate().slideX(begin: 0.1),
          );
        },
      ),
    );
  }

  Widget _buildContinueStudyingSection() {
    if (_recentStudies.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _l10n.tr('continue_studying'),
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    GetIt.I<StorageService>().clearRecentStudies();
                    _recentStudies = [];
                  });
                },
                child: Text(
                  'Dismiss All',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            scrollDirection: Axis.horizontal,
            itemCount: _recentStudies.length,
            itemBuilder: (context, index) {
              final study = _recentStudies[index];
              try {
                final company = ExamItemModel.fromJson(study['company']);
                final modIndex = study['modIndex'] as int;
                final modTitle = study['modTitle'] as String;

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StudyLayersPage(
                          company: company,
                          initialModuleIndex: modIndex,
                        ),
                      ),
                    ).then((_) => _loadRecentStudy());
                  },
                  child: Container(
                    width: 280,
                    margin: const EdgeInsets.only(right: 16, bottom: 8, top: 4),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: company.fullLogoUrl.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: company.fullLogoUrl,
                                      width: 24,
                                      height: 24,
                                      fit: BoxFit.contain,
                                      placeholder: (context, url) => const Text(
                                        '🧠',
                                        style: TextStyle(fontSize: 24),
                                      ),
                                      errorWidget: (context, url, error) =>
                                          const Text(
                                            '🧠',
                                            style: TextStyle(fontSize: 24),
                                          ),
                                    )
                                  : const Text(
                                      '🧠',
                                      style: TextStyle(fontSize: 24),
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          modTitle,
                                          style: GoogleFonts.inter(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF1E293B),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () async {
                                          await GetIt.I<StorageService>()
                                              .removeRecentStudy(company.id);
                                          _loadRecentStudy();
                                        },
                                        child: const Icon(
                                          Icons.close_rounded,
                                          size: 16,
                                          color: Color(0xFFCBD5E1),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    company.name,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: const Color(0xFF94A3B8),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Progress',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF94A3B8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${((modIndex + 1) / 8 * 100).toInt()}%',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: const Color(0xFF1E293B),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: (modIndex + 1) / 8,
                            backgroundColor: const Color(0xFFF1F5F9),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              const Color(0xFF6366F1).withOpacity(0.8),
                            ),
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6366F1).withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Continue lesson',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.1);
              } catch (e) {
                return const SizedBox.shrink();
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCoursesSection() {
    return FutureBuilder<List<ExamCategoryModel>>(
      future: _categoriesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildCourseSkeleton();
        }

        final categories = snapshot.hasData
            ? snapshot.data!
            : <ExamCategoryModel>[];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            _l10n.tr('categories'),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1E293B),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.auto_awesome_rounded,
                              size: 14,
                              color: Color(0xFF6366F1),
                            ),
                          ),
                        ],
                      ),
                      if (categories.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    AllCategoriesPage(categories: categories),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  _l10n.tr('view_all'),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF6366F1),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 14,
                                  color: Color(0xFF6366F1),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Explore top government exam categories',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ).animate(),
            const SizedBox(height: 25),
            if (snapshot.hasError || categories.isEmpty)
              _buildEmptyState(
                'No courses available right now',
                'assets/Icons/courses_icon.svg',
              )
            else
              SizedBox(
                height: 440, // Taller for the premium cards
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  scrollDirection: Axis.horizontal,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 210 / 175,
                  ),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    return _buildCategoryCard(categories[index], index);
                  },
                ),
              ),
              const SizedBox(height: 24),
              // Footer Banner
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(16),
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
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.explore_outlined,
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
                              'Discover the best learning paths',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                            Text(
                              'Smart preparation for your bright future',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: const Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.trending_flat_rounded,
                        color: Color(0xFFCBD5E1),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildSeeMoreCard(List<ExamCategoryModel> categories) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AllCategoriesPage(categories: categories),
          ),
        );
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.arrow_forward_rounded, color: primaryColor),
            ),
            const SizedBox(height: 12),
            Text(
              'See More',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ).animate().slideX(begin: 0.1),
    );
  }

  Widget _buildCategoryCard(ExamCategoryModel category, int index) {
    final color = Color(category.displayColorValue);
    final isTrending = index == 1; // Simulate trending for the second card

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SubcategoryPage(category: category),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isTrending ? const Color(0xFF6366F1).withOpacity(0.3) : const Color(0xFFF1F5F9),
            width: isTrending ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Halo Icon
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: color.withOpacity(0.1), width: 1),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.05),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.1),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Text(
                        category.displayIcon.isEmpty ? '🎓' : category.displayIcon,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                // Title
                Text(
                  category.title.toUpperCase(),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E293B),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                // Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.business_center_rounded, size: 10, color: color),
                      const SizedBox(width: 4),
                      Text(
                        'Government Body',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Bottom Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.menu_book_rounded, size: 12, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '12 Courses',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_forward_rounded, size: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ],
            ),
            if (isTrending)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_fire_department_rounded, size: 10, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        'Trending',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: Duration(milliseconds: index * 50)).scale(begin: const Offset(0.95, 0.95));
  }


  // ─── Free Exams Section ─────────────────────────────────────────

  static const _freeExamColors = [
    Color(0xFF6366F1),
    Color(0xFFEC4899),
    Color(0xFF10B981),
    Color(0xFF3B82F6),
    Color(0xFFF59E0B),
  ];

  Widget _buildFreeExamsSection() {
    return FutureBuilder<List<FreeExamModel>>(
      future: _freeExamsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildFreeExamSkeleton();
        }

        final exams = snapshot.hasData ? snapshot.data! : <FreeExamModel>[];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  const SizedBox(width: 0),
                  Text(
                    _l10n.tr('free_exams'),
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'FREE',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                  ),
                ],
              ).animate(),
            ),
            const SizedBox(height: 15),
            if (snapshot.hasError || exams.isEmpty)
              _buildEmptyState(
                'No mock tests available',
                'assets/Icons/exam_icon.svg',
              )
            else
              SizedBox(
                height: 230,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: exams.length,
                  itemBuilder: (context, index) {
                    return _buildFreeExamCard(exams[index], index);
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildFreeExamCard(FreeExamModel exam, int index) {
    final configs = [
      {
        'color': const Color(0xFF3B82F6),
        'bg': const Color(0xFFF0F6FF),
        'tagBg': const Color(0xFFDCEAFD),
        'tagFg': const Color(0xFF1D4ED8),
      },
      {
        'color': const Color(0xFF8B5CF6),
        'bg': const Color(0xFFF5F3FF),
        'tagBg': const Color(0xFFEDE9FE),
        'tagFg': const Color(0xFF6D28D9),
      },
      {
        'color': const Color(0xFF059669),
        'bg': const Color(0xFFF0FDF8),
        'tagBg': const Color(0xFFD1FAE5),
        'tagFg': const Color(0xFF065F46),
      },
      {
        'color': const Color(0xFFF59E0B),
        'bg': const Color(0xFFFFFBEB),
        'tagBg': const Color(0xFFFEF3C7),
        'tagFg': const Color(0xFF92400E),
      },
      {
        'color': const Color(0xFFEF4444),
        'bg': const Color(0xFFFFF5F5),
        'tagBg': const Color(0xFFFEE2E2),
        'tagFg': const Color(0xFF991B1B),
      },
    ];

    final cfg = configs[index % configs.length];
    final color = cfg['color'] as Color;
    final bgColor = cfg['bg'] as Color;
    final tagBg = cfg['tagBg'] as Color;
    final tagFg = cfg['tagFg'] as Color;

    IconData examIcon = Icons.quiz_outlined;
    if (exam.setName.contains('ALP'))
      examIcon = Icons.train_outlined;
    else if (exam.setName.contains('NTPC'))
      examIcon = Icons.directions_railway_outlined;
    else if (exam.setName.contains('SSC'))
      examIcon = Icons.account_balance_outlined;
    else if (exam.setName.contains('UPSC'))
      examIcon = Icons.gavel_outlined;

    return SizedBox(
          width: MediaQuery.of(context).size.width * 0.45,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
            child: _HoverCard(
              color: color,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Top section ──────────────────────────────
                    Container(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(18),
                          topRight: Radius.circular(18),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: color.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Icon(examIcon, color: color, size: 20),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.4,
                            child: Text(
                              exam.setName,

                              style: GoogleFonts.inter(
                                fontSize: 14,
                                textStyle: TextStyle(
                                  overflow: TextOverflow.ellipsis,
                                ),

                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1E293B),
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Divider ──────────────────────────────────
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFE2E8F0),
                    ),

                    // ── Bottom section ───────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category tag
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: tagBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              exam.displayCategory,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: tagFg,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Question count
                          Row(
                            children: [
                              Icon(
                                Icons.help_outline_rounded,
                                size: 12,
                                color: const Color(0xFF94A3B8),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '${exam.formattedCount} Qs',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                width: 3,
                                height: 3,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFCBD5E1),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Free',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF059669),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Start button
                          SizedBox(
                            width: double.infinity,
                            child: _ShimmerButton(
                              color: color,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        MockTestPage(setName: exam.setName),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(delay: (60 + 100 * index).ms, duration: 350.ms)
        .slideY(begin: 0.15, curve: Curves.easeOutCubic);
  }

  // ─── Study Materials Section ───────────────────────────────────

  Widget _buildStudyMaterialsSection() {
    return FutureBuilder<List<StudyMaterialModel>>(
      future: _studyMaterialsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildMaterialSkeleton();
        }

        final allMaterials = snapshot.hasData
            ? snapshot.data!
            : <StudyMaterialModel>[];
        final materials = allMaterials
            .where((m) => m.visibility.toLowerCase() == 'free')
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Text(
                    _l10n.tr('study_materials'),
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AllStudyMaterialsPage(),
                        ),
                      );
                    },
                    child: Text(
                      _l10n.tr('view_all'),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ],
              ).animate(),
            ),
            const SizedBox(height: 15),
            if (snapshot.hasError || materials.isEmpty)
              _buildEmptyState(
                'No free materials available',
                'assets/Icons/study_icon.svg',
              )
            else
              SizedBox(
                height: 100,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: materials.length,
                  itemBuilder: (context, index) {
                    return _buildMaterialCard(materials[index], index);
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildMaterialCard(StudyMaterialModel material, int index) {
    final color = index % 2 == 0
        ? const Color(0xFFF9A826)
        : const Color(0xFF4AC2E3);

    return GestureDetector(
      onTap: () {
        if (material.isPdf) {
          PdfViewerPage.open(context, material.fullFileUrl, material.title);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Video player coming soon!')),
          );
        }
      },
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 16, bottom: 10, top: 5),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Row(
          children: [
            // Left Side: Icon Chip
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child:
                    material.thumbnailPath != null &&
                        material.thumbnailPath!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: material.fullThumbnailUrl,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Center(
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  color,
                                ),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: SvgPicture.asset(
                              'assets/Images/pdf_icon.svg',
                              // width: 28,
                              // height: 28,
                            ),
                          ),
                        ),
                      )
                    : SvgPicture.asset(
                        'assets/Images/pdf_icon.svg',
                        width: 28,
                        height: 28,
                      ),
              ),
            ),
            const SizedBox(width: 16),
            // Middle: Text Content
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    material.displayCategory.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: color,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    material.title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        material.isVideo
                            ? Icons.videocam_outlined
                            : Icons.description_outlined,
                        size: 12,
                        color: const Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        material.isVideo ? 'Video' : 'PDF Document',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Right Side: Arrow Icon
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 12,
                color: Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    ).animate().slideX(begin: 0.1);
  }

  Widget _buildMaterialSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSkeletonBox(width: 140, height: 20),
              _buildSkeletonBox(width: 80, height: 14),
            ],
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 240,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              return Container(
                    width: 180,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        _buildSkeletonBox(height: 100, borderRadius: 24),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSkeletonBox(width: 60, height: 12),
                              const SizedBox(height: 12),
                              _buildSkeletonBox(
                                width: double.infinity,
                                height: 16,
                              ),
                              const SizedBox(height: 6),
                              _buildSkeletonBox(width: 100, height: 16),
                              const SizedBox(height: 15),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildSkeletonBox(width: 40, height: 12),
                                  _buildSkeletonBox(
                                    width: 24,
                                    height: 24,
                                    borderRadius: 12,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat())
                  .shimmer(duration: 1200.ms, color: const Color(0xFFF8FAFC));
            },
          ),
        ),
      ],
    );
  }

  // ─── Testimonials Section ───────────────────────────────────────

  static const _avatarGradients = [
    [Color(0xFFF9A826), Color(0xFFFF6B35)],
    [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    [Color(0xFF10B981), Color(0xFF14B8A6)],
    [Color(0xFF3B82F6), Color(0xFF4AC2E3)],
    [Color(0xFFEC4899), Color(0xFFF472B6)],
  ];

  Widget _buildTestimonialsSection() {
    return FutureBuilder<List<TestimonialModel>>(
      future: _testimonialsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildTestimonialSkeleton();
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(
            'No student feedback yet',
            Icons.rate_review_outlined,
          );
        }

        final testimonials = snapshot.data!;
        final storage = GetIt.I<StorageService>();
        final isLoggedIn = storage.getToken() != null;

        return Column(
          children: [
            const SizedBox(height: 20),
            // Centered Header
            Center(
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        bottom: 0,
                        child: Container(
                          height: 10,
                          width: 120,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD54F).withOpacity(0.4),
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),
                      Text(
                        'What Our Students Say',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF1E293B),
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Our Students send us bunch of smilies with our services and we love them',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF64748B),
                        height: 1.5,
                      ),
                    ),
                  ),
                  if (isLoggedIn) ...[
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _showFeedbackDialog,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: primaryColor.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.edit_note_rounded,
                              color: primaryColor,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Write a Review',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Horizontal Scrollable Cards
            SizedBox(
              height: 240,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: testimonials.length,
                itemBuilder: (context, index) {
                  return _buildTestimonialCard(testimonials[index], index);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTestimonialCard(TestimonialModel testimonial, int index) {
    final gradientColors = _avatarGradients[index % _avatarGradients.length];

    return Container(
      width: 280,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    testimonial.initials,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      testimonial.userName,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          Icons.star_rounded,
                          color: i < testimonial.stars
                              ? const Color(0xFFFFB300)
                              : const Color(0xFFE2E8F0),
                          size: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Text(
              testimonial.content,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF64748B),
                height: 1.5,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            testimonial.timeAgo,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    ).animate().scale(
      begin: const Offset(0.95, 0.95),
      duration: 500.ms,
      curve: Curves.easeOutBack,
    );
  }

  // ─── Skeleton Loaders ─────────────────────────────────────────

  Widget _buildSkeletonBox({
    double width = double.infinity,
    double height = 14,
    double borderRadius = 8,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }

  Widget _buildCourseSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSkeletonBox(width: 100, height: 20),
              _buildSkeletonBox(width: 50, height: 14),
            ],
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 200,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              return Container(
                    width: 160,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE2E8F0),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const Spacer(),
                        _buildSkeletonBox(width: 120, height: 16),
                        const SizedBox(height: 8),
                        _buildSkeletonBox(width: 80, height: 12),
                      ],
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat())
                  .shimmer(duration: 1200.ms, color: const Color(0xFFF8FAFC));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFreeExamSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              _buildSkeletonBox(width: 36, height: 36, borderRadius: 10),
              const SizedBox(width: 12),
              _buildSkeletonBox(width: 140, height: 20),
              const Spacer(),
              _buildSkeletonBox(width: 60, height: 24, borderRadius: 20),
            ],
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 160,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              return Container(
                    width: 240,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSkeletonBox(width: 160, height: 16),
                        const SizedBox(height: 8),
                        _buildSkeletonBox(width: 100, height: 12),
                        const Spacer(),
                        Row(
                          children: [
                            _buildSkeletonBox(
                              width: 70,
                              height: 24,
                              borderRadius: 8,
                            ),
                            const Spacer(),
                            _buildSkeletonBox(width: 50, height: 10),
                          ],
                        ),
                      ],
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat())
                  .shimmer(duration: 1200.ms, color: const Color(0xFFF8FAFC));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTestimonialSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              _buildSkeletonBox(width: 36, height: 36, borderRadius: 10),
              const SizedBox(width: 12),
              _buildSkeletonBox(width: 160, height: 20),
            ],
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 210,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: 2,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              return Container(
                    width: 300,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: const BoxDecoration(
                                color: Color(0xFFE2E8F0),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSkeletonBox(width: 100, height: 14),
                                  const SizedBox(height: 6),
                                  _buildSkeletonBox(width: 60, height: 10),
                                ],
                              ),
                            ),
                            _buildSkeletonBox(
                              width: 40,
                              height: 24,
                              borderRadius: 20,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildSkeletonBox(height: 12),
                        const SizedBox(height: 8),
                        _buildSkeletonBox(height: 12),
                        const SizedBox(height: 8),
                        _buildSkeletonBox(width: 180, height: 12),
                        const Spacer(),
                        Row(
                          children: List.generate(
                            5,
                            (i) => Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: _buildSkeletonBox(
                                width: 16,
                                height: 16,
                                borderRadius: 4,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat())
                  .shimmer(duration: 1200.ms, color: const Color(0xFFF8FAFC));
            },
          ),
        ),
      ],
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

  Widget _buildWhatsAppSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Connect & Learn',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1E293B),
            ),
          ),
        ),
        const SizedBox(height: 15),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, const Color(0xFFF0FDF4).withOpacity(0.5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF22C55E).withOpacity(0.08),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(color: const Color(0xFFDCFCE7)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.chat_rounded,
                        color: Color(0xFF16A34A),
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _l10n.tr('whatsapp_title'),
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1E293B),
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Connect with 50,000+ Aspirants',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: const Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF22C55E), Color(0xFF15803D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF22C55E).withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () =>
                        _showWIPAlert(context, 'WhatsApp Community'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Get Started on WhatsApp',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAboutUsSection() {
    return Container(
      width: double.infinity,
      // color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
      child: Column(
        children: [
          // const Divider(color: Color(0xFFF1F5F9), thickness: 1),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.school_rounded,
                color: Color(0xFF64748B),
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'SKY HIGH',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF1E293B),
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            _l10n.tr('about_desc'),
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildMinimalFooterIcon(Icons.email_outlined),
              _buildMinimalFooterIcon(Icons.phone_outlined),
              _buildMinimalFooterIcon(Icons.location_on_outlined),
              _buildMinimalFooterIcon(Icons.facebook_rounded),
            ],
          ),
          const SizedBox(height: 40),
          Text(
            '© 2026 SkyHigh Learning',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFFCBD5E1),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildMinimalFooterIcon(IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Icon(icon, color: const Color(0xFF94A3B8), size: 20),
    );
  }

  Widget _buildEmptyState(String message, dynamic icon) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Decorative Background Elements
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -40,
              left: -20,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: secondaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(top: 20, left: 20, child: _buildDotPattern()),
            Positioned(bottom: 20, right: 20, child: _buildDotPattern()),

            // Main Content
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        shape: BoxShape.circle,
                      ),
                      child: icon is IconData
                          ? Icon(icon, size: 32, color: const Color(0xFF94A3B8))
                          : SvgPicture.asset(
                              icon as String,
                              width: 32,
                              height: 32,
                              colorFilter: const ColorFilter.mode(
                                Color(0xFF94A3B8),
                                BlendMode.srcIn,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: const Color(0xFF475569),
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Check back later for new updates',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().scale(begin: const Offset(0.95, 0.95));
  }

  void _showFeedbackDialog() {
    final storage = GetIt.I<StorageService>();
    final user = storage.getUserData();
    final userName = user?['name'] ?? 'Guest';
    final contentController = TextEditingController();
    int selectedStars = 5;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          title: Column(
            children: [
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Give Feedback',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Hi $userName, how was your experience with SkyHigh?',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final isSelected = index < selectedStars;
                  return GestureDetector(
                    onTap: () {
                      setDialogState(() {
                        selectedStars = index + 1;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        isSelected
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: isSelected
                            ? const Color(0xFFFFB300)
                            : const Color(0xFFE2E8F0),
                        size: 40,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: contentController,
                maxLines: 4,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF1E293B),
                ),
                decoration: InputDecoration(
                  hintText: 'Tell us what you liked or what we can improve...',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF94A3B8),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.all(20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(
                      color: primaryColor.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryColor, primaryColor.withBlue(220)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () async {
                        if (contentController.text.isEmpty) return;

                        final navigator = Navigator.of(context);
                        final scaffoldMessenger = ScaffoldMessenger.of(
                          this.context,
                        );

                        try {
                          final res = await ExamService().submitTestimonial(
                            content: contentController.text,
                            stars: selectedStars,
                            userName: userName,
                          );

                          if (res['success'] == true) {
                            navigator.pop();
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  res['message'] ?? 'Feedback submitted!',
                                  style: GoogleFonts.inter(),
                                ),
                                backgroundColor: const Color(0xFF10B981),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                            setState(() {
                              _testimonialsFuture = ExamService()
                                  .getTestimonials();
                            });
                          }
                        } catch (e) {
                          scaffoldMessenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                'Error: $e',
                                style: GoogleFonts.inter(),
                              ),
                              backgroundColor: const Color(0xFFEF4444),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Submit',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDotPattern() {
    return Opacity(
      opacity: 0.2,
      child: Column(
        children: List.generate(
          3,
          (i) => Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              3,
              (j) => Container(
                width: 3,
                height: 3,
                margin: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Color(0xFFCBD5E1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Hover lift card ────────────────────────────────────────────────────────────
class _HoverCard extends StatefulWidget {
  final Widget child;
  final Color color;
  const _HoverCard({required this.child, required this.color});

  @override
  State<_HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<_HoverCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _lift;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _lift = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _ctrl.forward(),
      onExit: (_) => _ctrl.reverse(),
      child: GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) => _ctrl.reverse(),
        onTapCancel: () => _ctrl.reverse(),
        child: AnimatedBuilder(
          animation: _lift,
          builder: (_, child) => Transform.translate(
            offset: Offset(0, -5 * _lift.value),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(0.15 * _lift.value),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: child,
            ),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

// ── Shimmer start button ───────────────────────────────────────────────────────
class _ShimmerButton extends StatefulWidget {
  final Color color;
  final VoidCallback? onTap;

  const _ShimmerButton({required this.color, this.onTap});

  @override
  State<_ShimmerButton> createState() => _ShimmerButtonState();
}

class _ShimmerButtonState extends State<_ShimmerButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _shimmer = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _shimmer,
        builder: (_, __) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // ── Shimmer sweep ──
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: FractionalTranslation(
                      translation: Offset(-2 + _shimmer.value * 4, 0),
                      child: Transform.rotate(
                        angle: -0.4,
                        child: Container(
                          width: 36,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.white.withOpacity(0.22),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // ── Label ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.play_circle_outline_rounded,
                      color: Colors.white,
                      size: 15,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Start Now',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
