import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/home_bloc.dart';
import '../../../data/models/recipe_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_cubit.dart';
import '../../auth/cubit/auth_cubit.dart';
import 'recipe_detail_screen.dart';
import 'see_all_screen.dart';
import 'add_food_screen.dart';
import '../../profile/screens/user_stock_screen.dart';
import '../widgets/recipe_card.dart';
import '../../notification/bloc/notification_bloc.dart';
import '../../notification/screens/notification_screen.dart';
import '../models/food_model.dart';
import '../services/food_service.dart';
import '../../../core/utils/responsive_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final RecipeService _recipeService = RecipeService();
  bool _isExpanded = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeCubit>().isDarkMode;

    return Scaffold(
      body: RefreshIndicator(
        edgeOffset: 120, // Start below the app bar area
        displacement: 40, // How far it moves down during the refresh
        onRefresh: () async {
          final isGuest = context.read<AuthCubit>().isGuest;
          context.read<HomeBloc>().add(LoadHomeRecipes(isGuest: isGuest));
          _searchController.clear();
        },
        child: CustomScrollView(
        slivers: [
          // Clean White AppBar with Greeting
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
                child: Row(
                  children: [
                    // Greeting Text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'สวัสดี! 👋',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          BlocBuilder<AuthCubit, AuthState>(
                            builder: (context, state) {
                              String name = 'ผู้เยี่ยมชม';
                              if (state is AuthAuthenticated) {
                                name = state.user.username;
                              }
                              return Text(
                                name,
                                style: TextStyle(
                                  fontSize: 22.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    // Notification Icon
                    BlocBuilder<NotificationBloc, NotificationState>(
                      builder: (context, state) {
                        int unreadCount = 0;
                        if (state is NotificationLoaded) {
                          unreadCount = state.unreadCount;
                        }
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const NotificationScreen(),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isDarkMode ? const Color(0xFF1E2D4A) : Colors.grey[100],
                              shape: BoxShape.circle,
                            ),
                            child: Badge(
                              label: unreadCount > 0 ? Text(unreadCount.toString()) : null,
                              isLabelVisible: unreadCount > 0,
                              backgroundColor: Colors.red,
                              child: Icon(
                                Icons.notifications_outlined,
                                color: isDarkMode ? Colors.white : Colors.grey[700],
                                size: 24.scale,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    // Profile Avatar
                    BlocBuilder<AuthCubit, AuthState>(
                      builder: (context, state) {
                        String? imageUrl;
                        String initial = '👤';
                        if (state is AuthAuthenticated) {
                          imageUrl = state.user.profileImage;
                          if (state.user.username.isNotEmpty) {
                            initial = state.user.username.substring(0, 1).toUpperCase();
                          }
                        }
                        return Container(
                          width: 44.scale,
                          height: 44.scale,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppTheme.primaryGradient,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.brandPurple.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: imageUrl != null && imageUrl.isNotEmpty
                              ? ClipOval(
                                  child: Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Center(
                                      child: Text(initial, style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                )
                              : Center(
                                  child: Text(initial, style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold)),
                                ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Search Bar — Clean Style
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 0),
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onSubmitted: (value) {
                  context.read<HomeBloc>().add(SearchRecipes(value));
                },
                decoration: InputDecoration(
                  hintText: 'ค้นหาสูตรอาหาร...',
                  hintStyle: TextStyle(color: AppTheme.brandPurple, fontSize: 15.sp),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[400], size: 24.scale),
                  suffixIcon: GestureDetector(
                    onTap: () => _showFilterSheet(context),
                    child: Container(
                      margin: EdgeInsets.all(8.scale),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2BBBAD),
                        borderRadius: BorderRadius.circular(10.scale),
                      ),
                      child: Icon(Icons.tune, color: Colors.white, size: 20.scale),
                    ),
                  ),
                  filled: true,
                  fillColor: isDarkMode ? const Color(0xFF16213E) : Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),

          // Active Filter Indicator
          SliverToBoxAdapter(
            child: BlocBuilder<HomeBloc, HomeState>(
              builder: (context, state) {
                if (state is! HomeLoaded) return const SizedBox.shrink();
                final catIds = state.selectedFilterCategoryIds;
                final tagIds = state.selectedFilterTagIds;
                if (catIds.isEmpty && tagIds.isEmpty) return const SizedBox.shrink();
                
                final totalFilters = catIds.length + tagIds.length;
                final isGuest = context.read<AuthCubit>().isGuest;
                
                return Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 0),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: AppTheme.brandPurple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20.scale),
                          border: Border.all(color: AppTheme.brandPurple.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.filter_alt, size: 16.scale, color: AppTheme.brandPurple),
                            SizedBox(width: 4.w),
                            Text(
                              'ตัวกรอง ($totalFilters)',
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.brandPurple,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 8.w),
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          context.read<HomeBloc>().add(LoadHomeRecipes(isGuest: isGuest));
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(20.scale),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.close, size: 14.scale, color: Colors.grey[600]),
                              SizedBox(width: 4.w),
                              Text(
                                'ล้างตัวกรอง',
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.brandPurple,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
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
                  final isGuest = context.watch<AuthCubit>().isGuest;
                  final isFiltering = state.selectedCategoryId != null || 
                                     state.selectedFilterCategoryIds.isNotEmpty || 
                                     state.selectedFilterTagIds.isNotEmpty ||
                                     state.searchQuery.isNotEmpty;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Gen Z Recommendations (Horizontal)
                      if (state.recommendedGenZ.isNotEmpty)
                        _buildHorizontalSection(
                          context: context,
                          title: 'เมนูสำหรับ Gen Z 🎧✨',
                          recipes: state.recommendedGenZ,
                          isDarkMode: isDarkMode,
                        ),

                      // 1. Recommended for You (Horizontal) - Hide for guests and when filtering
                      if (!isGuest && !isFiltering && state.recommendedForYou.isNotEmpty)
                        _buildHorizontalSection(
                          context: context,
                          title: 'แนะนำสำหรับคุณ ✨',
                          recipes: state.recommendedForYou,
                          isDarkMode: isDarkMode,
                        ),

                      // 2. Based on Stock (Horizontal) - Hide for guests and when filtering
                      if (!isGuest && !isFiltering && state.recommendedFromStock.isNotEmpty)
                        _buildHorizontalSection(
                          context: context,
                          title: 'เมนูจากของที่มี 🥦',
                          recipes: state.recommendedFromStock,
                          isDarkMode: isDarkMode,
                        ),

                      // 3. Category Chips - Hide when filtering
                      if (!isFiltering && state.categories.isNotEmpty)
                        _buildCategoryChips(
                          context: context,
                          categories: state.categories,
                          selectedId: state.selectedCategoryId,
                          isDarkMode: isDarkMode,
                        ),

                      // 4. Main List Title
                      if (state.recipes.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isFiltering ? 'ผลการค้นหา 🔍' : 'สูตรอาหารยอดนิยม 🔥',
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode ? Colors.white : Colors.black87,
                                ),
                              ),
                              if (!isFiltering) // Only show See all for default list
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => SeeAllScreen(
                                          title: 'เมนูที่แนะนำสำหรับคุณ ✨',
                                          recipes: state.recipes,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'See all',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.brandPurple,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                      if (state.recipes.isEmpty)
                        _buildEmptyWidget()
                      else
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _buildMasonryGrid(state.recipes),
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
    ),
    floatingActionButton: Builder(
        builder: (context) {
          final authState = context.watch<AuthCubit>().state;
          final isGuest = context.watch<AuthCubit>().isGuest;
          
          if (authState is! AuthAuthenticated || isGuest) return const SizedBox.shrink();

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (_isExpanded) ...[
                _buildFabAction(
                  icon: Icons.kitchen_outlined,
                  label: 'จัดการวัตถุดิบ (ตู้เย็น)',
                  iconColor: AppTheme.brandBlue,
                  onTap: () {
                    setState(() => _isExpanded = false);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const UserStockScreen()),
                    );
                  },
                  isDarkMode: isDarkMode,
                ),
                const SizedBox(height: 12),
                _buildFabAction(
                  icon: Icons.restaurant_menu_outlined,
                  label: 'เพิ่มสูตรอาหาร',
                  iconColor: AppTheme.brandPurple,
                  onTap: () async {
                    setState(() => _isExpanded = false);
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AddFoodScreen()),
                    );
                    if (result == true) {
                      if (context.mounted) {
                         context.read<HomeBloc>().add(LoadHomeRecipes());
                      }
                    }
                  },
                  isDarkMode: isDarkMode,
                ),
                const SizedBox(height: 12),
              ],

              GestureDetector(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: AppTheme.brandGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.brandPurple.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: AnimatedRotation(
                      turns: _isExpanded ? 0.125 : 0, // 45 degrees
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(Icons.add, color: Colors.white, size: 28),
                    ),
                  ),
                ),
              ),
            ],
          );
        }
      ),
    );
  }

  Widget _buildFabAction({
    required IconData icon,
    required String label,
    required Color iconColor,
    required VoidCallback onTap,
    required bool isDarkMode,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1E2D4A) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconColor,
              boxShadow: [
                BoxShadow(
                  color: iconColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips({
    required BuildContext context,
    required List<Map<String, dynamic>> categories,
    required int? selectedId,
    required bool isDarkMode,
  }) {
    // Emoji map for common Thai categories
    const emojiMap = {
      'อาหารคาว': '🍛',
      'ของหวาน': '🍰',
      'อาหารว่าง': '🍿',
      'อาหารจานเดียว': '🍲',
      'กับข้าว': '🥘',
      'อาหารอีสาน': '🌶️',
      'อาหารเหนือ': '🍜',
      'อาหารใต้': '🦐',
      'อาหารญี่ปุ่น': '🍱',
      'อาหารจีน': '🥟',
      'อาหารฝรั่ง': '🍕',
      'เครื่องดื่ม': '🧃',
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'หมวดหมู่',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 46,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categories.length + 1,
              itemBuilder: (context, index) {
                final isAll = index == 0;
                final isSelected = isAll
                    ? selectedId == null
                    : categories[index - 1]['category_id'] == selectedId;
                final label = isAll
                    ? 'ทั้งหมด'
                    : categories[index - 1]['category_name'] ?? '';
                final emoji = isAll ? '🍽️' : (emojiMap[label] ?? '🍴');

                return Padding(
                  padding: EdgeInsets.only(right: index < categories.length ? 10 : 0),
                  child: GestureDetector(
                    onTap: () {
                      context.read<HomeBloc>().add(
                        SelectCategory(isAll ? null : categories[index - 1]['category_id']),
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDarkMode ? const Color(0xFF2A3D5A) : Colors.black87)
                            : (isDarkMode ? const Color(0xFF1E2D4A) : Colors.white),
                        borderRadius: BorderRadius.circular(14.scale),
                        border: isSelected
                            ? null
                            : Border.all(
                                color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
                              ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        children: [
                          Text(emoji, style: TextStyle(fontSize: 16.sp)),
                          SizedBox(width: 6.w),
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : (isDarkMode ? Colors.grey[300] : Colors.grey[600]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
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
              color: AppTheme.brandPurple,
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
                  AppTheme.brandPurple.withValues(alpha: 0.1),
                  AppTheme.accentYellow.withValues(alpha: 0.1),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_off,
              size: 60,
              color: AppTheme.brandPurple,
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
                  AppTheme.brandPurple.withValues(alpha: 0.1),
                  AppTheme.accentYellow.withValues(alpha: 0.1),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.restaurant_menu,
              size: 60,
              color: AppTheme.brandPurple,
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

  Widget _buildMasonryGrid(List<Recipe> recipes) {
    final leftColumn = <Widget>[];
    final rightColumn = <Widget>[];

    for (int i = 0; i < recipes.length; i++) {
      final card = Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: RecipeCard(recipe: recipes[i], index: i),
      );
      if (i.isEven) {
        leftColumn.add(card);
      } else {
        rightColumn.add(card);
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: leftColumn,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            children: rightColumn,
          ),
        ),
      ],
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
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SeeAllScreen(title: title, recipes: recipes),
                    ),
                  );
                },
                child: Text(
                  'See all',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.brandPurple,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
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

  void _showAiPromptModal(BuildContext context) {
    final nameController = TextEditingController();
    final promptController = TextEditingController();
    final isDarkMode = context.read<ThemeCubit>().isDarkMode;
    final loadingNotifier = ValueNotifier<bool>(false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24.h,
          top: 24.h,
          left: 24.w,
          right: 24.w,
        ),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1A1A2E) : Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30.scale)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2.scale),
                ),
              ),
            ),
            SizedBox(height: 24.h),
            Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.amber[700], size: 28.scale),
                SizedBox(width: 12.w),
                Text(
                  'สร้างสูตรอาหารด้วย AI ✨',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              'บอกชื่อเมนูหรือสไตล์ที่คุณอยากทาน\nแล้วให้ AI ช่วยรังสรรค์สูตรพิเศษให้คุณครับ! ✍️🥘',
              style: TextStyle(
                fontSize: 14.sp,
                color: isDarkMode ? Colors.white70 : Colors.grey[600],
                height: 1.5,
              ),
            ),
            SizedBox(height: 24.h),
            _buildPromptField(
              controller: nameController,
              label: 'ชื่อเมนูที่ต้องการ',
              hint: 'เช่น ข้าวผัดไข่เยี่ยวม้ากะเพรากรอบ',
              icon: Icons.restaurant,
              isDarkMode: isDarkMode,
            ),
            SizedBox(height: 16.h),
            _buildPromptField(
              controller: promptController,
              label: 'สไตล์หรือรายละเอียดเพิ่มเติม (Prompt)',
              hint: 'เช่น ขอแบบรสจัดจ้าน, สำหรับ 2 ท่าน, ใช้หม้อทอดไร้น้ำมัน...',
              icon: Icons.edit_note,
              maxLines: 3,
              isDarkMode: isDarkMode,
            ),
            SizedBox(height: 32.h),
            ValueListenableBuilder<bool>(
              valueListenable: loadingNotifier,
              builder: (context, isLoading, child) {
                return SizedBox(
                  width: double.infinity,
                  height: 56.h,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : () async {
                      if (nameController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('กรุณาระบุชื่อเมนูก่อนนะครับ!'))
                        );
                        return;
                      }

                      loadingNotifier.value = true;
                      
                      try {
                        final recipes = await _recipeService.generateNewRecipeByAI(
                          nameController.text.trim(),
                          prompt: promptController.text.trim(),
                        );
                        
                        if (context.mounted) {
                          if (recipes.isNotEmpty) {
                            Navigator.pop(context); // Close modal
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddFoodScreen(initialRecipe: recipes.first),
                              ),
                            );
                          } else {
                            loadingNotifier.value = false;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('ขออภัยครับ AI ไม่สามารถสร้างสูตรได้ในขณะนี้'))
                            );
                          }
                        }
                      } catch (e) {
                        if (context.mounted) {
                          loadingNotifier.value = false;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('เกิดข้อผิดพลาด: $e'))
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.brandPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.scale)),
                      elevation: 4,
                    ),
                    child: isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text('สร้างสูตรอาหารเลย ✨', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                  ),
                );
              }
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromptField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    required bool isDarkMode,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white70 : Colors.black54,
          ),
        ),
        SizedBox(height: 8.h),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontSize: 14.sp),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13.sp),
            prefixIcon: Icon(icon, color: AppTheme.brandPurple, size: 20.scale),
            filled: true,
            fillColor: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.scale),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
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


// Recommendation Card for Horizontal List — Clean Design
class _RecommendationCard extends StatelessWidget {
  final Recipe recipe;
  final bool isDarkMode;

  const _RecommendationCard({required this.recipe, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    final isGuest = context.read<AuthCubit>().isGuest;
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => RecipeDetailScreen(recipe: recipe)),
        );
        if (result == true && context.mounted) {
          context.read<HomeBloc>().add(LoadHomeRecipes(isGuest: isGuest));
        }
      },
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E2D4A) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image with heart icon
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                  child: Image.network(
                    recipe.imageUrl,
                    height: 110,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 110,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                      ),
                      child: const Icon(Icons.broken_image, color: Colors.grey, size: 32),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      recipe.isLiked ? Icons.favorite : Icons.favorite_border,
                      size: 18,
                      color: recipe.isLiked ? Colors.red : Colors.grey[400],
                    ),
                  ),
                ),
              ],
            ),
            // Info section
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Time + Like in one row
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 13, color: Colors.grey[400]),
                      const SizedBox(width: 3),
                      Text(
                        '${recipe.prepTime} นาที',
                        style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.favorite, size: 13, color: Colors.red),
                      const SizedBox(width: 3),
                      Text(
                        '${recipe.likeCount}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                        ),
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
                              color: AppTheme.brandPurple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                (recipe.tags ?? [])[i],
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.brandPurple,
                                  fontWeight: FontWeight.w600,
                                ),
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
        ),
      ),
    );
  }
}

void _showFilterSheet(BuildContext context) {
    final recipeService = RecipeService();
    final homeBloc = context.read<HomeBloc>();
    final currentState = homeBloc.state;
    final initialCategoryIds = currentState is HomeLoaded ? currentState.selectedFilterCategoryIds : <int>[];
    final initialTagIds = currentState is HomeLoaded ? currentState.selectedFilterTagIds : <int>[];
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return FutureBuilder<Map<String, dynamic>>(
          future: recipeService.getRecipeFilterOption(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                height: 200,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: const Center(child: CircularProgressIndicator(color: AppTheme.brandPurple)),
              );
            }

            final categories = (snapshot.data?['categories'] as List<CategoryModel>?) ?? [];
            final tags = (snapshot.data?['tags'] as List<TagModel>?) ?? [];

            return _FilterSheetContent(
              categories: categories,
              tags: tags,
              homeBloc: homeBloc,
              initialCategoryIds: initialCategoryIds,
              initialTagIds: initialTagIds,
            );
          },
        );
      },
    );
  }

class _FilterSheetContent extends StatefulWidget {
  final List<CategoryModel> categories;
  final List<TagModel> tags;
  final HomeBloc homeBloc;
  final List<int> initialCategoryIds;
  final List<int> initialTagIds;

  const _FilterSheetContent({
    required this.categories,
    required this.tags,
    required this.homeBloc,
    this.initialCategoryIds = const [],
    this.initialTagIds = const [],
  });

  @override
  State<_FilterSheetContent> createState() => _FilterSheetContentState();
}

class _FilterSheetContentState extends State<_FilterSheetContent> {
  late final Set<int> _selectedCategoryIds;
  late final Set<int> _selectedTagIds;

  @override
  void initState() {
    super.initState();
    _selectedCategoryIds = Set<int>.from(widget.initialCategoryIds);
    _selectedTagIds = Set<int>.from(widget.initialTagIds);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ค้นหาด้วยตัวกรอง 🔍',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedCategoryIds.clear();
                      _selectedTagIds.clear();
                    });
                  },
                  child: const Text('ล้างทั้งหมด', style: TextStyle(color: Colors.grey)),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Scrollable Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Categories
                  if (widget.categories.isNotEmpty) ...[
                    const Row(
                      children: [
                        Icon(Icons.category, color: AppTheme.brandPurple, size: 20),
                        SizedBox(width: 8),
                        Text('หมวดหมู่', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.categories.map((cat) {
                        final isSelected = _selectedCategoryIds.contains(cat.categoryId);
                        return FilterChip(
                          label: Text(cat.categoryName),
                          selected: isSelected,
                          selectedColor: AppTheme.brandPurple.withOpacity(0.2),
                          checkmarkColor: AppTheme.brandPurple,
                          backgroundColor: Colors.grey[100],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected ? AppTheme.brandPurple : Colors.grey[300]!,
                            ),
                          ),
                          onSelected: (_) {
                            setState(() {
                              if (isSelected) {
                                _selectedCategoryIds.remove(cat.categoryId);
                              } else {
                                _selectedCategoryIds.add(cat.categoryId);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Tags
                  if (widget.tags.isNotEmpty) ...[
                    const Row(
                      children: [
                        Icon(Icons.local_offer, color: Colors.blueAccent, size: 20),
                        SizedBox(width: 8),
                        Text('แท็ก', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.tags.map((tag) {
                        final isSelected = _selectedTagIds.contains(tag.tagId);
                        return FilterChip(
                          label: Text('#${tag.tagName}'),
                          selected: isSelected,
                          selectedColor: Colors.blueAccent.withOpacity(0.2),
                          checkmarkColor: Colors.blueAccent,
                          backgroundColor: Colors.grey[100],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected ? Colors.blueAccent : Colors.grey[300]!,
                            ),
                          ),
                          onSelected: (_) {
                            setState(() {
                              if (isSelected) {
                                _selectedTagIds.remove(tag.tagId);
                              } else {
                                _selectedTagIds.add(tag.tagId);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Search Button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brandPurple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  elevation: 4,
                ),
                onPressed: () {
                  final categoryIds = _selectedCategoryIds.toList();
                  final tagIds = _selectedTagIds.toList();

                  if (categoryIds.isEmpty && tagIds.isEmpty) {
                    // No filter selected → reload all
                    widget.homeBloc.add(LoadHomeRecipes());
                  } else {
                    widget.homeBloc.add(
                      FilterSearchRecipes(categoryIds: categoryIds, tagIds: tagIds),
                    );
                  }
                  Navigator.pop(context);
                },
                child: const Text(
                  'ค้นหา',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
