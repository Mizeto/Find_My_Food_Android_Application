import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

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

  const AuthAuthenticated(this.user);

  @override
  List<Object?> get props => [user];
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
  static const String _userKey = 'cached_user';
  
  // Define GoogleSignIn instance once
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: '717179936950-aolfunbngehe1fj91bj8bp7uhufpvbnt.apps.googleusercontent.com',
  );

  AuthCubit({AuthService? authService})
      : _authService = authService ?? AuthService(),
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
          emit(AuthAuthenticated(user));
          return;
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
      
      // Inject dummy ID if missing, to satisfy UserModel requirements
      if (!userData.containsKey('user_id')) {
        userData['user_id'] = 1;
      }
      
      final user = UserModel.fromJson(userData);
      
      await _cacheUser(user);
      emit(AuthAuthenticated(user));
    } catch (e) {
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
    int age,
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
        age: age,
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
          
          final user = UserModel(
            id: userData['user_id'] ?? 1,
            username: userData['username'] ?? googleUser.displayName ?? 'Google User',
            email: userData['email'] ?? googleUser.email,
            profileImage: userData['image_url'],
            loginType: LoginType.email,
          );
          
          await _cacheUser(user);
          print('Emit AuthAuthenticated'); // Debug print
          emit(AuthAuthenticated(user));
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
    emit(AuthLoading());
    try {
      final imageUrl = await _authService.uploadUserImage(imagePath);
      
      // Update the current user with new image
      if (state is AuthAuthenticated || currentUser != null) {
        final updatedUser = currentUser!.copyWith(profileImage: imageUrl);
        await _cacheUser(updatedUser);
        emit(AuthAuthenticated(updatedUser));
      }
    } catch (e) {
      String msg = e.toString().replaceAll('Exception: ', '');
      emit(AuthError(msg));
      // Re-emit authenticated state if we had a user
      if (currentUser != null) {
        emit(AuthAuthenticated(currentUser!));
      }
    }
  }

  // Guest Sign In
  Future<void> signInAsGuest() async {
    emit(AuthLoading());

    try {
      final user = UserModel.guest();
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

      // Clear cached user
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);

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
}
