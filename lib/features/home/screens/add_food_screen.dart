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
  
  // Dynamic Lists
  List<Map<String, dynamic>> _ingredients = [
    {'name': '', 'qty': '1', 'unit_id': null, 'id': 0, 'main': true}
  ];
  List<String> _steps = [''];
  
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
      if (recipe.ingredients != null && recipe.ingredients!.isNotEmpty) {
        _ingredients = recipe.ingredients!.map((i) => <String, dynamic>{
          'name': i.ingredientName,
          'qty': i.quantityValue > 0 ? i.quantityValue.toString().replaceAll(RegExp(r'\.0$'), '') : '1',
          'unit_id': i.unitId != 0 ? i.unitId : null,
          'id': i.ingredientId,
          'main': i.isMainIngredient,
        }).toList();
      } else {
        // Ensure at least one empty row if AI failed
        if (_ingredients.isEmpty) {
           _ingredients = [{'name': '', 'qty': '1', 'unit_id': null, 'id': 0, 'main': true}];
        }
      }

      // Steps
      if (recipe.steps != null && recipe.steps!.isNotEmpty) {
        _steps = recipe.steps!.map((s) => s.instruction).toList();
      } else {
         if (_steps.isEmpty) _steps = [''];
      }
      
      // Safety setState (though usually not needed in initState)
      if (mounted) setState(() {});
      
      // If we already have categories/tags loaded (unlikely during initState, but possible on hot reload)
      if (_availableCategories.isNotEmpty || _availableTags.isNotEmpty) {
        _matchAiDataToDb();
      }
    }
  }

  void _matchAiDataToDb() {
    if (widget.initialRecipe == null) return;
    final recipe = widget.initialRecipe!;

    setState(() {
      // 1. Match Categories by Name
      if (recipe.categoryDetails != null) {
        for (var aiCat in recipe.categoryDetails!) {
          if (aiCat.categoryId == 0) {
            final match = _availableCategories.firstWhere(
              (c) => c.categoryName.trim() == aiCat.categoryName.trim(), 
              orElse: () => CategoryModel(categoryId: -1, categoryName: '')
            );
            if (match.categoryId != -1) {
              _selectedCategoryIds.add(match.categoryId);
            }
          }
        }
      }

      // 2. Match Tags by Name (from tagDetails or tags list)
      final allAiTagNames = <String>{};
      if (recipe.tagDetails != null) {
        allAiTagNames.addAll(recipe.tagDetails!.map((t) => t.tagName.trim()));
      }
      if (recipe.tags != null) {
        allAiTagNames.addAll(recipe.tags!.map((t) => t.trim()));
      }

      for (var name in allAiTagNames) {
        final match = _availableTags.firstWhere(
          (t) => t.tagName.trim() == name,
          orElse: () => TagModel(tagId: -1, tagName: '')
        );
        if (match.tagId != -1) {
          _selectedTagIds.add(match.tagId);
        }
      }

      // 3. Match Ingredient Units by Name
      for (var item in _ingredients) {
        if (item['unit_id'] == null) {
          // Attempt to find unitName from recipe model if it exists
          final aiIng = recipe.ingredients?.firstWhere((i) => i.ingredientName == item['name'], orElse: () => recipe.ingredients!.first);
          if (aiIng != null && aiIng.unitName.isNotEmpty) {
             final unitMatch = _units.firstWhere(
               (u) => u.unitName.trim() == aiIng.unitName.trim(),
               orElse: () => UnitModel(unitId: -1, unitName: '')
             );
             if (unitMatch.unitId != -1) {
               item['unit_id'] = unitMatch.unitId;
             }
          }
        }
      }
    });
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
    });
  }

  void _removeIngredient(int index) {
    setState(() {
      _ingredients.removeAt(index);
    });
  }

  void _addStep() {
    setState(() {
      _steps.add('');
    });
  }

  void _removeStep(int index) {
    setState(() {
      _steps.removeAt(index);
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
            final unitId = entry.value['unit_id'] ?? (_units.isNotEmpty ? _units.first.unitId : 0);
            
            return {
              'ingredient_id': entry.value['id'] ?? 0, 
              'quantity': int.tryParse(entry.value['qty'].toString()) ?? 1,
              'unit_id': unitId, 
              'is_main_ingredient': entry.value['main'] == true,
              // 'ingredient_name': entry.value['name'], // Spec doesn't show it but could be useful
            };
         }).toList(),
        'steps': _steps.asMap().entries.map((entry) {
          return {
            'step_no': entry.key + 1,
            'instruction': entry.value
          };
        }).toList(),
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
                      if (textController.text.isEmpty && item['name'].toString().isNotEmpty) {
                        textController.text = item['name'];
                      }
                      return TextFormField(
                        controller: textController,
                        focusNode: focusNode,
                        onChanged: (val) {
                          item['name'] = val;
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
                    initialValue: item['qty'].toString(),
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
                                initialValue: entry.value,
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
}
