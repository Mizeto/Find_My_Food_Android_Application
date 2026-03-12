import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppTheme.primaryGreen),
              title: const Text('เลือกจากแกลเลอรี'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppTheme.primaryOrange),
              title: const Text('ถ่ายรูปใหม่'),
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
        title: const Text('เพิ่มวัตถุดิบ', style: TextStyle(fontWeight: FontWeight.bold)),
        content: StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'ชื่อวัตถุดิบ'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: qtyCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'จำนวน'),
                ),
                const SizedBox(height: 12),
                if (units.isNotEmpty)
                  DropdownButtonFormField<int>(
                    value: selectedUnitId,
                    decoration: const InputDecoration(labelText: 'หน่วย'),
                    items: units.map((u) {
                      return DropdownMenuItem(value: u.unitId, child: Text(u.unitName));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => selectedUnitId = val);
                    },
                  ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('เป็นวัตถุดิบหลัก?'),
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
            child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
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
            child: const Text('เพิ่ม', style: TextStyle(color: Colors.white)),
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
        title: const Text('เพิ่มขั้นตอน', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: stepCtrl,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'อธิบายขั้นตอนการทำ...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryOrange),
            onPressed: () {
              if (stepCtrl.text.isNotEmpty) {
                parentContext.read<CreateRecipeCubit>().addStep(stepCtrl.text);
              }
              Navigator.pop(ctx);
            },
            child: const Text('เพิ่ม', style: TextStyle(color: Colors.white)),
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
            title: const Text('สร้างสูตรอาหาร', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.black87),
          ),
          body: state.isLoading && state.availableCategories.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                  children: [
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
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
                                height: 200,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(20),
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
                                          Icon(Icons.add_a_photo, size: 50, color: Colors.grey[400]),
                                          const SizedBox(height: 10),
                                          Text('เพิ่มรูปภาพอาหารของคุณ', style: TextStyle(color: Colors.grey[600])),
                                        ],
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Basic details
                            TextFormField(
                              controller: _titleController,
                              decoration: const InputDecoration(
                                labelText: 'ชื่อเมนู',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.restaurant_menu),
                              ),
                              validator: (v) => v!.isEmpty ? 'กรุณากรอกชื่อ' : null,
                            ),
                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _descriptionController,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                labelText: 'คำอธิบาย / จุดเด่นของเมนู',
                                border: OutlineInputBorder(),
                                alignLabelWithHint: true,
                              ),
                              validator: (v) => v!.isEmpty ? 'กรุณากรอกคำอธิบาย' : null,
                            ),
                            const SizedBox(height: 16),

                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _timeController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'เวลาทำ (นาที)',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.timer),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: SwitchListTile(
                                    title: const Text('สาธารณะ', style: TextStyle(fontWeight: FontWeight.bold)),
                                    value: state.isPublic,
                                    onChanged: (val) => context.read<CreateRecipeCubit>().updateBasicInfo(isPublic: val),
                                    activeColor: AppTheme.primaryGreen,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 40, thickness: 1),

                            // Categories
                            const Text('หมวดหมู่ (Categories)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: state.availableCategories.map((cat) {
                                final isSelected = state.selectedCategories.any((c) => c.categoryId == cat.categoryId);
                                return FilterChip(
                                  label: Text(cat.categoryName),
                                  selected: isSelected,
                                  selectedColor: AppTheme.primaryOrange.withOpacity(0.2),
                                  checkmarkColor: AppTheme.primaryOrange,
                                  onSelected: (_) => context.read<CreateRecipeCubit>().toggleCategory(cat),
                                );
                              }).toList(),
                            ),
                            const Divider(height: 40, thickness: 1),

                            // Tags
                            const Text('แท็ก (Tags)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: state.availableTags.map((tag) {
                                final isSelected = state.selectedTags.any((t) => t.tagId == tag.tagId);
                                return FilterChip(
                                  label: Text('#${tag.tagName}'),
                                  selected: isSelected,
                                  selectedColor: Colors.blueAccent.withOpacity(0.2),
                                  checkmarkColor: Colors.blueAccent,
                                  onSelected: (_) => context.read<CreateRecipeCubit>().toggleTag(tag),
                                );
                              }).toList(),
                            ),
                            const Divider(height: 40, thickness: 1),

                            // Ingredients
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('วัตถุดิบ (Ingredients)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                IconButton(
                                  icon: const Icon(Icons.add_circle, color: AppTheme.primaryGreen, size: 28),
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
                                  leading: const Icon(Icons.kitchen, color: Colors.teal),
                                  title: Text('${ing['name']} ${ing['isMainIngredient'] == true ? "(หลัก)" : ""}'),
                                  subtitle: Text('${ing['quantity']} ${ing['unitName']}'),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                    onPressed: () => context.read<CreateRecipeCubit>().removeIngredient(i),
                                  ),
                                );
                              },
                            ),
                            if (state.ingredients.isEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 20),
                                child: Text('ยังไม่มีวัตถุดิบ', style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic)),
                              ),
                            const Divider(height: 20, thickness: 1),

                            // Steps
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('วิธีทำ (Steps)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                IconButton(
                                  icon: const Icon(Icons.add_circle, color: AppTheme.primaryOrange, size: 28),
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
                                    backgroundColor: AppTheme.primaryOrange.withOpacity(0.2),
                                    child: Text('${i + 1}', style: const TextStyle(color: AppTheme.primaryOrange, fontWeight: FontWeight.bold)),
                                  ),
                                  title: Text(state.steps[i]),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                    onPressed: () => context.read<CreateRecipeCubit>().removeStep(i),
                                  ),
                                );
                              },
                            ),
                            if (state.steps.isEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 20),
                                child: Text('ยังไม่มีขั้นตอนวิธีทำ', style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic)),
                              ),

                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ),

                    // Floating Submit Button
                    Positioned(
                      bottom: 20,
                      left: 20,
                      right: 20,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
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
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                              )
                            : const Text('บันทึกสูตรอาหาร', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
