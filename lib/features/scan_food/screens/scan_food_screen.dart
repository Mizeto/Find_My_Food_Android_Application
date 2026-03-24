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
import 'custom_camera_screen.dart';

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
  bool _forceSearch = false; // Default to Normal Search

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    final isGuest = context.read<AuthCubit>().isGuest;
    if (isGuest) {
      _showLoginPrompt(context);
      return;
    }

    try {
      if (source == ImageSource.camera) {
        // Use custom premium scanner camera screen
        final dynamic result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CustomScannerCameraScreen(initialIsDishMode: _isDishMode),
          ),
        );

        if (result == 'GALLERY') {
          // If user clicked album icon from custom camera, trigger gallery picker
          _pickImage(context, ImageSource.gallery);
          return;
        }

        if (result is Map && result.containsKey('file') && context.mounted) {
          setState(() {
            _image = result['file'] as File;
            _isDishMode = result['isDishMode'] as bool;
          });
          context.read<ScanFoodCubit>().analyzeImage(XFile(_image!.path), isDishPrediction: _isDishMode, forceSearch: _forceSearch);
        }
        return;
      }

      // Default gallery picker
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
        context.read<ScanFoodCubit>().analyzeImage(pickedFile, isDishPrediction: _isDishMode, forceSearch: _forceSearch);
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
            // Store reference before clearing for navigation
            final imageToPass = _image;
            
            // Clear local image state so it's fresh when user returns
            setState(() {
              _image = null;
            });

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ScanResultScreen(
                  image: imageToPass,
                  ingredients: state.ingredients,
                  dishResult: state.dishResponse,
                  isRecommendation: !_isDishMode,
                ),
              ),
            );
          } else if (state is ScanFoodError) {
            String title = 'ขออภัย';
            String message = state.message;
            IconData icon = Icons.error_outline;
            Color iconColor = Colors.red;

            if (state.message == 'NO_FOOD_DATA') {
              title = 'ไม่พบข้อมูล';
              message = 'เราไม่มีข้อมูลอาหารเมนูนี้ หรือ วัตถุดิบนี้เลยครับ ลองรูปอื่นดูนะ 🤔';
              icon = Icons.search_off;
              iconColor = Colors.orange;
            } else if (_isDishMode) {
              // Custom text for Dish Prediction Mode ("ค้นหาสูตรจากรูป")
              title = 'ขออภัย';
              message = 'รูปภาพนี้ไม่ใช่อาหาร กรุณาเลือกรูปภาพอาหาร หรือ ถ่ายภาพอาหาร';
              icon = Icons.broken_image;
              iconColor = Colors.redAccent;
            } else {
              // Ingredient analysis mode
              title = 'ไม่พบวัตถุดิบ';
              message = 'ไม่พบวัตถุดิบในรูปภาพ กรุณาลองเลือกรูปภาพ หรือ ถ่ายภาพใหม่อีกครั้ง';
              icon = Icons.search_off;
              iconColor = Colors.orange;
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
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Mode Selection
                  Container(
                    margin: EdgeInsets.only(bottom: 24.h),
                    padding: EdgeInsets.all(4.scale),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey[200],
                      borderRadius: BorderRadius.circular(15.scale),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildModeToggle(
                            label: 'ค้นหาสูตรจากรูป',
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

                  // Force Search Toggle (Visible only in Dish Mode) - Compact Pill Style
                  if (_isDishMode)
                    Padding(
                      padding: EdgeInsets.only(bottom: 24.h),
                      child: Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                          decoration: BoxDecoration(
                            color: isDarkMode ? Colors.white.withOpacity(0.08) : Colors.white,
                            borderRadius: BorderRadius.circular(30.scale),
                            border: Border.all(
                              color: _forceSearch ? AppTheme.brandPurple.withOpacity(0.5) : Colors.grey.withOpacity(0.2),
                              width: 1.2,
                            ),
                            boxShadow: isDarkMode ? [] : [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _forceSearch ? Icons.auto_awesome : Icons.search,
                                size: 18.scale,
                                color: _forceSearch ? AppTheme.brandPurple : Colors.grey,
                              ),
                              SizedBox(width: 8.w),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'ค้นหาอย่างละเอียด (Force Search)',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.bold,
                                      color: isDarkMode ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    _forceSearch ? 'เจาะจงสูตร AI 🤖' : 'หาในระบบปกติ 🔍',
                                    style: TextStyle(
                                      fontSize: 9.sp,
                                      color: isDarkMode ? Colors.white54 : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(width: 12.w),
                              SizedBox(
                                height: 28.h,
                                width: 40.w,
                                child: Transform.scale(
                                  scale: 0.7,
                                  child: Switch(
                                    value: _forceSearch,
                                    activeColor: AppTheme.brandPurple,
                                    onChanged: (val) => setState(() => _forceSearch = val),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

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

                  if (isAnalyzing) ...[
                    SizedBox(height: 24.h),
                    const CircularProgressIndicator(),
                    SizedBox(height: 16.h),
                    Text(
                      _isDishMode ? 'กำลังค้นหาสูตรจากรูป...' : 'กำลังวิเคราะห์วัตถุดิบ...',
                      style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'AI กำลังประมวลผลรูปภาพของคุณ',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13.sp),
                    ),
                  ],

                  if (!isAnalyzing) ...[
                    SizedBox(height: 16.h),
                    Text(
                      _isDishMode ? 'คุณทานอะไรอยู่ครับ?' : 'มีวัตถุดิบอะไรบ้าง?',
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      _isDishMode 
                        ? 'ให้ AI ช่วยวิเคราะห์ว่าจานนี้คือเมนูอะไร\nและค้นหาสูตรอาหารที่แสนอร่อยมาให้คุณ!'
                        : 'ถ่ายรูปวัตถุดิบในตู้เย็นหรือหน้าร้าน\nให้เราช่วยแนะนำเมนูที่น่าจะทำได้!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15.sp, color: Colors.grey[600], height: 1.5),
                    ),
                    SizedBox(height: 40.h),

                    // Action Buttons
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
            Icon(icon, size: 18.scale, color: isSelected ? (label == 'ค้นหาสูตรจากรูป' ? AppTheme.brandBlue : AppTheme.brandPurple) : Colors.grey),
            SizedBox(width: 8.w),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13.sp, 
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, 
                  color: isSelected ? (isDarkMode ? Colors.white : Colors.black) : (isDarkMode ? Colors.white54 : Colors.grey)
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
