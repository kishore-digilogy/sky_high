import 'package:dio/dio.dart';
import 'package:sky_high/core/services/api_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final Dio _dio = ApiService().dio;
  final String baseUrl = ApiService.baseUrl;

  NotificationService._internal();

  Future<List<dynamic>> getActiveNotifications() async {
    try {
      final response = await _dio.get('$baseUrl/notifications/active');
      if (response.statusCode == 200 || response.statusCode == 304) {
        return response.data as List<dynamic>;
      }
      return [];
    } catch (e) {
      print('Error fetching notifications: $e');
      return [];
    }
  }

  Future<int> getNotificationCount() async {
    try {
      final notifications = await getActiveNotifications();
      return notifications.length;
    } catch (e) {
      return 0;
    }
  }
}
