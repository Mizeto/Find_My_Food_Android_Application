import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../data/repositories/recipe_repository.dart';
import '../../home/models/food_model.dart';
import '../bloc/create_recipe_cubit.dart';

class CreateRecipeScreen extends StatelessWidget {
  const CreateRecipeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CreateRecipeCubit(context.read<RecipeRepository>())..fetchOptions(),
      child: const CreateRecipeView(),
    );
  }
}

class CreateRecipeView extends StatefulWidget {
  const CreateRecipeView({super.key});

  @override
  State<CreateRecipeView> createState() => _CreateRecipeViewState();
}

class _CreateRecipeViewState extends State<CreateRecipeView> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _timeController = TextEditingController();
  final _imagePicker = ImagePicker();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(source: source);
      if (pickedFile != null && mounted) {
        context.read<CreateRecipeCubit>().setImagePath(pickedFile.path);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('เลือกรูปผิดพลาด: $e')));
    }
  }

  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.scale))),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.photo_library, color: AppTheme.primaryGreen, size: 24.scale),
              title: Text('เลือกจากแกลเลอรี', style: TextStyle(fontSize: 16.sp)),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt, color: AppTheme.brandPurple, size: 24.scale),
              title: Text('ถ่ายรูปใหม่', style: TextStyle(fontSize: 16.sp)),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _addIngredientDialog(BuildContext parentContext, List<UnitModel> units) {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    int selectedUnitId = units.isNotEmpty ? units.first.unitId : 0;
    bool isMain = false;

    showDialog(
      context: parentContext,
      builder: (ctx) => AlertDialog(
        title: Text('เพิ่มวัตถุดิบ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp)),
        content: StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'ชื่อวัตถุดิบ',
                    labelStyle: TextStyle(fontSize: 14.sp),
                  ),
                  style: TextStyle(fontSize: 16.sp),
                ),
                SizedBox(height: 12.h),
                TextField(
                  controller: qtyCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'จำนวน',
                    labelStyle: TextStyle(fontSize: 14.sp),
                  ),
                  style: TextStyle(fontSize: 16.sp),
                ),
                SizedBox(height: 12.h),
                if (units.isNotEmpty)
                  DropdownButtonFormField<int>(
                    value: selectedUnitId,
                    decoration: InputDecoration(
                      labelText: 'หน่วย',
                      labelStyle: TextStyle(fontSize: 14.sp),
                    ),
                    items: units.map((u) {
                      return DropdownMenuItem(value: u.unitId, child: Text(u.unitName));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => selectedUnitId = val);
                    },
                  ),
                SizedBox(height: 12.h),
                SwitchListTile(
                  title: Text('เป็นวัตถุดิบหลัก?', style: TextStyle(fontSize: 16.sp)),
                  value: isMain,
                  onChanged: (val) => setState(() => isMain = val),
                  activeColor: AppTheme.primaryGreen,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('ยกเลิก', style: TextStyle(color: Colors.grey, fontSize: 14.sp)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.scale)),
            ),
            onPressed: () {
              if (nameCtrl.text.isEmpty || qtyCtrl.text.isEmpty) return;
              final qty = double.tryParse(qtyCtrl.text) ?? 1.0;
              final unitName = units.firstWhere((u) => u.unitId == selectedUnitId, orElse: () => UnitModel(unitId: 0, unitName: 'หน่วย')).unitName;

              parentContext.read<CreateRecipeCubit>().addIngredient({
                'ingredientId': 0, // backend might handle new ingredients
                'name': nameCtrl.text,
                'quantity': qty,
                'unitId': selectedUnitId,
                'unitName': unitName,
                'isMainIngredient': isMain,
              });
              Navigator.pop(ctx);
            },
            child: Text('เพิ่ม', style: TextStyle(color: Colors.white, fontSize: 14.sp)),
          ),
        ],
      ),
    );
  }

  void _addStepDialog(BuildContext parentContext) {
    final stepCtrl = TextEditingController();

    showDialog(
      context: parentContext,
      builder: (ctx) => AlertDialog(
        title: Text('เพิ่มขั้นตอน', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp)),
        content: TextField(
          controller: stepCtrl,
          maxLines: 4,
          style: TextStyle(fontSize: 16.sp),
          decoration: InputDecoration(
            hintText: 'อธิบายขั้นตอนการทำ...',
            hintStyle: TextStyle(fontSize: 14.sp),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.scale)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('ยกเลิก', style: TextStyle(color: Colors.grey, fontSize: 14.sp)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brandPurple,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.scale)),
            ),
            onPressed: () {
              if (stepCtrl.text.isNotEmpty) {
                parentContext.read<CreateRecipeCubit>().addStep(stepCtrl.text);
              }
              Navigator.pop(ctx);
            },
            child: Text('เพิ่ม', style: TextStyle(color: Colors.white, fontSize: 14.sp)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CreateRecipeCubit, CreateRecipeState>(
      listener: (context, state) {
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error!)));
        }
        if (state.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('สร้างสูตรอาหารสำเร็จ! 🍽️', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
          Navigator.pop(context, true); // Output success signal to reload parent 
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Text('สร้างสูตรอาหาร', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 20.sp)),
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.black87),
          ),
          body: state.isLoading && state.availableCategories.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                  children: [
                    SingleChildScrollView(
                      padding: EdgeInsets.all(20.scale),
                      child: Form(
                        key: _formKey,
                        onChanged: () {
                          context.read<CreateRecipeCubit>().updateBasicInfo(
                            title: _titleController.text,
                            description: _descriptionController.text,
                            cookingTime: int.tryParse(_timeController.text) ?? 0,
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Image Upload Container
                            GestureDetector(
                              onTap: () => _showImageSourceActionSheet(context),
                              child: Container(
                                width: double.infinity,
                                height: 200.h,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(20.scale),
                                  image: state.imagePath != null
                                      ? DecorationImage(
                                          image: FileImage(File(state.imagePath!)),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: state.imagePath == null
                                    ? Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.add_a_photo, size: 50.scale, color: Colors.grey[400]),
                                          SizedBox(height: 10.h),
                                          Text('เพิ่มรูปภาพอาหารของคุณ', style: TextStyle(color: Colors.grey[600], fontSize: 14.sp)),
                                        ],
                                      )
                                    : null,
                              ),
                            ),
                            SizedBox(height: 24.h),

                            // Basic details
                            TextFormField(
                              controller: _titleController,
                              decoration: InputDecoration(
                                labelText: 'ชื่อเมนู',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.scale)),
                                prefixIcon: Icon(Icons.restaurant_menu, size: 24.scale),
                              ),
                              validator: (v) => v!.isEmpty ? 'กรุณากรอกชื่อ' : null,
                            ),
                            SizedBox(height: 16.h),

                            TextFormField(
                              controller: _descriptionController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                labelText: 'คำอธิบาย / จุดเด่นของเมนู',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.scale)),
                                alignLabelWithHint: true,
                              ),
                              validator: (v) => v!.isEmpty ? 'กรุณากรอกคำอธิบาย' : null,
                            ),
                            SizedBox(height: 16.h),

                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _timeController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: 'เวลาทำ (นาที)',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.scale)),
                                      prefixIcon: Icon(Icons.timer, size: 24.scale),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 16.w),
                                Expanded(
                                  child: SwitchListTile(
                                    title: Text('สาธารณะ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp)),
                                    value: state.isPublic,
                                    onChanged: (val) => context.read<CreateRecipeCubit>().updateBasicInfo(isPublic: val),
                                    activeColor: AppTheme.primaryGreen,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 8.w),
                                  ),
                                ),
                              ],
                            ),
                            Divider(height: 40.h, thickness: 1),

                            // Categories
                            Text('หมวดหมู่ (Categories)', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
                            SizedBox(height: 12.h),
                            Wrap(
                              spacing: 8.w,
                              runSpacing: 8.h,
                              children: state.availableCategories.map((cat) {
                                final isSelected = state.selectedCategories.any((c) => c.categoryId == cat.categoryId);
                                return FilterChip(
                                  label: Text(cat.categoryName, style: TextStyle(fontSize: 14.sp)),
                                  selected: isSelected,
                                  selectedColor: AppTheme.brandPurple.withOpacity(0.2),
                                  checkmarkColor: AppTheme.brandPurple,
                                  onSelected: (_) => context.read<CreateRecipeCubit>().toggleCategory(cat),
                                );
                              }).toList(),
                            ),
                            Divider(height: 40.h, thickness: 1),

                            // Tags
                            Text('แท็ก (Tags)', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
                            SizedBox(height: 12.h),
                            Wrap(
                              spacing: 8.w,
                              runSpacing: 8.h,
                              children: state.availableTags.map((tag) {
                                final isSelected = state.selectedTags.any((t) => t.tagId == tag.tagId);
                                return FilterChip(
                                  label: Text('#${tag.tagName}', style: TextStyle(fontSize: 14.sp)),
                                  selected: isSelected,
                                  selectedColor: Colors.blueAccent.withOpacity(0.2),
                                  checkmarkColor: Colors.blueAccent,
                                  onSelected: (_) => context.read<CreateRecipeCubit>().toggleTag(tag),
                                );
                              }).toList(),
                            ),
                            Divider(height: 40.h, thickness: 1),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('วัตถุดิบ (Ingredients)', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
                                IconButton(
                                  icon: Icon(Icons.add_circle, color: AppTheme.primaryGreen, size: 28.scale),
                                  onPressed: () => _addIngredientDialog(context, state.availableUnits),
                                ),
                              ],
                            ),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: state.ingredients.length,
                              itemBuilder: (ctx, i) {
                                final ing = state.ingredients[i];
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Icon(Icons.kitchen, color: Colors.teal, size: 24.scale),
                                  title: Text('${ing['name']} ${ing['isMainIngredient'] == true ? "(หลัก)" : ""}', style: TextStyle(fontSize: 16.sp)),
                                  subtitle: Text('${ing['quantity']} ${ing['unitName']}', style: TextStyle(fontSize: 14.sp)),
                                  trailing: IconButton(
                                    icon: Icon(Icons.remove_circle_outline, color: Colors.red, size: 24.scale),
                                    onPressed: () => context.read<CreateRecipeCubit>().removeIngredient(i),
                                  ),
                                );
                              },
                            ),
                            if (state.ingredients.isEmpty)
                              Padding(
                                padding: EdgeInsets.only(bottom: 20.h),
                                child: Text('ยังไม่มีวัตถุดิบ', style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic, fontSize: 14.sp)),
                              ),
                            Divider(height: 20.h, thickness: 1),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('วิธีทำ (Steps)', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
                                IconButton(
                                  icon: Icon(Icons.add_circle, color: AppTheme.brandPurple, size: 28.scale),
                                  onPressed: () => _addStepDialog(context),
                                ),
                              ],
                            ),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: state.steps.length,
                              itemBuilder: (ctx, i) {
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: CircleAvatar(
                                    radius: 20.scale,
                                    backgroundColor: AppTheme.brandPurple.withOpacity(0.2),
                                    child: Text('${i + 1}', style: TextStyle(color: AppTheme.brandPurple, fontWeight: FontWeight.bold, fontSize: 14.sp)),
                                  ),
                                  title: Text(state.steps[i], style: TextStyle(fontSize: 16.sp)),
                                  trailing: IconButton(
                                    icon: Icon(Icons.remove_circle_outline, color: Colors.red, size: 24.scale),
                                    onPressed: () => context.read<CreateRecipeCubit>().removeStep(i),
                                  ),
                                );
                              },
                            ),
                            if (state.steps.isEmpty)
                              Padding(
                                padding: EdgeInsets.only(bottom: 20.h),
                                child: Text('ยังไม่มีขั้นตอนวิธีทำ', style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic, fontSize: 14.sp)),
                              ),

                            SizedBox(height: 100.h),
                          ],
                        ),
                      ),
                    ),

                    // Floating Submit Button
                    Positioned(
                      bottom: 20.h,
                      left: 20.w,
                      right: 20.w,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.scale)),
                          elevation: 8,
                        ),
                        onPressed: state.isLoading
                            ? null
                            : () {
                                if (_formKey.currentState!.validate()) {
                                  context.read<CreateRecipeCubit>().submit();
                                }
                              },
                        child: state.isLoading
                            ? SizedBox(
                                height: 24.scale,
                                width: 24.scale,
                                child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                              )
                            : Text('บันทึกสูตรอาหาร', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
