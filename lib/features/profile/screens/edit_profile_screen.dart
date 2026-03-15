import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_cubit.dart';
import '../../../core/utils/responsive_helper.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        setState(() => _isUploading = true);
        await context.read<AuthCubit>().uploadProfileImage(image.path);
        setState(() => _isUploading = false);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('อัปโหลดรูปภาพสำเร็จ!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.scale)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20.scale),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'เลือกรูปภาพ',
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20.h),
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(10.scale),
                  decoration: BoxDecoration(
                    color: AppTheme.brandPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10.scale),
                  ),
                  child: Icon(Icons.camera_alt, color: AppTheme.brandPurple, size: 24.scale),
                ),
                title: Text('ถ่ายภาพ', style: TextStyle(fontSize: 16.sp)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(10.scale),
                  decoration: BoxDecoration(
                    color: AppTheme.brandPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10.scale),
                  ),
                  child: Icon(Icons.photo_library, color: AppTheme.brandPurple, size: 24.scale),
                ),
                title: Text('เลือกจากแกลเลอรี', style: TextStyle(fontSize: 16.sp)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showEditUsernameDialog(String currentUsername) async {
    final controller = TextEditingController(text: currentUsername);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('แก้ไขชื่อผู้ใช้'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'ชื่อผู้ใช้ใหม่'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthCubit>().updateUsername(controller.text.trim());
            },
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );
  }

  Future<void> _showChangePasswordDialog() async {
    final oldPassController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();
    bool isOldVisible = false;
    bool isNewVisible = false;
    bool isConfirmVisible = false;
    bool isLoading = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24.scale)),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 24.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2.scale),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  // Header
                  Row(
                    children: [
                      Icon(Icons.lock_reset, color: const Color(0xFFFF6B35), size: 28.scale),
                      SizedBox(width: 12.w),
                      Text(
                        'เปลี่ยนรหัสผ่าน',
                        style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  SizedBox(height: 24.h),
                  // Old password
                  TextField(
                    controller: oldPassController,
                    obscureText: !isOldVisible,
                    enabled: !isLoading,
                    decoration: InputDecoration(
                      labelText: 'รหัสผ่านเดิม',
                      prefixIcon: Icon(Icons.lock_outline, size: 24.scale),
                      suffixIcon: IconButton(
                        icon: Icon(isOldVisible ? Icons.visibility : Icons.visibility_off, size: 24.scale),
                        onPressed: () => setModalState(() => isOldVisible = !isOldVisible),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.scale)),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  // New password
                  TextField(
                    controller: newPassController,
                    obscureText: !isNewVisible,
                    enabled: !isLoading,
                    decoration: InputDecoration(
                      labelText: 'รหัสผ่านใหม่',
                      prefixIcon: Icon(Icons.lock_outline, size: 24.scale),
                      suffixIcon: IconButton(
                        icon: Icon(isNewVisible ? Icons.visibility : Icons.visibility_off, size: 24.scale),
                        onPressed: () => setModalState(() => isNewVisible = !isNewVisible),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.scale)),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  // Confirm password
                  TextField(
                    controller: confirmPassController,
                    obscureText: !isConfirmVisible,
                    enabled: !isLoading,
                    decoration: InputDecoration(
                      labelText: 'ยืนยันรหัสผ่านใหม่',
                      prefixIcon: Icon(Icons.lock_outline, size: 24.scale),
                      suffixIcon: IconButton(
                        icon: Icon(isConfirmVisible ? Icons.visibility : Icons.visibility_off, size: 24.scale),
                        onPressed: () => setModalState(() => isConfirmVisible = !isConfirmVisible),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.scale)),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              if (newPassController.text != confirmPassController.text) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        Icon(Icons.error_outline, color: Colors.white, size: 24.scale),
                                        SizedBox(width: 12.w),
                                        Text('รหัสผ่านใหม่ไม่ตรงกัน', style: TextStyle(fontSize: 14.sp)),
                                      ],
                                    ),
                                    backgroundColor: Colors.red,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.scale)),
                                  ),
                                );
                                return;
                              }
                              if (oldPassController.text.isEmpty ||
                                  newPassController.text.isEmpty ||
                                  confirmPassController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        Icon(Icons.error_outline, color: Colors.white, size: 24.scale),
                                        SizedBox(width: 12.w),
                                        Text('กรุณากรอกข้อมูลให้ครบ', style: TextStyle(fontSize: 14.sp)),
                                      ],
                                    ),
                                    backgroundColor: Colors.red,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.scale)),
                                  ),
                                );
                                return;
                              }
                              Navigator.pop(ctx);
                              context.read<AuthCubit>().changePassword(
                                    oldPassController.text,
                                    newPassController.text,
                                    confirmPassController.text,
                                  );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B35),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.scale),
                        ),
                      ),
                      child: isLoading
                          ? SizedBox(
                              height: 24.scale,
                              width: 24.scale,
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text('เปลี่ยนรหัสผ่าน', style: TextStyle(fontSize: 16.sp)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80.h,
        title: Text('แก้ไขข้อมูลส่วนตัว', style: TextStyle(fontSize: 20.sp)),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.brandGradient,
          ),
        ),
        foregroundColor: Colors.white,
      ),
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(
                 content: Text(state.message),
                 backgroundColor: Colors.red,
               ),
             );
          } else if (state is AuthAuthenticated && state.message != null) {
             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(
                 content: Text(state.message!),
                 backgroundColor: Colors.green,
               ),
             );
          }
        },
        builder: (context, state) {
          if (state is! AuthAuthenticated) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = state.user;

          return SingleChildScrollView(
            padding: EdgeInsets.all(24.scale),
            child: Column(
              children: [
                // Profile Image
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    GestureDetector(
                      onTap: _isUploading ? null : _showImageSourceDialog,
                      child: Container(
                        width: 120.scale,
                        height: 120.scale,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppTheme.brandGradient,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.brandPurple.withOpacity(0.3),
                              blurRadius: 15.scale,
                              offset: Offset(0, 5.h),
                            ),
                          ],
                        ),
                        child: _isUploading
                            ? const Center(
                                child: CircularProgressIndicator(color: Colors.white),
                              )
                            : user.profileImage != null && user.profileImage!.isNotEmpty
                                ? ClipOval(
                                    child: Image.network(
                                      user.profileImage!,
                                      fit: BoxFit.cover,
                                      width: 120.scale,
                                      height: 120.scale,
                                      errorBuilder: (_, __, ___) => _buildDefaultAvatar(user),
                                    ),
                                  )
                                : _buildDefaultAvatar(user),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(8.scale),
                      decoration: const BoxDecoration(
                        color: AppTheme.brandPurple,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20.scale,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                Text(
                  'กดที่รูปเพื่อเปลี่ยนรูปภาพของคุณ',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14.sp,
                  ),
                ),
                SizedBox(height: 32.h),

                // User Info Card
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.scale),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(20.scale),
                    child: Column(
                      children: [
                        _InfoRow(
                          icon: Icons.person,
                          label: 'ชื่อผู้ใช้',
                          value: user.username,
                          onEdit: () => _showEditUsernameDialog(user.username),
                        ),
                        Divider(height: 24.h),
                        _InfoRow(
                          icon: Icons.email,
                          label: 'อีเมล',
                          value: user.email.isNotEmpty ? user.email : '-',
                          // Email usually not editable directly or needs verification, so leaving readonly
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 24.h),

                // Change Password Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _showChangePasswordDialog,
                    icon: Icon(Icons.lock_reset, size: 20.scale),
                    label: Text('เปลี่ยนรหัสผ่าน', style: TextStyle(fontSize: 16.sp)),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.scale),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDefaultAvatar(dynamic user) {
    return Center(
      child: Text(
        user.username.isNotEmpty == true
            ? user.username.substring(0, 1).toUpperCase()
            : '👤',
        style: TextStyle(
          fontSize: 48.sp,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onEdit; // Added onEdit callback

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeCubit>().isDarkMode;

    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(10.scale),
          decoration: BoxDecoration(
            color: AppTheme.brandPurple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10.scale),
          ),
          child: Icon(icon, color: AppTheme.brandPurple, size: 24.scale),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
        if (onEdit != null)
           IconButton(
            icon: Icon(Icons.edit, size: 20.scale, color: Colors.grey), 
            onPressed: onEdit,
           ),
      ],
    );
  }
}
