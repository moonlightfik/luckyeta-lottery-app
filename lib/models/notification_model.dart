import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String title;
  final String message;
  final String type;
  final String lotteryId;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.lotteryId,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    return AppNotification(
      id: id,
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      type: data['type'] ?? '',
      lotteryId: data['lotteryId'] ?? '',
      isRead: data['isRead'] ?? false,
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ??
              DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'message': message,
      'type': type,
      'lotteryId': lotteryId,
      'isRead': isRead,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}