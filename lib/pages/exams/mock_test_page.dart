import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sky_high/core/services/exam_service.dart';
import 'package:sky_high/core/services/storage_service.dart';
import 'package:sky_high/data/models/mock_question_model.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MockTestPage extends StatefulWidget {
  final String? setName;
  final String? companyName;
  final int? companyId;
  final int? chapterId;
  final int? topicId;
  final String? questionType;

  const MockTestPage({
    super.key,
    this.setName,
    this.companyName,
    this.companyId,
    this.chapterId,
    this.topicId,
    this.questionType,
  });

  @override
  State<MockTestPage> createState() => _MockTestPageState();
}

class _MockTestPageState extends State<MockTestPage> {
  final ExamService _examService = ExamService();
  List<MockQuestionModel> _questions = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  Map<int, String?> _userAnswers = {};
  Set<int> _markedForReview = {};
  bool _isSubmitting = false;
  bool _hasStarted = false;

  Timer? _timer;
  int _secondsRemaining = 0;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _timer?.cancel();
        _submitTest(isAutoSubmit: true);
      }
    });
  }

  String _formatTime(int seconds) {
    int h = seconds ~/ 3600;
    int m = (seconds % 3600) ~/ 60;
    int s = seconds % 60;
    return "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  Future<void> _loadQuestions() async {
    try {
      List<MockQuestionModel> questions;
      if (widget.questionType != null && widget.companyId != null) {
        questions = await _examService.getMcqQuestions(
          companyId: widget.companyId!,
          questionType: widget.questionType!,
          chapterId: widget.chapterId,
          topicId: widget.topicId,
          setName: widget.setName,
        );
      } else if (widget.companyName != null && widget.companyId != null) {
        questions = await _examService.getMockQuestionsByCompany(
          companyName: widget.companyName!,
          companyId: widget.companyId!,
          setName: widget.setName,
        );
      } else {
        questions = await _examService.getMockQuestions(
          setName: widget.setName ?? '',
        );
      }

      setState(() {
        _questions = questions;
        _isLoading = false;
        _secondsRemaining = _questions.length * 60; // 1 minute per question
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading questions: $e')));
    }
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
      });
    }
  }

  void _previousQuestion() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
    }
  }

  Future<void> _submitTest({bool isAutoSubmit = false}) async {
    if (_isSubmitting) return;

    bool shouldSubmit = isAutoSubmit;

    if (!isAutoSubmit) {
      // Show confirmation first
      final unansweredCount = _questions.length - _userAnswers.length;
      shouldSubmit =
          await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                'Submit Test?',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Are you sure you want to submit your test?',
                    style: GoogleFonts.outfit(),
                  ),
                  if (unansweredCount > 0) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Colors.amber,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'You have $unansweredCount unanswered questions.',
                              style: GoogleFonts.outfit(
                                color: Colors.amber[900],
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(
                    'Review More',
                    style: GoogleFonts.outfit(color: const Color(0xFF64748B)),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22C55E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Submit Now',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ) ??
          false;
    }

    if (!shouldSubmit) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      int score = 0;
      _userAnswers.forEach((index, answer) {
        if (answer == _questions[index].correctOption) {
          score++;
        }
      });

      // Get user data for user_id
      final storage = GetIt.I<StorageService>();
      final userData = storage.getUserData();
      final userId = userData != null
          ? userData['id'] as int
          : 14; // Default to 14 if not found

      final firstQ = _questions.first;

      // print('Submitting Test Results:');
      // print('User ID: $userId');
      // print('Set Name: ${widget.setName}');
      // print('Score: $score');
      // print('Total Questions: ${_questions.length}');

      final success = await _examService.submitMockTest(
        userId: userId,
        category: firstQ.category ?? "free",
        language: firstQ.language ?? "English",
        setName: widget.setName ?? "",
        score: score,
        totalQuestions: _questions.length,
        categoryId: firstQ.categoryId,
        subcategoryId: firstQ.subcategoryId,
        companyId: firstQ.companyId,
        subcategoryName: firstQ.subcategoryName,
        companyName: firstQ.companyName,
      );

      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test not submitted. Please check your connection.'),
            backgroundColor: Colors.red,
          ),
        );
      }

      _timer?.cancel();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MockTestResultPage(
              questions: _questions,
              userAnswers: _userAnswers,
              isSubmitted: success,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<bool> _showExitConfirmation() async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.red),
                const SizedBox(width: 12),
                Text(
                  'Quit Test?',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            content: Text(
              'Are you sure you want to exit? Your current test progress will be lost and cannot be recovered.',
              style: GoogleFonts.outfit(
                color: const Color(0xFF64748B),
                height: 1.5,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Stay',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.withOpacity(0.1),
                  foregroundColor: Colors.red,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Exit',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 900;
        return _buildResponsiveLayout(context, isMobile);
      },
    );
  }

  Widget _buildResponsiveLayout(BuildContext context, bool isMobile) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: _buildSkeleton(isMobile),
      );
    }
    if (_questions.isEmpty && !_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F172A),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Back to Learning',
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 16),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.assignment_late_rounded,
                  size: 64,
                  color: Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No Questions Found',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'We couldn\'t find any questions for this test set at the moment. Please check back later.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    color: const Color(0xFF64748B),
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text('GO BACK'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!_hasStarted) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F172A),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Test Instructions',
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 18),
          ),
        ),
        body: _buildInstructions(isMobile),
      );
    }

    final currentQuestion = _questions[_currentIndex];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _showExitConfirmation();
        if (shouldPop && mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: _buildAppBar(isMobile),
        endDrawer: isMobile
            ? Drawer(width: 320, child: _buildSidebar(isMobile))
            : null,
        body: Stack(
          children: [
            isMobile
                ? Column(
                    children: [
                      _buildQuestionHeader(currentQuestion, isMobile),
                      LinearProgressIndicator(
                        value: (_currentIndex + 1) / _questions.length,
                        backgroundColor: const Color(0xFFE2E8F0),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF22C55E),
                        ),
                        minHeight: 3,
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 20,
                          ),
                          child: _buildQuestionContent(currentQuestion),
                        ),
                      ),
                      _buildBottomActions(isMobile),
                    ],
                  )
                : Row(
                    children: [
                      // Main Question Area
                      Expanded(
                        flex: 3,
                        child: Column(
                          children: [
                            _buildQuestionHeader(currentQuestion, isMobile),
                            LinearProgressIndicator(
                              value: (_currentIndex + 1) / _questions.length,
                              backgroundColor: const Color(0xFFE2E8F0),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF22C55E),
                              ),
                              minHeight: 3,
                            ),
                            Expanded(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(24),
                                child: _buildQuestionContent(currentQuestion),
                              ),
                            ),
                            _buildBottomActions(isMobile),
                          ],
                        ),
                      ),
                      // Sidebar Palette
                      _buildSidebar(isMobile),
                    ],
                  ),
            if (_isSubmitting)
              Container(
                color: Colors.black45,
                child: const Center(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Submitting your test...'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructions(bool isMobile) {
    int totalQuestions = _questions.length;
    int totalMinutes = totalQuestions;

    return Stack(
      children: [
        // Top Background
        Container(
          height: 250,
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
          ),
        ),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              children: [
                const SizedBox(height: 10),
                // Icon and Title
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.assignment_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ).animate().scale(duration: 400.ms),
                const SizedBox(height: 20),
                Text(
                  widget.setName ?? "Untitled",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 40),
                // Stats Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _buildStatCard(
                            Icons.help_outline,
                            'Questions',
                            '$totalQuestions',
                            const Color(0xFF3B82F6),
                          ),
                          const SizedBox(width: 12),
                          _buildStatCard(
                            Icons.timer_outlined,
                            'Minutes',
                            '$totalMinutes',
                            const Color(0xFF22C55E),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      // Rules Section
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'IMPORTANT RULES',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF94A3B8),
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildRuleItem(
                        Icons.check_circle_outline,
                        'Each question carries 1 mark.',
                      ),
                      _buildRuleItem(
                        Icons.info_outline,
                        'Total duration is $totalMinutes minutes.',
                      ),
                      _buildRuleItem(
                        Icons.lock_clock_outlined,
                        'The test will auto-submit when time is up.',
                      ),
                      _buildRuleItem(
                        Icons.language,
                        'Questions are available in English.',
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _hasStarted = true;
                            });
                            _startTimer();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B82F6),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 8,
                            shadowColor: const Color(
                              0xFF3B82F6,
                            ).withOpacity(0.4),
                          ),
                          child: Text(
                            'START TEST NOW',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF3B82F6)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: const Color(0xFF334155),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionContent(MockQuestionModel currentQuestion) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          currentQuestion.questionText,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
            height: 1.5,
          ),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
        if (currentQuestion.questionImage != null &&
            currentQuestion.questionImage!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: currentQuestion.fullQuestionImage,
                placeholder: (context, url) =>
                    const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            ),
          ),
        const SizedBox(height: 30),
        _buildOption(
          currentQuestion,
          'a',
          currentQuestion.optionA,
          currentQuestion.fullOptionAImage,
        ),
        _buildOption(
          currentQuestion,
          'b',
          currentQuestion.optionB,
          currentQuestion.fullOptionBImage,
        ),
        _buildOption(
          currentQuestion,
          'c',
          currentQuestion.optionC,
          currentQuestion.fullOptionCImage,
        ),
        _buildOption(
          currentQuestion,
          'd',
          currentQuestion.optionD,
          currentQuestion.fullOptionDImage,
        ),
      ],
    );
  }

  PreferredSizeWidget _buildAppBar(bool isMobile) {
    return AppBar(
      backgroundColor: const Color(0xFF0F172A),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () async {
          final shouldPop = await _showExitConfirmation();
          if (shouldPop && mounted) {
            Navigator.pop(context);
          }
        },
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.setName ?? "Untitled",
            style: GoogleFonts.outfit(
              fontSize: isMobile ? 14 : 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            'FREE',
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF38BDF8),
            ),
          ),
        ],
      ),
      actions: [
        if (!isMobile) ...[
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.timer_outlined,
                  color: Color(0xFF22C55E),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  _formatTime(_secondsRemaining),
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF22C55E),
                  ),
                ),
              ],
            ),
          ),
          _buildActionButton(Icons.description_outlined, 'Paper'),
          _buildActionButton(Icons.info_outline, 'Info'),
        ] else ...[
          // Mobile compact timer
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: const Color(0xFF22C55E).withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.access_time_filled_rounded,
                    color: Color(0xFF22C55E),
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatTime(_secondsRemaining),
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF22C55E),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.grid_view_rounded, color: Colors.white),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String label) {
    return Container(
      margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
      child: OutlinedButton.icon(
        onPressed: () {},
        icon: Icon(icon, size: 16, color: Colors.white70),
        label: Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.white24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildQuestionHeader(MockQuestionModel question, bool isMobile) {
    bool isMarked = _markedForReview.contains(_currentIndex);

    return Container(
      color: const Color(0xFF3B82F6),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 24,
        vertical: 12,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10),
              ],
            ),
            child: Text(
              'QUESTION ${_currentIndex + 1}',
              style: GoogleFonts.outfit(
                color: const Color(0xFF3B82F6),
                fontWeight: FontWeight.w900,
                fontSize: 10,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(width: 12),
          if (isMarked)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bookmark, color: Colors.white, size: 10),
                  const SizedBox(width: 4),
                  Text(
                    'MARKED',
                    style: GoogleFonts.outfit(
                      fontSize: 8,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ).animate().shimmer(),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Text(
                  'English',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Icon(
                  Icons.arrow_drop_down,
                  size: 16,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOption(
    MockQuestionModel question,
    String key,
    String? text,
    String image,
  ) {
    if ((text == null || text.isEmpty) && image.isEmpty)
      return const SizedBox.shrink();

    bool isSelected = _userAnswers[_currentIndex] == key;

    return GestureDetector(
      onTap: () {
        setState(() {
          _userAnswers[_currentIndex] = key;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF3B82F6)
                : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withOpacity(0.1),
                    blurRadius: 8,
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF3B82F6)
                    : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  key.toUpperCase(),
                  style: GoogleFonts.outfit(
                    color: isSelected ? Colors.white : const Color(0xFF64748B),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (text != null && text.isNotEmpty)
                    Text(
                      text,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        color: isSelected
                            ? const Color(0xFF1E293B)
                            : const Color(0xFF334155),
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  if (image.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: image,
                          height: 100,
                          fit: BoxFit.contain,
                          placeholder: (context, url) =>
                              const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.error),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF3B82F6),
                size: 20,
              ).animate().scale(),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          if (!isMobile) ...[
            _buildSecondaryButton(
              _markedForReview.contains(_currentIndex)
                  ? 'Unmark'
                  : 'Mark for Review',
              () {
                setState(() {
                  if (_markedForReview.contains(_currentIndex)) {
                    _markedForReview.remove(_currentIndex);
                  } else {
                    _markedForReview.add(_currentIndex);
                    _nextQuestion(); // Automatically move to next after marking
                  }
                });
              },
              isMobile,
              color: _markedForReview.contains(_currentIndex)
                  ? const Color(0xFFF59E0B)
                  : null,
            ),
            const SizedBox(width: 12),
            _buildSecondaryButton('Clear', () {
              setState(() {
                _userAnswers.remove(_currentIndex);
              });
            }, isMobile),
            const Spacer(),
            if (_currentIndex > 0) ...[
              _buildPrimaryButton(
                'Previous',
                _previousQuestion,
                const Color(0xFF64748B),
                isMobile,
              ),
              const SizedBox(width: 12),
            ],
            _buildPrimaryButton(
              'Next',
              _nextQuestion,
              const Color(0xFF1E293B),
              isMobile,
            ),
            const SizedBox(width: 12),
            _buildPrimaryButton(
              'Submit',
              _submitTest,
              const Color(0xFF22C55E),
              isMobile,
            ),
          ] else ...[
            // Mobile compact actions
            Expanded(
              child: _buildSecondaryButton(
                _markedForReview.contains(_currentIndex) ? 'Unmark' : 'Mark',
                () {
                  setState(() {
                    if (_markedForReview.contains(_currentIndex)) {
                      _markedForReview.remove(_currentIndex);
                    } else {
                      _markedForReview.add(_currentIndex);
                      _nextQuestion();
                    }
                  });
                },
                isMobile,
                color: _markedForReview.contains(_currentIndex)
                    ? const Color(0xFFF59E0B)
                    : null,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildSecondaryButton('Clear', () {
                setState(() {
                  _userAnswers.remove(_currentIndex);
                });
              }, isMobile),
            ),
            const SizedBox(width: 6),
            if (_currentIndex > 0) ...[
              Expanded(
                child: _buildPrimaryButton(
                  'Prev',
                  _previousQuestion,
                  const Color(0xFF64748B),
                  isMobile,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Expanded(
              child: _buildPrimaryButton(
                'Next',
                _nextQuestion,
                const Color(0xFF1E293B),
                isMobile,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildPrimaryButton(
                'Submit',
                _submitTest,
                const Color(0xFF22C55E),
                isMobile,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSecondaryButton(
    String label,
    VoidCallback onTap,
    bool isMobile, {
    Color? color,
  }) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 4 : 24,
          vertical: isMobile ? 12 : 15,
        ),
        side: BorderSide(color: color ?? const Color(0xFFE2E8F0)),
        backgroundColor: color?.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          color: color ?? const Color(0xFF64748B),
          fontWeight: FontWeight.w600,
          fontSize: isMobile ? 11 : 14,
        ),
      ),
    );
  }

  Widget _buildPrimaryButton(
    String label,
    VoidCallback onTap,
    Color color,
    bool isMobile,
  ) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 36,
          vertical: isMobile ? 12 : 15,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 0,
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontWeight: FontWeight.bold,
          fontSize: isMobile ? 12 : 14,
        ),
      ),
    );
  }

  Widget _buildSidebar(bool isMobile) {
    int answered = _userAnswers.length;
    int marked = _markedForReview.length;
    int notAnswered = _questions.length - answered;
    if (notAnswered < 0) notAnswered = 0;

    return Container(
      width: isMobile ? double.infinity : 300,
      decoration: BoxDecoration(
        color: Colors.white,
        border: isMobile
            ? null
            : const Border(left: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Column(
        children: [
          if (isMobile)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 40, 20, 10),
              child: Row(
                children: [
                  Text(
                    'Test Progress',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
          _buildUserInfo(),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsGrid(),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'QUESTION PALETTE',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                      Text(
                        '${_questions.length} total',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF3B82F6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                        ),
                    itemCount: _questions.length,
                    itemBuilder: (context, index) {
                      return _buildPaletteItem(index, isMobile);
                    },
                  ),
                ],
              ),
            ),
          ),
          _buildClosePalette(isMobile),
        ],
      ),
    );
  }

  Widget _buildUserInfo() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFF3B82F6),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                'K',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'kishorekumar',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                'ID: 14',
                style: GoogleFonts.outfit(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Column(
      children: [
        Row(
          children: [
            _buildStatItem(
              'Answered',
              _userAnswers.length,
              const Color(0xFF22C55E),
            ),
            _buildStatItem(
              'Not Answered',
              _questions.length - _userAnswers.length,
              const Color(0xFFEF4444),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildStatItem(
              'Marked',
              _markedForReview.length,
              const Color(0xFFF59E0B),
            ),
            _buildStatItem(
              'Not Visited',
              _questions.length - (_currentIndex + 1),
              const Color(0xFFE2E8F0),
              textColor: Colors.black54,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem(
    String label,
    int count,
    Color color, {
    Color textColor = Colors.white,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.outfit(
                  color: textColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaletteItem(int index, bool isMobile) {
    bool isCurrent = _currentIndex == index;
    bool isAnswered = _userAnswers.containsKey(index);
    bool isMarked = _markedForReview.contains(index);
    bool isVisited = index <= _currentIndex; // Simple visited logic

    Color bgColor = const Color(0xFFE2E8F0); // Not Visited
    Color textColor = const Color(0xFF64748B);
    BoxBorder? border;

    if (isAnswered && isMarked) {
      bgColor = const Color(0xFF8B5CF6); // Answered & Marked
      textColor = Colors.white;
    } else if (isAnswered) {
      bgColor = const Color(0xFF22C55E); // Answered
      textColor = Colors.white;
    } else if (isMarked) {
      bgColor = const Color(0xFFF59E0B); // Marked
      textColor = Colors.white;
    } else if (isVisited) {
      bgColor = const Color(
        0xFFEF4444,
      ); // Visited but not answered (Not Answered)
      textColor = Colors.white;
    }

    if (isCurrent) {
      border = Border.all(color: const Color(0xFF3B82F6), width: 2);
    }

    return GestureDetector(
      onTap: () {
        setState(() => _currentIndex = index);
        if (isMobile) Navigator.pop(context); // Close drawer on mobile
      },
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: border,
        ),
        child: Center(
          child: Text(
            '${index + 1}',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClosePalette(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      child: ElevatedButton(
        onPressed: () {
          if (isMobile) Navigator.pop(context);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0F172A),
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          isMobile ? 'Close Progress' : 'Close Palette',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildSkeleton(bool isMobile) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE2E8F0),
      highlightColor: const Color(0xFFF8FAFC),
      child: Column(
        children: [
          Container(height: 80, color: Colors.white), // AppBar skeleton
          Container(
            height: 50,
            color: Colors.white.withOpacity(0.5),
          ), // Subheader skeleton
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(height: 20, width: 200, color: Colors.white),
                        const SizedBox(height: 30),
                        Container(
                          height: 100,
                          width: double.infinity,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 40),
                        ...List.generate(
                          4,
                          (index) => Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            height: 60,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (!isMobile)
                  Container(
                    width: 300,
                    color: Colors.white.withOpacity(0.3),
                  ), // Sidebar skeleton
              ],
            ),
          ),
          Container(height: 80, color: Colors.white), // Bottom actions skeleton
        ],
      ),
    );
  }
}

class MockTestResultPage extends StatelessWidget {
  final List<MockQuestionModel> questions;
  final Map<int, String?> userAnswers;
  final bool isSubmitted;

  const MockTestResultPage({
    super.key,
    required this.questions,
    required this.userAnswers,
    required this.isSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    int correctCount = 0;
    userAnswers.forEach((index, answer) {
      if (answer == questions[index].correctOption) {
        correctCount++;
      }
    });

    double percentage = (correctCount / questions.length) * 100;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  questions.first.setName.toUpperCase(),
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF3B82F6),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Test Completed!',
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                if (isSubmitted) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Color(0xFF22C55E),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Results Submitted Successfully',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: const Color(0xFF22C55E),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Color(0xFFEF4444),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Results Not Submitted',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: const Color(0xFFEF4444),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 30),
                _buildResultImage(percentage),
                const SizedBox(height: 20),
                Text(
                  _getResultMessage(percentage),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _getResultColor(percentage),
                  ),
                ),
                const SizedBox(height: 30),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 140,
                      height: 140,
                      child: CircularProgressIndicator(
                        value: percentage / 100,
                        strokeWidth: 10,
                        backgroundColor: const Color(0xFFF1F5F9),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getResultColor(percentage),
                        ),
                      ),
                    ),
                    Column(
                      children: [
                        Text(
                          '$correctCount',
                          style: GoogleFonts.outfit(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: _getResultColor(percentage),
                          ),
                        ),
                        Text(
                          'OUT OF ${questions.length}',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Percentage: ${percentage.toStringAsFixed(1)}%',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MockTestReviewPage(
                                questions: questions,
                                userAnswers: userAnswers,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Review Answers',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MockTestPage(
                                setName: questions.first.setName,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 8,
                          shadowColor: const Color(0xFF3B82F6).withOpacity(0.4),
                        ),
                        child: Text(
                          'Retake Test',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Go to Home',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF64748B),
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
  }

  Widget _buildResultImage(double percentage) {
    String assetPath;
    bool isSvg = true;

    if (percentage < 20) {
      assetPath = 'assets/Images/bad_result.jpg';
      isSvg = false;
    } else if (percentage <= 70) {
      assetPath = 'assets/Images/average_result.svg';
    } else {
      assetPath = 'assets/Images/successfull_result.svg';
    }

    return Container(
      height: 180,
      width: 180,
      child: isSvg
          ? SvgPicture.asset(
              assetPath,
              fit: BoxFit.contain,
              placeholderBuilder: (context) =>
                  const Center(child: CircularProgressIndicator()),
            )
          : ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(assetPath, fit: BoxFit.contain),
            ),
    ).animate().scale(duration: 600.ms, curve: Curves.elasticOut);
  }

  String _getResultMessage(double percentage) {
    if (percentage < 20) {
      return 'Keep going to reach more! You can do it.';
    } else if (percentage <= 70) {
      return 'Good effort! Aim higher next time.';
    } else {
      return 'Excellent! You are a superstar!';
    }
  }

  Color _getResultColor(double percentage) {
    if (percentage < 20) {
      return const Color(0xFFEF4444);
    } else if (percentage <= 70) {
      return const Color(0xFFF59E0B);
    } else {
      return const Color(0xFF22C55E);
    }
  }
}

class MockTestReviewPage extends StatefulWidget {
  final List<MockQuestionModel> questions;
  final Map<int, String?> userAnswers;

  const MockTestReviewPage({
    super.key,
    required this.questions,
    required this.userAnswers,
  });

  @override
  State<MockTestReviewPage> createState() => _MockTestReviewPageState();
}

class _MockTestReviewPageState extends State<MockTestReviewPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 600;
        return _buildLayout(context, isMobile);
      },
    );
  }

  Widget _buildLayout(BuildContext context, bool isMobile) {
    // Filter questions based on search query
    final List<int> filteredIndices = [];
    for (int i = 0; i < widget.questions.length; i++) {
      final question = widget.questions[i];
      final qNum = (i + 1).toString();
      final text = question.questionText.toLowerCase();
      final query = _searchQuery.toLowerCase();

      if (query.isEmpty || qNum.contains(query) || text.contains(query)) {
        filteredIndices.add(i);
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search Question # or text...',
                  border: InputBorder.none,
                  hintStyle: GoogleFonts.outfit(color: Colors.black26),
                ),
                style: GoogleFonts.outfit(color: Colors.black87),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
              )
            : Text(
                'Answer Review',
                style: GoogleFonts.outfit(
                  fontSize: isMobile ? 18 : 22,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
        leading: IconButton(
          icon: Icon(
            _isSearching ? Icons.close : Icons.arrow_back,
            color: const Color(0xFF0F172A),
          ),
          onPressed: () {
            if (_isSearching) {
              setState(() {
                _isSearching = false;
                _searchQuery = '';
                _searchController.clear();
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.search, color: Color(0xFF0F172A)),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
            ),
          if (!isMobile && !_isSearching) ...[
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        MockTestPage(setName: widget.questions.first.setName),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Restart Test'),
            ),
          ] else if (isMobile && !_isSearching) ...[
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Color(0xFF3B82F6)),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        MockTestPage(setName: widget.questions.first.setName),
                  ),
                );
              },
            ),
          ],
          const SizedBox(width: 8),
        ],
      ),
      body: filteredIndices.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.search_off_rounded,
                    size: 64,
                    color: Color(0xFFE2E8F0),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No matching questions found',
                    style: GoogleFonts.outfit(color: const Color(0xFF94A3B8)),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(isMobile ? 12 : 24),
              itemCount: filteredIndices.length,
              itemBuilder: (context, index) {
                final originalIndex = filteredIndices[index];
                final question = widget.questions[originalIndex];
                final userAnswer = widget.userAnswers[originalIndex];
                final isCorrect = userAnswer == question.correctOption;

                return Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isCorrect
                          ? const Color(0xFF22C55E).withOpacity(0.1)
                          : const Color(0xFFEF4444).withOpacity(0.1),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isCorrect
                                  ? const Color(0xFF22C55E).withOpacity(0.1)
                                  : const Color(0xFFEF4444).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isCorrect ? Icons.check_circle : Icons.cancel,
                                  color: isCorrect
                                      ? const Color(0xFF22C55E)
                                      : const Color(0xFFEF4444),
                                  size: 14,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'QUESTION ${originalIndex + 1}',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 10,
                                    letterSpacing: 1,
                                    color: isCorrect
                                        ? const Color(0xFF22C55E)
                                        : const Color(0xFFEF4444),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          if (!isCorrect)
                            Text(
                              'INCORRECT',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                                color: const Color(0xFFEF4444),
                              ),
                            )
                          else
                            Text(
                              'CORRECT',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                                color: const Color(0xFF22C55E),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (question.questionImage != null &&
                          question.questionImage!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: question.fullQuestionImage,
                              placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                              errorWidget: (context, url, error) =>
                                  const Icon(Icons.error),
                            ),
                          ),
                        ),
                      Text(
                        question.questionText,
                        style: GoogleFonts.outfit(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E293B),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Your Answer
                      _buildAnswerBox(
                        'YOUR ANSWER',
                        userAnswer != null
                            ? "${userAnswer.toUpperCase()} ${question.getOptionText(userAnswer)}"
                            : "Not Answered",
                        userAnswer != null
                            ? (isCorrect
                                  ? const Color(0xFF22C55E)
                                  : const Color(0xFFEF4444))
                            : const Color(0xFF94A3B8),
                      ),
                      if (!isCorrect) ...[
                        const SizedBox(height: 12),
                        _buildAnswerBox(
                          'CORRECT ANSWER',
                          "${question.correctOption.toUpperCase()} ${question.getOptionText(question.correctOption)}",
                          const Color(0xFF22C55E),
                        ),
                      ],
                      if (question.explanation != null &&
                          question.explanation!.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withOpacity(0.05),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: const Color(0xFF3B82F6).withOpacity(0.1),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.lightbulb_outline,
                                    size: 16,
                                    color: Color(0xFF3B82F6),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'EXPLANATION',
                                    style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF3B82F6),
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                question.explanation!,
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  color: const Color(0xFF334155),
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildAnswerBox(String label, String value, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}
