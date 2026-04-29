import 'package:dio/dio.dart';
import 'package:sky_high/data/models/exam_category_model.dart';
import 'package:sky_high/data/models/testimonial_model.dart';
import 'package:sky_high/data/models/free_exam_model.dart';
import 'package:sky_high/data/models/study_material_model.dart';

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
}
