import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../services/food_service.dart';
import '../models/food_model.dart';

class AddFoodScreen extends StatefulWidget {
  const AddFoodScreen({super.key});

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
  
  // Dynamic Lists
  final List<Map<String, dynamic>> _ingredients = [
    {'name': '', 'qty': '1', 'unit_id': null, 'id': 0, 'main': true}
  ];
  final List<String> _steps = [''];
  
  bool _isPublic = true;

  @override
  void initState() {
    super.initState();
    _loadUnits();
  }

  Future<void> _loadUnits() async {
    try {
      final units = await _recipeService.getAllUnits();
      setState(() {
        _units = units;
      });
    } catch (e) {
      print('Error loading units: $e');
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

    setState(() => _isLoading = true);
    try {
      final prompt = _nameController.text.trim();
      final url = await _recipeService.generateRecipeImage(prompt);
      
      if (url != null) {
        setState(() {
          _aiGeneratedUrl = url;
          _selectedImage = null; // Clear local file if AI generated
        });
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('สร้างรูปภาพด้วย AI สำเร็จ!'), backgroundColor: AppTheme.primaryOrange),
          );
        }
      } else {
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
      _ingredients.add({'name': '', 'qty': '1', 'unit_id': _units.isNotEmpty ? _units.first.unitId : null, 'id': 0, 'main': isMain});
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
      };

      // 3. Create Recipe
      final success = await _recipeService.createNewRecipe(recipeData);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('บันทึกสูตรอาหารเรียบร้อย!'), backgroundColor: AppTheme.primaryGreen),
          );
          Navigator.pop(context, true);
        } else {
          _showErrorDialog('บันทึกไม่สำเร็จ');
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: item['main'] == true ? AppTheme.primaryOrange.withOpacity(0.3) : Colors.teal.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
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
                        decoration: const InputDecoration(
                          hintText: 'ค้นหาวัตถุดิบ...',
                          prefixIcon: Icon(Icons.search, size: 20),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10),
                          border: UnderlineInputBorder(),
                        ),
                      );
                    },
                )),
                const SizedBox(width: 8),
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
                    decoration: const InputDecoration(hintText: 'จำนวน', contentPadding: EdgeInsets.symmetric(horizontal: 10)),
                )),
                const SizedBox(width: 8),
                Expanded(flex: 2, child: DropdownButtonFormField<int>(
                    isExpanded: true,
                    value: item['unit_id'],
                    decoration: const InputDecoration(hintText: 'หน่วย', contentPadding: EdgeInsets.symmetric(horizontal: 10)),
                    items: _units.map((u) => DropdownMenuItem(value: u.unitId, child: Text(u.unitName, style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis))).toList(),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('สร้างสูตรอาหาร 🍳'),
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppTheme.primaryGradient)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Basic Info
              const Text('ข้อมูลทั่วไป', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'ชื่อเมนู', border: OutlineInputBorder(), prefixIcon: Icon(Icons.restaurant)),
                validator: (v) => v!.isEmpty ? 'กรุณาระบุชื่อ' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'คำอธิบายสั้นๆ', border: OutlineInputBorder(), prefixIcon: Icon(Icons.description)),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _timeController,
                decoration: const InputDecoration(labelText: 'เวลาปรุง (นาที)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.timer)),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'ระบุเวลา' : null,
              ),
              
              SwitchListTile(
                title: const Text('เผยแพร่สาธารณะ'),
                value: _isPublic,
                onChanged: (v) => setState(() => _isPublic = v),
              ),

              const Divider(height: 40),

               // Ingredients Section
               Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                    const Text('วัตถุดิบหลัก', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryOrange)),
                    IconButton(onPressed: () => _addIngredient(isMain: true), icon: const Icon(Icons.add_circle, color: AppTheme.primaryOrange)),
                 ],
               ),
               ..._ingredients.asMap().entries.where((e) => e.value['main'] == true).map((entry) {
                   return _buildIngredientRow(entry.key, entry.value);
               }),

               const SizedBox(height: 16),
               Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                    const Text('วัตถุดิบย่อย / เครื่องปรุง', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
                    IconButton(onPressed: () => _addIngredient(isMain: false), icon: const Icon(Icons.add_circle, color: Colors.teal)),
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
                   const Text('วิธีทำ 👨‍🍳', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                   IconButton(onPressed: _addStep, icon: const Icon(Icons.add_circle, color: AppTheme.primaryGreen)),
                ],
              ),
               ..._steps.asMap().entries.map((entry) {
                  int index = entry.key;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            CircleAvatar(radius: 12, backgroundColor: AppTheme.primaryOrange, child: Text('${index+1}', style: const TextStyle(fontSize: 12, color: Colors.white))),
                            const SizedBox(width: 12),
                            Expanded(child: TextFormField(
                                initialValue: entry.value,
                                onChanged: (val) => _steps[index] = val,
                                maxLines: 2,
                                decoration: const InputDecoration(hintText: 'คำอธิบายขั้นตอน...', border: OutlineInputBorder()),
                            )),
                            IconButton(onPressed: () => _removeStep(index), icon: const Icon(Icons.remove_circle_outline, color: Colors.red)),
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
                            ListTile(leading: const Icon(Icons.camera), title: const Text('ถ่ายรูป'), onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); }),
                            ListTile(leading: const Icon(Icons.photo), title: const Text('เลือกจากอัลบั้ม'), onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); }),
                            ListTile(
                              leading: const Icon(Icons.auto_awesome, color: AppTheme.primaryOrange), 
                              title: const Text('สร้างรูปด้วย AI ✨', style: TextStyle(color: AppTheme.primaryOrange, fontWeight: FontWeight.bold)), 
                              onTap: () { 
                                Navigator.pop(context); 
                                _generateImageWithAI(); 
                              }
                            ),
                        ]
                    ));
                },
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                    image: _selectedImage != null 
                        ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover) 
                        : (_aiGeneratedUrl != null 
                            ? DecorationImage(image: NetworkImage(_aiGeneratedUrl!), fit: BoxFit.cover)
                            : null),
                  ),
                  child: (_selectedImage == null && _aiGeneratedUrl == null) ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [Icon(Icons.add_a_photo, size: 50, color: Colors.grey), SizedBox(height: 8), Text('เพิ่มรูปอาหาร')],
                  ) : (_isLoading ? const Center(child: CircularProgressIndicator()) : null),
                ),
              ),
              
              const SizedBox(height: 40),
              
              SizedBox(
                height: 56,
                child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitpost,
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryOrange, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('บันทึกสูตรอาหาร', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
