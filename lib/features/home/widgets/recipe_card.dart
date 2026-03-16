import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/models/recipe_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../bloc/home_bloc.dart';
import '../screens/recipe_detail_screen.dart';
import '../../../../core/utils/responsive_helper.dart';

class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final int index;
  final bool isHorizontal;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const RecipeCard({
    super.key,
    required this.recipe,
    required this.index,
    this.isHorizontal = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + (index * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: () async {
          final isGuest = context.read<AuthCubit>().isGuest;
          final result = await Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  RecipeDetailScreen(recipe: recipe),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              transitionDuration: const Duration(milliseconds: 300),
            ),
          );

          if (result == true && context.mounted) {
            try {
              context.read<HomeBloc>().add(LoadHomeRecipes(isGuest: isGuest));
            } catch (_) {
              // HomeBloc not available in this route (e.g. LikedRecipes, MyRecipes)
            }
          }
        },
        child: Container(
          child: Card(
            clipBehavior: Clip.antiAlias,
            elevation: isHorizontal ? 2 : 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isVisibleHorizontal ? 15.scale : 20.scale)),
            child: isHorizontal ? _buildHorizontalLayout() : _buildVerticalLayout(),
          ),
        ),
      ),
    );
  }

  bool get isVisibleHorizontal => isHorizontal;

  Widget _buildVerticalLayout() {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image with Heart Overlay
          Stack(
            children: [
              Hero(
                tag: 'recipe-image-${recipe.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20.scale)),
                  child: Image.network(
                    recipe.imageUrl,
                    height: 110.h,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 110.h,
                      color: Colors.grey[200],
                      child: Icon(Icons.broken_image, color: Colors.grey, size: 24.scale),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Row(
                  children: [
                    if (onEdit != null)
                      GestureDetector(
                        onTap: onEdit,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.edit_outlined,
                            size: 18.scale,
                            color: AppTheme.brandPurple,
                          ),
                        ),
                      ),
                    if (onEdit != null) const SizedBox(width: 8),
                    if (onDelete != null)
                      GestureDetector(
                        onTap: onDelete,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.delete_outline,
                            size: 18.scale,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    if (onDelete != null) const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        recipe.isLiked ? Icons.favorite : Icons.favorite_border,
                        size: 18.scale,
                        color: recipe.isLiked ? Colors.red : Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipe.title,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 13, color: Colors.grey[400]),
                    const SizedBox(width: 3),
                    Text(
                      '${recipe.prepTime} นาที',
                      style: TextStyle(fontSize: 11.sp, color: Colors.grey[400]),
                    ),
                    SizedBox(width: 8.w),
                    Icon(Icons.favorite, size: 13.scale, color: Colors.red),
                    SizedBox(width: 3.w),
                    Text(
                      '${recipe.likeCount}',
                      style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                // Tags
                if ((recipe.tags ?? []).isNotEmpty) ...[
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 22,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      separatorBuilder: (_, __) => const SizedBox(width: 4),
                      itemCount: (recipe.tags ?? []).length > 2 ? 2 : (recipe.tags ?? []).length,
                      itemBuilder: (context, i) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppTheme.brandPurple.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6.scale),
                          ),
                          child: Text(
                            (recipe.tags ?? [])[i],
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: AppTheme.brandPurple.withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      );
  }

  Widget _buildHorizontalLayout() {
    return SizedBox(
      height: 120.h, // Reduced size
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image on Left
          Hero(
            tag: 'recipe-image-${recipe.id}',
            child: SizedBox(
              width: 120.w,
              height: 120.h,
              child: Image.network(
                recipe.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
            ),
          ),
          
          // Content on Right
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          recipe.title,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                       Row(
                        children: [
                              if (onEdit != null)
                                GestureDetector(
                                  onTap: onEdit,
                                  child: Icon(
                                    Icons.edit_outlined,
                                    size: 14.scale,
                                    color: AppTheme.brandPurple,
                                  ),
                                ),
                              if (onEdit != null) SizedBox(width: 8.w),
                              if (onDelete != null)
                                GestureDetector(
                                  onTap: onDelete,
                                  child: Icon(
                                    Icons.delete_outline,
                                    size: 14.scale,
                                    color: Colors.red,
                                  ),
                                ),
                              if (onDelete != null) SizedBox(width: 8.w),
                               Icon(
                                recipe.isLiked ? Icons.favorite : Icons.favorite_border,
                                size: 12.scale,
                                color: recipe.isLiked ? Colors.red : Colors.grey,
                              ),
                              SizedBox(width: 2.w),
                              Text(
                                '${recipe.likeCount}',
                                style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold),
                              ),
                        ],
                      ),
                    ],
                  ),
                  Flexible(
                    child: Text(
                      recipe.description,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Horizontal Layout Tags
                  if ((recipe.tags ?? []).isNotEmpty) ...[
                    SizedBox(
                      height: 20,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        separatorBuilder: (_, __) => const SizedBox(width: 4),
                        itemCount: (recipe.tags ?? []).length > 2 ? 2 : (recipe.tags ?? []).length,
                        itemBuilder: (context, i) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.brandPurple.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(6.scale),
                            ),
                            child: Center(
                              child: Text(
                                (recipe.tags ?? [])[i],
                                style: TextStyle(
                                  fontSize: 8.sp,
                                  color: AppTheme.brandPurple.withOpacity(0.8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 12, color: AppTheme.brandPurple),
                      const SizedBox(width: 4),
                      Text(
                        '${recipe.prepTime} นาที',
                        style: const TextStyle(fontSize: 11, color: AppTheme.brandPurple, fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
