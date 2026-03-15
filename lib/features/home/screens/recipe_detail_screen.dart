import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../data/models/recipe_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_cubit.dart';
import '../../../core/utils/responsive_helper.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/recipe_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/shopping_service.dart';
import '../models/food_model.dart';
import '../../../core/navigation/navigation_cubit.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;

  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen>
    with TickerProviderStateMixin {
  bool _isFavorite = false;
  int _likeCount = 0;
  late AnimationController _favoriteController;
  late Animation<double> _favoriteAnimation;
  Recipe? _fullRecipe;
  bool _isLoadingDetails = true;
  bool _isModified = false;

  @override
  void initState() {
    super.initState();
    _favoriteController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _favoriteAnimation = Tween<double>(begin: 1, end: 1.3).animate(
      CurvedAnimation(parent: _favoriteController, curve: Curves.elasticOut),
    );
    _isFavorite = widget.recipe.isLiked;
    _likeCount = widget.recipe.likeCount;
    _loadFullRecipe();
  }

  Future<void> _loadFullRecipe() async {
    try {
      // Assuming RecipeRepository is provided via RepositoryProvider in main.dart
      // If not accessible easier, we might need to look it up.
      // Based on main.dart, it uses RepositoryProvider.
      final repository = context.read<RecipeRepository>(); 
      final fullRecipe = await repository.getRecipeDetail(widget.recipe.id);
      if (mounted) {
        setState(() {
          _fullRecipe = fullRecipe;
          _isFavorite = fullRecipe.isLiked;
          _likeCount = fullRecipe.likeCount;
          _isLoadingDetails = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingDetails = false;
        });
        // Optional: show error snackbar, but we fallback to widget.recipe anyway
        print('Error loading full recipe: $e');
      }
    }
  }

  Future<void> _toggleFavorite() async {
    final repository = context.read<RecipeRepository>();
    final currentRecipeId = widget.recipe.id;

    Map<String, dynamic>? data;
    try {
      if (_isFavorite) {
        data = await repository.unlikeRecipe(currentRecipeId);
      } else {
        data = await repository.likeRecipe(currentRecipeId);
        _favoriteController.forward().then((_) {
          _favoriteController.reverse();
        });
        HapticFeedback.lightImpact();
      }

      if (data != null && mounted) {
        setState(() {
          _isFavorite = data!['is_liked'] ?? !_isFavorite;
          _likeCount = (data!['like_count'] as num?)?.toInt() ?? _likeCount;
          _isModified = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use full recipe if available, otherwise fallback to widget.recipe
    final displayRecipe = _fullRecipe ?? widget.recipe;
    final isDarkMode = context.watch<ThemeCubit>().isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF1A1A2E) : const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          // ... (AppBar uses displayRecipe or widget.recipe - mostly specific fields that won't change like image/title)
          SliverAppBar(
            expandedHeight: 300.h,
            pinned: true,
            stretch: true,
            backgroundColor: AppTheme.brandPurple,
            leading: Container(
              margin: EdgeInsets.all(8.scale),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white, size: 24.scale),
                onPressed: () => Navigator.pop(context, _isModified),
              ),
            ),
            actions: [
               // ... existing actions
               // Favorite Button with Animation
              Container(
                margin: EdgeInsets.all(8.scale),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: ScaleTransition(
                  scale: _favoriteAnimation,
                  child: IconButton(
                    icon: Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: _isFavorite ? Colors.red : Colors.white,
                      size: 24.scale,
                    ),
                    onPressed: _toggleFavorite,
                  ),
                ),
              ),
              // Share Button
              Container(
                margin: EdgeInsets.only(right: 8.w),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(Icons.share, color: Colors.white, size: 24.scale),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('แชร์สูตรอาหาร...')),
                    );
                  },
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.blurBackground,
              ],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'recipe-image-${displayRecipe.id}',
                    child: Image.network(
                      displayRecipe.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        decoration: BoxDecoration(
                          gradient: Theme.of(context).brightness == Brightness.dark 
                              ? AppTheme.brandGradientDark 
                              : AppTheme.brandGradient,
                        ),
                        child: const Icon(
                          Icons.broken_image,
                          size: 60,
                          color: Colors.white54,
                        ),
                      ),
                    ),
                  ),
                  // Gradient overlay
                  Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.7),
                          ],
                          stops: const [0.5, 1.0],
                        ),
                      ),
                    ),
                    // Title at bottom
                    Positioned(
                      bottom: 16.h,
                      left: 16.w,
                      right: 16.w,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayRecipe.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 26.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  offset: Offset(0, 2.h),
                                  blurRadius: 6.scale,
                                  color: Colors.black45,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Wrap(
                            spacing: 12.w,
                            runSpacing: 8.h,
                            children: [
                              _buildInfoChip(
                                Icons.access_time,
                                '${displayRecipe.prepTime} นาที',
                                AppTheme.brandGradient.colors[0],
                              ),
                              _buildInfoChip(
                                Icons.restaurant,
                                'สูตรอาหาร',
                                AppTheme.brandGradient.colors[1],
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

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description
                  _buildSectionCard(
                    icon: Icons.description,
                    title: 'คำอธิบาย',
                    color: AppTheme.brandPurple,
                    child: Text(
                      displayRecipe.description,
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: isDarkMode ? Colors.white70 : Colors.grey[700],
                        height: 1.6,
                      ),
                    ),
                  ),

                  SizedBox(height: 20.h),

                  // Ingredients Section
                  _buildSectionCard(
                    icon: Icons.kitchen,
                    title: 'วัตถุดิบ 🥬',
                    color: Colors.teal,
                    child: _isLoadingDetails
                      ? const Center(child: CircularProgressIndicator())
                      : (displayRecipe.ingredients != null && displayRecipe.ingredients!.isNotEmpty)
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Main Ingredients Section
                              if (displayRecipe.ingredients!.any((ing) => ing.isMainIngredient)) ...[
                                Text(
                                  'วัตถุดิบหลัก',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.brandPurple,
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                ...displayRecipe.ingredients!
                                    .where((ing) => ing.isMainIngredient)
                                    .map((ing) => _buildIngredientRow(ing)),
                                const SizedBox(height: 16),
                              ],
                              
                              // Sub Ingredients Section
                              if (displayRecipe.ingredients!.any((ing) => !ing.isMainIngredient)) ...[
                                Text(
                                  'วัตถุดิบย่อย / เครื่องปรุง',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal[700],
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                ...displayRecipe.ingredients!
                                    .where((ing) => !ing.isMainIngredient)
                                    .map((ing) => _buildIngredientRow(ing)),
                              ],
                            ],
                          )
                        : Text(
                            'ไม่มีข้อมูลวัตถุดิบ',
                            style: TextStyle(
                              fontSize: 16,
                              color: isDarkMode ? Colors.white54 : Colors.grey[500],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                  ),

                  SizedBox(height: 20.h),

                  // Cooking Method
                  _buildSectionCard(
                    icon: Icons.restaurant_menu,
                    title: 'วิธีทำ 👨‍🍳',
                    color: AppTheme.brandBlue,
                    child: _isLoadingDetails
                      ? const Center(child: CircularProgressIndicator())
                      : Text(
                          displayRecipe.cookingMethod,
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: isDarkMode ? Colors.white70 : Colors.grey[700],
                            height: 1.8,
                          ),
                        ),
                  ),

                  SizedBox(height: 20.h),

                  // Tags Section
                  if (displayRecipe.tags != null && displayRecipe.tags!.isNotEmpty) ...[
                    _buildSectionCard(
                      icon: Icons.local_offer,
                      title: 'แท็ก 🏷️',
                      color: Colors.blueAccent,
                      child: Wrap(
                        spacing: 8.w,
                        runSpacing: 8.h,
                        children: displayRecipe.tags!.map((tag) {
                          return Container(
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent.withValues(alpha: isDarkMode ? 0.2 : 0.1),
                              borderRadius: BorderRadius.circular(20.scale),
                              border: Border.all(color: Colors.blueAccent.withValues(alpha: isDarkMode ? 0.5 : 0.3)),
                            ),
                            child: Text(
                              '#$tag',
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: isDarkMode ? const Color(0xFF64B5F6) : Colors.blueAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    SizedBox(height: 20.h),
                  ],

                  // Add to Shopping List Button
                  _buildAddToShoppingListButton(context),

                  SizedBox(height: 100.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20.scale),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8.scale,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16.scale, color: color),
          SizedBox(width: 6.w),
          Text(
            text,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required Color color,
    required Widget child,
  }) {
    final isDarkMode = context.read<ThemeCubit>().isDarkMode;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.scale),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E2D4A) : Colors.white,
        borderRadius: BorderRadius.circular(20.scale),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 20.scale,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.scale),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.scale),
                ),
                child: Icon(icon, color: color, size: 24.scale),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          child,
        ],
      ),
    );
  }

  Widget _buildAddToShoppingListButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _showAddIngredientsDialog(context),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 18.h),
        decoration: BoxDecoration(
          gradient: AppTheme.greenGradient,
          borderRadius: BorderRadius.circular(30.scale),
          boxShadow: [
            BoxShadow(
              color: AppTheme.brandBlue.withValues(alpha: 0.4),
              blurRadius: 20.scale,
              offset: Offset(0, 8.h),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_shopping_cart, color: Colors.white, size: 24.scale),
            SizedBox(width: 12.w),
            Text(
              'เพิ่มวัตถุดิบลงรายการซื้อ',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddIngredientsDialog(BuildContext context) async {
    // Use user loaded recipe details if available, else fallback to widget.recipe
    final currentRecipe = _fullRecipe ?? widget.recipe;
    final ingredients = currentRecipe.ingredients ?? [];
    
    if (ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่มีข้อมูลวัตถุดิบในเมนูนี้')),
      );
      return;
    }

    // Load units
    List<UnitModel> allUnits = [];
    try {
      allUnits = await context.read<RecipeRepository>().getUnits();
    } catch (e) {
      print('Error loading units: $e');
    }

    // Selected state
    final Set<int> selectedIndices = Set.from(List.generate(ingredients.length, (i) => i));
    
    // Modified values
    final Map<int, double> quantities = {};
    final Map<int, int> unitIds = {};
    
    // Initialize with current values
    for (int i = 0; i < ingredients.length; i++) {
        quantities[i] = ingredients[i].quantity;
        unitIds[i] = ingredients[i].unitId;
    }

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30.scale)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  margin: EdgeInsets.only(top: 12.h),
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2.scale),
                  ),
                ),
              ),
              
              Padding(
                padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 0),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10.scale),
                      decoration: BoxDecoration(
                        gradient: AppTheme.greenGradient,
                        borderRadius: BorderRadius.circular(12.scale),
                      ),
                      child: Icon(Icons.shopping_basket, color: Colors.white, size: 24.scale),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Text(
                        'เลือกวัตถุดิบที่ต้องการ',
                        style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: context.read<ThemeCubit>().isDarkMode ? Colors.white : Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 8.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Text('ปรับเปลี่ยนจำนวนและหน่วยได้ตามต้องการ', style: TextStyle(color: context.read<ThemeCubit>().isDarkMode ? Colors.white54 : Colors.grey[600], fontSize: 14.sp)),
              ),

              const Divider(height: 30),

              // Ingredient List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 20),
                  itemCount: ingredients.length,
                  itemBuilder: (context, index) {
                    final ing = ingredients[index];
                    final isSelected = selectedIndices.contains(index);
                    final currentQty = quantities[index] ?? ing.quantity;
                    final currentUnitId = unitIds[index] ?? ing.unitId;
                    
                    return Container(
                      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      padding: EdgeInsets.all(12.scale),
                      decoration: BoxDecoration(
                        color: context.read<ThemeCubit>().isDarkMode ? const Color(0xFF1E2D4A) : Colors.white,
                        borderRadius: BorderRadius.circular(15.scale),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10.scale,
                            offset: Offset(0, 4.h),
                          ),
                        ],
                        border: Border.all(
                          color: isSelected ? AppTheme.brandBlue.withOpacity(0.3) : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: isSelected,
                            activeColor: AppTheme.brandBlue,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            onChanged: (val) {
                              setModalState(() {
                                if (val == true) {
                                  selectedIndices.add(index);
                                } else {
                                  selectedIndices.remove(index);
                                }
                              });
                            },
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ing.ingredientName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16.sp,
                                    color: isSelected 
                                      ? (context.read<ThemeCubit>().isDarkMode ? Colors.white : Colors.black) 
                                      : (context.read<ThemeCubit>().isDarkMode ? Colors.white30 : Colors.grey[400]),
                                  ),
                                ),
                                SizedBox(height: 12.h),
                                Row(
                                  children: [
                                    // Quantity Stepper
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(8.scale),
                                      ),
                                      child: Row(
                                        children: [
                                          IconButton(
                                            visualDensity: VisualDensity.compact,
                                            icon: Icon(Icons.remove, size: 16.scale),
                                            onPressed: !isSelected ? null : () {
                                                if (currentQty > 0.5) {
                                                  setModalState(() => quantities[index] = currentQty - 0.5);
                                                }
                                            },
                                          ),
                                          SizedBox(
                                            width: 40.w,
                                            child: Text(
                                              currentQty.toStringAsFixed(currentQty.truncateToDouble() == currentQty ? 0 : 1),
                                              textAlign: TextAlign.center,
                                              style: TextStyle(fontWeight: FontWeight.bold, color: context.read<ThemeCubit>().isDarkMode ? Colors.black87 : Colors.black87, fontSize: 14.sp),
                                            ),
                                          ),
                                          IconButton(
                                            visualDensity: VisualDensity.compact,
                                            icon: Icon(Icons.add, size: 16.scale),
                                            onPressed: !isSelected ? null : () {
                                                setModalState(() => quantities[index] = currentQty + 0.5);
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: 12.w),
                                    // Unit Dropdown
                                    Expanded(
                                      child: Container(
                                        padding: EdgeInsets.symmetric(horizontal: 10.w),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius: BorderRadius.circular(8.scale),
                                        ),
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton<int>(
                                            value: currentUnitId == 0 && allUnits.isNotEmpty ? allUnits.first.unitId : currentUnitId,
                                            isExpanded: true,
                                            style: TextStyle(fontSize: 14.sp, color: Colors.black, fontWeight: FontWeight.w500),
                                            items: allUnits.map((u) => DropdownMenuItem(
                                              value: u.unitId,
                                              child: Text(u.unitName),
                                            )).toList(),
                                            onChanged: !isSelected ? null : (val) {
                                               if (val != null) {
                                                  setModalState(() => unitIds[index] = val);
                                               }
                                            },
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
                    );
                  },
                ),
              ),

              // Action Button
              Container(
                padding: EdgeInsets.all(24.scale),
                decoration: BoxDecoration(
                  color: context.read<ThemeCubit>().isDarkMode ? const Color(0xFF1E2D4A) : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      offset: Offset(0, -4.h),
                      blurRadius: 10.scale,
                    ),
                  ],
                ),
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: selectedIndices.isEmpty ? null : () async {
                        Navigator.pop(context);
                        
                        // Prepare custom selections
                        final List<Map<String, dynamic>> customSelections = [];
                        for (final index in selectedIndices) {
                            final ing = ingredients[index];
                            final qty = quantities[index] ?? ing.quantity;
                            final unitId = unitIds[index] ?? ing.unitId;
                            
                            customSelections.add({
                                'item_name': ing.ingredientName,
                                'quantity': qty,
                                'unit_id': unitId,
                                'is_check': false,
                            });
                        }
                        
                        _createShoppingListFromCustomSelection(customSelections);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.brandPurple,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.scale)),
                        disabledBackgroundColor: Colors.grey[300],
                        elevation: 0,
                      ),
                      child: Text(
                        'สร้างรายการซื้อ (${selectedIndices.length})',
                        style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createShoppingListFromCustomSelection(List<Map<String, dynamic>> itemsPayload) async {
    // Show Loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final success = await ShoppingService().createNewShoppingList(
        shoppingType: 'recipe',
        listName: widget.recipe.title,
        items: itemsPayload,
      );

      if (context.mounted) {
        Navigator.pop(context); // Close loading
        
        if (success) {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                   const Icon(Icons.check_circle, color: Colors.white),
                   SizedBox(width: 12.w),
                   const Expanded(
                     child: Text(
                       'สร้างรายการสั่งซื้อเรียบร้อยแล้ว!',
                       style: TextStyle(fontWeight: FontWeight.bold),
                     ),
                   ),
                ],
              ),
              backgroundColor: AppTheme.brandBlue,
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 100.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.scale)),
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'ดูรายการ',
                textColor: Colors.white,
                onPressed: () {
                  // Switch to Shopping List tab
                  context.read<NavigationCubit>().setTab(2);
                  // Pop back to main navigation
                  Navigator.pop(context);
                },
              ),
            ),
          );
        } else {
           _showError('ไม่สามารถสร้างรายการได้');
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        _showError('เกิดข้อผิดพลาด: $e');
      }
    }
  }

  Widget _buildIngredientRow(RecipeIngredientItem ing) {
    final isDarkMode = context.read<ThemeCubit>().isDarkMode;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        children: [
          Container(
            width: 8.scale,
            height: 8.scale,
            decoration: BoxDecoration(
              color: ing.isMainIngredient ? AppTheme.brandPurple : Colors.teal,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              ing.ingredientName,
              style: TextStyle(
                fontSize: 16.sp,
                color: ing.isMainIngredient 
                  ? (isDarkMode ? Colors.white : Colors.black) 
                  : (isDarkMode ? Colors.white70 : Colors.grey[800]),
                fontWeight: ing.isMainIngredient ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.teal.withValues(alpha: 0.2) : Colors.teal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.scale),
            ),
            child: Text(
              '${ing.quantity.toStringAsFixed(ing.quantity.truncateToDouble() == ing.quantity ? 0 : 1)} ${ing.unitName}',
              style: TextStyle(
                fontSize: 14.sp,
                color: isDarkMode ? const Color(0xFF4DB6AC) : Colors.teal[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
