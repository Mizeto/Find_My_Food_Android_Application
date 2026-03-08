import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../home/bloc/home_bloc.dart';
import '../../../core/theme/app_theme.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: Text(isRecommendation ? 'แนะนำสูตรอาหาร ✨' : 'ผลการทำนาย 🤖'),
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
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: FileImage(image),
                  fit: BoxFit.cover,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (dishResult != null) ...[
                    if (dishResult!.recipes != null && dishResult!.recipes!.isNotEmpty) ...[
                      Text(
                        isRecommendation ? 'เมนูที่แนะนำสำหรับคุณ ✨' : 'เมนูอาหารของคุณคือ...',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryOrange,
                        ),
                      ),
                      const SizedBox(height: 20),
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
                            const SizedBox(height: 40),
                            const Icon(Icons.sentiment_dissatisfied, size: 80, color: Colors.grey),
                            const SizedBox(height: 16),
                            const Text(
                              'ไม่พบสูตรอาหารที่เหมาะสม 😅',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                  
                  if (ingredients.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'วัตถุดิบที่ตรวจพบ:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Ingredients List tags
                    Wrap(
                      spacing: 8,
                      runSpacing: 12,
                      children: ingredients.map((ingredient) => Chip(
                        label: Text(
                          ingredient,
                          style: const TextStyle(fontSize: 14),
                        ),
                        backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                        side: BorderSide.none,
                      )).toList(),
                    ),
                  ],
                  
                  const SizedBox(height: 40),
                  
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
                          icon: Icon(dishResult != null ? Icons.refresh : Icons.search),
                          label: Text(
                            dishResult != null ? 'สแกนใหม่' : 'หาเมนูอาหาร',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: dishResult != null ? AppTheme.primaryOrange : AppTheme.primaryGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
