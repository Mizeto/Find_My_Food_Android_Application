import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../cubit/auth_cubit.dart';
import '../../../core/navigation/navigation_cubit.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive_helper.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  String _selectedGender = 'เพศชาย';

  final List<String> _genders = ['เพศชาย', 'เพศหญิง', 'อื่นๆ'];
  DateTime? _selectedDate;
  int _calculatedAge = 0;

  @override
  void dispose() {
    _usernameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _birthDateController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onRegister() {
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('กรุณาระบุวันเกิด')));
        return;
      }

      if (_selectedGender == 'เลือกเพศ') {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('กรุณาเลือกเพศ')));
        return;
      }

      context.read<AuthCubit>().register(
        _usernameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
        _firstNameController.text.trim(),
        _lastNameController.text.trim(),
        _selectedGender,
        DateFormat('yyyy-MM-dd').format(_selectedDate!),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.brandPurple,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _birthDateController.text = DateFormat('dd/MM/yyyy').format(picked);
        _calculateAge();
      });
    }
  }

  void _calculateAge() {
    if (_selectedDate == null) return;

    final now = DateTime.now();
    int age = now.year - _selectedDate!.year;
    if (now.month < _selectedDate!.month ||
        (now.month == _selectedDate!.month && now.day < _selectedDate!.day)) {
      age--;
    }
    _calculatedAge = age;
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData prefixIcon,
    Widget? suffix,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.scale),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.scale),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is AuthAuthenticated) {
            // Success: Clear stack and return to root (AuthWrapper)
            // AuthWrapper in main.dart will handle resetting the tab index.
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/', (route) => false);
          } else if (state is AuthRegisterSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('สมัครสมาชิกสำเร็จ! กรุณาเข้าสู่ระบบ'),
                backgroundColor: AppTheme.brandBlue,
              ),
            );
            // Go back to login/root
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/', (route) => false);
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return SafeArea(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 28.w),
              children: [
                SizedBox(height: 12.h),

                // Back to Login
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.arrow_back_ios,
                      size: 16.scale,
                      color: const Color(0xFF2D2D3A),
                    ),
                    label: const Text(
                      'Back to Login',
                      style: TextStyle(
                        color: Color(0xFF2D2D3A),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 8.h),

                // Sign Up Header
                Center(
                  child: Text(
                    'Sign Up',
                    style: TextStyle(
                      fontSize: 30.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2D2D3A),
                    ),
                  ),
                ),
                SizedBox(height: 28.h),

                // Form
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Email
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        enabled: !isLoading,
                        decoration: _inputDecoration(
                          label: 'Email',
                          prefixIcon: Icons.email_outlined,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return 'กรุณากรอกอีเมล';
                          if (!value.contains('@'))
                            return 'รูปแบบอีเมลไม่ถูกต้อง';
                          return null;
                        },
                      ),
                      SizedBox(height: 14.h),

                      // Username
                      TextFormField(
                        controller: _usernameController,
                        enabled: !isLoading,
                        decoration: _inputDecoration(
                          label: 'Username',
                          prefixIcon: Icons.account_circle_outlined,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return 'กรุณากรอกชื่อผู้ใช้';
                          return null;
                        },
                      ),
                      SizedBox(height: 14.h),

                      // First Name & Last Name
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _firstNameController,
                              enabled: !isLoading,
                              style: TextStyle(fontSize: 16.sp),
                              decoration: _inputDecoration(
                                label: 'ชื่อจริง',
                                prefixIcon: Icons.person_outline,
                              ),
                              validator: (v) => v!.isEmpty ? 'required' : null,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: TextFormField(
                              controller: _lastNameController,
                              enabled: !isLoading,
                              style: TextStyle(fontSize: 16.sp),
                              decoration: _inputDecoration(
                                label: 'นามสกุล',
                                prefixIcon: Icons.person_outline,
                              ),
                              validator: (v) => v!.isEmpty ? 'required' : null,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 14.h),

                      // Gender & Birthday
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 12.w),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F8FA),
                                borderRadius: BorderRadius.circular(16.scale),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedGender,
                                  isExpanded: true,
                                  icon: Icon(
                                    Icons.keyboard_arrow_down,
                                    color: Colors.grey[400],
                                  ),
                                  items: _genders
                                      .map(
                                        (g) => DropdownMenuItem(
                                          value: g,
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.wc,
                                                size: 18.scale,
                                                color: Colors.grey[400],
                                              ),
                                              SizedBox(width: 8.w),
                                              Text(
                                                g,
                                                style: TextStyle(
                                                  fontSize: 14.sp,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: isLoading
                                      ? null
                                      : (v) => setState(
                                          () => _selectedGender = v!,
                                        ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: TextFormField(
                              controller: _birthDateController,
                              readOnly: true,
                              onTap: isLoading
                                  ? null
                                  : () => _selectDate(context),
                              decoration: _inputDecoration(
                                label: 'วันเกิด',
                                hint: 'วว/ดด/ปปปป',
                                prefixIcon: Icons.calendar_today_outlined,
                                suffix: _selectedDate != null
                                    ? Padding(
                                        padding: EdgeInsets.all(14.scale),
                                        child: Text(
                                          '$_calculatedAge ปี',
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                              validator: (v) => (v == null || v.isEmpty)
                                  ? 'ระบุวันเกิด'
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 14.h),

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
                              size: 20.scale,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return 'กรุณากรอกรหัสผ่าน';
                          if (value.length < 6)
                            return 'รหัสผ่านต้องยาวอย่างน้อย 6 ตัวอักษร';
                          return null;
                        },
                      ),
                      SizedBox(height: 14.h),

                      // Confirm Password
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: !_isPasswordVisible,
                        enabled: !isLoading,
                        decoration: _inputDecoration(
                          label: 'Confirm Password',
                          prefixIcon: Icons.lock_outline,
                        ),
                        style: TextStyle(fontSize: 16.sp),
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return 'กรุณายืนยันรหัสผ่าน';
                          if (value != _passwordController.text)
                            return 'รหัสผ่านไม่ตรงกัน';
                          return null;
                        },
                      ),
                      SizedBox(height: 28.h),

                      // Register Button
                      SizedBox(
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
                            onPressed: isLoading ? null : _onRegister,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.scale),
                              ),
                            ),
                            child: isLoading
                                ? SizedBox(
                                    height: 24.scale,
                                    width: 24.scale,
                                    child: const CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    'Sign Up',
                                    style: TextStyle(
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      SizedBox(height: 24.h),

                      // Or continue with
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.grey[300])),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            child: Text(
                              'Or continue with',
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: Colors.grey[400],
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: Colors.grey[300])),
                        ],
                      ),
                      SizedBox(height: 20.h),

                      // Social Login Icons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildSocialButton(
                            child: Text(
                              'G',
                              style: TextStyle(
                                fontSize: 22.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ),
                          SizedBox(width: 20.w),
                          _buildSocialButton(
                            child: Icon(
                              Icons.apple,
                              size: 28.scale,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(width: 20.w),
                          _buildSocialButton(
                            child: Icon(
                              Icons.facebook,
                              size: 28.scale,
                              color: const Color(0xFF1877F2),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 24.h),

                      // Already have an account
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Already have an account? ",
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14.sp,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Text(
                              'Sign In',
                              style: TextStyle(
                                color: AppTheme.brandPurple,
                                fontWeight: FontWeight.bold,
                                fontSize: 14.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 30.h),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSocialButton({required Widget child}) {
    return Container(
      width: 56.scale,
      height: 56.scale,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.scale),
        border: Border.all(color: Colors.grey.shade200),
        color: Colors.white,
      ),
      child: Center(child: child),
    );
  }
}
