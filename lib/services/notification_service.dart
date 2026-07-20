import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Generic notification creator
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    required String lotteryId,
    String? action,
  }) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .add({
      'title': title,
      'message': message,
      'type': type,
      'lotteryId': lotteryId,
      'action': action,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Creator notification when lottery sells out
  Future<void> notifyLotterySoldOut({
    required String creatorId,
    required String creatorName,
    required String lotteryId,
    required String lotteryTitle,
    required int totalTickets,
  }) async {
    await sendNotification(
      userId: creatorId,
      title: "🎉 Your lottery is sold out!",
      message:
          "Hi $creatorName,\n\nYour lottery \"$lotteryTitle\" has officially sold all $totalTickets tickets.\n\nThe draw is now ready.",
      type: "sold_out",
      lotteryId: lotteryId,
      action: "view_lottery",
    );
  }

  /// Creator notification after draw
  Future<void> notifyDrawCompleted({
    required String creatorId,
    required String creatorName,
    required String lotteryId,
    required String lotteryTitle,
  }) async {
    await sendNotification(
      userId: creatorId,
      title: "🏆 Draw Completed",
      message:
          "Hi $creatorName,\n\nThe draw for \"$lotteryTitle\" has finished.\n\nTap to view the winners.",
      type: "draw_complete",
      lotteryId: lotteryId,
      action: "view_winners",
    );
  }

  /// Winner notification
  Future<void> notifyWinner({
    required String userId,
    required String userName,
    required String lotteryId,
    required String lotteryTitle,
  }) async {
    await sendNotification(
      userId: userId,
      title: "🎉 Congratulations!",
      message:
          "Hi $userName,\n\nYou won \"$lotteryTitle\"!\n\nTap here to claim your prize.",
      type: "winner",
      lotteryId: lotteryId,
      action: "claim_prize",
    );
  }

  /// Loser notification
  Future<void> notifyLoser({
    required String userId,
    required String userName,
    required String lotteryId,
    required String lotteryTitle,
  }) async {
    await sendNotification(
      userId: userId,
      title: "🍀 Better Luck Next Time",
      message:
          "Hi $userName,\n\nThe draw for \"$lotteryTitle\" has ended.\n\nUnfortunately your ticket wasn't selected this time.\n\nTry again—you might be the next winner!",
      type: "loser",
      lotteryId: lotteryId,
      action: "buy_again",
    );
  }

  /// Mark notification as read
  Future<void> markAsRead({
    required String userId,
    required String notificationId,
  }) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .update({
      'isRead': true,
    });
  }
}