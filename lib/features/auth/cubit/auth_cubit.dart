import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../../profile/services/user_service.dart'; // Import UserService

// Auth States
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UserModel user;
  final String? message;

  const AuthAuthenticated(this.user, {this.message});

  @override
  List<Object?> get props => [user, message];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

class AuthRegisterSuccess extends AuthState {}

class AuthGoogleRegistrationRequired extends AuthState {
  final String tempToken;

  const AuthGoogleRegistrationRequired(this.tempToken);

  @override
  List<Object?> get props => [tempToken];
}

// Auth Cubit
class AuthCubit extends Cubit<AuthState> {
  final AuthService _authService;
  final UserService _userService; // Add UserService
  static const String _userKey = 'cached_user';
  static const String _guestUuidKey = 'guest_uuid';
  
  // Define GoogleSignIn instance once
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: '717179936950-aolfunbngehe1fj91bj8bp7uhufpvbnt.apps.googleusercontent.com',
  );

  AuthCubit({AuthService? authService, UserService? userService})
      : _authService = authService ?? AuthService(),
        _userService = userService ?? UserService(),
        super(AuthInitial());

  // Check if user is already logged in
  Future<void> checkAuthStatus() async {
    emit(AuthLoading());

    try {
      // 1. Check cached user first (App Session)
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);

      if (userJson != null) {
        try {
          final user = UserModel.fromJson(json.decode(userJson));
          
          // Guest user: restore without auth token
          if (user.isGuest && user.guestUuid != null) {
            print('DEBUG: Restoring guest session with UUID: ${user.guestUuid}');
            emit(AuthAuthenticated(user));
            return;
          }
          
          // Regular user: verify the auth token is also present
          final token = await _authService.getToken();
          if (token != null && token.isNotEmpty) {
            emit(AuthAuthenticated(user));
            return;
          } else {
            // Token missing — cache is stale, force re-login
            print('DEBUG: Cached user found but auth token is missing — clearing cache');
            await prefs.remove(_userKey);
          }
        } catch (e) {
             // Json parse error, clear cache
             await prefs.remove(_userKey);
        }
      }

      // 2. If no valid app session, check for existing Google Session (Recovery)
      // This handles cases where the app was killed during Google Sign In
      try {
        print('DEBUG: Checking for silent Google Sign In...');
        final GoogleSignInAccount? googleUser = await _googleSignIn.signInSilently();
        if (googleUser != null) {
          print('DEBUG: Recovered Google Session: ${googleUser.email}');
          await _handleGoogleUser(googleUser);
          return;
        }
      } catch (e) {
        print('DEBUG: Silent Google Sign In failed: $e');
      }

      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthUnauthenticated());
    }
  }

  // Login
  Future<void> login(String username, String password) async {
    emit(AuthLoading());

    try {
      final userData = await _authService.login(username, password);
      print('DEBUG: AuthService.login returned: $userData');
      
      // Inject dummy ID if missing, to satisfy UserModel requirements
      final userId = userData['user_id'] as int? ?? 1;
      
      final initialUser = UserModel.fromJson(userData);
      print('DEBUG: Initial user from login: $initialUser');
      
      // Try to fetch full profile immediately for the latest data (including image)
      print('DEBUG: Attempting investigative profile fetch for $username (ID: $userId)...');
      final fullProfile = await _userService.getUserProfile(
        userId: userId,
        username: initialUser.username,
      );

      if (fullProfile != null) {
        print('DEBUG: Post-login profile fetch SUCCESS: $fullProfile');
      } else {
        print('DEBUG: Post-login profile fetch FAILED (returning null)');
      }

      final finalUser = fullProfile ?? initialUser;
      
      await _cacheUser(finalUser);
      emit(AuthAuthenticated(finalUser));
    } catch (e) {
      print('DEBUG: Login Error: $e');
      String msg = e.toString().replaceAll('Exception: ', '');
      emit(AuthError(msg));
    }
  }

  // Register
  Future<void> register(
    String username,
    String email,
    String password,
    String firstName,
    String lastName,
    String gender,
    String birthDate,
  ) async {
    emit(AuthLoading());

    try {
      final success = await _authService.register(
        username: username,
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        gender: gender,
        birthDate: birthDate,
      );

      if (success) {
        // Emit success state instead of auto-login
        emit(AuthRegisterSuccess());
      } else {
        emit(const AuthError('สมัครสมาชิกไม่สำเร็จ กรุณาลองใหม่'));
      }
    } catch (e) {
      String msg = e.toString().replaceAll('Exception: ', '');
      emit(AuthError(msg));
    }
  }

  // Sign In with Google
  Future<void> signInWithGoogle() async {
    emit(AuthLoading());
    try {
      // Force sign out first to allow user to choose account
      print('DEBUG: googleSignIn.signOut() calling...');
      await _googleSignIn.signOut();
      print('DEBUG: googleSignIn.signOut() completed.');
      
      print('DEBUG: googleSignIn.signIn() calling...');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      print('DEBUG: googleSignIn.signIn() result: $googleUser');
      
      if (googleUser == null) {
        // User cancelled the sign-in
        print('DEBUG: User cancelled sign-in (googleUser is null)');
        emit(AuthUnauthenticated());
        return;
      }
      
      await _handleGoogleUser(googleUser);

    } catch (e) {
      String msg = e.toString().replaceAll('Exception: ', '');
      emit(AuthError(msg));
    }
  }

  // Helper method to process Google User (used by both signInWithGoogle and checkAuthStatus)
  Future<void> _handleGoogleUser(GoogleSignInAccount googleUser) async {
      print('DEBUG: Getting authentication/idToken...');
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;
      print('DEBUG: idToken received: ${idToken != null ? "YES (Length: ${idToken.length})" : "NO"}');
      
      if (idToken == null) {
        throw Exception('ไม่สามารถรับ ID Token จาก Google ได้');
      }
      
      // Send ID token to backend
      final data = await _authService.googleLoginWithIdToken(idToken);
      
      // Check if this is a new user (needs registration) or existing user
      if (data['temp_token'] != null) {
        // New user - need to complete registration (explicit temp_token)
        emit(AuthGoogleRegistrationRequired(data['temp_token']));
      } else if (data['access_token'] != null) {
        // Check if the access_token is actually a temp_token by decoding it
        final accessToken = data['access_token'];
        bool isRegisterToken = false;
        
        try {
          Map<String, dynamic> decodedToken = JwtDecoder.decode(accessToken);
          print('Decoded Token: $decodedToken'); // Debug print
          if (decodedToken['type'] == 'google_register') {
            isRegisterToken = true;
          }
        } catch (e) {
          // Token decode failed, assume normal access token
          print('Token decode error: $e');
        }

        if (isRegisterToken) {
           print('Emit AuthGoogleRegistrationRequired'); // Debug print
           emit(AuthGoogleRegistrationRequired(accessToken));
        } else {
           // Existing user - logged in successfully
          final userData = data['data'] as Map<String, dynamic>? ?? {};
          final userId = userData['user_id'] as int? ?? 1;
          print('DEBUG: Google Login success. User data: $userData');
          
          // Use fromJson for consistent normalization and parsing
          final initialUser = UserModel.fromJson({
            ...userData,
            'user_id': userId, // Ensure ID is present
            if (userData['email'] == null) 'email': googleUser.email,
            if (userData['username'] == null) 'username': googleUser.displayName,
          });
          print('DEBUG: Initial Google user: $initialUser');
          
          // Fetch full profile for latest data
          print('DEBUG: Attempting investigative profile fetch for Google User ${initialUser.username} (ID: $userId)...');
          final fullProfile = await _userService.getUserProfile(
            userId: userId,
            username: initialUser.username,
          );

          if (fullProfile != null) {
            print('DEBUG: Post-Google-login profile fetch SUCCESS: $fullProfile');
          } else {
            print('DEBUG: Post-Google-login profile fetch FAILED (returning null)');
          }

          final finalUser = fullProfile ?? initialUser;

          await _cacheUser(finalUser);
          print('Emit AuthAuthenticated'); // Debug print
          emit(AuthAuthenticated(finalUser));
        }
      } else {
        throw Exception('Invalid response from server');
      }
  }

  // Handle Google Login Result (Token received directly)
  Future<void> loginWithGoogle(Map<String, dynamic> data) async {
    emit(AuthLoading());
    try {
      // Assuming data contains access_token and maybe user info
      // We might need to fetch user profile if it's not in the data
      // For now, construct a user model from what we have or just token
      
      // If the backend returns the same structure as normal login:
      if (!data.containsKey('user_id')) {
        data['user_id'] = 1; // Dummy ID if missing
      }
      if (!data.containsKey('username')) {
        data['username'] = 'Google User';
      }
      
      final user = UserModel.fromJson(data);
      await _cacheUser(user);
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError('Failed to process Google Login: $e'));
    }
  }

  // Handle Google Login Result (Need Registration)
  void requireGoogleRegistration(String tempToken) {
    emit(AuthGoogleRegistrationRequired(tempToken));
  }

  // Complete Google Registration
  Future<void> completeGoogleRegistration({
    required String tempToken,
    required String username,
    required String gender,
    required String birthDate,
  }) async {
    emit(AuthLoading());
    try {
      final data = await _authService.googleRegister(
        tempToken: tempToken,
        username: username,
        gender: gender,
        birthDate: birthDate,
      );
      
      // After success, we expect a token/user object similar to login
      await loginWithGoogle(data);
      
    } catch (e) {
       String msg = e.toString().replaceAll('Exception: ', '');
       emit(AuthError(msg));
    }
  }

  // Upload Profile Image
  Future<void> uploadProfileImage(String imagePath) async {
    final originalUser = currentUser; // Capture user before loading
    emit(AuthLoading());
    try {
      // 1. Upload image
      final uploadedUrl = await _authService.uploadUserImage(imagePath);
      
      // 2. Fetch updated user profile (investigative fetch)
      final updatedUserFromApi = await _userService.getUserProfile(
        userId: originalUser?.id,
        username: originalUser?.username,
      );

      if (updatedUserFromApi != null) {
        // Update cache and emit
        await _cacheUser(updatedUserFromApi);
        emit(AuthAuthenticated(updatedUserFromApi, message: 'อัปเดตรูปโปรไฟล์สำเร็จ'));
      } else if (originalUser != null) {
        // Fallback: Use original user but update image URL if returned from upload
        final fallbackUser = uploadedUrl.isNotEmpty 
            ? originalUser.copyWith(profileImage: uploadedUrl) 
            : originalUser;
            
        emit(AuthAuthenticated(fallbackUser, message: 'อัปโหลดสำเร็จ (ระบบกำลังประมวลผลรูปภาพ)')); 
      }
    } catch (e) {
      String msg = e.toString().replaceAll('Exception: ', '');
      emit(AuthError(msg));
      // Re-emit authenticated state if we had a user
      if (originalUser != null) {
        emit(AuthAuthenticated(originalUser));
      }
    }
  }

  // Guest Sign In
  Future<void> signInAsGuest() async {
    emit(AuthLoading());

    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if there's an existing guest UUID, otherwise generate new one
      String? existingUuid = prefs.getString(_guestUuidKey);
      final guestUuid = existingUuid ?? const Uuid().v4();
      
      // Save guest UUID
      await prefs.setString(_guestUuidKey, guestUuid);
      print('DEBUG: Guest sign in with UUID: $guestUuid');
      
      final user = UserModel.guest(uuid: guestUuid);
      await _cacheUser(user);
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError('เกิดข้อผิดพลาด: ${e.toString()}'));
    }
  }

  // Sign Out
  Future<void> signOut() async {
    emit(AuthLoading());

    try {
      // Ensure Google Sign Out
      try {
        await _googleSignIn.signOut();
      } catch (_) {}

      // Clear cached user, auth token, AND guest UUID
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);
      await prefs.remove(_guestUuidKey);
      await _authService.clearToken();

      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError('เกิดข้อผิดพลาดในการออกจากระบบ: ${e.toString()}'));
    }
  }

  // Helper: Cache user to SharedPreferences
  Future<void> _cacheUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, json.encode(user.toJson()));
  }

  // Getter for current user
  UserModel? get currentUser {
    final state = this.state;
    if (state is AuthAuthenticated) {
      return state.user;
    }
    return null;
  }

  bool get isAuthenticated => state is AuthAuthenticated;

  bool get isGuest {
    final user = currentUser;
    return user?.isGuest ?? false;
  }

  // Update Username
  Future<void> updateUsername(String newUsername) async {
    final originalUser = currentUser; // Capture user before loading
    emit(AuthLoading());
    try {
      final success = await _userService.updateUsername(newUsername);
      if (success) {
        if (originalUser != null) {
          final updatedUser = originalUser.copyWith(username: newUsername);
          await _cacheUser(updatedUser);
          emit(AuthAuthenticated(updatedUser, message: 'แก้ไขชื่อผู้ใช้สำเร็จ')); // Use captured user
        } else {
           // Should not happen, but if originalUser was null, try to reload/check
           emit(AuthError('User not found locally'));
        }
      } else {
        emit(AuthError('Failed to update username'));
        // Restore state
        if (originalUser != null) emit(AuthAuthenticated(originalUser));
      }
    } catch (e) {
      String msg = e.toString().replaceAll('Exception: ', '');
      emit(AuthError(msg));
       if (originalUser != null) emit(AuthAuthenticated(originalUser));
    }
  }

  // Change Password
  Future<void> changePassword(String currentPassword, String newPassword, String confirmPassword) async {
    final originalUser = currentUser; // Capture user before loading
    emit(AuthLoading());
    try {
      final success = await _userService.changePassword(
        currentPassword: currentPassword, 
        newPassword: newPassword, 
        confirmPassword: confirmPassword
      );
      
      if (success) {
        if (originalUser != null) {
          emit(AuthAuthenticated(originalUser, message: 'เปลี่ยนรหัสผ่านสำเร็จ'));
        }
      } else {
        emit(AuthError('Failed to change password'));
        if (originalUser != null) emit(AuthAuthenticated(originalUser));
      }
    } catch (e) {
      String msg = e.toString().replaceAll('Exception: ', '');
      emit(AuthError(msg));
      if (originalUser != null) emit(AuthAuthenticated(originalUser));
    }
  }
}
