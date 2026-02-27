import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_cubit.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../auth/services/auth_service.dart';
import 'edit_profile_screen.dart';

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
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF6B35).withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.person_add, color: Colors.white, size: 40),
                        const SizedBox(height: 12),
                        const Text(
                          'คุณกำลังใช้งานแบบผู้เยี่ยมชม',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'เข้าสู่ระบบหรือสมัครสมาชิกเพื่อใช้งานฟีเจอร์ทั้งหมด',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              context.read<AuthCubit>().signOut();
                            },
                            icon: const Icon(Icons.login),
                            label: const Text('ผูกบัญชี / เข้าสู่ระบบ', style: TextStyle(fontSize: 16)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFFFF6B35),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
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
                SliverToBoxAdapter(
                  child: _ProfileMenu(isDarkMode: isDarkMode),
                ),

              // Theme Toggle
              SliverToBoxAdapter(
                child: _ThemeToggle(isDarkMode: isDarkMode),
              ),

              // Logout Button
              SliverToBoxAdapter(
                child: _LogoutButton(),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
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
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
      child: Column(
        children: [
          // Avatar and Notification Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTheme.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryOrange.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: user.profileImage != null && user.profileImage!.isNotEmpty
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.white.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.notifications_outlined,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // User Info
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.username,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Stats Row
          Row(
            children: [
              _StatItem(
                count: '0',
                label: 'ผู้ติดตาม',
                isDarkMode: isDarkMode,
              ),
              const SizedBox(width: 24),
              _StatItem(
                count: '0',
                label: 'กำลังติดตาม',
                isDarkMode: isDarkMode,
              ),
            ],
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
        style: const TextStyle(
          fontSize: 28,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// Stat Item
class _StatItem extends StatelessWidget {
  final String count;
  final String label;
  final bool isDarkMode;

  const _StatItem({
    required this.count,
    required this.label,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          count,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      ],
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
      _MenuItem(Icons.notifications_outlined, 'เพื่อนของคุณ'),
      _MenuItem(Icons.bar_chart, 'สถิติของสูตร'),
      _MenuItem(Icons.access_time, 'สูตรอาหารที่เพิ่งดู'),
      _MenuItem(Icons.workspace_premium_outlined, 'พรีเมียม'),
      _MenuItem(Icons.emoji_events_outlined, 'กิจกรรม'),
      _MenuItem(Icons.settings_outlined, 'การตั้งค่า'),
      _MenuItem(Icons.help_outline, 'คำถามที่พบบ่อย'),
      _MenuItem(Icons.send_outlined, 'ส่งข้อเสนอแนะ'),
    ];

    return Column(
      children: [
        const Divider(height: 1),
        ...menuItems.map((item) => _MenuItemTile(
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
            )),
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
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Row(
                    children: [
                      Icon(Icons.feedback_outlined, color: Color(0xFFFF6B35), size: 28),
                      SizedBox(width: 12),
                      Text(
                        'ส่งข้อเสนอแนะ',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: titleCtrl,
                    enabled: !isSending,
                    decoration: InputDecoration(
                      labelText: 'หัวข้อ',
                      prefixIcon: const Icon(Icons.title),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: detailCtrl,
                    enabled: !isSending,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'รายละเอียด',
                      alignLabelWithHint: true,
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 52),
                        child: Icon(Icons.description_outlined),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isSending
                          ? null
                          : () async {
                              final title = titleCtrl.text.trim();
                              final detail = detailCtrl.text.trim();
                              if (title.isEmpty || detail.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('กรุณากรอกหัวข้อและรายละเอียด'),
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
                                            ok ? Icons.check_circle : Icons.error_outline,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(width: 12),
                                          Text(ok
                                              ? 'ส่งข้อเสนอแนะเรียบร้อยแล้ว ขอบคุณ!'
                                              : 'ส่งข้อเสนอแนะไม่สำเร็จ'),
                                        ],
                                      ),
                                      backgroundColor: ok ? Colors.green : Colors.red,
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B35),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isSending
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('ส่งข้อเสนอแนะ', style: TextStyle(fontSize: 16)),
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right,
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.white.withOpacity(0.05)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            isDarkMode ? Icons.dark_mode : Icons.light_mode,
            color: isDarkMode ? Colors.yellow[600] : Colors.orange,
          ),
          const SizedBox(width: 12),
          Text(
            isDarkMode ? 'โหมดมืด' : 'โหมดสว่าง',
            style: TextStyle(
              fontSize: 16,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const Spacer(),
          Switch(
            value: isDarkMode,
            onChanged: (_) {
              context.read<ThemeCubit>().toggleTheme();
            },
            activeColor: AppTheme.primaryOrange,
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
      margin: const EdgeInsets.all(16),
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
        ),
        label: Text(
          labelText,
          style: TextStyle(color: isGuest ? Colors.blue : Colors.red),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: isGuest ? Colors.blue : Colors.red),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
