import 'package:dio/dio.dart';

class NotificationService {
  final Dio _dio = Dio();
  final String baseUrl = 'https://skyhighapi.digilogy.dev/api';

  Future<List<dynamic>> getActiveNotifications() async {
    try {
      final response = await _dio.get('$baseUrl/notifications/active');
      if (response.statusCode == 200) {
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
