import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive_helper.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _authService = AuthService();
  final _pageController = PageController();

  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  int _currentStep = 0;
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    _pageController.dispose();
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: AppTheme.brandBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _requestOTP() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showError('กรุณากรอกอีเมล');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _authService.requestPasswordOTP(email);
      _showSuccess('ส่ง OTP ไปยัง $email แล้ว');
      _goToStep(1);
    } catch (e) {
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOTP() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty) {
      _showError('กรุณากรอก OTP');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _authService.verifyPasswordOTP(_emailController.text.trim(), otp);
      _showSuccess('ยืนยัน OTP สำเร็จ');
      _goToStep(2);
    } catch (e) {
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final newPass = _newPasswordController.text;
    final confirmPass = _confirmPasswordController.text;
    if (newPass.isEmpty || confirmPass.isEmpty) {
      _showError('กรุณากรอกรหัสผ่านใหม่');
      return;
    }
    if (newPass != confirmPass) {
      _showError('รหัสผ่านไม่ตรงกัน');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _authService.resetPassword(
        email: _emailController.text.trim(),
        otp: _otpController.text.trim(),
        newPassword: newPass,
      );
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            icon: const Icon(Icons.check_circle, color: AppTheme.brandBlue, size: 64),
            title: const Text('สำเร็จ!'),
            content: const Text('เปลี่ยนรหัสผ่านเรียบร้อยแล้ว\nกรุณาเข้าสู่ระบบด้วยรหัสผ่านใหม่'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                child: Text('ไปหน้าเข้าสู่ระบบ', style: TextStyle(color: AppTheme.brandPurple, fontSize: 14.sp)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _goToStep(int step) {
    setState(() => _currentStep = step);
    _pageController.animateToPage(step,
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
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
        borderRadius: BorderRadius.circular(16.scale),
        borderSide: const BorderSide(color: AppTheme.brandBlue, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final steps = ['อีเมล', 'OTP', 'รหัสผ่านใหม่'];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios, color: const Color(0xFF2D2D3A), size: 20.scale),
                    onPressed: () {
                      if (_currentStep > 0) {
                        _goToStep(_currentStep - 1);
                      } else {
                        Navigator.pop(context);
                      }
                    },
                  ),
                  Text(
                    'Forget Password',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2D2D3A),
                    ),
                  ),
                ],
              ),
            ),

            // Step indicator
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 12.h),
              child: Row(
                children: List.generate(steps.length * 2 - 1, (i) {
                  // Even index = circle, odd index = line
                  if (i.isEven) {
                    final stepIndex = i ~/ 2;
                    final isActive = stepIndex <= _currentStep;
                    return Container(
                      width: 32.scale,
                      height: 32.scale,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: isActive ? AppTheme.brandGradient : null,
                        color: isActive ? null : Colors.grey[200],
                      ),
                      child: Center(
                        child: stepIndex < _currentStep
                            ? Icon(Icons.check, size: 18.scale, color: Colors.white)
                            : Text(
                                '${stepIndex + 1}',
                                style: TextStyle(
                                  color: isActive ? Colors.white : Colors.grey[500],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.sp,
                                ),
                              ),
                      ),
                    );
                  } else {
                    final lineAfterStep = (i + 1) ~/ 2;
                    final isActive = lineAfterStep <= _currentStep;
                    return Expanded(
                      child: Container(
                        height: 2.h,
                        margin: EdgeInsets.symmetric(horizontal: 4.w),
                        color: isActive ? AppTheme.brandPurple : Colors.grey[300],
                      ),
                    );
                  }
                }),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: steps
                    .map((s) => Text(s, style: TextStyle(color: Colors.grey[500], fontSize: 12.sp)))
                    .toList(),
              ),
            ),

            SizedBox(height: 24.h),

            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildEmailStep(),
                  _buildOTPStep(),
                  _buildResetStep(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientButton({
    required String label,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56.h,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppTheme.brandGradient,
          borderRadius: BorderRadius.circular(16.scale),
          boxShadow: [
            BoxShadow(
              color: AppTheme.brandPurple.withOpacity(0.3),
              blurRadius: 16.scale,
              offset: Offset(0, 6.h),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.scale),
            ),
          ),
          child: _isLoading
              ? SizedBox(
                  height: 24.scale,
                  width: 24.scale,
                  child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : Text(label, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ),
    );
  }

  // ──────────── Step 1: Email ────────────
  Widget _buildEmailStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 32.w),
      child: Column(
        children: [
          SizedBox(height: 20.h),
          Container(
            padding: EdgeInsets.all(20.scale),
            decoration: BoxDecoration(
              gradient: AppTheme.brandGradient,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.email_outlined, size: 48.scale, color: Colors.white),
          ),
          SizedBox(height: 24.h),
          Text(
            'กรอกอีเมลของคุณ',
            style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold, color: const Color(0xFF2D2D3A)),
          ),
          SizedBox(height: 8.h),
          Text(
            'เราจะส่งรหัส OTP ไปยังอีเมลของคุณ',
            style: TextStyle(color: Colors.grey[500], fontSize: 14.sp),
          ),
          SizedBox(height: 28.h),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            enabled: !_isLoading,
            style: TextStyle(fontSize: 16.sp),
            decoration: _inputDecoration(label: 'Email', prefixIcon: Icons.email_outlined),
          ),
          SizedBox(height: 24.h),
          _buildGradientButton(label: 'ส่ง OTP', onPressed: _isLoading ? null : _requestOTP),
        ],
      ),
    );
  }

  // ──────────── Step 2: OTP ────────────
  Widget _buildOTPStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 32.w),
      child: Column(
        children: [
          SizedBox(height: 20.h),
          Container(
            padding: EdgeInsets.all(20.scale),
            decoration: BoxDecoration(
              gradient: AppTheme.brandGradient,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.lock_clock, size: 48.scale, color: Colors.white),
          ),
          SizedBox(height: 24.h),
          Text(
            'กรอกรหัส OTP',
            style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold, color: const Color(0xFF2D2D3A)),
          ),
          SizedBox(height: 8.h),
          Text(
            'รหัสถูกส่งไปที่ ${_emailController.text}',
            style: TextStyle(color: Colors.grey[500], fontSize: 14.sp),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 28.h),
          TextFormField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            enabled: !_isLoading,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24.sp, letterSpacing: 8, fontWeight: FontWeight.bold),
            decoration: _inputDecoration(label: 'OTP', prefixIcon: Icons.pin_outlined),
          ),
          SizedBox(height: 12.h),
          TextButton(
            onPressed: _isLoading ? null : _requestOTP,
            child: Text('ส่ง OTP อีกครั้ง', style: TextStyle(color: AppTheme.brandPurple, fontSize: 14.sp)),
          ),
          SizedBox(height: 12.h),
          _buildGradientButton(label: 'ยืนยัน OTP', onPressed: _isLoading ? null : _verifyOTP),
        ],
      ),
    );
  }

  // ──────────── Step 3: New Password ────────────
  Widget _buildResetStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 32.w),
      child: Column(
        children: [
          SizedBox(height: 20.h),
          Container(
            padding: EdgeInsets.all(20.scale),
            decoration: BoxDecoration(
              gradient: AppTheme.brandGradient,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.lock_reset, size: 48.scale, color: Colors.white),
          ),
          SizedBox(height: 24.h),
          Text(
            'ตั้งรหัสผ่านใหม่',
            style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold, color: const Color(0xFF2D2D3A)),
          ),
          SizedBox(height: 28.h),
          TextFormField(
            controller: _newPasswordController,
            obscureText: !_isPasswordVisible,
            enabled: !_isLoading,
            style: TextStyle(fontSize: 16.sp),
            decoration: _inputDecoration(
              label: 'รหัสผ่านใหม่',
              prefixIcon: Icons.lock_outline,
              suffix: IconButton(
                icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey[400], size: 20.scale),
                onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: !_isConfirmPasswordVisible,
            enabled: !_isLoading,
            style: TextStyle(fontSize: 16.sp),
            decoration: _inputDecoration(
              label: 'ยืนยันรหัสผ่านใหม่',
              prefixIcon: Icons.lock_outline,
              suffix: IconButton(
                icon: Icon(_isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey[400], size: 20.scale),
                onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
              ),
            ),
          ),
          SizedBox(height: 24.h),
          _buildGradientButton(label: 'เปลี่ยนรหัสผ่าน', onPressed: _isLoading ? null : _resetPassword),
        ],
      ),
    );
  }
}
