import 'package:dio/dio.dart';
import 'package:sky_high/data/models/exam_category_model.dart';
import 'package:sky_high/data/models/testimonial_model.dart';
import 'package:sky_high/data/models/free_exam_model.dart';
import 'package:sky_high/data/models/study_material_model.dart';
import 'package:sky_high/data/models/mock_question_model.dart';
import 'package:sky_high/data/models/mcq_set_model.dart';

class ExamService {
  final Dio _dio = Dio();
  final String baseUrl = 'https://skyhighapi.digilogy.dev/api';

  Future<List<ExamCategoryModel>> getCategories() async {
    try {
      final response = await _dio.get('$baseUrl/exam');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => ExamCategoryModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load categories');
      }
    } catch (e) {
      throw Exception('Failed to load categories: $e');
    }
  }

  Future<List<TestimonialModel>> getTestimonials() async {
    try {
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
      if (response.statusCode == 200) {
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
          'setName': setName == 'Untitled' ? null : setName,
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
    String? setName,
  }) async {
    try {
      final response = await _dio.get(
        '$baseUrl/mock-tests/questions',
        queryParameters: {
          'question_type': questionType,
          'company_id': companyId,
          'chapter_id': chapterId,
          'topic_id': topicId,
          'set_name': setName,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 304) {
        final List<dynamic> data = response.data;
        return data
            .map((json) => MockQuestionModel.fromJson(json as Map<String, dynamic>))
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
}
