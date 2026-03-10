import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
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
      appBar: AppBar(
        title: const Text(
          'เมนูที่ถูกใจ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDarkMode ? Colors.white : Colors.black87,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadLikedRecipes,
        color: AppTheme.primaryOrange,
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text('เกิดข้อผิดพลาด: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadLikedRecipes,
              child: const Text('ลองใหม่'),
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
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite_border,
                size: 80,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'ยังไม่มีเมนูที่ถูกใจ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'หาสูตรอาหารที่ชอบและกดหัวใจเพื่อบันทึกไว้ที่นี่!',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _recipes!.length,
      itemBuilder: (context, index) {
        final recipe = _recipes![index];
        return RecipeCard(recipe: recipe, index: index);
      },
    );
  }
}
