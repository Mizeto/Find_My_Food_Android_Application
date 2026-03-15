import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_cubit.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../bloc/scan_food_cubit.dart';
import 'scan_result_screen.dart';

class ScanFoodScreen extends StatelessWidget {
  const ScanFoodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ScanFoodCubit(),
      child: const _ScanFoodView(),
    );
  }
}

class _ScanFoodView extends StatefulWidget {
  const _ScanFoodView();

  @override
  State<_ScanFoodView> createState() => _ScanFoodViewState();
}

class _ScanFoodViewState extends State<_ScanFoodView> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  bool _isDishMode = true; // Default to Dish Prediction

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    final isGuest = context.read<AuthCubit>().isGuest;
    if (isGuest) {
      _showLoginPrompt(context);
      return;
    }

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null && context.mounted) {
        setState(() {
          _image = File(pickedFile.path);
        });
        context.read<ScanFoodCubit>().analyzeImage(pickedFile, isDishPrediction: _isDishMode);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void _showLoginPrompt(BuildContext context) {
    final isDarkMode = context.read<ThemeCubit>().isDarkMode;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF1E2D4A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.scale)),
        title: Row(
          children: [
            Icon(Icons.lock_outline, color: AppTheme.brandPurple, size: 24.scale),
            SizedBox(width: 10.w),
            Text(
              'เข้าสู่ระบบก่อนใช้งาน',
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontSize: 18.sp),
            ),
          ],
        ),
        content: Text(
          'ฟังก์ชันสแกนอาหารและวัตถุดิบ\nจำเป็นต้องเข้าสู่ระบบก่อนเพื่อจัดเก็บข้อมูลและประมวลผลครับ 🍳',
          style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54, fontSize: 14.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ไว้ทีหลัง', style: TextStyle(color: Colors.grey, fontSize: 14.sp)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthCubit>().signOut(); // Clear guest session and go to login
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brandPurple,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.scale)),
            ),
            child: Text('เข้าสู่ระบบ', style: TextStyle(color: Colors.white, fontSize: 14.sp)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeCubit>().isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF1A1A2E) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text('AI Scanner 📸', style: TextStyle(fontSize: 20.sp)),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: isDarkMode ? AppTheme.brandGradientDark : AppTheme.brandGradient,
          ),
        ),
      ),
      body: BlocConsumer<ScanFoodCubit, ScanFoodState>(
        listener: (context, state) {
          if (state is ScanFoodSuccess) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ScanResultScreen(
                  image: _image!,
                  ingredients: state.ingredients,
                  dishResult: state.dishResponse,
                  isRecommendation: !_isDishMode,
                ),
              ),
            );
          } else if (state is ScanFoodError) {
            String title = 'ข้อผิดพลาด';
            String message = state.message;
            IconData icon = Icons.error_outline;
            Color iconColor = Colors.red;

            if (state.message == 'NO_FOOD_DATA') {
              title = 'ไม่พบข้อมูล';
              message = 'เราไม่มีข้อมูลอาหารเมนูนี้ หรือ วัตถุดิบนี้เลยครับ ลองรูปอื่นดูนะ 🤔';
              icon = Icons.search_off;
              iconColor = Colors.orange;
            } else if (state.message.contains('ไม่ใช่อาหาร')) {
              title = 'ขออภัย';
              icon = Icons.broken_image;
              iconColor = Colors.redAccent;
            } else {
              // Catch all other messages gracefully
              title = 'ขออภัย';
            }

            showDialog(
              context: context,
              builder: (context) {
                final isDarkModeDialog = context.watch<ThemeCubit>().isDarkMode;
                return AlertDialog(
                  backgroundColor: isDarkModeDialog ? const Color(0xFF1E2D4A) : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.scale)),
                title: Row(
                  children: [
                    Icon(icon, color: iconColor, size: 24.scale),
                    SizedBox(width: 10.w),
                    Text(title, style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: isDarkModeDialog ? Colors.white : Colors.black87)),
                  ],
                ),
                content: Text(message, style: TextStyle(color: isDarkModeDialog ? Colors.white70 : Colors.black54, fontSize: 14.sp)),
                actions: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.brandPurple,
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.scale)),
                    ),
                    child: Text('ตกลง', style: TextStyle(color: Colors.white, fontSize: 14.sp)),
                  ),
                ],
              );
              },
            );
          }
        },
        builder: (context, state) {
          bool isAnalyzing = state is ScanFoodLoading;

          return Container(
            width: double.infinity,
            padding: EdgeInsets.all(24.scale),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isAnalyzing) ...[
                    SizedBox(height: 100.h),
                    const CircularProgressIndicator(),
                    SizedBox(height: 24.h),
                    Text(
                      _isDishMode ? 'กำลังวิเคราะห์เมนูอาหาร...' : 'กำลังวิเคราะห์วัตถุดิบ...',
                      style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'AI กำลังประมวลผลรูปภาพของคุณ',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14.sp),
                    ),
                  ] else ...[
                    // Selection Mode
                    Container(
                      padding: EdgeInsets.all(4.scale),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey[200],
                        borderRadius: BorderRadius.circular(15.scale),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildModeToggle(
                              label: 'ทายจากรูปอาหาร',
                              icon: Icons.restaurant,
                              isSelected: _isDishMode,
                              isDarkMode: isDarkMode,
                              onTap: () => setState(() => _isDishMode = true),
                            ),
                          ),
                          Expanded(
                            child: _buildModeToggle(
                              label: 'แนะนำสูตรอาหาร',
                              icon: Icons.shopping_basket,
                              isSelected: !_isDishMode,
                              isDarkMode: isDarkMode,
                              onTap: () => setState(() => _isDishMode = false),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 32.h),
                    
                    // Preview Area
                    if (_image != null)
                      Container(
                        height: 250.h,
                        width: double.infinity,
                        margin: EdgeInsets.only(bottom: 32.h),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20.scale),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20.scale,
                              offset: Offset(0, 10.h),
                            ),
                          ],
                          image: DecorationImage(
                            image: FileImage(_image!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                    else
                      Container(
                        height: 160.h,
                        margin: EdgeInsets.only(bottom: 32.h),
                        decoration: BoxDecoration(
                          color: (_isDishMode ? AppTheme.brandBlue : AppTheme.brandPurple).withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            _isDishMode ? Icons.fastfood : Icons.kitchen,
                            size: 70.scale,
                            color: (_isDishMode ? AppTheme.brandBlue : AppTheme.brandPurple).withOpacity(0.5),
                          ),
                        ),
                      ),
            
                    Text(
                      _isDishMode ? 'คุณทานอะไรอยู่ครับ?' : 'มีวัตถุดิบอะไรบ้าง?',
                      style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      _isDishMode 
                        ? 'ให้ AI ช่วยทายว่าจานนี้คือเมนูอะไร\nคัดเลือกมาให้เพื่อให้คุณรู้ข้อมูล!'
                        : 'ถ่ายรูปวัตถุดิบในตู้เย็นหรือหน้าร้าน\nให้เราช่วยแนะนำเมนูที่น่าจะทำได้!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15.sp, color: Colors.grey[600], height: 1.5),
                    ),
                    SizedBox(height: 40.h),
            
                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: _buildSmallActionButton(
                            icon: Icons.photo_library_outlined,
                            label: 'อัลบั้ม',
                            onTap: () => _pickImage(context, ImageSource.gallery),
                            color: isDarkMode ? Colors.grey[400]! : Colors.grey[700]!,
                            isDarkMode: isDarkMode,
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: _buildSmallActionButton(
                            icon: Icons.camera_alt,
                            label: 'ถ่ายรูป',
                            onTap: () => _pickImage(context, ImageSource.camera),
                            color: _isDishMode ? AppTheme.brandBlue : AppTheme.brandPurple,
                            isPrimary: true,
                            isDarkMode: isDarkMode,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildModeToggle({required String label, required IconData icon, required bool isSelected, required VoidCallback onTap, required bool isDarkMode}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: isSelected ? (isDarkMode ? const Color(0xFF1E2D4A) : Colors.white) : Colors.transparent,
          borderRadius: BorderRadius.circular(12.scale),
          boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4.scale, offset: Offset(0, 2.h))] : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18.scale, color: isSelected ? (label == 'ทายจากรูปอาหาร' ? AppTheme.brandBlue : AppTheme.brandPurple) : Colors.grey),
            SizedBox(width: 8.w),
            Text(label, style: TextStyle(
              fontSize: 14.sp, 
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, 
              color: isSelected ? (isDarkMode ? Colors.white : Colors.black) : (isDarkMode ? Colors.white54 : Colors.grey)
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallActionButton({required IconData icon, required String label, required VoidCallback onTap, required Color color, bool isPrimary = false, required bool isDarkMode}) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 20.scale),
      label: Text(label, style: TextStyle(fontSize: 14.sp)),
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? color : (isDarkMode ? Colors.white.withOpacity(0.05) : Colors.white),
        foregroundColor: isPrimary ? Colors.white : color,
        elevation: isPrimary ? 4 : 0,
        padding: EdgeInsets.symmetric(vertical: 15.h),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.scale), side: isPrimary ? BorderSide.none : BorderSide(color: color.withOpacity(isDarkMode ? 0.3 : 0.2))),
      ),
    );
  }
}
