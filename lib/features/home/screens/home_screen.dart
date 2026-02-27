import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/home_bloc.dart';
import '../../../data/models/recipe_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_cubit.dart';
import '../../auth/cubit/auth_cubit.dart';
import 'recipe_detail_screen.dart';
import 'add_food_screen.dart';
import '../widgets/recipe_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeCubit>().isDarkMode;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Gradient AppBar ที่สวยงาม
          SliverAppBar(
            expandedHeight: 140,
            floating: true,
            pinned: true,
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: AppTheme.primaryGradient,
              ),
              child: FlexibleSpaceBar(
                centerTitle: true,
                title: const Text(
                  'Find My Food 🍳',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    shadows: [
                      Shadow(
                        offset: Offset(0, 1),
                        blurRadius: 3,
                        color: Colors.black26,
                      ),
                    ],
                  ),
                ),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                  ),
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: Opacity(
                      opacity: 0.3,
                      child: Icon(
                        Icons.restaurant,
                        size: 100,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              // Theme toggle button
              IconButton(
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    isDarkMode ? Icons.light_mode : Icons.dark_mode,
                    key: ValueKey(isDarkMode),
                    color: Colors.white,
                  ),
                ),
                onPressed: () {
                  context.read<ThemeCubit>().toggleTheme();
                },
              ),
              const SizedBox(width: 8),
            ],
          ),

          // Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryOrange.withValues(alpha: 0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: TextField(
                  textInputAction: TextInputAction.search,
                  onSubmitted: (value) {
                    context.read<HomeBloc>().add(SearchRecipes(value));
                  },
                  decoration: InputDecoration(
                    hintText: 'วันนี้มีอะไรในตู้เย็น? (เช่น ไข่, หมู)',
                    prefixIcon: const Icon(Icons.search, color: AppTheme.primaryOrange),
                    suffixIcon: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.tune, color: Colors.white, size: 20),
                    ),
                    filled: true,
                    fillColor: isDarkMode ? const Color(0xFF16213E) : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Recipe Content
          SliverToBoxAdapter(
            child: BlocBuilder<HomeBloc, HomeState>(
              builder: (context, state) {
                if (state is HomeLoading) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildLoadingShimmer(isDarkMode),
                  );
                }

                if (state is HomeError) {
                  return _buildErrorWidget(state.message);
                }

                if (state is HomeLoaded) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Recommended for You (Horizontal)
                      if (state.recommendedForYou.isNotEmpty)
                        _buildHorizontalSection(
                          context: context,
                          title: 'แนะนำสำหรับคุณ ✨',
                          recipes: state.recommendedForYou,
                          isDarkMode: isDarkMode,
                        ),

                      // 2. Based on Stock (Horizontal)
                      if (state.recommendedFromStock.isNotEmpty)
                        _buildHorizontalSection(
                          context: context,
                          title: 'เมนูจากของที่มี 🥦',
                          recipes: state.recommendedFromStock,
                          isDarkMode: isDarkMode,
                        ),

                      // 3. Main List Title
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                        child: Text(
                          state.recipes.isEmpty ? '' : 'ค้นหาเมนูอร่อย 🍳',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      if (state.recipes.isEmpty)
                        _buildEmptyWidget()
                      else
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: state.recipes.length,
                            itemBuilder: (context, index) {
                              return RecipeCard(
                                recipe: state.recipes[index],
                                index: index,
                              );
                            },
                          ),
                        ),
                    ],
                  );
                }

                return _buildInitialWidget();
              },
            ),
          ),

          // Bottom padding for navigation bar
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
      floatingActionButton: Builder(
        builder: (context) {
          final authState = context.watch<AuthCubit>().state;
          if (authState is! AuthAuthenticated) return const SizedBox.shrink();

          return FloatingActionButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddFoodScreen()),
              );
              if (result == true) {
                if (context.mounted) {
                   // Refresh list
                   context.read<HomeBloc>().add(LoadHomeRecipes());
                }
              }
            },
            backgroundColor: AppTheme.primaryOrange,
            child: const Icon(Icons.add, color: Colors.white),
          );
        }
      ),
    );
  }

  Widget _buildLoadingShimmer(bool isDarkMode) {
    return Column(
      children: List.generate(
        3,
        (index) => Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: _ShimmerCard(isDarkMode: isDarkMode),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 100),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'เกิดข้อผิดพลาด 😅',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 100),
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryOrange.withValues(alpha: 0.1),
                  AppTheme.accentYellow.withValues(alpha: 0.1),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_off,
              size: 60,
              color: AppTheme.primaryOrange,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'ไม่เจอเมนูที่ค้นหาเลยครับ 😅',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ลองค้นหาด้วยคำอื่นดูนะ',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 100),
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryOrange.withValues(alpha: 0.1),
                  AppTheme.accentYellow.withValues(alpha: 0.1),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.restaurant_menu,
              size: 60,
              color: AppTheme.primaryOrange,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'พิมพ์วัตถุดิบเพื่อค้นหาเมนู 🔍',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalSection({
    required BuildContext context,
    required String title,
    required List<Recipe> recipes,
    required bool isDarkMode,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {}, // View all functionality
                child: const Text(
                  'ดูทั้งหมด',
                  style: TextStyle(color: AppTheme.primaryOrange),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              final recipe = recipes[index];
              return _RecommendationCard(recipe: recipe, isDarkMode: isDarkMode);
            },
          ),
        ),
      ],
    );
  }
}

// Shimmer Loading Card
class _ShimmerCard extends StatefulWidget {
  final bool isDarkMode;

  const _ShimmerCard({required this.isDarkMode});

  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -1, end: 2).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height: 280,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value, 0),
              colors: widget.isDarkMode
                  ? [
                      const Color(0xFF16213E),
                      const Color(0xFF1A1A2E),
                      const Color(0xFF16213E),
                    ]
                  : [
                      Colors.grey[300]!,
                      Colors.grey[100]!,
                      Colors.grey[300]!,
                    ],
            ),
          ),
        );
      },
    );
  }
}


// Recommendation Card for Horizontal List
class _RecommendationCard extends StatelessWidget {
  final Recipe recipe;
  final bool isDarkMode;

  const _RecommendationCard({required this.recipe, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => RecipeDetailScreen(recipe: recipe)),
        );
      },
      child: Container(
        width: 200,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                   Image.network(
                    recipe.imageUrl,
                    height: 130,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 130,
                      color: Colors.grey[200],
                      child: const Icon(Icons.broken_image, color: Colors.grey),
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
                      ),
                      child: const Icon(Icons.favorite_border, size: 16, color: Colors.red),
                    ),
                  ),
                ],
              ),
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
                        const Icon(Icons.favorite, size: 14, color: Colors.red),
                        const SizedBox(width: 4),
                        Text(
                          '${recipe.likeCount}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryOrange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.add, size: 16, color: AppTheme.primaryOrange),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
