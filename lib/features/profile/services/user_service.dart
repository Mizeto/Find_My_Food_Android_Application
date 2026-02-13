import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../auth/models/user_model.dart';
import '../../../data/models/recipe_model.dart';

class UserService {
  static const String baseUrl = 'https://find-my-food-api.onrender.com';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<Map<String, String>> _getHeaders({bool isMultipart = false}) async {
    final token = await _getToken();
    final headers = {
      'accept': 'application/json',
    };
    if (!isMultipart) {
      headers['Content-Type'] = 'application/json';
    }
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // 1. GET User Profile - Trying multiple possible endpoints (expanded probe)
  Future<UserModel?> getUserProfile({int? userId, String? username}) async {
    final endpoints = [
       if (userId != null && userId != 0) '/users/$userId',
       if (userId != null && userId != 0) '/users/getUser/$userId',
       if (userId != null && userId != 0) '/users/getUserProfileById/$userId',
       if (username != null) '/users/$username',
       '/users/me',
       '/users/profile',
       '/users/getUserProfile',
       '/users/getSimpleUserInfo',
       '/usersme',
       '/usersprofile',
       '/usersgetUserProfile',
       '/usersgetSimpleUserInfo',
       '/auth/me',
       '/auth/profile',
       '/me',
       '/profile',
       '/users', // No slash
       '/users/', // With slash
    ];

    for (final path in endpoints) {
      try {
        final headers = await _getHeaders();
        final url = '$baseUrl$path';
        print('DEBUG: Trying to fetch profile from: $url');
        final response = await http.get(Uri.parse(url), headers: headers).timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
          print('DEBUG: Response from $path: $jsonResponse');
          
          final data = (jsonResponse['data'] != null && jsonResponse['data'] is Map) 
              ? jsonResponse['data'] 
              : jsonResponse;
              
          // Check if this looks like user data (should have username or email)
          if (data is Map<String, dynamic> && (data.containsKey('username') || data.containsKey('email'))) {
             final user = UserModel.fromJson(data);
             // If ID is valid or we have username, it's likely correct
             if (user.id != 0 || (user.username != 'User' && user.username.isNotEmpty)) {
                print('DEBUG: SUCCESS! Found correct profile endpoint: $path');
                return user;
             }
          }
          print('DEBUG: Data from $path did not match UserModel structure');
        } else if (response.statusCode != 404) {
          print('DEBUG: $path returned status: ${response.statusCode}');
        }
      } catch (e) {
        // Silently continue for probe
      }
    }
    return null;
  }

  // 2. GET /usersgetSimpleUserInfo - Get Simple User Info
  Future<Map<String, dynamic>?> getSimpleUserInfo() async {
    try {
      final headers = await _getHeaders();
      // Using the exact path from user request.
      // If this fails, we might need to check if it's /users/getSimpleUserInfo
      final response = await http.get(Uri.parse('$baseUrl/usersgetSimpleUserInfo'), headers: headers);

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        print('Get Simple Info Failed: ${response.statusCode} - trying fallback path');
        // Fallback to /users/getSimpleUserInfo just in case
        final fallbackResponse = await http.get(Uri.parse('$baseUrl/users/getSimpleUserInfo'), headers: headers);
        if (fallbackResponse.statusCode == 200) {
           return jsonDecode(utf8.decode(fallbackResponse.bodyBytes));
        }
        print('Fallback Simple Info Failed: ${fallbackResponse.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error getting simple user info: $e');
      return null;
    }
  }

  // 3. GET /users/getUserLikeRecipe - Get Liked Recipes
  Future<List<Recipe>> getUserLikeRecipes() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/users/getUserLikeRecipe'), headers: headers);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
        if (jsonResponse is List) {
          return jsonResponse.map((data) => Recipe.fromJson(data)).toList();
        } else if (jsonResponse['data'] is List) {
           return (jsonResponse['data'] as List).map((data) => Recipe.fromJson(data)).toList();
        }
        return [];
      } else {
        print('Get Liked Recipes Failed: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error getting liked recipes: $e');
      return [];
    }
  }

  // 4. POST /users/createUser - Create/Register User
  Future<bool> createUser({
    required String email,
    required String password,
    required String username,
    required String firstName,
    required String lastName,
    required String gender,
    required String birthDate, // YYYY-MM-DD
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
        return true;
      } else {
        print('Create User Failed: ${response.statusCode} ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error creating user: $e');
      return false;
    }
  }

  // 5. POST /users/uploadUserImage - Upload Profile Image
  Future<String?> uploadUserImage(String filePath) async {
    try {
      final headers = await _getHeaders(isMultipart: true);
      // Remove Content-Type from headers as MultipartRequest sets it automatically with boundary
      headers.remove('Content-Type');

      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/users/uploadUserImage'));
      request.headers.addAll(headers);
      
      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['image_url'] ?? data['url']; // Adjust based on actual response
      } else {
         print('Upload Image Failed: ${response.statusCode} ${response.body}');
         return null;
      }
    } catch (e) {
       print('Error uploading image: $e');
       return null;
    }
  }

  // 6. POST /users/changePassword
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = {
        'current_password': currentPassword,
        'new_password': newPassword,
        'confirm_password': confirmPassword,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/users/changePassword'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Change Password Failed: ${response.statusCode} ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error changing password: $e');
      return false;
    }
  }

  // 7. PATCH /users/updateUsername
  Future<bool> updateUsername(String username) async {
    try {
      final headers = await _getHeaders();
      final body = {
        'username': username,
      };

      final response = await http.patch(
        Uri.parse('$baseUrl/users/updateUsername'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Update Username Failed: ${response.statusCode} ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error updating username: $e');
      return false;
    }
  }
}
