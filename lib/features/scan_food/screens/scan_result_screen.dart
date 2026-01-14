import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../home/bloc/home_bloc.dart';
import '../../../core/theme/app_theme.dart';
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
                    const Text(
                      'เมนูอาหารที่คุณทานคือ...',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryOrange,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ...dishResult!.top3.asMap().entries.map((entry) {
                      final prediction = entry.value;
                      final isTop = entry.key == 0;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isTop ? AppTheme.primaryOrange.withOpacity(0.1) : Colors.grey[100],
                          borderRadius: BorderRadius.circular(15),
                          border: isTop ? Border.all(color: AppTheme.primaryOrange.withOpacity(0.3)) : null,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  prediction.className,
                                  style: TextStyle(
                                    fontSize: isTop ? 20 : 16,
                                    fontWeight: isTop ? FontWeight.bold : FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '${(prediction.confidence * 100).toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    color: isTop ? AppTheme.primaryOrange : Colors.grey[600],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(5),
                              child: LinearProgressIndicator(
                                value: prediction.confidence,
                                backgroundColor: Colors.grey[300],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isTop ? AppTheme.primaryOrange : Colors.grey[400]!,
                                ),
                                minHeight: 8,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
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
                  
                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Navigate to Home and Search
                        final query = dishResult != null 
                            ? dishResult!.top3.first.className 
                            : ingredients.join(',');
                        
                        context.read<HomeBloc>().add(SearchRecipes(query));
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                      icon: const Icon(Icons.search),
                      label: Text(
                        dishResult != null ? 'ดูวิธีทำเมนูนี้' : 'ค้นหาเมนูจากวัตถุดิบนี้',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: dishResult != null ? AppTheme.primaryOrange : AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 5,
                      ),
                    ),
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
