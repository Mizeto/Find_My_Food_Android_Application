import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/models/recipe_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../bloc/home_bloc.dart';
import '../screens/recipe_detail_screen.dart';

class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final int index;
  final bool isHorizontal;

  const RecipeCard({
    super.key,
    required this.recipe,
    required this.index,
    this.isHorizontal = false,
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
            context.read<HomeBloc>().add(LoadHomeRecipes(isGuest: isGuest));
          }
        },
        child: Container(
          child: Card(
            clipBehavior: Clip.antiAlias,
            elevation: isHorizontal ? 2 : 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isVisibleHorizontal ? 15 : 20)),
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
                child: Image.network(
                  recipe.imageUrl,
                  height: 110, // Matched to horizontal cards for consistency
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 110,
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    recipe.isLiked ? Icons.favorite : Icons.favorite_border,
                    size: 18,
                    color: recipe.isLiked ? Colors.red : Colors.grey,
                  ),
                ),
              ),
            ],
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipe.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${recipe.prepTime} นาที',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.favorite,
                      size: 14,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${recipe.likeCount}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryOrange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.add,
                        size: 16,
                        color: AppTheme.primaryOrange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
  }

  Widget _buildHorizontalLayout() {
    return SizedBox(
      height: 120, // Reduced size
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image on Left
          Hero(
            tag: 'recipe-image-${recipe.id}',
            child: SizedBox(
              width: 120,
              height: 120,
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
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          recipe.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                       Row(
                        children: [
                          Icon(
                            recipe.isLiked ? Icons.favorite : Icons.favorite_border,
                            size: 12,
                            color: recipe.isLiked ? Colors.red : Colors.grey,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${recipe.likeCount}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    recipe.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 12, color: AppTheme.primaryOrange),
                      const SizedBox(width: 4),
                      Text(
                        '${recipe.prepTime} นาที',
                        style: const TextStyle(fontSize: 11, color: AppTheme.primaryOrange, fontWeight: FontWeight.w600),
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
