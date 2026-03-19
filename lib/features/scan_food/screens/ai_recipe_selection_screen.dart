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

  @override
  void initState() {
    super.initState();
    if (widget.predictedNames.isNotEmpty) {
      _selectedName = widget.predictedNames.first;
    }
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
                      itemCount: widget.predictedNames.length,
                      itemBuilder: (context, index) {
                        final name = widget.predictedNames[index];
                        final isSelected = _selectedName == name;

                        return GestureDetector(
                          onTap: () => setState(() => _selectedName = name),
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
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 20.h),
                  SizedBox(
                    width: double.infinity,
                    height: 55.h,
                    child: ElevatedButton(
                      onPressed: (isLoading || _selectedName == null)
                          ? null
                          : () {
                              context.read<ScanFoodCubit>().generateAIRecipe(_selectedName!);
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
}
