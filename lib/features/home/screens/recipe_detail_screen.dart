import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../data/models/recipe_model.dart';
import '../../../core/theme/app_theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/recipe_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/shopping_service.dart';
import '../models/food_model.dart';

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

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ... (AppBar uses displayRecipe or widget.recipe - mostly specific fields that won't change like image/title)
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            stretch: true,
            backgroundColor: AppTheme.primaryOrange,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context, _isModified),
              ),
            ),
            actions: [
               // ... existing actions
               // Favorite Button with Animation
              Container(
                margin: const EdgeInsets.all(8),
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
                    ),
                    onPressed: _toggleFavorite,
                  ),
                ),
              ),
              // Share Button
              Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.share, color: Colors.white),
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
              background: Hero(
                tag: 'recipe-image-${displayRecipe.id}',
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      displayRecipe.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        decoration: const BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                        ),
                        child: const Icon(
                          Icons.broken_image,
                          size: 60,
                          color: Colors.white54,
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
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayRecipe.title,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  offset: Offset(0, 2),
                                  blurRadius: 6,
                                  color: Colors.black45,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            children: [
                              _buildInfoChip(
                                Icons.access_time,
                                '${displayRecipe.prepTime} นาที',
                                AppTheme.primaryOrange,
                              ),
                              _buildInfoChip(
                                Icons.restaurant,
                                'สูตรอาหาร',
                                AppTheme.primaryGreen,
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
                    color: AppTheme.primaryOrange,
                    child: Text(
                      displayRecipe.description,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                        height: 1.6,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

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
                                const Text(
                                  'วัตถุดิบหลัก',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryOrange,
                                  ),
                                ),
                                const SizedBox(height: 8),
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
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal[700],
                                  ),
                                ),
                                const SizedBox(height: 8),
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
                              color: Colors.grey[500],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                  ),

                  const SizedBox(height: 20),

                  // Cooking Method
                  _buildSectionCard(
                    icon: Icons.restaurant_menu,
                    title: 'วิธีทำ 👨‍🍳',
                    color: AppTheme.primaryGreen,
                    child: _isLoadingDetails
                      ? const Center(child: CircularProgressIndicator())
                      : Text(
                          displayRecipe.cookingMethod,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                            height: 1.8,
                          ),
                        ),
                  ),

                  const SizedBox(height: 20),

                  // Add to Shopping List Button
                  _buildAddToShoppingListButton(context),

                  const SizedBox(height: 100),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: AppTheme.greenGradient,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryGreen.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_shopping_cart, color: Colors.white, size: 24),
            SizedBox(width: 12),
            Text(
              'เพิ่มวัตถุดิบลงรายการซื้อ',
              style: TextStyle(
                fontSize: 18,
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
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: AppTheme.greenGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.shopping_basket, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'เลือกวัตถุดิบที่ต้องการ',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text('ปรับเปลี่ยนจำนวนและหน่วยได้ตามต้องการ', style: TextStyle(color: Colors.grey[600])),
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
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: isSelected ? AppTheme.primaryGreen.withOpacity(0.3) : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: isSelected,
                            activeColor: AppTheme.primaryGreen,
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
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ing.ingredientName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: isSelected ? Colors.black : Colors.grey[400],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    // Quantity Stepper
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          IconButton(
                                            visualDensity: VisualDensity.compact,
                                            icon: const Icon(Icons.remove, size: 16),
                                            onPressed: !isSelected ? null : () {
                                                if (currentQty > 0.5) {
                                                  setModalState(() => quantities[index] = currentQty - 0.5);
                                                }
                                            },
                                          ),
                                          SizedBox(
                                            width: 40,
                                            child: Text(
                                              currentQty.toStringAsFixed(currentQty.truncateToDouble() == currentQty ? 0 : 1),
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          IconButton(
                                            visualDensity: VisualDensity.compact,
                                            icon: const Icon(Icons.add, size: 16),
                                            onPressed: !isSelected ? null : () {
                                                setModalState(() => quantities[index] = currentQty + 0.5);
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Unit Dropdown
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton<int>(
                                            value: currentUnitId == 0 && allUnits.isNotEmpty ? allUnits.first.unitId : currentUnitId,
                                            isExpanded: true,
                                            style: const TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.w500),
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
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      offset: const Offset(0, -4),
                      blurRadius: 10,
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
                        backgroundColor: AppTheme.primaryOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        disabledBackgroundColor: Colors.grey[300],
                        elevation: 0,
                      ),
                      child: Text(
                        'สร้างรายการซื้อ (${selectedIndices.length})',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
              content: const Row(
                children: [
                   Icon(Icons.check_circle, color: Colors.white),
                   SizedBox(width: 12),
                   Expanded(child: Text('สร้างรายการสั่งซื้อเรียบร้อยแล้ว!')),
                ],
              ),
              backgroundColor: AppTheme.primaryGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              action: SnackBarAction(
                label: 'ดูรายการ',
                textColor: Colors.white,
                onPressed: () {
                   // Navigate to Shopping List Screen
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: ing.isMainIngredient ? AppTheme.primaryOrange : Colors.teal,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              ing.ingredientName,
              style: TextStyle(
                fontSize: 16,
                color: ing.isMainIngredient ? Colors.black : Colors.grey[800],
                fontWeight: ing.isMainIngredient ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${ing.quantity.toStringAsFixed(ing.quantity.truncateToDouble() == ing.quantity ? 0 : 1)} ${ing.unitName}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.teal,
                fontWeight: FontWeight.w600,
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
