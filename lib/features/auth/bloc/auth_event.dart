part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

// เหตุการณ์ที่ 1: กดปุ่ม Login
class LoginRequested extends AuthEvent {
  final String email;
  final String password;

  const LoginRequested(this.email, this.password);
}

// เหตุการณ์ที่ 2: กดปุ่ม Logout
class LogoutRequested extends AuthEvent {}
