import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../bloc/scan_food_cubit.dart';
import 'scan_result_screen.dart';

class ScanFoodScreen extends StatelessWidget {
  const ScanFoodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ScanFoodCubit(),
      child: const _ScanFoodView(),
    );
  }
}

class _ScanFoodView extends StatefulWidget {
  const _ScanFoodView();

  @override
  State<_ScanFoodView> createState() => _ScanFoodViewState();
}

class _ScanFoodViewState extends State<_ScanFoodView> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  bool _isDishMode = true; // Default to Dish Prediction

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null && context.mounted) {
        setState(() {
          _image = File(pickedFile.path);
        });
        context.read<ScanFoodCubit>().analyzeImage(pickedFile, isDishPrediction: _isDishMode);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Scanner 📸'),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,
          ),
        ),
      ),
      body: BlocConsumer<ScanFoodCubit, ScanFoodState>(
        listener: (context, state) {
          if (state is ScanFoodSuccess) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ScanResultScreen(
                  image: _image!,
                  ingredients: state.ingredients,
                  dishResult: state.dishResponse,
                ),
              ),
            );
          } else if (state is ScanFoodError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          bool isAnalyzing = state is ScanFoodLoading;

          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isAnalyzing) ...[
                    const SizedBox(height: 100),
                    const CircularProgressIndicator(),
                    const SizedBox(height: 24),
                    Text(
                      _isDishMode ? 'กำลังวิเคราะห์เมนูอาหาร...' : 'กำลังวิเคราะห์วัตถุดิบ...',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'AI กำลังประมวลผลรูปภาพของคุณ',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ] else ...[
                    // Selection Mode
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildModeToggle(
                              label: 'ทายเมนูอาหาร',
                              icon: Icons.restaurant,
                              isSelected: _isDishMode,
                              onTap: () => setState(() => _isDishMode = true),
                            ),
                          ),
                          Expanded(
                            child: _buildModeToggle(
                              label: 'สแกนวัตถุดิบ',
                              icon: Icons.shopping_basket,
                              isSelected: !_isDishMode,
                              onTap: () => setState(() => _isDishMode = false),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Preview Area
                    if (_image != null)
                      Container(
                        height: 250,
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 32),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                          image: DecorationImage(
                            image: FileImage(_image!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                    else
                      Container(
                        height: 160,
                        margin: const EdgeInsets.only(bottom: 32),
                        decoration: BoxDecoration(
                          color: _isDishMode ? AppTheme.primaryOrange.withOpacity(0.05) : AppTheme.primaryGreen.withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            _isDishMode ? Icons.fastfood : Icons.kitchen,
                            size: 70,
                            color: _isDishMode ? AppTheme.primaryOrange.withOpacity(0.5) : AppTheme.primaryGreen.withOpacity(0.5),
                          ),
                        ),
                      ),
            
                    Text(
                      _isDishMode ? 'คุณทานอะไรอยู่ครับ?' : 'มีวัตถุดิบอะไรบ้าง?',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _isDishMode 
                        ? 'ให้ AI ช่วยทายว่าจานนี้คือเมนูอะไร\nคัดเลือกมาให้ 3 อันดับที่แม่นยำที่สุด!'
                        : 'ถ่ายรูปวัตถุดิบในตู้เย็น\nให้เราช่วยหาเมนูที่ทำได้จริง!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, color: Colors.grey[600], height: 1.5),
                    ),
                    const SizedBox(height: 40),
            
                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: _buildSmallActionButton(
                            icon: Icons.photo_library_outlined,
                            label: 'อัลบั้ม',
                            onTap: () => _pickImage(context, ImageSource.gallery),
                            color: Colors.grey[700]!,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildSmallActionButton(
                            icon: Icons.camera_alt,
                            label: 'ถ่ายรูป',
                            onTap: () => _pickImage(context, ImageSource.camera),
                            color: _isDishMode ? AppTheme.primaryOrange : AppTheme.primaryGreen,
                            isPrimary: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildModeToggle({required String label, required IconData icon, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))] : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: isSelected ? AppTheme.primaryOrange : Colors.grey),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontSize: 14, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Colors.black : Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallActionButton({required IconData icon, required String label, required VoidCallback onTap, required Color color, bool isPrimary = false}) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? color : Colors.white,
        foregroundColor: isPrimary ? Colors.white : color,
        elevation: isPrimary ? 4 : 0,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: isPrimary ? BorderSide.none : BorderSide(color: color.withOpacity(0.2))),
      ),
    );
  }
}
