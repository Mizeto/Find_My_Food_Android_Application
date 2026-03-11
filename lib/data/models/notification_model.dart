import 'package:intl/intl.dart';

class NotificationModel {
  final int id;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;
  final String? type;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
    this.type,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    // Handle different date formats or nulls if necessary
    DateTime parsedDate;
    try {
      if (json['created_at'] != null) {
        parsedDate = DateTime.parse(json['created_at']);
      } else if (json['create_date'] != null) {
        parsedDate = DateTime.parse(json['create_date']);
      } else {
        parsedDate = DateTime.now();
      }
    } catch (e) {
      parsedDate = DateTime.now();
    }

    final title = json['title'] ?? '';
    final message = json['body'] ?? json['message'] ?? '';
    
    // Infer type if not provided
    String? type = json['type'];
    if (type == null) {
      if (title.contains('🚨') || message.contains('หมดอายุ')) {
        type = 'expire';
      }
    }

    return NotificationModel(
      id: json['notification_id'] ?? json['id'] ?? 0,
      title: title,
      message: message,
      isRead: json['is_read'] == 1 || json['is_read'] == true,
      createdAt: parsedDate,
      type: type,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'type': type,
    };
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 7) {
      return DateFormat('dd MMM yyyy', 'th_TH').format(createdAt);
    } else if (difference.inDays >= 1) {
      return '${difference.inDays} วันที่แล้ว';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours} ชั่วโมงที่แล้ว';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes} นาทีที่แล้ว';
    } else {
      return 'เมื่อสักครู่';
    }
  }
}
