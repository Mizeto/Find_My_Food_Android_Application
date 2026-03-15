import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../cubit/auth_cubit.dart';
import '../../../core/navigation/navigation_cubit.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import '../../../core/utils/responsive_helper.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            // Success handler: The AuthWrapper in main.dart will automatically
            // detect the state change and show the MainNavigationScreen.
            // We only need to clear any login-specific UI if necessary.
          } else if (state is AuthError) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red),
                    SizedBox(width: 10),
                    Text('เข้าสู่ระบบไม่สำเร็จ'),
                  ],
                ),
                content: Text(state.message),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('ตกลง'),
                  ),
                ],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            );
          }
        },
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: 28.w),
            children: [
              SizedBox(height: 30.h),
              _buildTopIllustration(),
              SizedBox(height: 24.h),
              _buildGreeting(),
              SizedBox(height: 32.h),
              const _LoginForm(),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopIllustration() {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background decoration
          Container(
            width: 160.scale,
            height: 160.scale,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppTheme.brandBlue.withOpacity(0.1),
                  AppTheme.brandPurple.withOpacity(0.1),
                ],
              ),
            ),
          ),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppTheme.brandBlue.withOpacity(0.15),
                  AppTheme.brandPurple.withOpacity(0.15),
                ],
              ),
            ),
          ),
          // Chef emoji
          Text('👨‍🍳', style: TextStyle(fontSize: 64.sp)),
        ],
      ),
    );
  }

  Widget _buildGreeting() {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) =>
              AppTheme.brandGradient.createShader(bounds),
          child: Text(
            'Hello!',
            style: TextStyle(
              fontSize: 36.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Welcome to Find My Food',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }
}

class _LoginForm extends StatefulWidget {
  const _LoginForm();

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _rememberMe = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthCubit>().login(
            _usernameController.text.trim(),
            _passwordController.text,
          );
    }
  }

  Future<void> _onGoogleLogin() async {
    context.read<AuthCubit>().signInWithGoogle();
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData prefixIcon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey[500]),
      prefixIcon: Icon(prefixIcon, color: Colors.grey[400]),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF8F8FA),
      contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.scale),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.scale),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.brandBlue, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthCubit>().state;
    final isLoading = state is AuthLoading;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Label
          Padding(
            padding: EdgeInsets.only(left: 4.w, bottom: 16.h),
            child: Text(
              'Login',
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2D2D3A),
              ),
            ),
          ),

          // Username
          TextFormField(
            controller: _usernameController,
            keyboardType: TextInputType.text,
            enabled: !isLoading,
            decoration: _inputDecoration(
              label: 'Username',
              prefixIcon: Icons.person_outline,
            ),
            validator: (value) =>
                (value == null || value.isEmpty) ? 'กรุณากรอกชื่อผู้ใช้' : null,
          ),
          const SizedBox(height: 16),

          // Password
          TextFormField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            enabled: !isLoading,
            decoration: _inputDecoration(
              label: 'Password',
              prefixIcon: Icons.lock_outline,
              suffix: IconButton(
                icon: Icon(
                  _isPasswordVisible
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: Colors.grey[400],
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
            ),
            validator: (value) =>
                (value == null || value.isEmpty) ? 'กรุณากรอกรหัสผ่าน' : null,
          ),
          const SizedBox(height: 8),

          // Remember me + Forget Password
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _rememberMe,
                      activeColor: AppTheme.brandPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      onChanged: (val) {
                        setState(() => _rememberMe = val ?? false);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Remember me',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: isLoading
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ForgotPasswordScreen(),
                          ),
                        );
                      },
                child: Text(
                  'Forget Password',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: AppTheme.brandPurple,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),

          // Login Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppTheme.brandGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.brandPurple.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: isLoading ? null : _onLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'เข้าสู่ระบบ',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Google Login Button (Refined)
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton(
              onPressed: isLoading ? null : _onGoogleLogin,
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('G', 
                    style: TextStyle(
                      fontSize: 20, 
                      fontWeight: FontWeight.bold, 
                      color: Color(0xFF4285F4) // Google Blue
                    )
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'เข้าสู่ระบบด้วย Google',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Sign up link
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Don't have an account? ",
                style: TextStyle(color: Colors.grey[500], fontSize: 14.sp),
              ),
              GestureDetector(
                onTap: isLoading
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                               builder: (context) => const RegisterScreen()),
                        );
                      },
                child: Text(
                  'Sign Up',
                  style: TextStyle(
                    color: AppTheme.brandPurple,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // Guest Mode (Bottom with Divider)
          Padding(
            padding: EdgeInsets.only(top: 10.h),
            child: Column(
              children: [
                Divider(color: Colors.grey[200]),
                SizedBox(height: 10.h),
                TextButton.icon(
                  onPressed: isLoading
                      ? null
                      : () => context.read<AuthCubit>().signInAsGuest(),
                  icon: Icon(Icons.person_outline, color: Colors.grey[400], size: 20),
                  label: Text(
                    'ใช้งานแบบผู้เยี่ยมชม',
                    style: TextStyle(color: Colors.grey[400], fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton({VoidCallback? onTap, required Widget child}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          color: Colors.white,
        ),
        child: Center(child: child),
      ),
    );
  }
}
