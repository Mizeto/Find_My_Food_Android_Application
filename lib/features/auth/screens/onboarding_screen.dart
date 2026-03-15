import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive_helper.dart';
import '../cubit/auth_cubit.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top decorative area
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  // Decorative circles
                  Positioned(
                    top: -40,
                    right: -30,
                    child: Container(
                      width: 160.scale,
                      height: 160.scale,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.brandBlue.withOpacity(0.08),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 60,
                    right: 50,
                    child: Container(
                      width: 80.scale,
                      height: 80.scale,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.brandPurple.withOpacity(0.1),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 40,
                    left: -20,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.brandBlue.withOpacity(0.06),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 140,
                    left: 20,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.brandPurple.withOpacity(0.08),
                      ),
                    ),
                  ),

                  // Main content
                  Center(
                    child: FadeTransition(
                      opacity: _fadeIn,
                      child: SlideTransition(
                        position: _slideUp,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Hero emoji
                            Container(
                              padding: EdgeInsets.all(32.scale),
                              decoration: BoxDecoration(
                                gradient: AppTheme.brandGradient,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.brandPurple.withOpacity(0.3),
                                    blurRadius: 40,
                                    offset: const Offset(0, 16),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  AppTheme.logo,
                                  width: 90.scale,
                                  height: 90.scale,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            SizedBox(height: 40.h),

                            // Title
                            Text(
                              'Find My',
                              style: TextStyle(
                                fontSize: 38.sp,
                                fontWeight: FontWeight.w300,
                                color: const Color(0xFF2D2D3A),
                                height: 1.2,
                              ),
                            ),
                            ShaderMask(
                              shaderCallback: (bounds) =>
                                  AppTheme.brandGradient.createShader(bounds),
                               child: Text(
                                 'Food',
                                 style: TextStyle(
                                   fontSize: 48.sp,
                                   fontWeight: FontWeight.bold,
                                   color: Colors.white,
                                   height: 1.1,
                                 ),
                               ),
                             ),
                             SizedBox(height: 16.h),
                             Text(
                               'ค้นหาเมนูอาหารจากวัตถุดิบที่มี\nง่าย สะดวก ครบจบในแอปเดียว',
                               textAlign: TextAlign.center,
                               style: TextStyle(
                                 fontSize: 16.sp,
                                 color: Colors.grey[500],
                                 height: 1.6,
                               ),
                             ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Feature highlights
            Expanded(
              flex: 2,
              child: FadeTransition(
                opacity: _fadeIn,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildFeatureRow(Icons.search, 'ค้นหาเมนูจากวัตถุดิบที่มีอยู่'),
                      SizedBox(height: 12.h),
                      _buildFeatureRow(Icons.camera_alt_outlined, 'สแกนวัตถุดิบด้วย AI อัจฉริยะ'),
                      SizedBox(height: 12.h),
                      _buildFeatureRow(Icons.shopping_cart_outlined, 'จัดการรายการซื้อของอัตโนมัติ'),
                    ],
                  ),
                ),
              ),
            ),

            // CTA Button
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 40),
              child: FadeTransition(
                opacity: _fadeIn,
                child: SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppTheme.brandGradient,
                      borderRadius: BorderRadius.circular(30.scale),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.brandPurple.withOpacity(0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        context.read<AuthCubit>().completeOnboarding();
                      },
                      style: ElevatedButton.styleFrom(
                               backgroundColor: Colors.transparent,
                               shadowColor: Colors.transparent,
                               shape: RoundedRectangleBorder(
                                 borderRadius: BorderRadius.circular(30.scale),
                               ),
                             ),
                             child: Row(
                               mainAxisAlignment: MainAxisAlignment.center,
                               children: [
                                 Text(
                                   'เริ่มต้นใช้งาน',
                                   style: TextStyle(
                                     fontSize: 20.sp,
                                     fontWeight: FontWeight.bold,
                                     color: Colors.white,
                                   ),
                                 ),
                                 SizedBox(width: 12.w),
                                 Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 24.scale),
                               ],
                             ),
                           ),
                          ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.brandBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.brandBlue, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 15.sp,
              color: const Color(0xFF4A4A5A),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
