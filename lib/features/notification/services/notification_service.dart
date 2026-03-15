import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../../auth/services/auth_service.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final AuthService _authService = AuthService();

  Future<void> initialize() async {
    try {
      // 1. Request Permission
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        if (kDebugMode) {
          print('🔔 User granted notification permission');
        }
        
        // 2. Initial sync if already logged in
        await syncToken();
      } else {
        if (kDebugMode) {
          print('🔔 User declined or has not accepted notification permission');
        }
      }

      // 3. Listen for token refresh
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        if (kDebugMode) {
          print('🔔 FCM Token Refreshed: $newToken');
        }
        await _authService.updateFCMToken(newToken);
      });
    } catch (e) {
      if (kDebugMode) {
        print('🔔 NotificationService initialization failed: $e');
      }
    }
  }

  Future<void> syncToken() async {
    try {
      String? token = await _messaging.getToken();
      if (token != null) {
        if (kDebugMode) {
          print('🚀 FCM TOKEN: $token');
        }
        
        // Send to backend
        bool success = await _authService.updateFCMToken(token);
        if (success) {
          if (kDebugMode) print('✅ FCM Token synced with backend');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔔 Error syncing FCM Token: $e');
      }
    }
  }
}
