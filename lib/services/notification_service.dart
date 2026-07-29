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
    Map<String, dynamic>? extraData,
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
      'extraData': extraData ?? {},
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
      extraData: {
        'totalTickets': totalTickets,
        'creatorName': creatorName,
      },
    );
  }

  /// Creator notification after draw (UPDATED with more details)
  Future<void> notifyDrawCompleted({
    required String creatorId,
    required String creatorName,
    required String lotteryId,
    required String lotteryTitle,
    int? winnersCount,
    int? totalParticipants,
    List<String>? winnerIds,
    List<int>? winningNumbers,
  }) async {
    String message;
    
    if (winnersCount != null && totalParticipants != null) {
      message = "Hi $creatorName,\n\nThe draw for \"$lotteryTitle\" has finished!\n\n"
          "🎯 $winnersCount winner(s) selected from $totalParticipants participants.\n\n"
          "Tap to view the winners.";
    } else {
      message = "Hi $creatorName,\n\nThe draw for \"$lotteryTitle\" has finished.\n\n"
          "Tap to view the winners.";
    }

    await sendNotification(
      userId: creatorId,
      title: "🏆 Draw Completed!",
      message: message,
      type: "draw_complete",
      lotteryId: lotteryId,
      action: "view_winners",
      extraData: {
        'winnersCount': winnersCount,
        'totalParticipants': totalParticipants,
        'winnerIds': winnerIds,
        'winningNumbers': winningNumbers,
        'creatorName': creatorName,
      },
    );
  }

  /// 🆕 Creator reminder for upcoming draw
  Future<void> notifyCreatorUpcomingDraw({
    required String creatorId,
    required String creatorName,
    required String lotteryId,
    required String lotteryTitle,
    required DateTime drawTime,
    int? ticketsSold,
    int? totalTickets,
  }) async {
    final timeRemaining = drawTime.difference(DateTime.now());
    final hoursRemaining = timeRemaining.inHours;
    final minutesRemaining = timeRemaining.inMinutes;

    String timeMessage;
    if (hoursRemaining > 0) {
      timeMessage = '$hoursRemaining hours';
    } else if (minutesRemaining > 0) {
      timeMessage = '$minutesRemaining minutes';
    } else {
      timeMessage = 'very soon';
    }

    String ticketStatus = '';
    if (ticketsSold != null && totalTickets != null) {
      ticketStatus = '\n📊 $ticketsSold out of $totalTickets tickets sold.';
    }

    await sendNotification(
      userId: creatorId,
      title: "⏰ Draw Reminder",
      message: "Hi $creatorName,\n\nThe draw for \"$lotteryTitle\" is scheduled in $timeMessage!$ticketStatus\n\n"
          "Make sure everything is ready.",
      type: "draw_reminder",
      lotteryId: lotteryId,
      action: "view_lottery",
      extraData: {
        'drawTime': drawTime.toIso8601String(),
        'hoursRemaining': hoursRemaining,
        'minutesRemaining': minutesRemaining,
        'ticketsSold': ticketsSold,
        'totalTickets': totalTickets,
        'creatorName': creatorName,
      },
    );
  }

  /// 🆕 Notification for low ticket sales (when draw time is near)
  Future<void> notifyCreatorLowTickets({
    required String creatorId,
    required String creatorName,
    required String lotteryId,
    required String lotteryTitle,
    required int ticketsSold,
    required int totalTickets,
    required DateTime drawTime,
  }) async {
    final remainingTickets = totalTickets - ticketsSold;
    final drawTimeFormatted = '${drawTime.hour.toString().padLeft(2, '0')}:${drawTime.minute.toString().padLeft(2, '0')}';

    await sendNotification(
      userId: creatorId,
      title: "⚠️ Low Ticket Sales Alert",
      message: "Hi $creatorName,\n\nYour lottery \"$lotteryTitle\" has only $remainingTickets tickets remaining.\n\n"
          "The draw is scheduled for $drawTimeFormatted. Consider promoting it!",
      type: "low_tickets",
      lotteryId: lotteryId,
      action: "promote_lottery",
      extraData: {
        'ticketsSold': ticketsSold,
        'totalTickets': totalTickets,
        'remainingTickets': remainingTickets,
        'drawTime': drawTime.toIso8601String(),
        'creatorName': creatorName,
      },
    );
  }

  /// Winner notification (UPDATED with ticket number)
  Future<void> notifyWinner({
    required String userId,
    required String lotteryId,
    required String lotteryTitle,
    int? ticketNumber,
  }) async {
    String message;
    if (ticketNumber != null) {
      message = "🎉 Congratulations!\n\nYou won \"$lotteryTitle\" with ticket #$ticketNumber!\n\n"
          "Tap here to claim your prize.";
    } else {
      message = "🎉 Congratulations!\n\nYou won \"$lotteryTitle\"!\n\n"
          "Tap here to claim your prize.";
    }

    await sendNotification(
      userId: userId,
      title: "🎉 Congratulations!",
      message: message,
      type: "winner",
      lotteryId: lotteryId,
      action: "claim_prize",
      extraData: {
        'ticketNumber': ticketNumber,
        'lotteryTitle': lotteryTitle,
      },
    );
  }

  /// Loser notification (UPDATED with more details)
  Future<void> notifyLoser({
    required String userId,
    required String lotteryId,
    required String lotteryTitle,
    int? ticketNumber,
  }) async {
    String message;
    if (ticketNumber != null) {
      message = "🍀 Better Luck Next Time\n\nThe draw for \"$lotteryTitle\" has ended.\n\n"
          "Your ticket #$ticketNumber wasn't selected this time.\n\n"
          "Better luck next time!";
    } else {
      message = "🍀 Better Luck Next Time\n\nThe draw for \"$lotteryTitle\" has ended.\n\n"
          "Unfortunately your ticket wasn't selected this time.\n\n"
          "Better luck next time!";
    }

    await sendNotification(
      userId: userId,
      title: "🍀 Better Luck Next Time",
      message: message,
      type: "loser",
      lotteryId: lotteryId,
      action: "buy_again",
      extraData: {
        'ticketNumber': ticketNumber,
        'lotteryTitle': lotteryTitle,
      },
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

  /// 🆕 Mark all notifications as read
  Future<void> markAllAsRead({
    required String userId,
  }) async {
    final notifications = await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (final doc in notifications.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  /// 🆕 Get unread notification count (FIXED)
  Future<int> getUnreadNotificationCount({
    required String userId,
  }) async {
    try {
      // Try using count() first (newer Firebase version)
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .count()
          .get();
      
      return snapshot.count ?? 0;
    } catch (e) {
      // Fallback to fetching all docs (older Firebase version)
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();
      
      return snapshot.docs.length;
    }
  }

  /// 🆕 Delete old notifications
  Future<void> deleteOldNotifications({
    required String userId,
    int daysOld = 30,
  }) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
    
    final oldNotifications = await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('createdAt', isLessThan: Timestamp.fromDate(cutoffDate))
        .get();

    final batch = _firestore.batch();
    for (final doc in oldNotifications.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}