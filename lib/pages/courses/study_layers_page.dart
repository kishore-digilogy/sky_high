import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:sky_high/core/services/storage_service.dart';
import 'package:sky_high/data/models/exam_category_model.dart';
import 'package:sky_high/data/models/study_layer_model.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
  
  List<StudyLayerModel> _layers = [];
  int _selectedModuleIndex = 0;
  bool _isLoading = true;
  String? _error;
  bool _isPaidUser = false;

  @override
  void initState() {
    super.initState();
    _checkSubscription();
    _fetchLayers();
  }

  void _checkSubscription() {
    final userData = _storage.getUserData();
    if (userData != null) {
      // Assuming 'subscription_status' or similar field
      _isPaidUser = userData['subscription_status'] == 'paid' || userData['is_paid'] == true;
    }
  }

  Future<void> _fetchLayers() async {
    try {
      final queryParams = {'company_id': widget.company.id};
      if (widget.jobId != null) {
        queryParams['job_id'] = widget.jobId!;
      }

      final response = await _dio.get(
        'https://skyhighapi.digilogy.dev/api/admin/study-layers',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        setState(() {
          _layers = data.map((json) => StudyLayerModel.fromJson(json)).toList();
          if (_layers.isEmpty) {
            _layers = _getMockLayers();
          }
          _isLoading = false;
        });
        // Open drawer by default after loading
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scaffoldKey.currentState?.openDrawer();
        });
      } else {
        setState(() {
          _error = 'Failed to load journey';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Something went wrong';
        _isLoading = false;
        // Fallback to mock for testing
        _layers = _getMockLayers();
      });
    }
  }

  List<StudyLayerModel> _getMockLayers() {
    return [
      StudyLayerModel(id: 1, title: 'Basic Information', moduleNumber: 1, points: 50, description: 'Information about organisation'),
      StudyLayerModel(id: 2, title: 'Syllabus', moduleNumber: 2, points: 75, description: 'Exam syllabus and topics'),
      StudyLayerModel(id: 3, title: 'Preparation Plan', moduleNumber: 3, points: 100, description: 'How to prepare effectively'),
      StudyLayerModel(id: 4, title: 'Chapter-wise / Topic-wise ...', moduleNumber: 4, points: 150, description: 'Detailed study materials'),
      StudyLayerModel(id: 5, title: 'Chapter-wise / Topic-wise ...', moduleNumber: 5, points: 200, description: 'Deep dive topics'),
      StudyLayerModel(id: 6, title: 'Chapter-wise / Topic-wise ...', moduleNumber: 6, points: 250, description: 'Advanced concepts'),
      StudyLayerModel(id: 7, title: 'Chapter-wise / Topic-wise ...', moduleNumber: 7, points: 350, description: 'Revision materials'),
      StudyLayerModel(id: 8, title: 'Online Test Series', moduleNumber: 8, points: 300, description: 'Practice exams'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF64748B), size: 20),
          onPressed: () => Navigator.pop(context),
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
              child: const Icon(Icons.menu_open_rounded, color: Colors.blue, size: 20),
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
                icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8), size: 20),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _layers.length,
            itemBuilder: (context, index) {
              final layer = _layers[index];
              final isLocked = !layer.isFree && !_isPaidUser;
              final isSelected = _selectedModuleIndex == index;

              return _buildModuleTile(layer, index, isSelected, isLocked);
            },
          ),
        ),
        _buildOverallProgress(),
      ],
    );
  }

  Widget _buildModuleTile(StudyLayerModel layer, int index, bool isSelected, bool isLocked) {
    final colors = [
      const Color(0xFF6366F1),
      const Color(0xFFEC4899),
      const Color(0xFF06B6D4),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFF8B5CF6),
      const Color(0xFFEF4444),
      const Color(0xFFF97316),
    ];
    final color = colors[index % colors.length];

    return InkWell(
      onTap: isLocked ? () => _showLockedDialog() : () {
        setState(() => _selectedModuleIndex = index);
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
                isLocked ? Icons.lock_outline_rounded : _getModuleIcon(layer.moduleNumber),
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
                    'MOD ${layer.moduleNumber}',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? color : const Color(0xFF94A3B8),
                    ),
                  ),
                  Text(
                    layer.title,
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
              const Icon(Icons.lock_rounded, size: 14, color: Color(0xFF94A3B8))
            else ...[
              if (layer.points > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.yellow.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 8, color: Colors.orange),
                      const SizedBox(width: 2),
                      Text(
                        '${layer.points}',
                        style: GoogleFonts.outfit(fontSize: 9, color: Colors.orange, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              const SizedBox(width: 4),
              if (layer.isFree)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'FREE',
                    style: GoogleFonts.outfit(fontSize: 9, color: Colors.orange, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(delay: (50 * index).ms).slideX(begin: -0.1);
  }

  IconData _getModuleIcon(int modNum) {
    switch (modNum) {
      case 1: return Icons.info_outline_rounded;
      case 2: return Icons.menu_book_rounded;
      case 3: return Icons.track_changes_rounded;
      case 4: return Icons.article_outlined;
      case 8: return Icons.quiz_outlined;
      default: return Icons.layers_outlined;
    }
  }

  Widget _buildMainContent() {
    final selectedLayer = _layers[_selectedModuleIndex];
    
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildContentHeader(selectedLayer),
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
              child: _buildMaterialsView(selectedLayer),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentHeader(StudyLayerModel layer) {
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
                  'MODULE ${layer.moduleNumber}',
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            layer.title,
            style: GoogleFonts.outfit(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            layer.description ?? 'Complete this module to progress in your learning journey.',
            style: GoogleFonts.outfit(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildMaterialsView(StudyLayerModel layer) {
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
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: Center(
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
                  child: Icon(Icons.assignment_outlined, size: 48, color: Colors.blue.withOpacity(0.3)),
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
                  'Premium materials are being prepared for this module.\nCheck back soon!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(color: const Color(0xFF64748B), height: 1.5),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF4F46E5),
              padding: const EdgeInsets.symmetric(vertical: 16),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Complete & Next Module',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, size: 20),
              ],
            ),
          ),
        ),
      ],
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
                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
              ),
              Text(
                '${(_selectedModuleIndex + 1) * 12}%',
                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue),
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.lock_rounded, color: Colors.orange),
            const SizedBox(width: 10),
            Text('Premium Content', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'This module is part of our Elite Learning Path. Upgrade your subscription to unlock all modules and advanced test series.',
          style: GoogleFonts.outfit(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Maybe Later', style: GoogleFonts.outfit(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to payment/subscription
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Upgrade Now', style: GoogleFonts.outfit(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
