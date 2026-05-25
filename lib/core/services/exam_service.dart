import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:sky_high/core/services/storage_service.dart';
import 'package:sky_high/core/services/api_service.dart';
import 'package:sky_high/data/models/exam_category_model.dart';
import 'package:sky_high/data/models/testimonial_model.dart';
import 'package:sky_high/data/models/free_exam_model.dart';
import 'package:sky_high/data/models/study_material_model.dart';
import 'package:sky_high/data/models/mock_question_model.dart';
import 'package:sky_high/data/models/mcq_set_model.dart';
import 'package:sky_high/data/models/mock_test_result_model.dart';

class ExamService {
  static final ExamService _instance = ExamService._internal();
  factory ExamService() => _instance;

  final Dio _dio = ApiService().dio;
  final String baseUrl = ApiService.baseUrl;

  ExamService._internal();

  Future<List<ExamCategoryModel>> getCategories() async {
    try {
      final response = await _dio.get('$baseUrl/exam');
      if (response.statusCode == 200 || response.statusCode == 304) {
        final List<dynamic> data = response.data;
        // print("ExamService: Parsing ${data.length} categories...");
        final categories = data
            .map((json) => ExamCategoryModel.fromJson(json))
            .toList();

        // Custom sorting based on title keywords
        final priorityOrder = [
          'maharatna',
          'navratna',
          'navatrna',
          'miniratna',
          'minirathna',
          'other',
          'min',
          'railway',
        ];

        categories.sort((a, b) {
          final sortTitleA = a.originalTitle.toLowerCase();
          final sortTitleB = b.originalTitle.toLowerCase();

          int getPriority(String title) {
            for (int i = 0; i < priorityOrder.length; i++) {
              if (title.contains(priorityOrder[i])) {
                return i;
              }
            }
            return priorityOrder.length;
          }

          final pA = getPriority(sortTitleA);
          final pB = getPriority(sortTitleB);

          if (pA != pB) {
            return pA.compareTo(pB);
          }
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        });

        return categories;
      } else {
        throw Exception('Failed to load categories: ${response.statusCode}');
      }
    } on DioException catch (de) {
      print(
        "ExamService: Dio error fetching categories: ${de.type} - ${de.message}",
      );
      if (de.type == DioExceptionType.connectionTimeout) {
        throw Exception('Connection timed out while fetching categories.');
      }
      throw Exception('Network error: ${de.message}');
    } catch (e) {
      print("ExamService: Unexpected error: $e");
      throw Exception('Failed to load categories: $e');
    }
  }

  Future<List<TestimonialModel>> getTestimonials() async {
    try {
      print("ExamService: Fetching testimonials from $baseUrl/testimonials");
      final response = await _dio.get('$baseUrl/testimonials');
      if (response.statusCode == 200 || response.statusCode == 304) {
        final Map<String, dynamic> body = response.data;
        if (body['success'] == true && body['data'] != null) {
          final List<dynamic> data = body['data'];
          return data
              .map(
                (json) =>
                    TestimonialModel.fromJson(json as Map<String, dynamic>),
              )
              .where((t) => t.isApproved)
              .toList();
        }
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load testimonials: $e');
    }
  }

  Future<List<FreeExamModel>> getFreeExams({
    String language = 'English',
  }) async {
    try {
      final response = await _dio.get(
        '$baseUrl/mock-tests/free-sets',
        queryParameters: {'language': language},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data
            .map((json) => FreeExamModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load free exams: $e');
    }
  }

  Future<List<StudyMaterialModel>> getStudyMaterials({
    String language = 'English',
  }) async {
    try {
      final response = await _dio.get(
        '$baseUrl/content',
        queryParameters: {'lang': language},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data
            .map(
              (json) =>
                  StudyMaterialModel.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load study materials: $e');
    }
  }

  Future<List<MockQuestionModel>> getMockQuestions({
    required String setName,
    String language = 'English',
    int limit = 200,
  }) async {
    try {
      final response = await _dio.get(
        '$baseUrl/mock-tests/questions-by-set',
        queryParameters: {
          'language': language,
          'limit': limit,
          'setName': setName,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 304) {
        final List<dynamic> data = response.data;
        return data
            .map(
              (json) =>
                  MockQuestionModel.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load mock questions: $e');
    }
  }

  Future<List<MockQuestionModel>> getMockQuestionsByCompany({
    required String companyName,
    required int companyId,
    String? setName,
    String language = 'English',
    int limit = 200,
  }) async {
    try {
      final response = await _dio.get(
        '$baseUrl/mock-tests/questions/$companyName',
        queryParameters: {
          'language': language,
          'limit': limit,
          'set_name': setName == 'Untitled' ? null : setName,
          'company_id': companyId,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 304) {
        final List<dynamic> data = response.data;
        return data
            .map(
              (json) =>
                  MockQuestionModel.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load mock questions: $e');
    }
  }

  Future<List<McqSetModel>> getMcqSets({
    required int companyId,
    required String questionType,
  }) async {
    try {
      final response = await _dio.get(
        '$baseUrl/mock-tests/mcq-sets',
        queryParameters: {
          'company_id': companyId,
          'question_type': questionType,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 304) {
        final List<dynamic> data = response.data;
        return data
            .map((json) => McqSetModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load MCQ sets: $e');
    }
  }

  Future<List<MockQuestionModel>> getMcqQuestions({
    required int companyId,
    required String questionType,
    int? chapterId,
    int? topicId,
    int? subtopicId,
    String? setName,
  }) async {
    try {
      final queryParams = {
        'question_type': questionType,
        'company_id': companyId,
        'chapter_id': chapterId,
        'topic_id': topicId,
        'subtopic_id': subtopicId,
        'set_name': setName,
      };

      final uri = Uri.parse('$baseUrl/mock-tests/questions').replace(
        queryParameters: queryParams.map((k, v) => MapEntry(k, v?.toString())),
      );
      print("Fetching MCQ Questions URL: $uri");

      final response = await _dio.get(
        '$baseUrl/mock-tests/questions',
        queryParameters: queryParams,
      );
      if (response.statusCode == 200 || response.statusCode == 304) {
        final List<dynamic> data = response.data;
        return data
            .map(
              (json) =>
                  MockQuestionModel.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load MCQ questions: $e');
    }
  }

  Future<bool> submitMockTest({
    required int userId,
    required String category,
    required String language,
    required String setName,
    required int score,
    required int totalQuestions,
    int? categoryId,
    int? subcategoryId,
    dynamic companyId,
    String? subcategoryName,
    String? companyName,
  }) async {
    try {
      final response = await _dio.post(
        '$baseUrl/mock-tests/submit',
        data: {
          "user_id": userId,
          "category": category,
          "language": language,
          "set_name": setName,
          "score": score,
          "total_questions": totalQuestions,
          "category_id": categoryId,
          "subcategory_id": subcategoryId,
          "company_id": companyId is String && companyId == "free"
              ? null
              : companyId,
          "subcategory_name": subcategoryName,
          "company_name": companyName,
        },
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error submitting test: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> submitTestimonial({
    required String content,
    required int stars,
    required String userName,
    int? categoryId,
  }) async {
    try {
      final payload = {
        "content": content,
        "stars": stars,
        "category_id": categoryId,
        "user_name": userName,
      };
      print(
        "ExamService: Posting testimonial to $baseUrl/testimonials with payload: $payload",
      );

      final response = await _dio.post('$baseUrl/testimonials', data: payload);

      print("ExamService: Testimonial response: ${response.data}");
      return response.data;
    } catch (e) {
      print("ExamService: Error posting testimonial: $e");
      throw Exception('Failed to submit testimonial: $e');
    }
  }

  Future<Map<String, dynamic>> getUserProgress({
    required int companyId,
    int? subJobId,
  }) async {
    try {
      final queryParams = {
        'company_id': companyId,
        if (subJobId != null) 'sub_job_id': subJobId,
      };
      final response = await _dio.get(
        '$baseUrl/user-progress',
        queryParameters: queryParams,
      );
      print("resposne:${response.data}");
      if (response.statusCode == 200 || response.statusCode == 304) {
        return response.data as Map<String, dynamic>;
      }
      return {};
    } catch (e) {
      print('Error getting user progress: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> updateUserProgress({
    required String moduleId,
    required int isCompleted,
    required int companyId,
    int? subJobId,
  }) async {
    try {
      final payload = {
        "moduleId": moduleId,
        "isCompleted": isCompleted,
        "companyId": companyId,
        if (subJobId != null) "subJobId": subJobId,
      };
      final response = await _dio.post(
        '$baseUrl/user-progress/update',
        data: payload,
      );
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      return {};
    } catch (e) {
      print('Error updating user progress: $e');
      return {};
    }
  }

  Future<List<MockTestResultModel>> getMockTestResults(int userId) async {
    try {
      final response = await _dio.get('$baseUrl/mock-tests/results/$userId');
      if (response.statusCode == 200 || response.statusCode == 304) {
        final List<dynamic> data = response.data;
        return data
            .map(
              (json) =>
                  MockTestResultModel.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      }
      return [];
    } catch (e) {
      print('Error getting mock test results: $e');
      return [];
    }
  }
}
