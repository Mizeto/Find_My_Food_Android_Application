import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../data/repositories/recipe_repository.dart';
import '../../../data/models/recipe_model.dart';
import '../../home/widgets/recipe_card.dart';

class LikedRecipesScreen extends StatefulWidget {
  const LikedRecipesScreen({super.key});

  @override
  State<LikedRecipesScreen> createState() => _LikedRecipesScreenState();
}

class _LikedRecipesScreenState extends State<LikedRecipesScreen> {
  List<Recipe>? _recipes;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLikedRecipes();
  }

  Future<void> _loadLikedRecipes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final recipes = await context.read<RecipeRepository>().getUserLikeRecipes();
      if (mounted) {
        setState(() {
          _recipes = recipes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF1A1A2E) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        toolbarHeight: 80.h,
        title: Text(
          'เมนูที่ถูกใจ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20.sp,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.brandGradient,
          ),
        ),
        elevation: 0,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadLikedRecipes,
        color: AppTheme.brandPurple,
        child: _buildContent(isDarkMode),
      ),
    );
  }

  Widget _buildContent(bool isDarkMode) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60.scale, color: Colors.red),
            SizedBox(height: 16.h),
            Text('เกิดข้อผิดพลาด: $_error', style: TextStyle(fontSize: 14.sp)),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: _loadLikedRecipes,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.scale)),
              ),
              child: Text('ลองใหม่', style: TextStyle(fontSize: 14.sp)),
            ),
          ],
        ),
      );
    }

    if (_recipes == null || _recipes!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24.scale),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite_border,
                size: 80.scale,
                color: isDarkMode ? Colors.red.shade300 : Colors.redAccent,
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'ยังไม่มีเมนูที่ถูกใจ',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.grey[400] : Colors.grey,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'หาสูตรอาหารที่ชอบและกดหัวใจเพื่อบันทึกไว้ที่นี่!',
              style: TextStyle(
                color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.scale),
      itemCount: _recipes!.length,
      itemBuilder: (context, index) {
        final recipe = _recipes![index];
        return RecipeCard(recipe: recipe, index: index);
      },
    );
  }
}
