import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.createdAt,
    required this.isRead,
    required this.relatedId,
  });

  final String id;
  final String title;
  final String description;
  final String type;
  final DateTime? createdAt;
  final bool isRead;
  final String relatedId;

  String get timestampLabel {
    final time = createdAt;
    if (time == null) return 'Just now';
    final now = DateTime.now();
    if (time.year == now.year &&
        time.month == now.month &&
        time.day == now.day) {
      final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
      return '$hour:${time.minute.toString().padLeft(2, '0')}';
    }
    return '${time.day}/${time.month}/${time.year}';
  }

  factory NotificationModel.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    final createdAt = data['createdAt'];
    return NotificationModel(
      id: id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      type: data['type'] as String? ?? 'general',
      createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
      isRead: data['isRead'] as bool? ?? false,
      relatedId: data['relatedId'] as String? ?? '',
    );
  }
}
