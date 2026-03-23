import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_cubit.dart';
import '../../../core/navigation/navigation_cubit.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../bloc/home_bloc.dart';
import '../services/food_service.dart';
import '../models/food_model.dart';

class AddFoodScreen extends StatefulWidget {
  final RecipeModel? initialRecipe;
  const AddFoodScreen({super.key, this.initialRecipe});

  @override
  State<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends State<AddFoodScreen> {
  final _formKey = GlobalKey<FormState>();
  final _recipeService = RecipeService();
  bool _isLoading = false;

  // Form Controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _timeController = TextEditingController();
  
  // Image
  File? _selectedImage;
  String? _aiGeneratedUrl;
  final ImagePicker _picker = ImagePicker();

  // Data
  List<UnitModel> _units = [];
  List<CategoryModel> _availableCategories = [];
  List<TagModel> _availableTags = [];
  
  // Selected
  final Set<int> _selectedCategoryIds = {};
  final Set<int> _selectedTagIds = {};
  
  // Dynamic Lists (with Controllers for robust UI updates)
  List<Map<String, dynamic>> _ingredients = [];
  final List<TextEditingController> _ingredientNameControllers = [];
  final List<TextEditingController> _ingredientQtyControllers = [];
  
  List<String> _steps = [];
  final List<TextEditingController> _stepControllers = [];
  
  bool _isPublic = true;

  @override
  void initState() {
    super.initState();
    _loadUnits();
    _loadCategoriesAndTags();
    _initializeForEdit();
  }

  void _initializeForEdit() {
    if (widget.initialRecipe != null) {
      final recipe = widget.initialRecipe!;
      print('DEBUG: Initializing AddFoodScreen with recipe: ${recipe.recipeName}');
      print('DEBUG: Ingredients count: ${recipe.ingredients?.length ?? 0}');
      print('DEBUG: Steps count: ${recipe.steps?.length ?? 0}');

      _nameController.text = recipe.recipeName;
      _descriptionController.text = recipe.description;
      _timeController.text = recipe.cookingTimeMin > 0 ? recipe.cookingTimeMin.toString() : '';
      _isPublic = recipe.isPublic;
      
      if (recipe.imageUrl.isNotEmpty) {
        if (recipe.imageUrl.startsWith('http')) {
          _aiGeneratedUrl = recipe.imageUrl;
        }
      }

      // Initial ID matching (if IDs already present)
      if (recipe.categoryDetails != null) {
        for (var cat in recipe.categoryDetails!) {
          if (cat.categoryId != 0) _selectedCategoryIds.add(cat.categoryId);
        }
      }
      if (recipe.tagDetails != null) {
        for (var tag in recipe.tagDetails!) {
          if (tag.tagId != 0) _selectedTagIds.add(tag.tagId);
        }
      }

      // Ingredients
      _ingredientNameControllers.clear();
      _ingredientQtyControllers.clear();
      if (recipe.ingredients != null && recipe.ingredients!.isNotEmpty) {
        _ingredients = recipe.ingredients!.map((i) {
          _ingredientNameControllers.add(TextEditingController(text: i.ingredientName));
          _ingredientQtyControllers.add(TextEditingController(text: i.quantityValue > 0 ? i.quantityValue.toString().replaceAll(RegExp(r'\.0$'), '') : '1'));
          return <String, dynamic>{
            'name': i.ingredientName,
            'qty': i.quantityValue > 0 ? i.quantityValue.toString().replaceAll(RegExp(r'\.0$'), '') : '1',
            'unit_id': i.unitId != 0 ? i.unitId : null,
            'id': i.ingredientId,
            'main': i.isMainIngredient,
          };
        }).toList();
      } else {
        _ingredients = [{'name': '', 'qty': '1', 'unit_id': null, 'id': 0, 'main': true}];
        _ingredientNameControllers.add(TextEditingController());
        _ingredientQtyControllers.add(TextEditingController(text: '1'));
      }

      // Steps
      _stepControllers.clear();
      if (recipe.steps != null && recipe.steps!.isNotEmpty) {
        _steps = recipe.steps!.map((s) {
          _stepControllers.add(TextEditingController(text: s.instruction));
          return s.instruction;
        }).toList();
      } else {
        _steps = [''];
        _stepControllers.add(TextEditingController());
      }
      
      // Safety setState (though usually not needed in initState)
      if (mounted) setState(() {});
      
      // If we already have categories/tags loaded (unlikely during initState, but possible on hot reload)
      if (_availableCategories.isNotEmpty || _availableTags.isNotEmpty) {
        _matchAiDataToDb();
      }
    } else {
      // New Recipe: Initialize with one empty row
      _ingredients = [{'name': '', 'qty': '1', 'unit_id': null, 'id': 0, 'main': true}];
      _ingredientNameControllers.add(TextEditingController());
      _ingredientQtyControllers.add(TextEditingController(text: '1'));
      _steps = [''];
      _stepControllers.add(TextEditingController());
    }
  }

  void _matchAiDataToDb([RecipeModel? optionalRecipe]) {
    final recipe = optionalRecipe ?? widget.initialRecipe;
    if (recipe == null) return;

    print('DEBUG: _matchAiDataToDb starting for "${recipe.recipeName}"');
    
    // NO INTERNAL setState HERE!
    // The caller (like initState or _showAiPromptDialog's setState) should handle it.
    
    // 1. Match Categories by Name (Fuzzy)
    if (recipe.categoryDetails != null) {
      for (var aiCat in recipe.categoryDetails!) {
        final aiName = aiCat.categoryName.trim().toLowerCase();
        if (aiName.isEmpty) continue;
        
        final match = _availableCategories.firstWhere(
          (c) => c.categoryName.trim().toLowerCase() == aiName || 
                 aiName.contains(c.categoryName.trim().toLowerCase()) ||
                 c.categoryName.trim().toLowerCase().contains(aiName), 
          orElse: () => CategoryModel(categoryId: -1, categoryName: '')
        );
        if (match.categoryId != -1) {
          _selectedCategoryIds.add(match.categoryId);
          print('DEBUG: Matched Category: ${match.categoryName}');
        }
      }
    }

    // 2. Match Tags by Name (Fuzzy)
    final allAiTagNames = <String>{};
    if (recipe.tagDetails != null) {
      allAiTagNames.addAll(recipe.tagDetails!.map((t) => t.tagName.trim().toLowerCase()));
    }
    if (recipe.tags != null) {
      allAiTagNames.addAll(recipe.tags!.map((t) => t.trim().toLowerCase()));
    }

    for (var aiTagName in allAiTagNames) {
      if (aiTagName.isEmpty) continue;
      
      final match = _availableTags.firstWhere(
        (t) => t.tagName.trim().toLowerCase() == aiTagName ||
               aiTagName.contains(t.tagName.trim().toLowerCase()) ||
               t.tagName.trim().toLowerCase().contains(aiTagName),
        orElse: () => TagModel(tagId: -1, tagName: '')
      );
      if (match.tagId != -1) {
        _selectedTagIds.add(match.tagId);
        print('DEBUG: Matched Tag: ${match.tagName}');
      }
    }
    
    // 3. Match Ingredient Units by Name
    for (var item in _ingredients) {
      if (item['unit_id'] != null) continue; // Skip if already has ID
      final itemName = item['name']?.toString().toLowerCase() ?? '';
      
      // Look for unit name in recipe models
      if (recipe.ingredients != null) {
        final aiIng = recipe.ingredients!.firstWhere(
          (i) => i.ingredientName.toLowerCase() == itemName,
          orElse: () => RecipeIngredient(ingredientId: 0, ingredientName: '', quantityValue: 0, unitId: 0, unitName: '')
        );
        
        if (aiIng.unitName.isNotEmpty) {
          final unitMatch = _units.firstWhere(
            (u) => u.unitName.toLowerCase() == aiIng.unitName.toLowerCase(),
            orElse: () => UnitModel(unitId: -1, unitName: '')
          );
          if (unitMatch.unitId != -1) {
            item['unit_id'] = unitMatch.unitId;
            print('DEBUG: Matched Unit ${unitMatch.unitName} for ${item['name']}');
          }
        }
      }
    }
  }

  Future<void> _loadUnits() async {
    try {
      final units = await _recipeService.getAllUnits();
      if (mounted) {
        setState(() {
          _units = units;
        });
        
        if (widget.initialRecipe != null) {
          _matchAiDataToDb();
        }
      }
    } catch (e) {
      print('Error loading units: $e');
    }
  }

  Future<void> _loadCategoriesAndTags() async {
    try {
      final categories = await _recipeService.getRecipeCategory();
      final tags = await _recipeService.getRecipeTag();
      if (mounted) {
        setState(() {
          _availableCategories = categories;
          _availableTags = tags;
        });
        
        // After loading, attempt to match AI recommendations
        if (widget.initialRecipe != null) {
          _matchAiDataToDb();
        }
      }
    } catch (e) {
      print('Error loading categories/tags: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _timeController.dispose();
    for (var c in _ingredientNameControllers) {
      c.dispose();
    }
    for (var c in _ingredientQtyControllers) {
      c.dispose();
    }
    for (var c in _stepControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (pickedFile != null) {
         setState(() {
           _selectedImage = File(pickedFile.path);
           _aiGeneratedUrl = null; // Clear AI URL if user picks local image
         });
      }
    } catch (e) {
      _showErrorDialog('เลือกรูปภาพไม่สำเร็จ: $e');
    }
  }

  Future<void> _generateImageWithAI() async {
    if (_nameController.text.isEmpty) {
      _showErrorDialog('กรุณาระบุชื่อเมนูก่อนสร้างรูปภาพครับ!');
      return;
    }

    setState(() {
       _isLoading = true;
       _aiGeneratedUrl = null; // Clear old state
       _selectedImage = null;
    });
    try {
      final recipeName = _nameController.text.trim();
      final ingredients = _ingredients
          .where((i) => i['name'].toString().isNotEmpty)
          .map((i) => i['name'].toString())
          .toList();

      final result = await _recipeService.generateRecipeImage(recipeName, ingredients);
      
      if (result != null) {
        setState(() {
          if (result.startsWith('http')) {
            _aiGeneratedUrl = result;
            _selectedImage = null;
          } else {
            // It's a local file path (decoded from base64)
            _selectedImage = File(result);
            _aiGeneratedUrl = null;
          }
          _isLoading = false;
        });
        
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('สร้างรูปภาพด้วย AI สำเร็จ!'), backgroundColor: AppTheme.primaryOrange),
          );
        }
      } else {
        setState(() => _isLoading = false);
        _showErrorDialog('ขออภัยครับ ไม่สามารถสร้างรูปภาพได้ในขณะนี้');
      }
    } catch (e) {
      _showErrorDialog('เกิดข้อผิดพลาด: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addIngredient({bool isMain = false}) {
    setState(() {
      _ingredients.add(<String, dynamic>{'name': '', 'qty': '1', 'unit_id': _units.isNotEmpty ? _units.first.unitId : null, 'id': 0, 'main': isMain});
      _ingredientNameControllers.add(TextEditingController());
      _ingredientQtyControllers.add(TextEditingController(text: '1'));
    });
  }

  void _removeIngredient(int index) {
    setState(() {
      if (index < _ingredients.length) _ingredients.removeAt(index);
      if (index < _ingredientNameControllers.length) {
        _ingredientNameControllers[index].dispose();
        _ingredientNameControllers.removeAt(index);
      }
      if (index < _ingredientQtyControllers.length) {
        _ingredientQtyControllers[index].dispose();
        _ingredientQtyControllers.removeAt(index);
      }
    });
  }

  void _addStep() {
    setState(() {
      _steps.add('');
      _stepControllers.add(TextEditingController());
    });
  }

  void _removeStep(int index) {
    setState(() {
      if (index < _steps.length) _steps.removeAt(index);
      if (index < _stepControllers.length) {
        _stepControllers[index].dispose();
        _stepControllers.removeAt(index);
      }
    });
  }

  Future<void> _submitpost() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedImage == null && _aiGeneratedUrl == null) {
       _showErrorDialog('กรุณาเพิ่มรูปอาหารก่อนบันทึกครับ');
       return;
    }

    setState(() => _isLoading = true);

    try {
      String imageUrl = 'https://placehold.co/600x400.png';

      // 1. Determine Source & Upload if needed
      if (_aiGeneratedUrl != null) {
        imageUrl = _aiGeneratedUrl!;
      } else if (_selectedImage != null) {
        final url = await _recipeService.uploadNewRecipeImage(_selectedImage!.path);
        if (url != null) {
            imageUrl = url;
        } else {
            throw Exception('Upload image failed');
        }
      }

      // 2. Prepare Data
      final recipeData = {
        'recipe_name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'cooking_time_min': int.tryParse(_timeController.text) ?? 15,
        'image_url': imageUrl,
        'is_public': _isPublic,
         'ingredients': _ingredients.asMap().entries.map((entry) {
            final idx = entry.key;
            final unitId = entry.value['unit_id'] ?? (_units.isNotEmpty ? _units.first.unitId : 0);
            final name = _ingredientNameControllers[idx].text.trim();
            final qtyStr = _ingredientQtyControllers[idx].text.trim();
            
            if (name.isEmpty) return null; // Skip empty ingredients
            
            return {
              'ingredient_id': entry.value['id'] ?? 0, 
              'quantity': int.tryParse(qtyStr) ?? 1,
              'unit_id': unitId, 
              'is_main_ingredient': entry.value['main'] == true,
              'ingredient_name': name,
            };
         }).where((i) => i != null).map((i) => i!).toList(),
        'steps': _steps.asMap().entries.map((entry) {
          final idx = entry.key;
          final instruction = _stepControllers[idx].text.trim();
          
          if (instruction.isEmpty) return null;
          
          return {
            'step_no': idx + 1,
            'instruction': instruction
          };
        }).where((s) => s != null).map((s) => s!).toList(),
        'categories': _selectedCategoryIds.toList(),
        'tags': _selectedTagIds.toList(),
      };

      // 3. Create or Update Recipe
      bool success = false;
      if (widget.initialRecipe != null && widget.initialRecipe!.recipeId != 0) {
        // Update Mode
        final recipeId = widget.initialRecipe!.recipeId;
        
        final headerData = {
          'recipe_name': recipeData['recipe_name'],
          'description': recipeData['description'],
          'cooking_time_min': recipeData['cooking_time_min'],
          'is_public': recipeData['is_public'],
          'is_active': widget.initialRecipe?.isActive ?? true,
          'categories': recipeData['categories'] ?? [],
          'tags': recipeData['tags'] ?? [],
        };
        
        final headerSuccess = await _recipeService.updateRecipeHeaderById(recipeId, headerData);
        final imageSuccess = await _recipeService.updateRecipeImage(recipeId, recipeData['image_url'] as String);
        final ingredientsSuccess = await _recipeService.updateRecipeIngredientById(recipeId, recipeData['ingredients'] as List<Map<String, dynamic>>);
        final stepsSuccess = await _recipeService.updateRecipeStepById(recipeId, recipeData['steps'] as List<Map<String, dynamic>>);
        
        print('DEBUG: Update Breakdown - Header: $headerSuccess, Image: $imageSuccess, Ingredients: $ingredientsSuccess, Steps: $stepsSuccess');
        success = headerSuccess && imageSuccess && ingredientsSuccess && stepsSuccess;
      } else {
        // Create Mode
        success = await _recipeService.createNewRecipe(recipeData);
      }

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text((widget.initialRecipe != null && widget.initialRecipe!.recipeId != 0) ? 'อัปเดตสูตรอาหารเรียบร้อย!' : 'บันทึกสูตรอาหารเรียบร้อย!'), 
              backgroundColor: AppTheme.primaryGreen
            ),
          );

          // Return to Home tab (index 0)
          context.read<NavigationCubit>().setTab(0);
          
          // Refresh Home recipes so the new one shows up
          final isGuest = context.read<AuthCubit>().isGuest;
          context.read<HomeBloc>().add(LoadHomeRecipes(isGuest: isGuest));
          
          // Pop back to the MainNavigationScreen root
          Navigator.of(context).popUntil((route) => route.isFirst);
        } else {
          _showErrorDialog(widget.initialRecipe != null ? 'อัปเดตไม่สำเร็จ' : 'บันทึกไม่สำเร็จ');
        }
      }
    } catch (e) {
      if (mounted) _showErrorDialog(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }

  Widget _buildIngredientRow(int index, Map<String, dynamic> item) {
    final isDarkMode = context.read<ThemeCubit>().isDarkMode;
    return Padding(
      padding: EdgeInsets.only(bottom: 12.0.h),
      child: Container(
        padding: EdgeInsets.all(12.scale),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E2D4A) : Colors.white,
          borderRadius: BorderRadius.circular(12.scale),
          border: Border.all(color: item['main'] == true ? AppTheme.primaryOrange.withOpacity(0.3) : Colors.teal.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4.scale,
              offset: Offset(0, 2.h),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(flex: 3, child: Autocomplete<IngredientModel>(
                    optionsBuilder: (TextEditingValue textEditingValue) async {
                      if (textEditingValue.text.isEmpty) {
                        return const Iterable<IngredientModel>.empty();
                      }
                      final results = await _recipeService.getIngredientByNameSearch(textEditingValue.text);
                      return results;
                    },
                    displayStringForOption: (option) => option.ingredientName,
                    onSelected: (option) {
                       setState(() {
                         item['name'] = option.ingredientName;
                         item['id'] = option.ingredientId;
                       });
                    },
                    fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
                      // Safety check for index
                      if (index >= _ingredientNameControllers.length) {
                        return const SizedBox.shrink();
                      }
                      
                      // Sync with our persistent controller (Safely after build)
                      final persistentController = _ingredientNameControllers[index];
                      if (textController.text != persistentController.text) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                           if (textController.text != persistentController.text) {
                             textController.text = persistentController.text;
                           }
                        });
                      }
                      
                      return TextFormField(
                        controller: textController,
                        focusNode: focusNode,
                        onChanged: (val) {
                          item['name'] = val;
                          persistentController.text = val;
                          item['id'] = 0;
                        },
                        decoration: InputDecoration(
                          hintText: 'ค้นหาวัตถุดิบ...',
                          prefixIcon: Icon(Icons.search, size: 20.scale),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10.w),
                          border: const UnderlineInputBorder(),
                        ),
                      );
                    },
                )),
                SizedBox(width: 8.w),
                IconButton(
                  onPressed: () => _removeIngredient(index), 
                  icon: const Icon(Icons.delete_outline, color: Colors.red)
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(flex: 1, child: TextFormField(
                    controller: (index < _ingredientQtyControllers.length) ? _ingredientQtyControllers[index] : null,
                    onChanged: (val) => item['qty'] = val,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(hintText: 'จำนวน', contentPadding: EdgeInsets.symmetric(horizontal: 10.w), labelStyle: TextStyle(fontSize: 14.sp)),
                    style: TextStyle(fontSize: 14.sp),
                )),
                SizedBox(width: 8.w),
                Expanded(flex: 2, child: DropdownButtonFormField<int>(
                    isExpanded: true,
                    value: item['unit_id'],
                    decoration: InputDecoration(hintText: 'หน่วย', contentPadding: EdgeInsets.symmetric(horizontal: 10.w), labelStyle: TextStyle(fontSize: 14.sp)),
                    items: _units.map((u) => DropdownMenuItem(value: u.unitId, child: Text(u.unitName, style: TextStyle(fontSize: 14.sp), overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (val) => setState(() => item['unit_id'] = val),
                    validator: (val) => val == null ? 'เลือก' : null,
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeCubit>().isDarkMode;
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF1A1A2E) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        toolbarHeight: 80.h,
        title: Text(widget.initialRecipe != null ? 'แก้ไขสูตรอาหาร ✏️' : 'สร้างสูตรอาหาร 🍳', style: TextStyle(fontSize: 20.sp)),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.brandGradient,
          ),
        ),
        foregroundColor: Colors.white,
        actions: [
          if (widget.initialRecipe != null && widget.initialRecipe!.recipeId == 0)
            IconButton(
              icon: const Icon(Icons.bug_report, color: Colors.white),
              onPressed: () {
                print('DEBUG: Initial Recipe Data: ${widget.initialRecipe!.toJson()}');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Logged recipe data to console!'))
                );
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.scale),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Magic AI Banner (Prominent)
              _buildAiBanner(),
              SizedBox(height: 24.h),

              // Basic Info
              Text('ข้อมูลทั่วไป', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
              SizedBox(height: 16.h),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'ชื่อเมนู', border: const OutlineInputBorder(), prefixIcon: Icon(Icons.restaurant, size: 24.scale), labelStyle: TextStyle(fontSize: 14.sp)),
                style: TextStyle(fontSize: 16.sp),
                validator: (v) => v!.isEmpty ? 'กรุณาระบุชื่อ' : null,
              ),
              SizedBox(height: 12.h),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'คำอธิบายสั้นๆ', border: const OutlineInputBorder(), prefixIcon: Icon(Icons.description, size: 24.scale), labelStyle: TextStyle(fontSize: 14.sp)),
                style: TextStyle(fontSize: 16.sp),
                maxLines: 2,
              ),
              SizedBox(height: 12.h),
              TextFormField(
                controller: _timeController,
                decoration: InputDecoration(labelText: 'เวลาปรุง (นาที)', border: const OutlineInputBorder(), prefixIcon: Icon(Icons.timer, size: 24.scale), labelStyle: TextStyle(fontSize: 14.sp)),
                style: TextStyle(fontSize: 16.sp),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'ระบุเวลา' : null,
              ),
              
              SwitchListTile(
                title: Text('เผยแพร่สาธารณะ', style: TextStyle(fontSize: 16.sp)),
                value: _isPublic,
                onChanged: (v) => setState(() => _isPublic = v),
              ),

              const Divider(height: 40),

              // Categories Section
              if (_availableCategories.isNotEmpty) ...[
                Text('หมวดหมู่ (Categories)', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
                SizedBox(height: 12.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: _availableCategories.map((cat) {
                    final isSelected = _selectedCategoryIds.contains(cat.categoryId);
                    return FilterChip(
                      label: Text(cat.categoryName, style: TextStyle(fontSize: 14.sp)),
                      selected: isSelected,
                      selectedColor: AppTheme.primaryOrange.withOpacity(0.2),
                      checkmarkColor: AppTheme.primaryOrange,
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
                SizedBox(height: 16.h),
              ],

              // Tags Section
              if (_availableTags.isNotEmpty) ...[
                Text('แท็ก (Tags)', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
                SizedBox(height: 12.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: _availableTags.map((tag) {
                    final isSelected = _selectedTagIds.contains(tag.tagId);
                    return FilterChip(
                      label: Text('#${tag.tagName}', style: TextStyle(fontSize: 14.sp)),
                      selected: isSelected,
                      selectedColor: Colors.blueAccent.withOpacity(0.2),
                      checkmarkColor: Colors.blueAccent,
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

              const Divider(height: 40),

               // Ingredients Section
               Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                    Text('วัตถุดิบหลัก', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : AppTheme.primaryOrange)),
                    IconButton(onPressed: () => _addIngredient(isMain: true), icon: Icon(Icons.add_circle, color: AppTheme.primaryOrange, size: 24.scale)),
                 ],
               ),
               ..._ingredients.asMap().entries.where((e) => e.value['main'] == true).map((entry) {
                   return _buildIngredientRow(entry.key, entry.value);
               }),

               SizedBox(height: 16.h),
               Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                    Text('วัตถุดิบย่อย / เครื่องปรุง', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white70 : Colors.teal)),
                     IconButton(onPressed: () => _addIngredient(isMain: false), icon: Icon(Icons.add_circle, color: Colors.teal, size: 24.scale)),
                  ],
                ),
                ..._ingredients.asMap().entries.where((e) => e.value['main'] != true).map((entry) {
                    return _buildIngredientRow(entry.key, entry.value);
                }),

               const Divider(height: 40),

               // Steps
               Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                    Text('วิธีทำ 👨‍🍳', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
                    IconButton(onPressed: _addStep, icon: Icon(Icons.add_circle, color: AppTheme.primaryGreen, size: 24.scale)),
                 ],
               ),
               ..._steps.asMap().entries.map((entry) {
                  int index = entry.key;
                  return Padding(
                    padding: EdgeInsets.only(bottom: 8.0.h),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            CircleAvatar(radius: 12.scale, backgroundColor: AppTheme.primaryOrange, child: Text('${index+1}', style: TextStyle(fontSize: 12.sp, color: Colors.white))),
                            SizedBox(width: 12.w),
                            Expanded(child: TextFormField(
                                controller: (index < _stepControllers.length) ? _stepControllers[index] : null,
                                onChanged: (val) => _steps[index] = val,
                                maxLines: 2,
                                style: TextStyle(fontSize: 14.sp),
                                decoration: InputDecoration(hintText: 'คำอธิบายขั้นตอน...', border: const OutlineInputBorder(), contentPadding: EdgeInsets.all(12.scale), hintStyle: TextStyle(fontSize: 14.sp)),
                            )),
                            IconButton(onPressed: () => _removeStep(index), icon: Icon(Icons.remove_circle_outline, color: Colors.red, size: 24.scale)),
                        ],
                    ),
                  );
              }),
              
              const Divider(height: 40),

              GestureDetector(
                onTap: () {
                    showModalBottomSheet(context: context, builder: (_) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                            ListTile(leading: Icon(Icons.camera, size: 24.scale), title: Text('ถ่ายรูป', style: TextStyle(fontSize: 16.sp)), onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); }),
                            ListTile(leading: Icon(Icons.photo, size: 24.scale), title: Text('เลือกจากอัลบั้ม', style: TextStyle(fontSize: 16.sp)), onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); }),
                            ListTile(
                              leading: Icon(Icons.auto_awesome, color: AppTheme.primaryOrange, size: 24.scale), 
                              title: Text('สร้างรูปด้วย AI ✨', style: TextStyle(color: AppTheme.primaryOrange, fontWeight: FontWeight.bold, fontSize: 16.sp)), 
                              onTap: () { 
                                Navigator.pop(context); 
                                _generateImageWithAI(); 
                              }
                            ),
                        ]
                    ));
                },
                child: Container(
                  height: 200.h,
                  width: double.infinity,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey[200],
                    borderRadius: BorderRadius.circular(20.scale),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (_selectedImage != null)
                        Image.file(
                          _selectedImage!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (ctx, err, stack) => const Icon(Icons.error, color: Colors.red),
                        )
                      else if (_aiGeneratedUrl != null)
                        Image.network(
                          _aiGeneratedUrl!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (ctx, err, stack) => Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [Icon(Icons.broken_image, color: Colors.grey, size: 40.scale), Text('ไม่สามารถโหลดรูปภาพได้', style: TextStyle(fontSize: 14.sp))],
                          ),
                        ),
                      if (_selectedImage == null && _aiGeneratedUrl == null)
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [Icon(Icons.add_a_photo, size: 50.scale, color: Colors.grey), SizedBox(height: 8.h), Text('เพิ่มรูปอาหาร', style: TextStyle(fontSize: 16.sp, color: Colors.grey))],
                        ),
                      if (_isLoading)
                        Container(
                          color: Colors.black26,
                          child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                        ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 40.h),
              
              SizedBox(
                height: 56.h,
                child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitpost,
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryOrange, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.scale))),
                    child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text((widget.initialRecipe != null && widget.initialRecipe!.recipeId != 0) ? 'อัปเดตสูตรอาหาร' : 'บันทึกสูตรอาหาร', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAiBanner() {
    final isDarkMode = context.read<ThemeCubit>().isDarkMode;
    return Container(
      padding: EdgeInsets.all(20.scale),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode 
            ? [const Color(0xFF2A3D5A), const Color(0xFF1E2D4A)]
            : [const Color(0xFFF0F4FF), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24.scale),
        border: Border.all(
          color: AppTheme.brandPurple.withOpacity(0.2),
          width: 1.5.scale,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.scale),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.auto_awesome, color: Colors.amber[700], size: 28.scale),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ให้ AI ช่วยคิดสูตรให้คุณ ✨',
                      style: TextStyle(
                        fontSize: 17.sp,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : AppTheme.brandPurple,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'เพียงบอกชื่อเมนูหรือไตล์ที่อยากทาน แล้วนั่งรอได้เลยครับ!',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: isDarkMode ? Colors.white70 : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showAiPromptDialog(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.brandPurple,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.scale)),
                elevation: 4,
                shadowColor: AppTheme.brandPurple.withOpacity(0.4),
              ),
              child: Text(
                'เริ่มรังสรรค์ด้วย AI 🤖',
                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAiPromptDialog() {
    final nameController = TextEditingController(text: _nameController.text);
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
          color: isDarkMode ? const Color(0xFF1E2D4A) : Colors.white,
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
                Icon(Icons.auto_awesome, color: AppTheme.primaryOrange, size: 28.scale),
                SizedBox(width: 12.w),
                Text(
                  'ให้ AI ช่วยคิดสูตรอาหาร ✨',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            _buildDialogTextField(
              controller: nameController,
              label: 'ชื่อเมนู',
              hint: 'เช่น ข้าวผัดไข่เยี่ยวม้ากะเพรากรอบ',
              isDarkMode: isDarkMode,
            ),
            SizedBox(height: 16.h),
            _buildDialogTextField(
              controller: promptController,
              label: 'สไตล์หรือ Prompt',
              hint: 'เช่น ขอรสจัดจ้าน, แบบภัตตาคาร...',
              maxLines: 3,
              isDarkMode: isDarkMode,
            ),
            SizedBox(height: 24.h),
            ValueListenableBuilder<bool>(
              valueListenable: loadingNotifier,
              builder: (context, isLoading, child) {
                return SizedBox(
                  width: double.infinity,
                  height: 50.h,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : () async {
                      if (nameController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('กรุณาระบุชื่อเมนูด้วยนะครับ!'))
                        );
                        return;
                      }

                      loadingNotifier.value = true;
                      
                      try {
                        final recipes = await _recipeService.generateNewRecipeByAI(
                          nameController.text.trim(),
                          prompt: promptController.text.trim(),
                        );
                        
                        if (recipes.isNotEmpty && context.mounted) {
                          RecipeModel recipe = recipes.first;
                          
                          // FALLBACK: If AI returns an existing recipe ID but no ingredients/steps, fetch them!
                          if (recipe.recipeId > 0 && 
                             (recipe.ingredients == null || recipe.ingredients!.isEmpty)) {
                            print('DEBUG: AI Recipe (ID: ${recipe.recipeId}) has no ingredients. Fetching full details...');
                            try {
                              final fullRecipe = await _recipeService.getRecipeDetailById(recipe.recipeId);
                              recipe = fullRecipe;
                            } catch (e) {
                              print('DEBUG: Failed to fetch full details for ID ${recipe.recipeId}: $e');
                            }
                          }

                          print('DEBUG: AI Recipe Auto-Fill - IngCount: ${recipe.ingredients?.length}, StepCount: ${recipe.steps?.length}');
                          
                          // Prepare data non-atomically first
                          final newIngredients = <Map<String, dynamic>>[];
                          final newNameControllers = <TextEditingController>[];
                          final newQtyControllers = <TextEditingController>[];
                          
                          if (recipe.ingredients != null && recipe.ingredients!.isNotEmpty) {
                            for (var i in recipe.ingredients!) {
                              final name = i.ingredientName;
                              final qty = i.quantityValue > 0 ? i.quantityValue.toString().replaceAll(RegExp(r'\.0$'), '') : '1';
                              newNameControllers.add(TextEditingController(text: name));
                              newQtyControllers.add(TextEditingController(text: qty));
                              
                              newIngredients.add(<String, dynamic>{
                                'name': name,
                                'qty': qty,
                                'unit_id': i.unitId != 0 ? i.unitId : null,
                                'id': i.ingredientId,
                                'main': i.isMainIngredient,
                              });
                            }
                          } else {
                            // Default if empty
                            newIngredients.add({'name': '', 'qty': '1', 'unit_id': null, 'id': 0, 'main': true});
                            newNameControllers.add(TextEditingController());
                            newQtyControllers.add(TextEditingController(text: '1'));
                          }

                          final newSteps = <String>[];
                          final newStepControllers = <TextEditingController>[];
                          
                          if (recipe.steps != null && recipe.steps!.isNotEmpty) {
                            for (var s in recipe.steps!) {
                              newSteps.add(s.instruction);
                              newStepControllers.add(TextEditingController(text: s.instruction));
                            }
                          } else {
                            newSteps.add('');
                            newStepControllers.add(TextEditingController());
                          }

                          // Unified state update
                          setState(() {
                             _nameController.text = recipe.recipeName;
                             _descriptionController.text = recipe.description;
                             _timeController.text = recipe.cookingTimeMin > 0 ? recipe.cookingTimeMin.toString() : '15';
                             
                             // Dispose old
                             for (var c in _ingredientNameControllers) c.dispose();
                             for (var c in _ingredientQtyControllers) c.dispose();
                             for (var c in _stepControllers) c.dispose();

                             _ingredients = newIngredients;
                             _ingredientNameControllers.clear();
                             _ingredientNameControllers.addAll(newNameControllers);
                             _ingredientQtyControllers.clear();
                             _ingredientQtyControllers.addAll(newQtyControllers);

                             _steps = newSteps;
                             _stepControllers.clear();
                             _stepControllers.addAll(newStepControllers);

                             if (recipe.imageUrl.isNotEmpty) {
                               _aiGeneratedUrl = recipe.imageUrl;
                               _selectedImage = null;
                             }
                             
                             _matchAiDataToDb(recipe);
                          });
                          Navigator.pop(context); // Close modal
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('AI รังสรรค์สูตรให้สำเร็จแล้ว! ✨'), backgroundColor: AppTheme.primaryGreen)
                          );
                        } else {
                          if (context.mounted) {
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
                      backgroundColor: AppTheme.primaryOrange,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.scale)),
                    ),
                    child: isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text('เติมข้อมูลอัตโนมัติ ✨', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                  ),
                );
              }
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
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
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white70 : Colors.black54,
          ),
        ),
        SizedBox(height: 8.h),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(fontSize: 14.sp, color: isDarkMode ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13.sp),
            filled: true,
            fillColor: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.scale),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          ),
        ),
      ],
    );
  }
}
