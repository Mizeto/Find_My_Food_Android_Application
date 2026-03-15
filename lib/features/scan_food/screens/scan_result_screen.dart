import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../home/bloc/home_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_cubit.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../data/repositories/recipe_repository.dart';
import '../../home/widgets/recipe_card.dart';
import '../../home/models/food_model.dart';

class ScanResultScreen extends StatelessWidget {
  final File image;
  final List<String> ingredients;
  final DishAIResponse? dishResult;
  final bool isRecommendation;

  const ScanResultScreen({
    super.key,
    required this.image,
    required this.ingredients,
    this.dishResult,
    this.isRecommendation = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeCubit>().isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF1A1A2E) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(isRecommendation ? 'แนะนำสูตรอาหาร ✨' : 'ผลการทำนาย 🤖', style: TextStyle(fontSize: 20.sp)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Header
            Container(
              height: 250.h,
              width: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: FileImage(image),
                  fit: BoxFit.cover,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10.scale,
                    offset: Offset(0, 5.h),
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: EdgeInsets.all(24.0.scale),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (dishResult != null) ...[
                    if (dishResult!.recipes != null && dishResult!.recipes!.isNotEmpty) ...[
                      Text(
                        isRecommendation ? 'เมนูที่แนะนำสำหรับคุณ ✨' : 'เมนูอาหารของคุณคือ...',
                        style: TextStyle(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.brandPurple,
                        ),
                      ),
                      SizedBox(height: 20.h),
                      ...dishResult!.recipes!.asMap().entries.map((entry) {
                        return RecipeCard(
                          recipe: entry.value, 
                          index: entry.key,
                          isHorizontal: true,
                        );
                      }).toList(),
                    ] else ...[
                      Center(
                        child: Column(
                          children: [
                            SizedBox(height: 40.h),
                            Image.asset(
                              'assets/images/food_illustration.png',
                              height: 120.h,
                              fit: BoxFit.contain,
                              opacity: const AlwaysStoppedAnimation(0.6), // Dimmed for "no results"
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              'ไม่พบสูตรอาหารที่เหมาะสม 😅',
                              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                  
                  if (ingredients.isNotEmpty) ...[
                    SizedBox(height: 24.h),
                    Text(
                      'วัตถุดิบที่ตรวจพบ:',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    
                    // Ingredients List tags
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 12.h,
                      children: ingredients.map((ingredient) => Chip(
                        label: Text(
                          ingredient,
                          style: TextStyle(fontSize: 14.sp, color: isDarkMode ? Colors.white : Colors.black87),
                        ),
                        backgroundColor: isDarkMode ? AppTheme.primaryGreen.withOpacity(0.15) : AppTheme.primaryGreen.withOpacity(0.1),
                        side: BorderSide.none,
                      )).toList(),
                    ),
                  ],
                  
                  SizedBox(height: 40.h),
                  
                  // Action Buttons
                  Row(
                    children: [
                      // Toggle between Scan Again or Search based on mode
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (dishResult != null) {
                              Navigator.of(context).pop();
                            } else {
                              final query = ingredients.join(',');
                              context.read<HomeBloc>().add(SearchRecipes(query));
                              Navigator.of(context).popUntil((route) => route.isFirst);
                            }
                          },
                          icon: Icon(dishResult != null ? Icons.refresh : Icons.search, size: 24.scale),
                          label: Text(
                            dishResult != null ? 'สแกนใหม่' : 'หาเมนูอาหาร',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: dishResult != null ? AppTheme.brandPurple : AppTheme.brandBlue,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.scale)),
                            elevation: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
