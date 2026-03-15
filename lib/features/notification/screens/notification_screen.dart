import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../bloc/notification_bloc.dart';
import '../../../data/models/notification_model.dart';
import '../../../core/utils/responsive_helper.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: () async {
              context.read<NotificationBloc>().add(FetchNotifications());
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Premium AppBar
                SliverAppBar(
                  toolbarHeight: 80.h,
                  pinned: true,
                  stretch: true,
                  centerTitle: true,
                  title: Text(
                    'การแจ้งเตือน',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20.sp,
                      color: Colors.white,
                    ),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    stretchModes: const [StretchMode.zoomBackground],
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: AppTheme.brandGradient,
                      ),
                    ),
                  ),
                  leading: IconButton(
                    icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: 20.scale),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
  
                // Content
                _buildBody(context, state),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, NotificationState state) {
    if (state is NotificationLoading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (state is NotificationError) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 60.scale, color: Colors.red),
              SizedBox(height: 16.h),
              Text('เกิดข้อผิดพลาด: ${state.message}', style: TextStyle(fontSize: 14.sp)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  context.read<NotificationBloc>().add(FetchNotifications());
                },
                child: const Text('ลองใหม่'),
              ),
            ],
          ),
        ),
      );
    }

    if (state is NotificationLoaded) {
      final notifications = state.notifications;

      if (notifications.isEmpty) {
        return SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(24.scale),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.notifications_off_outlined,
                    size: 80.scale,
                    color: Colors.grey.withOpacity(0.5),
                  ),
                ),
                SizedBox(height: 24.h),
                Text(
                  'ไม่มีการแจ้งเตือนในขณะนี้',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'เราจะแจ้งให้คุณทราบเมื่อมีข่าวสารใหม่ๆ',
                  style: TextStyle(color: Colors.grey, fontSize: 14.sp),
                ),
              ],
            ),
          ),
        );
      }

      // Group by date
      final grouped = _groupNotifications(notifications);

      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final key = grouped.keys.elementAt(index);
            final items = grouped[key]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 12.h),
                  child: Text(
                    key,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.brandPurple,
                    ),
                  ),
                ),
                ...items.map((noti) => _NotificationItemCard(notification: noti)),
              ],
            );
          },
          childCount: grouped.length,
        ),
      );
    }

    return const SliverToBoxAdapter(child: SizedBox.shrink());
  }

  Map<String, List<NotificationModel>> _groupNotifications(List<NotificationModel> list) {
    final Map<String, List<NotificationModel>> groups = {};
    final now = DateTime.now();

    for (var noti in list) {
      String key;
      final diff = now.difference(noti.createdAt).inDays;

      if (diff == 0) {
        key = 'วันนี้';
      } else if (diff == 1) {
        key = 'เมื่อวาน';
      } else {
        key = 'ก่อนหน้านี้';
      }

      if (!groups.containsKey(key)) {
        groups[key] = [];
      }
      groups[key]!.add(noti);
    }

    return groups;
  }
}

class _NotificationItemCard extends StatelessWidget {
  final NotificationModel notification;

  const _NotificationItemCard({required this.notification});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16.scale),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10.scale,
            offset: Offset(0, 4.h),
          ),
        ],
        border: notification.isRead 
          ? null 
          : Border.all(color: AppTheme.brandPurple.withOpacity(0.2), width: 1.w),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.scale),
        child: InkWell(
          onTap: () {
            if (!notification.isRead) {
              context.read<NotificationBloc>().add(
                MarkNotificationAsRead(id: notification.id),
              );
            }
          },
          child: Stack(
            children: [
              // Unread indicator line
              if (!notification.isRead)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 4.w,
                  child: Container(color: AppTheme.brandPurple),
                ),
              
              Padding(
                padding: EdgeInsets.all(16.scale),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon with background
                    Container(
                      padding: EdgeInsets.all(12.scale),
                      decoration: BoxDecoration(
                        color: _getIconColor(notification.type).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getIcon(notification.type),
                        color: _getIconColor(notification.type),
                        size: 24.scale,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  notification.title,
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: notification.isRead
                                        ? FontWeight.w600
                                        : FontWeight.bold,
                                  ),
                                  softWrap: true,
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Text(
                                notification.timeAgo,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            notification.message,
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: notification.isRead 
                                ? Colors.grey[600] 
                                : Theme.of(context).textTheme.bodyMedium?.color,
                              height: 1.4,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    
                    if (!notification.isRead)
                      Container(
                        margin: EdgeInsets.only(left: 8.w, top: 4.h),
                        width: 10.scale,
                        height: 10.scale,
                        decoration: BoxDecoration(
                          color: AppTheme.brandPurple,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange,
                              blurRadius: 4.scale,
                              spreadRadius: 1.scale,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIcon(String? type) {
    switch (type) {
      case 'expire':
        return Icons.timer_outlined;
      case 'info':
        return Icons.info_outline;
      case 'success':
        return Icons.check_circle_outline;
      default:
        return Icons.notifications_none;
    }
  }

  Color _getIconColor(String? type) {
    switch (type) {
      case 'expire':
        return Colors.orange;
      case 'info':
        return Colors.blue;
      case 'success':
        return Colors.green;
      default:
        return AppTheme.brandPurple;
    }
  }
}
