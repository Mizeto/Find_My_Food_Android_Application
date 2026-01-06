import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_cubit.dart';
import '../../auth/cubit/auth_cubit.dart';

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

              // Menu Items
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
      _MenuItem(Icons.person_outline, 'โพรไฟล์'),
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
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('เปิด ${item.title}'),
                    duration: const Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            )),
      ],
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
    return Container(
      margin: const EdgeInsets.all(16),
      child: OutlinedButton.icon(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('ออกจากระบบ'),
              content: const Text('คุณต้องการออกจากระบบหรือไม่?'),
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
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('ออกจากระบบ'),
                ),
              ],
            ),
          );
        },
        icon: const Icon(Icons.logout, color: Colors.red),
        label: const Text(
          'ออกจากระบบ',
          style: TextStyle(color: Colors.red),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.red),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
