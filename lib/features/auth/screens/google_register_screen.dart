import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../cubit/auth_cubit.dart';
import '../../../core/utils/responsive_helper.dart';

class GoogleRegisterScreen extends StatefulWidget {
  final String tempToken;

  const GoogleRegisterScreen({
    super.key,
    required this.tempToken,
  });

  @override
  State<GoogleRegisterScreen> createState() => _GoogleRegisterScreenState();
}

class _GoogleRegisterScreenState extends State<GoogleRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _birthDateController = TextEditingController();
  
  String _selectedGender = 'Male';
  final List<String> _genders = ['Male', 'Female', 'Other'];
  
  DateTime? _selectedDate;
  int _calculatedAge = 0;

  @override
  void dispose() {
    _usernameController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)), // Default to 18 years ago
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFF6B35),
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

  void _onSubmit() {
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณาระบุวันเกิด')),
        );
        return;
      }
      
      context.read<AuthCubit>().completeGoogleRegistration(
            tempToken: widget.tempToken,
            username: _usernameController.text.trim(),
            gender: _selectedGender,
            birthDate: DateFormat('yyyy-MM-dd').format(_selectedDate!),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ข้อมูลเพิ่มเติม', style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          } else if (state is AuthAuthenticated) {
            // Success, close this screen to go back to main navigation
            // Using pushReplacement in previous steps might leave us here, 
            // so we might need to pop until we clear auth flow or rely on main wrapper
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;
          
          return Container(
             height: double.infinity,
             decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFF6B35),
                  Color(0xFFFFD93D),
                ],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24.scale),
                child: Card(
                   shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.scale),
                  ),
                  elevation: 8.scale,
                  color: Colors.white.withOpacity(0.95),
                  child: Padding(
                    padding: EdgeInsets.all(24.scale),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                           Text(
                            'กรุณากรอกข้อมูลเพิ่มเติม',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22.sp,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFFF6B35),
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'เพื่อเริ่มต้นใช้งานอย่างเต็มรูปแบบ',
                            style: TextStyle(color: Colors.grey, fontSize: 14.sp),
                          ),
                          SizedBox(height: 32.h),
              
                          // Username
                          TextFormField(
                            controller: _usernameController,
                            enabled: !isLoading,
                            style: TextStyle(fontSize: 16.sp),
                            decoration: InputDecoration(
                              labelText: 'ชื่อผู้ใช้ (Username)',
                              labelStyle: TextStyle(fontSize: 14.sp),
                              prefixIcon: Icon(Icons.person_outline, size: 24.scale),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.scale),
                              ),
                              contentPadding: EdgeInsets.all(12.scale),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'กรุณากรอกชื่อผู้ใช้';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 20.h),
              
                          // Birth Date
                          TextFormField(
                            controller: _birthDateController,
                            readOnly: true,
                            enabled: !isLoading,
                            style: TextStyle(fontSize: 16.sp),
                            onTap: isLoading ? null : () => _selectDate(context),
                            decoration: InputDecoration(
                              labelText: 'วันเกิด',
                              labelStyle: TextStyle(fontSize: 14.sp),
                              hintText: 'วว/ดด/ปปปป',
                              hintStyle: TextStyle(fontSize: 16.sp),
                              prefixIcon: Icon(Icons.calendar_today, size: 24.scale),
                              suffixIcon: _selectedDate != null 
                                ? Padding(
                                    padding: EdgeInsets.all(12.scale),
                                    child: Text('อายุ $_calculatedAge ปี', style: TextStyle(fontSize: 12.sp)),
                                  ) 
                                : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.scale),
                              ),
                              contentPadding: EdgeInsets.all(12.scale),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'กรุณาระบุวันเกิด';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 20.h),
              
                          // Gender
                          DropdownButtonFormField<String>(
                            value: _selectedGender,
                            items: _genders.map((g) => DropdownMenuItem(
                              value: g, 
                              child: Text(g, style: TextStyle(fontSize: 16.sp))
                            )).toList(),
                            onChanged: isLoading ? null : (v) => setState(() => _selectedGender = v!),
                            decoration: InputDecoration(
                              labelText: 'เพศ',
                              labelStyle: TextStyle(fontSize: 14.sp),
                              prefixIcon: Icon(Icons.transgender, size: 24.scale),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.scale),
                              ),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12.w),
                            ),
                          ),
                          SizedBox(height: 32.h),
              
                          // Submit Button
                          SizedBox(
                            width: double.infinity,
                            height: 50.h,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : _onSubmit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF6B35),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.scale),
                                ),
                              ),
                              child: isLoading
                                  ? SizedBox(height: 24.scale, width: 24.scale, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : Text(
                                      'ยืนยันข้อมูล',
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
