import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../data/models/notification_model.dart';
import '../../auth/services/auth_service.dart';

class NotificationApiService {
  static const String baseUrl = 'https://find-my-food-api.onrender.com';
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// GET /notification/getAllNotification
  Future<List<NotificationModel>> getAllNotifications() async {
    try {
      final headers = await _getHeaders();
      final url = '$baseUrl/notification/getAllNotification';
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        List<dynamic> list = [];
        
        if (decoded is List) {
          list = decoded;
        } else if (decoded is Map && decoded.containsKey('data')) {
          final dataValue = decoded['data'];
          if (dataValue is List) {
            list = dataValue;
          }
        }

        return list.map((json) => NotificationModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load notifications: ${response.statusCode}');
      }
    } catch (e) {
      return [];
    }
  }

  /// GET /notification/getUnreadNotificationCount
  Future<int> getUnreadCount() async {
    try {
      final url = '$baseUrl/notification/getUnreadNotificationCount';
      
      final response = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        
        if (decoded is int) return decoded;
        if (decoded is Map) {
          // Check top level
          if (decoded['unread_count'] != null) return decoded['unread_count'];
          if (decoded['count'] != null) return decoded['count'];
          if (decoded['notification_count'] != null) return decoded['notification_count'];
          
          // Check nested in 'data'
          final dataValue = decoded['data'];
          if (dataValue is int) return dataValue;
          if (dataValue is Map) {
            return dataValue['notification_count'] ?? 
                   dataValue['unread_count'] ?? 
                   dataValue['count'] ?? 0;
          }
        }
        return 0;
      } else {
        return 0;
      }
    } catch (e) {
      return 0;
    }
  }

  /// PATCH /notification/readNotification
  /// Note: The curl didn't show a body, so it might mark ALL as read or take an ID in query/body.
  /// Assuming it marks all for now, or we can add optional notificationId if the API supports it.
  Future<bool> markAsRead({int? notificationId}) async {
    try {
      // If notificationId is provided, we might need a different endpoint or a body
      // For now, following the exact curl provided: PATCH /notification/readNotification
      final response = await http.patch(
        Uri.parse('$baseUrl/notification/readNotification'),
        headers: await _getHeaders(),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// GET /notification/sendExpirePushNotification
  Future<bool> sendTestExpirePush() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/notification/sendExpirePushNotification'),
        headers: {'Accept': 'application/json'}, // No Auth required based on curl
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
