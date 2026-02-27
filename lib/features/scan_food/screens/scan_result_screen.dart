import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../home/bloc/home_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/recipe_repository.dart';
import '../../home/widgets/recipe_card.dart';
import '../../home/models/food_model.dart';

class ScanResultScreen extends StatelessWidget {
  final File image;
  final List<String> ingredients;
  final DishAIResponse? dishResult;

  const ScanResultScreen({
    super.key,
    required this.image,
    required this.ingredients,
    this.dishResult,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(dishResult != null ? 'ผลการทำนาย 🤖' : 'ผลการวิเคราะห์ 🤖'),
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
                      const Text(
                        'เมนูอาหารที่คุณทานคือ...',
                        style: TextStyle(
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
                              'ไม่พบสูตรอาหารนี้ทีครับ 😅',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ] else ...[
                    const Text(
                      'วัตถุดิบที่พบ:',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryOrange,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Ingredients List tags
                    Wrap(
                      spacing: 8,
                      runSpacing: 12,
                      children: ingredients.map((ingredient) => Chip(
                        avatar: const CircleAvatar(
                          backgroundColor: Colors.white,
                          child: Icon(Icons.check, size: 16, color: AppTheme.primaryGreen),
                        ),
                        label: Text(
                          ingredient,
                          style: const TextStyle(fontSize: 16),
                        ),
                        backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                        side: BorderSide.none,
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      )).toList(),
                    ),
                  ],
                  
                  const SizedBox(height: 40),
                  
                  // Action Buttons
                  Row(
                    children: [
                      if (dishResult == null) ...[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final scaffoldMessenger = ScaffoldMessenger.of(context);
                              final repository = context.read<RecipeRepository>();
                              
                              bool allSuccess = true;
                              for (final ingredient in ingredients) {
                                final success = await repository.addUserStock(UserStockRequest(
                                  ingredientId: 0, // AI scan returns names, id unknown
                                  itemName: ingredient,
                                  quantity: 1,
                                  unitId: 0,
                                  expireDate: DateTime.now().add(const Duration(days: 7)).toIso8601String().split('T')[0],
                                  storageLocation: 'Fridge',
                                ));
                                if (!success) allSuccess = false;
                              }

                              if (allSuccess) {
                                scaffoldMessenger.showSnackBar(
                                  const SnackBar(content: Text('บันทึกวัตถุดิบลงตู้เย็นแล้ว! 🥦'), backgroundColor: AppTheme.primaryGreen),
                                );
                              } else {
                                scaffoldMessenger.showSnackBar(
                                  const SnackBar(content: Text('บันทึกไม่สำเร็จบางรายการ'), backgroundColor: Colors.red),
                                );
                              }
                            },
                            icon: const Icon(Icons.kitchen),
                            label: const Text('เก็บเข้าตู้เย็น'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primaryGreen,
                              side: const BorderSide(color: AppTheme.primaryGreen),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (dishResult == null)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // Navigate to Home and Search
                              final query = ingredients.join(',');
                              
                              context.read<HomeBloc>().add(SearchRecipes(query));
                              Navigator.of(context).popUntil((route) => route.isFirst);
                            },
                            icon: const Icon(Icons.search),
                            label: const Text(
                              'หาเมนูจากวัตถุดิบ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 5,
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
