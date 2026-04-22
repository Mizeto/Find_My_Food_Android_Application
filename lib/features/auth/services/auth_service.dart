import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthService {
  static const String baseUrl = 'http://43.229.132.119';
  static const String googleAuthBaseUrl = 'https://find-my-food-api.onrender.com';
  static const String _tokenKey = 'auth_token';

  // Save token to SharedPreferences
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    print(
      'DEBUG: Saving token to SharedPreferences with key: $_tokenKey (Token: ${token.substring(0, 10)}...)',
    );
    await prefs.setString(_tokenKey, token);
  }

  // Get token from SharedPreferences
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Clear token (for logout)
  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  // Login: POST /auth/login (x-www-form-urlencoded)
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'accept': 'application/json',
        },
        body: {
          'grant_type': 'password',
          'username': username,
          'password': password,
          'scope': '',
          'client_id': 'string',
          'client_secret': '********',
        },
      );

      if (response.statusCode == 200) {
        final responseBody = response.body;
        print('DEBUG: Login raw response: $responseBody');
        final data = jsonDecode(responseBody);
        print('Login Response: $data');

        // Check the body-level status (server returns 200 even on failure)
        if (data['status'] == 'fail') {
          throw Exception(data['message'] ?? 'เข้าสู่ระบบไม่สำเร็จ');
        }

        final String? token = data['access_token'];
        // Save the token
        if (token != null) {
          await _saveToken(token);
        }

        // Extract user data from the 'data' field
        final userData = data['data'] as Map<String, dynamic>? ?? {};

        // Try to get ID from token if not in userData
        int? userId = int.tryParse(userData['user_id']?.toString() ?? '');
        if (userId == null && token != null) {
          userId = _extractIdFromToken(token);
        }

        return {
          'user_id': userId ?? 0,
          'username': userData['username'] ?? username,
          'email': userData['email'] ?? 'user@example.com',
          'first_name': userData['first_name'],
          'last_name': userData['last_name'],
          'gender': userData['gender'],
          'age': userData['age'],
          'profile_image': userData['image_url'],
          'token': token,
        };
      } else {
        print('Login Failed: ${response.statusCode} ${response.body}');
        try {
          final error = jsonDecode(response.body);
          throw Exception(
            error['detail'] ?? error['message'] ?? 'Login failed',
          );
        } catch (_) {
          throw Exception('Login failed: ${response.statusCode}');
        }
      }
    } catch (e) {
      if (e is Exception && !e.toString().contains('Connection error')) rethrow;
      throw Exception('Connection error: $e');
    }
  }

  int? _extractIdFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = parts[1];
      final normalized = base64.normalize(payload);
      final decoded = utf8.decode(base64.decode(normalized));
      final Map<String, dynamic> map = json.decode(decoded);
      return int.tryParse(map['sub']?.toString() ?? '');
    } catch (e) {
      return null;
    }
  }

  // Register: POST /users/createUser (application/json)
  Future<bool> register({
    required String username,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String gender,
    required String birthDate, // Changed from age to birthDate (YYYY-MM-DD)
  }) async {
    try {
      final body = {
        'email': email,
        'password': password,
        'username': username,
        'first_name': firstName,
        'last_name': lastName,
        'gender': gender,
        'birth_date': birthDate,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/users/createUser'),
        headers: {
          'Content-Type': 'application/json',
          'accept': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Register Success: ${response.body}');
        return true;
      } else {
        print('Register Failed: ${response.statusCode} ${response.body}');
        try {
          final error = jsonDecode(response.body);
          throw Exception(error['detail'] ?? 'Registration failed');
        } catch (_) {
          throw Exception('Registration failed: ${response.statusCode}');
        }
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  // Google Register: POST /auth/google/register
  Future<Map<String, dynamic>> googleRegister({
    required String tempToken,
    required String username,
    required String gender,
    required String birthDate,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$googleAuthBaseUrl/auth/google/register'),
        headers: {
          'Content-Type': 'application/json',
          'accept': 'application/json',
        },
        body: jsonEncode({
          'temp_token': tempToken,
          'username': username,
          'gender': gender,
          'birth_date': birthDate,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        print('Google Register Success: $data');

        // Save the token if present
        if (data['access_token'] != null) {
          await _saveToken(data['access_token']);
        }

        return data;
      } else {
        print(
          'Google Register Failed: ${response.statusCode} ${response.body}',
        );
        try {
          final error = jsonDecode(response.body);
          throw Exception(error['detail'] ?? 'Google registration failed');
        } catch (_) {
          throw Exception('Google registration failed: ${response.statusCode}');
        }
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  // Upload User Image: POST /users/uploadUserImage (multipart/form-data)
  Future<String> uploadUserImage(String imagePath) async {
    try {
      // Get the stored token
      final token = await getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Not authenticated. Please login again.');
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/users/uploadUserImage'),
      );
      request.headers['accept'] = 'application/json';
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('file', imagePath));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        print('Upload Image Success: $data');
        // Return the image URL from the response
        return data['image_url'] ??
            data['url'] ??
            data['data']?['image_url'] ??
            '';
      } else {
        print('Upload Image Failed: ${response.statusCode} ${response.body}');
        try {
          final error = jsonDecode(response.body);
          throw Exception(
            error['message'] ?? error['detail'] ?? 'Image upload failed',
          );
        } catch (_) {
          throw Exception('Image upload failed: ${response.statusCode}');
        }
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  // Google Login with ID Token: POST /auth/google/login
  // Returns either access_token (existing user) or temp_token (new user)
  Future<Map<String, dynamic>> googleLoginWithIdToken(String idToken) async {
    try {
      // Senior Dev Debug: Decode token to verify audience (aud) and issuer (iss)
      // This helps identify if the serverClientId in the app matches the one on the backend
      try {
        final decodedToken = _decodeJWT(idToken);
        print('DEBUG: [Senior Analysis] ID Token contents:');
        print('DEBUG:   - Audience (aud): ${decodedToken['aud']}');
        print('DEBUG:   - Issuer (iss): ${decodedToken['iss']}');
        print('DEBUG:   - Expiration (exp): ${DateTime.fromMillisecondsSinceEpoch((decodedToken['exp'] ?? 0) * 1000)}');
        print('DEBUG:   - Email: ${decodedToken['email']}');
      } catch (e) {
        print('DEBUG: [Senior Analysis] Failed to decode token for debugging: $e');
      }

      // Defensive Body: Send under both common keys to be sure
      final Map<String, dynamic> body = {
        'id_token': idToken,
        'token': idToken,
      };

      print('DEBUG: Google Login Request URL: $googleAuthBaseUrl/auth/google/login');
      print('DEBUG: Google Login Request Body Keys: ${body.keys.toList()}');

      final response = await http.post(
        Uri.parse('$googleAuthBaseUrl/auth/google/login'),
        headers: {
          'Content-Type': 'application/json',
          'accept': 'application/json',
        },
        body: jsonEncode(body),
      );

      print('DEBUG: Google Login Response Status: ${response.statusCode}');
      print('DEBUG: Google Login Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        
        // Save the token if present (existing user)
        if (data['access_token'] != null) {
          await _saveToken(data['access_token']);
        }

        return data;
      } else {
        // More detailed error throwing
        Map<String, dynamic>? errorData;
        try {
          errorData = jsonDecode(response.body);
        } catch (_) {}

        final message = errorData?['message'] ?? errorData?['detail'] ?? 'Google login failed: ${response.statusCode}';
        throw Exception(message);
      }
    } catch (e) {
      if (e.toString().contains('Invalid token')) {
        print('DEBUG: [Senior Analysis] Backend rejected token with 400 Invalid token.');
        print('DEBUG: [Senior Analysis] This strongly suggests the Web Client ID (serverClientId) used in the app');
        print('DEBUG: [Senior Analysis] does NOT match the one configured on the backend server.');
      }
      throw Exception('Google Login failed: $e');
    }
  }

  // Helper to decode JWT for debugging (without needing external dependency if possible)
  Map<String, dynamic> _decodeJWT(String token) {
    final parts = token.split('.');
    if (parts.length != 3) throw Exception('Invalid JWT format');
    final payload = parts[1];
    final normalized = base64.normalize(payload);
    final decoded = utf8.decode(base64.decode(normalized));
    return json.decode(decoded);
  }

  // ──────────── Feedback ────────────

  /// POST /support/feedback/submit
  Future<bool> submitFeedback({
    required String title,
    required String detail,
  }) async {
    try {
      final token = await getToken();
      print(
        'DEBUG submitFeedback: token=${token != null ? "YES (${token.length} chars)" : "NULL"}',
      );
      final response = await http.post(
        Uri.parse('$baseUrl/support/feedback/submit'),
        headers: {
          'Content-Type': 'application/json',
          'accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'title': title, 'detail': detail}),
      );
      print('Feedback Response: ${response.statusCode} ${response.body}');
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  // ──────────── Forgot Password ────────────

  /// POST /auth/forgetPassword/requestOTP
  Future<bool> requestPasswordOTP(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/forgetPassword/requestOTP'),
        headers: {
          'Content-Type': 'application/json',
          'accept': 'application/json',
        },
        body: jsonEncode({'email': email}),
      );
      print('Request OTP Response: ${response.statusCode} ${response.body}');
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  /// POST /auth/forgetPassword/verifyOTP
  Future<bool> verifyPasswordOTP(String email, String otp) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/forgetPassword/verifyOTP'),
        headers: {
          'Content-Type': 'application/json',
          'accept': 'application/json',
        },
        body: jsonEncode({'email': email, 'otp': otp}),
      );
      print('Verify OTP Response: ${response.statusCode} ${response.body}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(
          error['detail'] ?? error['message'] ?? 'OTP ไม่ถูกต้อง',
        );
      }
    } catch (e) {
      if (e is Exception && e.toString().contains('OTP')) rethrow;
      throw Exception('Connection error: $e');
    }
  }

  /// POST /auth/forgetPassword/resetPassword
  Future<bool> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/forgetPassword/resetPassword'),
        headers: {
          'Content-Type': 'application/json',
          'accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'otp': otp,
          'new_password': newPassword,
        }),
      );
      print('Reset Password Response: ${response.statusCode} ${response.body}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(
          error['detail'] ?? error['message'] ?? 'รีเซ็ตรหัสผ่านไม่สำเร็จ',
        );
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  /// PATCH /auth/updateFCMToken
  Future<bool> updateFCMToken(String fcmToken) async {
    try {
      final token = await getToken();
      if (token == null) return false;

      final response = await http.patch(
        Uri.parse('$baseUrl/auth/updateFCMToken'),
        headers: {
          'Content-Type': 'application/json',
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'fcm_token': fcmToken}),
      );

      print(
        'Update FCM Token Response: ${response.statusCode} ${response.body}',
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('DEBUG: Error updating FCM token: $e');
      return false;
    }
  }
}
