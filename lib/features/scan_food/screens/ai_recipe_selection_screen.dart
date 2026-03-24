import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:find_my_food/core/theme/app_theme.dart';
import 'package:find_my_food/core/utils/responsive_helper.dart';
import 'package:find_my_food/features/scan_food/bloc/scan_food_cubit.dart';
import 'package:find_my_food/features/home/screens/add_food_screen.dart';
import 'package:find_my_food/features/home/models/food_model.dart';
import 'package:find_my_food/features/scan_food/bloc/scan_food_cubit.dart';
import 'package:find_my_food/features/scan_food/screens/scan_result_screen.dart';

class AIRecipeSelectionScreen extends StatefulWidget {
  final List<String> predictedNames;

  const AIRecipeSelectionScreen({
    super.key,
    required this.predictedNames,
  });

  @override
  State<AIRecipeSelectionScreen> createState() => _AIRecipeSelectionScreenState();
}

class _AIRecipeSelectionScreenState extends State<AIRecipeSelectionScreen> {
  String? _selectedName;
  final TextEditingController _customNameController = TextEditingController();
  final TextEditingController _customPromptController = TextEditingController();
  bool _isCustomMode = false;

  @override
  void initState() {
    super.initState();
    if (widget.predictedNames.isNotEmpty) {
      _selectedName = widget.predictedNames.first;
    } else {
      _isCustomMode = true;
      _selectedName = 'custom';
    }
  }

  @override
  void dispose() {
    _customNameController.dispose();
    _customPromptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Check if we already have a ScanFoodCubit in context, or create a new one
    // But usually this screen is pushed from ScanResult, so we might need a new provider 
    // or pass the cubit. Given the flow, a new provider is safer if we want to isolate AI gen.
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('เลือกเมนูที่ถูกต้อง'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.brandGradient,
          ),
        ),
      ),
      body: BlocProvider(
        create: (context) => ScanFoodCubit(),
        child: BlocConsumer<ScanFoodCubit, ScanFoodState>(
          listener: (context, state) {
            if (state is ScanFoodSuccess) {
              // Successfully generated! Go to Editor if model is available, else ScanResult
              if (state.recipeModel != null) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddFoodScreen(
                      initialRecipe: state.recipeModel,
                    ),
                  ),
                );
              } else {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ScanResultScreen(
                      image: null,
                      ingredients: state.ingredients,
                      dishResult: state.dishResponse,
                      isRecommendation: false,
                    ),
                  ),
                );
              }
            } else if (state is ScanFoodError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
          },
          builder: (context, state) {
            bool isLoading = state is ScanFoodLoading;

            return Padding(
              padding: EdgeInsets.all(20.scale),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI พบเมนูที่ใกล้เคียงดังนี้...',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'กรุณาเลือกชื่อเมนูที่ถูกต้องเพื่อสร้างสูตรอาหารด้วย AI',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 24.h),
                  Expanded(
                    child: ListView.builder(
                      itemCount: widget.predictedNames.length + 1,
                      itemBuilder: (context, index) {
                        final bool isOther = index == widget.predictedNames.length;
                        final name = isOther ? 'เมนูอื่นๆ...' : widget.predictedNames[index];
                        final isSelected = isOther ? _isCustomMode : (_selectedName == name && !_isCustomMode);

                        return Column(
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (isOther) {
                                    _isCustomMode = true;
                                    _selectedName = 'custom';
                                  } else {
                                    _isCustomMode = false;
                                    _selectedName = name;
                                  }
                                });
                              },
                              child: Container(
                                margin: EdgeInsets.only(bottom: 12.h),
                                padding: EdgeInsets.all(16.scale),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppTheme.brandPurple.withOpacity(0.1) : Colors.white,
                                  borderRadius: BorderRadius.circular(15.scale),
                                  border: Border.all(
                                    color: isSelected ? AppTheme.brandPurple : Colors.grey[300]!,
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isSelected ? Icons.check_circle : Icons.circle_outlined,
                                      color: isSelected ? AppTheme.brandPurple : Colors.grey,
                                    ),
                                    SizedBox(width: 16.w),
                                    Text(
                                      name,
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        color: isSelected ? AppTheme.brandPurple : Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (isOther && _isCustomMode) ...[
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.h),
                                child: Column(
                                  children: [
                                    _buildCustomInputField(
                                      controller: _customNameController,
                                      label: 'ชื่อเมนูอาหาร',
                                      hint: 'ตัวอย่าง: กะเพราไข่ดาวพรีเมียม',
                                      icon: Icons.restaurant_menu,
                                    ),
                                    SizedBox(height: 12.h),
                                    _buildCustomInputField(
                                      controller: _customPromptController,
                                      label: 'รายละเอียดเพิ่มเติม (Prompt)',
                                      hint: 'ตัวอย่าง: ขอแบบเผ็ดน้อย ใส่กะเพราเยอะๆ...',
                                      icon: Icons.edit_note,
                                      maxLines: 3,
                                    ),
                                    SizedBox(height: 16.h),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 20.h),
                  SizedBox(
                    width: double.infinity,
                    height: 55.h,
                    child: ElevatedButton(
                      onPressed: (isLoading || _selectedName == null || (_isCustomMode && _customNameController.text.isEmpty))
                          ? null
                          : () {
                              if (_isCustomMode) {
                                context.read<ScanFoodCubit>().generateAIRecipe(
                                  _customNameController.text.trim(),
                                  prompt: _customPromptController.text.trim(),
                                );
                              } else {
                                context.read<ScanFoodCubit>().generateAIRecipe(_selectedName!);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.brandPurple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.scale),
                        ),
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.auto_awesome, color: Colors.white),
                                SizedBox(width: 8.w),
                                Text(
                                  'สร้างสูตรอาหารด้วย AI',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
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
    );
  }

  Widget _buildCustomInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.brandPurple),
        labelStyle: TextStyle(color: AppTheme.brandPurple, fontSize: 14.sp),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.scale),
          borderSide: BorderSide(color: AppTheme.brandPurple.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.scale),
          borderSide: const BorderSide(color: AppTheme.brandPurple, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.scale),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      onChanged: (val) {
        // Trigger rebuild to update button state
        setState(() {});
      },
    );
  }
}
