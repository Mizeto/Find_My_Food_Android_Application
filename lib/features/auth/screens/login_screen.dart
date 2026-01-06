import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/auth_cubit.dart';
import 'register_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
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
        builder: (context, state) {
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFF6B35),
                  Color(0xFFFF8E53),
                  Color(0xFFFFD93D),
                ],
              ),
            ),
            child: SafeArea(
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                children: [
                  const SizedBox(height: 60), // Top spacing for aesthetics
                  // Logo & Welcome
                  _buildHeader(),

                  const SizedBox(height: 40),

                  // Login Buttons
                  // Always show the form to preserve state. Loading logic moved inside _LoginForm
                  _buildLoginButtons(context),

                  const SizedBox(height: 40),

                  // Footer
                  _buildFooter(),

                  const SizedBox(height: 20),
                ],
              ),
            ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // App Icon
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Text(
            '🍳',
            style: TextStyle(fontSize: 60),
          ),
        ),

        const SizedBox(height: 32),

        // Welcome Text
        const Text(
          'Find My Food',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                offset: Offset(0, 2),
                blurRadius: 8,
                color: Colors.black26,
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        Text(
          'ค้นหาเมนูอาหารจากวัตถุดิบที่มี',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButtons(BuildContext context) {
    return const _LoginForm();
  }

  Widget _buildFooter() {
    return Column(
      children: [
        const Text(
          'เข้าสู่ระบบเพื่อใช้งานฟีเจอร์ทั้งหมด',
          style: TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () {
             // Navigate to Register Screen will be implemented in _LoginForm usually,
             // but we can put it here if we want a global footer.
             // However, let's keep the flow clean.
          },
          child: const Text(''),
        )
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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthCubit>().login(
            _emailController.text.trim(),
            _passwordController.text,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch state to handle loading UI
    final state = context.watch<AuthCubit>().state;
    final isLoading = state is AuthLoading;

    return Card(
      color: Colors.white.withOpacity(0.9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Email
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                enabled: !isLoading, // Disable when loading
                decoration: const InputDecoration(
                  labelText: 'อีเมล',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'กรุณากรอกอีเมล';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Password
              TextFormField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                enabled: !isLoading, // Disable when loading
                decoration: InputDecoration(
                  labelText: 'รหัสผ่าน',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_isPasswordVisible
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'กรุณากรอกรหัสผ่าน';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Login Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _onLogin, // Disable click when loading
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
                      : const Text('เข้าสู่ระบบ', style: TextStyle(fontSize: 16)),
                ),
              ),
              
              const SizedBox(height: 16),

              // Register Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('ยังไม่มีบัญชี? ', style: TextStyle(color: Colors.black)),
                  TextButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const RegisterScreen()),
                            );
                          },
                    child: const Text('สมัครสมาชิก',
                        style: TextStyle(color: Color(0xFFFF6B35))),
                  ),
                ],
              ),

              const Divider(),
              
              // Guest Login
              TextButton.icon(
                onPressed: isLoading
                    ? null
                    : () => context.read<AuthCubit>().signInAsGuest(),
                icon: const Icon(Icons.person_outline, color: Colors.grey),
                label: const Text('ใช้งานแบบผู้เยี่ยมชม',
                    style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
