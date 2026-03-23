import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_cubit.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../home/widgets/recipe_card.dart';
import '../../home/models/food_model.dart';
import '../../home/services/food_service.dart';

import './ai_recipe_selection_screen.dart';

class ScanResultScreen extends StatefulWidget {
  final File? image;
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
  State<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen> {
  late List<String> _currentIngredients;
  DishAIResponse? _currentDishResult;
  Set<int> _selectedTags = {};
  bool _isLoading = false;
  final RecipeService _recipeService = RecipeService();

  @override
  void initState() {
    super.initState();
    _currentIngredients = List.from(widget.ingredients);
    _currentDishResult = widget.dishResult;
  }

  Future<void> _refreshRecipes() async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    try {
      if (_currentIngredients.isEmpty) {
        if (mounted) {
          setState(() {
            _currentDishResult = DishAIResponse(top3: [], ingredients: [], recipes: []);
            _isLoading = false;
          });
        }
        return;
      }

      final tagIds = _selectedTags.toList();
      final result = await _recipeService.getRecipeByIngredientAndTag(_currentIngredients, tagIds: tagIds);
      
      if (mounted) {
        setState(() {
          if (result != null) {
            // Filter out duplicate recipes by ID to prevent Hero tag crashes
            final seenIds = <int>{};
            final uniqueRecipes = result.recipes?.where((r) => seenIds.add(r.id)).toList();

            _currentDishResult = DishAIResponse(
              top3: result.top3,
              recipes: uniqueRecipes,
              ingredients: result.ingredients.isNotEmpty ? result.ingredients : _currentDishResult?.ingredients ?? [],
              tags: (result.tags != null && result.tags!.isNotEmpty) ? result.tags : _currentDishResult?.tags,
            );
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      print('DEBUG: Error in _refreshRecipes: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addIngredientManual() {
    final controller = TextEditingController();
    final isDarkMode = context.read<ThemeCubit>().isDarkMode;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28.scale)),
        child: Container(
          padding: EdgeInsets.all(24.scale),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1A1A2E) : const Color(0xFFF0F4FF),
            borderRadius: BorderRadius.circular(28.scale),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'เพิ่มวัตถุดิบเอง 🍎',
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.brandPurple,
                ),
              ),
              SizedBox(height: 20.h),
              TextField(
                controller: controller,
                autofocus: true,
                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  hintText: 'เช่น ไข่ไก่, หมูสับ...',
                  filled: true,
                  fillColor: isDarkMode ? Colors.white10 : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.scale),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                ),
              ),
              SizedBox(height: 24.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'ยกเลิก',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16.sp),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Container(
                    decoration: BoxDecoration(
                      gradient: AppTheme.brandGradient,
                      borderRadius: BorderRadius.circular(16.scale),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.brandBlue.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        if (controller.text.trim().isNotEmpty) {
                          setState(() {
                            _currentIngredients.add(controller.text.trim());
                          });
                          Navigator.pop(context);
                          _refreshRecipes();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.scale)),
                        elevation: 0,
                      ),
                      child: Text('เพิ่ม', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeCubit>().isDarkMode;
    
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF1A1A2E) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          widget.isRecommendation ? 'ผลการวิเคราะห์วัตถุดิบ 🥗' : 'ผลการวิเคราะห์อาหาร 🤖',
          style: TextStyle(fontSize: 20.sp),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.brandGradient,
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image Header
                Container(
                  height: 250.h,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppTheme.brandPurple.withOpacity(0.1),
                    image: widget.image != null ? DecorationImage(
                      image: FileImage(widget.image!),
                      fit: BoxFit.cover,
                    ) : null,
                    gradient: widget.image == null ? AppTheme.brandGradient : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10.scale,
                        offset: Offset(0, 5.h),
                      ),
                    ],
                  ),
                  child: widget.image == null ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.auto_awesome, color: Colors.white, size: 64.scale),
                        SizedBox(height: 12.h),
                        Text(
                          'AI GENERATED RECIPE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ) : null,
                ),
                
                Padding(
                  padding: EdgeInsets.all(24.0.scale),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Detected Ingredients Section
                      if (widget.isRecommendation) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'วัตถุดิบที่ตรวจพบ:',
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : AppTheme.brandBlue,
                              ),
                            ),
                            InkWell(
                              onTap: _addIngredientManual,
                              child: Container(
                                padding: EdgeInsets.all(4.scale),
                                decoration: const BoxDecoration(
                                  gradient: AppTheme.brandGradient,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.add, color: Colors.white, size: 24.scale),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        Wrap(
                          spacing: 8.w,
                          runSpacing: 8.h,
                          children: _currentIngredients.map((ingredient) => Chip(
                            label: Text(
                              ingredient,
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: isDarkMode ? Colors.white : AppTheme.brandBlue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            backgroundColor: isDarkMode 
                                ? AppTheme.brandBlue.withOpacity(0.2) 
                                : Colors.white,
                            deleteIcon: Container(
                              decoration: BoxDecoration(
                                color: AppTheme.brandBlue.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.close, size: 14.scale, color: AppTheme.brandBlue),
                            ),
                            onDeleted: () {
                              setState(() {
                                _currentIngredients.remove(ingredient);
                              });
                              _refreshRecipes();
                            },
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.scale),
                              side: BorderSide(
                                color: AppTheme.brandBlue.withOpacity(0.5),
                                width: 1.5.scale,
                              ),
                            ),
                            elevation: 1,
                            shadowColor: Colors.black12,
                          )).toList(),
                        ),
                        SizedBox(height: 16.h),
                        const Divider(height: 1),
                        SizedBox(height: 24.h),

                      // Cooking Methods (Tags) Section
                        if (_currentDishResult?.tags != null && _currentDishResult!.tags!.isNotEmpty) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'วิธีการปรุงที่แนะนำ:',
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode ? Colors.white : AppTheme.brandBlue,
                                ),
                              ),
                              if (_selectedTags.isNotEmpty)
                                TextButton(
                                  onPressed: () => setState(() => _selectedTags.clear()),
                                  child: Text('ล้างตัวกรอง', style: TextStyle(color: Colors.red, fontSize: 13.sp)),
                                ),
                            ],
                          ),
                          SizedBox(height: 12.h),
                          Wrap(
                            spacing: 8.w,
                            runSpacing: 10.h,
                            children: _currentDishResult!.tags!.map((tag) {
                              final isSelected = _selectedTags.contains(tag.tagId);
                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    if (isSelected) {
                                      _selectedTags.remove(tag.tagId);
                                    } else {
                                      _selectedTags.add(tag.tagId);
                                    }
                                  });
                                  _refreshRecipes(); // Call API when tag is toggled
                                },
                                borderRadius: BorderRadius.circular(20.scale),
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                                  decoration: BoxDecoration(
                                    gradient: isSelected ? AppTheme.brandGradient : null,
                                    color: isSelected ? null : (isDarkMode ? Colors.white.withOpacity(0.05) : Colors.white),
                                    borderRadius: BorderRadius.circular(20.scale),
                                    border: Border.all(
                                      color: isSelected ? Colors.transparent : AppTheme.brandPurple.withOpacity(0.3),
                                      width: 1.scale,
                                    ),
                                    boxShadow: isSelected ? [
                                      BoxShadow(
                                        color: AppTheme.brandPurple.withOpacity(0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      )
                                    ] : null,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (isSelected) 
                                        Padding(
                                          padding: EdgeInsets.only(right: 4.w),
                                          child: Icon(Icons.check, size: 14.scale, color: Colors.white),
                                        ),
                                      Text(
                                        tag.tagName,
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          color: isSelected ? Colors.white : (isDarkMode ? Colors.white : AppTheme.brandPurple),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                            SizedBox(height: 24.h),
                            const Divider(height: 1),
                            SizedBox(height: 24.h),
                          ],
                        ],

                      // Recipes Section
                      if (_currentDishResult != null) ...[
                        if (_currentDishResult!.recipes != null && _currentDishResult!.recipes!.isNotEmpty) ...[
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.isRecommendation ? 'เมนูที่แนะนำสำหรับคุณ ✨' : 'สูตรอาหารใกล้เคียง...',
                                style: TextStyle(
                                  fontSize: 19.sp,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode ? Colors.white : AppTheme.brandPurple,
                                ),
                              ),
                              SizedBox(height: 16.h),
                              ..._currentDishResult!.recipes!.asMap().entries.map((entry) {
                                final index = entry.key;
                                final recipe = entry.value;
                                return Padding(
                                  padding: EdgeInsets.only(bottom: 12.h),
                                  child: RecipeCard(
                                    key: ValueKey('recipe-${recipe.id}-${index}'),
                                    recipe: recipe, 
                                    index: index,
                                    isHorizontal: true,
                                  ),
                                );
                              }).toList(),
                              
                              // New: AI Selection for unsatisfied users
                              if (_currentDishResult?.predictedNames != null && _currentDishResult!.predictedNames!.isNotEmpty) ...[
                                SizedBox(height: 12.h),
                                _buildAINewRecipeSection(hasRecipes: true),
                              ],
                            ],
                          ),
                        ] else if (!_isLoading) ...[
                          Center(
                            child: Column(
                              children: [
                                SizedBox(height: 20.h),
                                Opacity(
                                  opacity: 0.6,
                                  child: Image.asset(
                                    AppTheme.illustrationFood,
                                    height: 100.h,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                SizedBox(height: 16.h),
                                  Text(
                                    'ไม่พบสูตรอาหารที่เหมาะสม 😅',
                                    style: TextStyle(
                                      fontSize: 17.sp, 
                                      fontWeight: FontWeight.bold, 
                                      color: Colors.grey,
                                    ),
                                  ),
                                  if (_currentDishResult?.predictedNames != null && _currentDishResult!.predictedNames!.isNotEmpty) ...[
                                    SizedBox(height: 24.h),
                                    _buildAINewRecipeSection(hasRecipes: false),
                                  ],
                              ],
                            ),
                          ),
                        ],
                      ],
                      
                      SizedBox(height: 40.h),
                      
                      // Action Button
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: AppTheme.brandGradient,
                                borderRadius: BorderRadius.circular(16.scale),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.brandPurple.withOpacity(0.3),
                                    blurRadius: 8.scale,
                                    offset: Offset(0, 4.h),
                                  ),
                                ],
                              ),
                              child: ElevatedButton.icon(
                                onPressed: () => Navigator.of(context).pop(),
                                icon: Icon(Icons.refresh, size: 24.scale),
                                label: Text(
                                  'สแกนใหม่',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 16.h),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16.scale),
                                  ),
                                ),
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
          if (_isLoading)
            Container(
              color: Colors.black45,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppTheme.brandBlue),
                    SizedBox(height: 16.h),
                    Text(
                      'กำลังค้นหาสูตรอาหาร...',
                      style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAINewRecipeSection({bool hasRecipes = false}) {
    return Column(
      children: [
        if (hasRecipes) ...[
          const Divider(height: 32),
          Text(
            'ไม่ถูกใจสูตรอาหารเหล่านี้? ลองถาม AI ดูสิ! ✨',
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.brandPurple.withOpacity(0.8),
            ),
          ),
          SizedBox(height: 12.h),
        ] else ...[
          Text(
            'แต่เราพบเมนูที่ใกล้เคียงจาก AI!',
            style: TextStyle(fontSize: 14.sp, color: AppTheme.brandPurple),
          ),
          SizedBox(height: 12.h),
        ],
        ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AIRecipeSelectionScreen(
                  predictedNames: _currentDishResult!.predictedNames!,
                ),
              ),
            );
          },
          icon: const Icon(Icons.auto_awesome, color: Colors.white),
          label: const Text('สร้างสูตรอาหารใหม่ผ่าน AI ✨'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.brandPurple,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.scale)),
            elevation: 2,
          ),
        ),
      ],
    );
  }
}
