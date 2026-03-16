import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../data/repositories/recipe_repository.dart';
import '../../../data/models/recipe_model.dart';
import '../../home/widgets/recipe_card.dart';
import '../../home/screens/add_food_screen.dart';

class MyRecipesScreen extends StatefulWidget {
  const MyRecipesScreen({super.key});

  @override
  State<MyRecipesScreen> createState() => _MyRecipesScreenState();
}

class _MyRecipesScreenState extends State<MyRecipesScreen> {
  List<Recipe>? _recipes;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMyRecipes();
  }

  Future<void> _loadMyRecipes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final recipes = await context.read<RecipeRepository>().getMyRecipes();
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

  Future<void> _editRecipe(Recipe recipe) async {
    try {
      setState(() => _isLoading = true);
      final recipeModel = await context.read<RecipeRepository>().getRecipeModelDetail(recipe.id);
      
      if (mounted) {
        setState(() => _isLoading = false);
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddFoodScreen(initialRecipe: recipeModel),
          ),
        );

        if (result == true) {
          _loadMyRecipes();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ไม่สามารถโหลดข้อมูลสูตรอาหารได้: $e')),
        );
      }
    }
  }

  Future<void> _deleteRecipe(Recipe recipe) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('ลบสูตรอาหาร', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.red)),
        content: Text('คุณต้องการลบ "${recipe.title}" ใช่หรือไม่?', style: TextStyle(fontSize: 16.sp)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('ยกเลิก', style: TextStyle(fontSize: 14.sp)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('ลบ', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        setState(() => _isLoading = true);
        final success = await context.read<RecipeRepository>().deleteMyRecipe(recipe.id);
        
        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('ลบสูตรอาหารเรียบร้อยแล้ว')),
            );
            _loadMyRecipes();
          } else {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('ไม่สามารถลบสูตรอาหารได้')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
          );
        }
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
          'สูตรอาหารของฉัน',
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
        onRefresh: _loadMyRecipes,
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
              onPressed: _loadMyRecipes,
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
                color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.restaurant_menu,
                size: 80.scale,
                color: isDarkMode ? Colors.grey[400] : Colors.grey,
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'ยังไม่มีสูตรอาหารที่คุณสร้าง',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.grey[400] : Colors.grey,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'เริ่มสร้างสูตรอาหารแสนอร่อยของคุณได้เลย!',
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
        return RecipeCard(
          recipe: recipe, 
          index: index,
          onEdit: () => _editRecipe(recipe),
          onDelete: () => _deleteRecipe(recipe),
        );
      },
    );
  }
}
