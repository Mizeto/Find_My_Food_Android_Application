import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_cubit.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../auth/services/auth_service.dart';
import 'edit_profile_screen.dart';
import './user_stock_screen.dart';
import './my_recipes_screen.dart';
import './liked_recipes_screen.dart';
import '../../notification/bloc/notification_bloc.dart';
import '../../notification/screens/notification_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeCubit>().isDarkMode;

    return Scaffold(
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          if (state is! AuthAuthenticated) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = state.user;

          return CustomScrollView(
            slivers: [
              // Profile Header
              SliverToBoxAdapter(
                child: _ProfileHeader(user: user, isDarkMode: isDarkMode),
              ),

              // Guest Banner: show bind account prompt
              if (user.isGuest)
                SliverToBoxAdapter(
                  child: Container(
                    margin: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 8.h,
                    ),
                    padding: EdgeInsets.all(20.scale),
                    decoration: BoxDecoration(
                      gradient: AppTheme.brandGradient,
                      borderRadius: BorderRadius.circular(16.scale),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.brandPurple.withOpacity(0.3),
                          blurRadius: 15.scale,
                          offset: Offset(0, 5.h),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.person_add,
                          color: Colors.white,
                          size: 40.scale,
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          'คุณกำลังใช้งานแบบผู้เยี่ยมชม',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'เข้าสู่ระบบหรือสมัครสมาชิกเพื่อใช้งานฟีเจอร์ทั้งหมด',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 13.sp,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16.h),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              context.read<AuthCubit>().signOut();
                            },
                            icon: const Icon(Icons.login),
                            label: Text(
                              'ผูกบัญชี / เข้าสู่ระบบ',
                              style: TextStyle(fontSize: 16.sp),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppTheme.brandPurple,
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.scale),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Menu Items (hide for guests)
              if (!user.isGuest)
                SliverToBoxAdapter(child: _ProfileMenu(isDarkMode: isDarkMode)),

              // Theme Toggle
              SliverToBoxAdapter(child: _ThemeToggle(isDarkMode: isDarkMode)),

              // Logout Button
              SliverToBoxAdapter(child: _LogoutButton()),

              SliverToBoxAdapter(child: SizedBox(height: 40.h)),
            ],
          );
        },
      ),
    );
  }
}

// Profile Header Widget
class _ProfileHeader extends StatelessWidget {
  final dynamic user;
  final bool isDarkMode;

  const _ProfileHeader({required this.user, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 60.h, 20.w, 12.h),
      child: Column(
        children: [
          // Avatar and Notification Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Container(
                width: 70.scale,
                height: 70.scale,
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
                child:
                    user.profileImage != null && user.profileImage!.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          user.profileImage!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildDefaultAvatar(),
                        ),
                      )
                    : _buildDefaultAvatar(),
              ),

              const Spacer(),

              // Notification Icon
              BlocBuilder<NotificationBloc, NotificationState>(
                builder: (context, state) {
                  int unreadCount = 0;
                  if (state is NotificationLoaded) {
                    unreadCount = state.unreadCount;
                  }
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.all(8.scale),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? Colors.white.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Badge(
                        label: unreadCount > 0
                            ? Text(unreadCount.toString())
                            : null,
                        isLabelVisible: unreadCount > 0,
                        backgroundColor: Colors.red,
                        child: Icon(
                          Icons.notifications_outlined,
                          color: isDarkMode ? Colors.white : Colors.black87,
                          size: 24.scale,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 12),

          // User Info
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.username,
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  user.email,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Center(
      child: Text(
        user.username.isNotEmpty == true
            ? user.username.substring(0, 1).toUpperCase()
            : '👤',
        style: TextStyle(
          fontSize: 28.sp,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}


// Profile Menu
class _ProfileMenu extends StatelessWidget {
  final bool isDarkMode;

  const _ProfileMenu({required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    final menuItems = [
      _MenuItem(Icons.person_outline, 'โปรไฟล์'),
      _MenuItem(Icons.kitchen_outlined, 'จัดการวัตถุดิบ (ตู้เย็น)'),
      _MenuItem(Icons.restaurant_menu_outlined, 'สูตรอาหารของฉัน'),
      _MenuItem(Icons.favorite_outline, 'เมนูที่ถูกใจ'),
      _MenuItem(Icons.send_outlined, 'ส่งข้อเสนอแนะ'),
    ];

    return Column(
      children: [
        const Divider(height: 0.5),
        ...menuItems.map(
          (item) => _MenuItemTile(
            icon: item.icon,
            title: item.title,
            isDarkMode: isDarkMode,
            onTap: () {
              if (item.title == 'โปรไฟล์') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EditProfileScreen(),
                  ),
                );
              } else if (item.title == 'จัดการวัตถุดิบ (ตู้เย็น)') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UserStockScreen(),
                  ),
                );
              } else if (item.title == 'สูตรอาหารของฉัน') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MyRecipesScreen(),
                  ),
                );
              } else if (item.title == 'เมนูที่ถูกใจ') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LikedRecipesScreen(),
                  ),
                );
              } else if (item.title == 'ส่งข้อเสนอแนะ') {
                _showFeedbackDialog(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('เปิด ${item.title}'),
                    duration: const Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  void _showFeedbackDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final detailCtrl = TextEditingController();
    bool isSending = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final isDarkMode = context.read<ThemeCubit>().isDarkMode;
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1E1E2E) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.white24 : Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    children: [
                      Icon(
                        Icons.feedback_outlined,
                        color: AppTheme.brandBlue,
                        size: 28.scale,
                      ),
                      SizedBox(width: 12.w),
                      ShaderMask(
                        shaderCallback: (bounds) => AppTheme.brandGradient.createShader(
                          Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                        ),
                        child: Text(
                          'ส่งข้อเสนอแนะ',
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white, // Required for ShaderMask to show colors
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  TextField(
                    controller: titleCtrl,
                    enabled: !isSending,
                    style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      labelText: 'หัวข้อ',
                      labelStyle: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                      prefixIcon: Icon(Icons.title, size: 24.scale, color: AppTheme.brandBlue),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.scale),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.scale),
                        borderSide: const BorderSide(color: AppTheme.brandBlue, width: 2),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  TextField(
                    controller: detailCtrl,
                    enabled: !isSending,
                    maxLines: 4,
                    style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      labelText: 'รายละเอียด',
                      labelStyle: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                      alignLabelWithHint: true,
                      prefixIcon: Padding(
                        padding: EdgeInsets.only(bottom: 52.h),
                        child: Icon(Icons.description_outlined, size: 24.scale, color: AppTheme.brandBlue),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.scale),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.scale),
                        borderSide: const BorderSide(color: AppTheme.brandBlue, width: 2),
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  GestureDetector(
                    onTap: isSending
                        ? null
                        : () async {
                            final title = titleCtrl.text.trim();
                            final detail = detailCtrl.text.trim();
                            if (title.isEmpty || detail.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'กรุณากรอกหัวข้อและรายละเอียด',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            setModalState(() => isSending = true);
                            try {
                              final ok = await AuthService().submitFeedback(
                                title: title,
                                detail: detail,
                              );
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        Icon(
                                          ok
                                              ? Icons.check_circle
                                              : Icons.error_outline,
                                          color: Colors.white,
                                          size: 24.scale,
                                        ),
                                        SizedBox(width: 12.w),
                                        Text(
                                          ok
                                              ? 'ส่งข้อเสนอแนะเรียบร้อยแล้ว ขอบคุณ!'
                                              : 'ส่งข้อเสนอแนะไม่สำเร็จ',
                                          style: TextStyle(fontSize: 14.sp),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: ok
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                );
                              }
                            } catch (e) {
                              setModalState(() => isSending = false);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('เกิดข้อผิดพลาด: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                    child: Container(
                      width: double.infinity,
                      height: 50.h,
                      decoration: BoxDecoration(
                        gradient: isSending ? null : AppTheme.brandGradient,
                        color: isSending ? Colors.grey : null,
                        borderRadius: BorderRadius.circular(12.scale),
                        boxShadow: isSending ? null : [
                          BoxShadow(
                            color: AppTheme.brandPurple.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: isSending
                            ? SizedBox(
                                height: 24.scale,
                                width: 24.scale,
                                child: const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'ส่งข้อเสนอแนะ',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
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
}

class _MenuItem {
  final IconData icon;
  final String title;

  _MenuItem(this.icon, this.title);
}

class _MenuItemTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isDarkMode;
  final VoidCallback onTap;

  const _MenuItemTile({
    required this.icon,
    required this.title,
    required this.isDarkMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.scale),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey[100],
                borderRadius: BorderRadius.circular(10.scale),
              ),
              child: Icon(
                icon,
                size: 20.scale,
                color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
            SizedBox(width: 16.w),
            Text(
              title,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right,
              size: 24.scale,
              color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}

// Theme Toggle
class _ThemeToggle extends StatelessWidget {
  final bool isDarkMode;

  const _ThemeToggle({required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      padding: EdgeInsets.all(16.scale),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.white.withOpacity(0.05)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16.scale),
      ),
      child: Row(
        children: [
          Icon(
            isDarkMode ? Icons.dark_mode : Icons.light_mode,
            size: 24.scale,
            color: isDarkMode ? Colors.yellow[600] : Colors.orange,
          ),
          SizedBox(width: 12.w),
          Text(
            isDarkMode ? 'โหมดมืด' : 'โหมดสว่าง',
            style: TextStyle(
              fontSize: 16.sp,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const Spacer(),
          Switch(
            value: isDarkMode,
            onChanged: (_) {
              context.read<ThemeCubit>().toggleTheme();
            },
            activeColor: AppTheme.brandPurple,
          ),
        ],
      ),
    );
  }
}

// Logout Button
class _LogoutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isGuest = context.watch<AuthCubit>().isGuest;
    final labelText = isGuest ? 'เข้าสู่ระบบ' : 'ออกจากระบบ';
    final dialogTitle = isGuest ? 'เข้าสู่ระบบ' : 'ออกจากระบบ';
    final dialogContent = isGuest
        ? 'คุณต้องการไปที่หน้าเข้าสู่ระบบเพื่อผูกบัญชีหรือไม่?'
        : 'คุณต้องการออกจากระบบหรือไม่?';

    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 16.h),
      child: OutlinedButton.icon(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(dialogTitle),
              content: Text(dialogContent),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('ยกเลิก'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.read<AuthCubit>().signOut();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: isGuest ? Colors.blue : Colors.red,
                  ),
                  child: Text(dialogTitle),
                ),
              ],
            ),
          );
        },
        icon: Icon(
          isGuest ? Icons.login : Icons.logout,
          color: isGuest ? Colors.blue : Colors.red,
          size: 20.scale,
        ),
        label: Text(
          labelText,
          style: TextStyle(
            color: isGuest ? Colors.blue : Colors.red,
            fontSize: 16.sp,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: isGuest ? Colors.blue : Colors.red),
          padding: EdgeInsets.symmetric(vertical: 14.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.scale),
          ),
        ),
      ),
    );
  }
}
