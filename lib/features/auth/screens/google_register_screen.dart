import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../cubit/auth_cubit.dart';

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
        title: const Text('ข้อมูลเพิ่มเติม'),
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
                padding: const EdgeInsets.all(24),
                child: Card(
                   shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 8,
                  color: Colors.white.withOpacity(0.95),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                           const Text(
                            'กรุณากรอกข้อมูลเพิ่มเติม',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFF6B35),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'เพื่อเริ่มต้นใช้งานอย่างเต็มรูปแบบ',
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 32),
              
                          // Username
                          TextFormField(
                            controller: _usernameController,
                            enabled: !isLoading,
                            decoration: InputDecoration(
                              labelText: 'ชื่อผู้ใช้ (Username)',
                              prefixIcon: const Icon(Icons.person_outline),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'กรุณากรอกชื่อผู้ใช้';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
              
                          // Birth Date
                          TextFormField(
                            controller: _birthDateController,
                            readOnly: true,
                            onTap: isLoading ? null : () => _selectDate(context),
                            decoration: InputDecoration(
                              labelText: 'วันเกิด',
                              hintText: 'วว/ดด/ปปปป',
                              prefixIcon: const Icon(Icons.calendar_today),
                              suffixIcon: _selectedDate != null 
                                ? Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Text('อายุ $_calculatedAge ปี'),
                                  ) 
                                : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'กรุณาระบุวันเกิด';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
              
                          // Gender
                          DropdownButtonFormField<String>(
                            value: _selectedGender,
                            items: _genders.map((g) => DropdownMenuItem(
                              value: g, 
                              child: Text(g)
                            )).toList(),
                            onChanged: isLoading ? null : (v) => setState(() => _selectedGender = v!),
                            decoration: InputDecoration(
                              labelText: 'เพศ',
                              prefixIcon: const Icon(Icons.transgender),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
              
                          // Submit Button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : _onSubmit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF6B35),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text(
                                      'ยืนยันข้อมูล',
                                      style: TextStyle(
                                        fontSize: 16,
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
