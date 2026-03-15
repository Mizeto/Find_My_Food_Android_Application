import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/recipe_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../bloc/home_bloc.dart';
import 'recipe_detail_screen.dart';

class SeeAllScreen extends StatelessWidget {
  final String title;
  final List<Recipe> recipes;

  const SeeAllScreen({
    super.key,
    required this.title,
    required this.recipes,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF1A1A2E) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        toolbarHeight: 80.h,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.brandGradient,
          ),
        ),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20.scale,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: EdgeInsets.all(16.scale),
        itemCount: recipes.length,
        separatorBuilder: (_, __) => SizedBox(height: 12.h),
        itemBuilder: (context, index) {
          final recipe = recipes[index];
          return GestureDetector(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RecipeDetailScreen(recipe: recipe),
                ),
              );
              if (result == true && context.mounted) {
                try {
                  final isGuest = context.read<AuthCubit>().isGuest;
                  context.read<HomeBloc>().add(LoadHomeRecipes(isGuest: isGuest));
                } catch (_) {}
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1E2D4A) : Colors.white,
                borderRadius: BorderRadius.circular(16.scale),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.06),
                    blurRadius: 8.scale,
                    offset: Offset(0, 2.h),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16.scale),
                child: SizedBox(
                  height: 120.h,
                  child: Row(
                    children: [
                      // Image
                      SizedBox(
                        width: 120.w,
                        height: 120.h,
                        child: Image.network(
                          recipe.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.grey[200],
                            child: Icon(Icons.broken_image, color: Colors.grey, size: 24.scale),
                          ),
                        ),
                      ),
                      // Content
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.all(12.scale),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Title + Like
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      recipe.title,
                                      style: TextStyle(
                                        fontSize: 15.sp,
                                        fontWeight: FontWeight.bold,
                                        color: isDarkMode ? Colors.white : Colors.black87,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  SizedBox(width: 4.w),
                                  Icon(
                                    recipe.isLiked ? Icons.favorite : Icons.favorite_border,
                                    size: 16.scale,
                                    color: recipe.isLiked ? Colors.red : Colors.grey[400],
                                  ),
                                  SizedBox(width: 2.w),
                                  Text(
                                    '${recipe.likeCount}',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.bold,
                                      color: isDarkMode ? Colors.white70 : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4.h),
                              // Description
                                Text(
                                  recipe.description,
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: isDarkMode ? Colors.white54 : Colors.grey[600],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 6.h),
                              // Tags
                                if ((recipe.tags ?? []).isNotEmpty)
                                  SizedBox(
                                    height: 22.h,
                                    child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      separatorBuilder: (_, __) => SizedBox(width: 4.w),
                                      itemCount: (recipe.tags ?? []).length > 2 ? 2 : (recipe.tags ?? []).length,
                                      itemBuilder: (context, i) {
                                        return Container(
                                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                                          decoration: BoxDecoration(
                                            color: AppTheme.brandPurple.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(10.scale),
                                          ),
                                          child: Center(
                                            child: Text(
                                              (recipe.tags ?? [])[i],
                                              style: TextStyle(
                                                fontSize: 11.sp,
                                                color: AppTheme.brandPurple,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                SizedBox(height: 6.h),
                              // Time
                                Row(
                                  children: [
                                    Icon(Icons.schedule, size: 14.scale, color: AppTheme.brandPurple),
                                    SizedBox(width: 4.w),
                                    Text(
                                      '${recipe.prepTime} นาที',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: AppTheme.brandPurple,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
