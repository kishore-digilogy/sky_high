import 'package:flutter/material.dart';
import 'package:sky_high/main.dart';
import 'package:sky_high/data/models/exam_category_model.dart';
import 'package:sky_high/data/models/job_model.dart';
import 'package:sky_high/core/services/api_service.dart';
import 'package:sky_high/pages/courses/study_layers_page.dart';
import 'package:sky_high/pages/exams/mock_test_page.dart';
import 'package:sky_high/pages/courses/sub_posted_jobs_page.dart';
import 'package:sky_high/pages/courses/company_details_page.dart';

class DeeplinkService {
  static final DeeplinkService _instance = DeeplinkService._internal();
  factory DeeplinkService() => _instance;

  DeeplinkService._internal();

  Map<String, dynamic>? _pendingPayload;
  bool _isAppInitialized = false;

  /// Mark the application as initialized and process any pending payload.
  void setAppInitialized() {
    print('DeeplinkService: App marked as initialized.');
    _isAppInitialized = true;
    if (_pendingPayload != null) {
      final payload = _pendingPayload!;
      _pendingPayload = null;
      print('DeeplinkService: Found pending payload. Triggering navigation.');
      // Small delay to ensure the navigator is fully built and ready
      Future.delayed(const Duration(milliseconds: 300), () {
        handlePayload(payload);
      });
    }
  }

  /// Entry point when a user clicks on a notification
  void onNotificationClicked(Map<String, dynamic> additionalData) {
    print('DeeplinkService: Notification clicked with payload: $additionalData');
    if (_isAppInitialized) {
      handlePayload(additionalData);
    } else {
      print('DeeplinkService: App is not initialized yet. Storing payload as pending.');
      _pendingPayload = additionalData;
    }
  }

  /// Process the payload and navigate to the target screen
  Future<void> handlePayload(Map<String, dynamic> data) async {
    final navigatorState = MyApp.navigatorKey.currentState;
    if (navigatorState == null) {
      print('DeeplinkService: NavigatorState is null. Storing payload as pending.');
      _pendingPayload = data;
      return;
    }

    final context = MyApp.navigatorKey.currentContext;
    if (context == null) return;

    final type = data['type']?.toString();
    if (type == null) {
      print('DeeplinkService: Payload is missing the "type" parameter.');
      return;
    }

    try {
      switch (type) {
        case 'study_layer':
          _handleStudyLayer(context, data);
          break;
        case 'mock_test':
          _handleMockTest(context, data);
          break;
        case 'post':
          await _handleSubPost(context, data);
          break;
        case 'course':
          _handleCourse(context, data);
          break;
        default:
          print('DeeplinkService: Unknown deep link type: $type');
      }
    } catch (e) {
      print('DeeplinkService: Error navigating to deep link target: $e');
    }
  }

  /// Page 1: Direct Study Layer Screen
  void _handleStudyLayer(BuildContext context, Map<String, dynamic> data) {
    final companyId = int.tryParse(data['company_id']?.toString() ?? '');
    final companyName = data['company_name']?.toString();
    if (companyId == null || companyName == null) {
      print('DeeplinkService: Missing company_id or company_name in study_layer payload.');
      return;
    }

    final jobId = int.tryParse(data['job_id']?.toString() ?? '');
    final initialModuleIndex = int.tryParse(data['initial_module_index']?.toString() ?? '');

    print('DeeplinkService: Navigating to StudyLayersPage (companyId: $companyId, jobId: $jobId)');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudyLayersPage(
          company: ExamItemModel(id: companyId, name: companyName),
          jobId: jobId,
          initialModuleIndex: initialModuleIndex,
        ),
      ),
    );
  }

  /// Page 2: Mock Test Screen
  void _handleMockTest(BuildContext context, Map<String, dynamic> data) {
    final setName = data['set_name']?.toString();
    final companyName = data['company_name']?.toString();
    final companyId = int.tryParse(data['company_id']?.toString() ?? '');

    if (setName == null || companyName == null || companyId == null) {
      print('DeeplinkService: Missing essential params (setName, companyName, companyId) for mock test.');
      return;
    }

    final chapterId = int.tryParse(data['chapter_id']?.toString() ?? '');
    final topicId = int.tryParse(data['topic_id']?.toString() ?? '');
    final subtopicId = int.tryParse(data['subtopic_id']?.toString() ?? '');
    final questionType = data['question_type']?.toString();

    print('DeeplinkService: Navigating to MockTestPage (setName: $setName)');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MockTestPage(
          setName: setName,
          companyName: companyName,
          companyId: companyId,
          chapterId: chapterId,
          topicId: topicId,
          subtopicId: subtopicId,
          questionType: questionType,
        ),
      ),
    );
  }

  /// Page 3: Sub Post Screen (fetching parent job and subjobs dynamically from APIs first)
  Future<void> _handleSubPost(BuildContext context, Map<String, dynamic> data) async {
    final companyId = int.tryParse(data['company_id']?.toString() ?? '');
    final companyName = data['company_name']?.toString();
    final parentJobId = int.tryParse(data['parent_job_id']?.toString() ?? '');

    if (companyId == null || companyName == null || parentJobId == null) {
      print('DeeplinkService: Missing parameters for sub-post deep link.');
      return;
    }

    // Show a loading dialog during the API requests
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: Color(0xFF6C63FF),
                ),
                SizedBox(height: 16),
                Text(
                  'Loading details...',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final dio = ApiService().dio;

      // 1. Fetch parent jobs and 2. sub-posted jobs concurrently
      final futures = await Future.wait([
        dio.get('${ApiService.baseUrl}/admin/posted-jobs', queryParameters: {'company_id': companyId}),
        dio.get('${ApiService.baseUrl}/admin/sub-posted-jobs', queryParameters: {'company_id': companyId}),
      ]);

      final jobsResponse = futures[0];
      final subResponse = futures[1];

      // Dismiss the loading dialog safely
      if (!context.mounted) return;
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (jobsResponse.statusCode == 200 && subResponse.statusCode == 200) {
        final List<dynamic> jobsList = jobsResponse.data;
        final allJobs = jobsList.map((json) => JobModel.fromJson(json)).toList();

        final JobModel parentJob = allJobs.firstWhere(
          (j) => j.id == parentJobId,
          orElse: () => throw Exception('Parent job ID $parentJobId not found.'),
        );

        final List<dynamic> subJobsList = subResponse.data;
        final matchingSubJobs = subJobsList
            .where((sj) => sj['parent_job_id'] == parentJobId)
            .toList();

        final company = ExamItemModel(id: companyId, name: companyName);

        print('DeeplinkService: Navigating to SubPostedJobsPage.');
        if (!context.mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SubPostedJobsPage(
              parentJob: parentJob,
              subJobs: matchingSubJobs,
              company: company,
            ),
          ),
        );
      } else {
        if (!context.mounted) return;
        _showErrorSnackBar(context, 'Failed to fetch job data.');
      }
    } catch (e) {
      // Dismiss the loading dialog if it's still shown
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      print('DeeplinkService: Error fetching data for sub-post: $e');
      if (context.mounted) {
        _showErrorSnackBar(context, 'Error loading job details: ${e.toString()}');
      }
    }
  }

  /// Page 4: Courses Screen (CompanyDetailsPage)
  void _handleCourse(BuildContext context, Map<String, dynamic> data) {
    final companyId = int.tryParse(data['company_id']?.toString() ?? '');
    final companyName = data['company_name']?.toString();
    if (companyId == null || companyName == null) {
      print('DeeplinkService: Missing company_id or company_name for course.');
      return;
    }

    print('DeeplinkService: Navigating to CompanyDetailsPage (companyId: $companyId)');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CompanyDetailsPage(
          company: ExamItemModel(id: companyId, name: companyName),
        ),
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
