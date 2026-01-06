part of 'auth_bloc.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object> get props => [];
}

class AuthInitial extends AuthState {} // สถานะเริ่มต้น

class AuthLoading extends AuthState {} // กำลังหมุนติ้วๆ

class AuthSuccess extends AuthState {} // ล็อกอินผ่าน

class AuthFailure extends AuthState {
  // ล็อกอินไม่ผ่าน
  final String error;
  const AuthFailure(this.error);
}
