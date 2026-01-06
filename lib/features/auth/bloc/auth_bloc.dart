import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthInitial()) {
    // ดักจับ Event Login
    on<LoginRequested>((event, emit) async {
      emit(AuthLoading()); // 1. สั่งให้หน้าจอหมุนโหลด

      try {
        // จำลองการยิง API (อนาคตใส่ Code จริงตรงนี้)
        await Future.delayed(Duration(seconds: 2));

        if (event.email == "test" && event.password == "1234") {
          emit(AuthSuccess()); // 2. ถ้าถูก ให้ผ่าน
        } else {
          emit(AuthFailure("รหัสผ่านผิดครับ")); // 3. ถ้าผิด ให้แจ้งเตือน
        }
      } catch (e) {
        emit(AuthFailure(e.toString()));
      }
    });
  }
}
