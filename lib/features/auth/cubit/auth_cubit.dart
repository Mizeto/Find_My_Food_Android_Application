import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

// Auth Cubit
class AuthCubit extends Cubit<AuthState> {
  final AuthService _authService;
  static const String _userKey = 'cached_user';

  AuthCubit({AuthService? authService})
      : _authService = authService ?? AuthService(),
        super(AuthInitial());

  // Check if user is already logged in
  Future<void> checkAuthStatus() async {
    emit(AuthLoading());

    try {
      // Check cached user first
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);

      if (userJson != null) {
        try {
          final user = UserModel.fromJson(json.decode(userJson));
          emit(AuthAuthenticated(user));
        } catch (e) {
            // Json parse error, clear cache
             await prefs.remove(_userKey);
             emit(AuthUnauthenticated());
        }
        return;
      }

      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthUnauthenticated());
    }
  }

  // Login
  Future<void> login(String email, String password) async {
    emit(AuthLoading());

    try {
      final userData = await _authService.login(email, password);
      // Backend returns fields that match UserModel.fromJson expectation
      final user = UserModel.fromJson(userData);
      
      await _cacheUser(user);
      emit(AuthAuthenticated(user));
    } catch (e) {
      // Clean error message
      String msg = e.toString().replaceAll('Exception: ', '');
      emit(AuthError(msg));
      // Reset to unauthenticated after error so UI can show form again if needed? 
      // Actually keeping error state is fine, UI handles it.
    }
  }

  // Register
  Future<void> register(String username, String email, String password) async {
    emit(AuthLoading());

    try {
      final userData = await _authService.register(username, email, password);
      final user = UserModel.fromJson(userData);
      
      await _cacheUser(user);
      emit(AuthAuthenticated(user));
    } catch (e) {
      String msg = e.toString().replaceAll('Exception: ', '');
      emit(AuthError(msg));
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


