import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/notification_service.dart';

class LotteryDrawService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();
  final Random _random = Random();

  //==============================
  // Lock Lottery
  //==============================
  Future<void> lockLottery(String lotteryId) async {
    await _firestore
        .collection('lotteries')
        .doc(lotteryId)
        .update({
      "status": "DRAWING",
    });
  }

  //==============================
  // Pick Winning Tickets (FIXED)
  //==============================
  Future<List<Map<String, dynamic>>> pickWinningTickets({
    required String lotteryId,
    required int winnersNeeded,
  }) async {
    final snapshot = await _firestore
        .collectionGroup("tickets")
        .where("lotteryID", isEqualTo: lotteryId)
        .where("status", isEqualTo: "ACTIVE")
        .get();

    if (snapshot.docs.isEmpty) {
      throw Exception("No purchased tickets found.");
    }

    final tickets = snapshot.docs
        .map((doc) => {
              "reference": doc.reference,
              "userId": doc["userId"],
              "ticketNumber": doc["ticketNumber"],
              "data": doc.data(),
            })
        .toList();

    // Shuffle so every ticket has equal chance
    tickets.shuffle(_random);

    // Ensure we don't ask for more winners than available tickets
    final actualWinners = min(winnersNeeded, tickets.length);
    
    return tickets.take(actualWinners).toList();
  }

  //==============================
  // Draw Lottery (FIXED)
  //==============================
  Future<void> drawLottery(String lotteryId) async {
    final lotteryRef = _firestore.collection("lotteries").doc(lotteryId);
    final lotterySnapshot = await lotteryRef.get();

    if (!lotterySnapshot.exists) {
      throw Exception("Lottery does not exist.");
    }

    final lottery = lotterySnapshot.data()!;

    if (lottery["status"] != "ACTIVE") {
      return;
    }

    // Prevent anyone from purchasing while drawing
    await lockLottery(lotteryId);

    final int winnersNeeded = lottery["numberOfWinners"] ?? 1;

    final winners = await pickWinningTickets(
      lotteryId: lotteryId,
      winnersNeeded: winnersNeeded,
    );

    if (winners.isEmpty) {
      // No tickets to draw from
      await lotteryRef.update({
        "status": "COMPLETED",
        "drawCompletedAt": FieldValue.serverTimestamp(),
        "message": "No participants",
      });
      return;
    }

    final batch = _firestore.batch();

    // Get the winning ticket numbers and user IDs
    final winningTicketNumbers = winners.map((w) => w["ticketNumber"] as int).toList();
    final winningUserIds = winners.map((w) => w["userId"] as String).toList();

    // -------------------------
    // Mark Winners (FIXED)
    // -------------------------
    for (final winner in winners) {
      batch.update(
        winner["reference"],
        {
          "status": "WON",
          "wonAt": FieldValue.serverTimestamp(),
        },
      );
    }

    // -------------------------
    // Mark Losers (FIXED)
    // -------------------------
    final allTickets = await _firestore
        .collectionGroup("tickets")
        .where("lotteryID", isEqualTo: lotteryId)
        .where("status", isEqualTo: "ACTIVE")
        .get();

    for (final doc in allTickets.docs) {
      final ticketNumber = doc["ticketNumber"] as int;
      final userId = doc["userId"] as String;
      
      // Check if THIS SPECIFIC ticket is a winner
      final isWinner = winningTicketNumbers.contains(ticketNumber) && 
                       winningUserIds.contains(userId);
      
      if (!isWinner) {
        batch.update(doc.reference, {
          "status": "LOST",
        });
      }
    }

    // -------------------------
    // Update Lottery Document
    // -------------------------
    batch.update(lotteryRef, {
      "winnerIds": winningUserIds,
      "winningTickets": winningTicketNumbers,
      "drawCompletedAt": FieldValue.serverTimestamp(),
      "status": "COMPLETED", // Will be updated to ACTIVE for recurring
    });

    await batch.commit();

    // Complete the lottery process
    await completeLottery(
      lotteryId: lotteryId,
      lotteryData: lottery,
      winnerIds: winningUserIds,
      winningNumbers: winningTicketNumbers,
    );
  }

  //==============================
  // Complete Lottery (FIXED)
  //==============================
  Future<void> completeLottery({
    required String lotteryId,
    required Map<String, dynamic> lotteryData,
    required List<String> winnerIds,
    required List<int> winningNumbers,
  }) async {
    final lotteryRef = _firestore.collection("lotteries").doc(lotteryId);

    final bool recurring = lotteryData["lotteryType"] == "recurring" ||
        lotteryData["lotteryType"] == "recurring";

    // Save history
    await saveDrawHistory(
      lotteryId: lotteryId,
      lotteryData: lotteryData,
      winnerIds: winnerIds,
      winningTickets: winningNumbers,
    );

    // Archive old tickets
    await archiveOldTickets(lotteryId: lotteryId);

    if (recurring) {
      await resetRecurringLottery(
        lotteryId: lotteryId,
        lotteryData: lotteryData,
        winnerIds: winnerIds,
        winningNumbers: winningNumbers,
      );
    } else {
      // Already updated in drawLottery
      // Just send notifications
    }

    // Send Notifications
    await _sendNotifications(
      lotteryId: lotteryId,
      lotteryData: lotteryData,
      winnerIds: winnerIds,
      winningNumbers: winningNumbers,
    );
  }

  //==============================
  // Send Notifications (FIXED)
  //==============================
  Future<void> _sendNotifications({
    required String lotteryId,
    required Map<String, dynamic> lotteryData,
    required List<String> winnerIds,
    required List<int> winningNumbers,
  }) async {
    // Notify creator
    await _notificationService.notifyDrawCompleted(
      creatorId: lotteryData["creatorId"],
      creatorName: lotteryData["creatorName"],
      lotteryId: lotteryId,
      lotteryTitle: lotteryData["title"],
    );

    // Notify winners
    for (final winnerId in winnerIds) {
      await _notificationService.notifyWinner(
        userId: winnerId,
        lotteryId: lotteryId,
        lotteryTitle: lotteryData["title"],
      );
    }

    // Notify losers
    final losers = await _firestore
        .collectionGroup("tickets")
        .where("lotteryID", isEqualTo: lotteryId)
        .where("status", isEqualTo: "LOST")
        .get();

    for (final loser in losers.docs) {
      await _notificationService.notifyLoser(
        userId: loser["userId"],
        lotteryId: lotteryId,
        lotteryTitle: lotteryData["title"],
      );
    }
  }

  //==============================
  // Reset Recurring Lottery
  //==============================
  Future<void> resetRecurringLottery({
    required String lotteryId,
    required Map<String, dynamic> lotteryData,
    required List<String> winnerIds,
    required List<int> winningNumbers,
  }) async {
    final lotteryRef = _firestore.collection("lotteries").doc(lotteryId);

    DateTime nextDraw = (lotteryData["nextDrawAt"] as Timestamp).toDate();

    if (lotteryData["drawFrequency"] == "Daily") {
      nextDraw = nextDraw.add(const Duration(days: 1));
    } else {
      nextDraw = nextDraw.add(const Duration(days: 7));
    }

    await lotteryRef.update({
      "ticketsSold": 0,
      "remainingTickets": lotteryData["totalTickets"],
      "status": "ACTIVE",
      "nextDrawAt": Timestamp.fromDate(nextDraw),
      "winnerIds": [], // Clear previous winners
      "winningTickets": [], // Clear previous winning numbers
    });
  }

  //==============================
  // Check All Lotteries
  //==============================
  Future<void> checkAndDrawLotteries() async {
    final now = Timestamp.now();

    final snapshot = await _firestore
        .collection("lotteries")
        .where("status", isEqualTo: "ACTIVE")
        .where("nextDrawAt", isLessThanOrEqualTo: now)
        .get();

    for (final lottery in snapshot.docs) {
      try {
        await drawLottery(lottery.id);
      } catch (e) {
        print("Failed drawing ${lottery.id}: $e");
      }
    }
  }

  //==============================
  // Save Draw History
  //==============================
  Future<void> saveDrawHistory({
    required String lotteryId,
    required Map<String, dynamic> lotteryData,
    required List<String> winnerIds,
    required List<int> winningTickets,
  }) async {
    await _firestore
        .collection("lotteries")
        .doc(lotteryId)
        .collection("history")
        .add({
      "drawDate": FieldValue.serverTimestamp(),
      "winnerIds": winnerIds,
      "winningTickets": winningTickets,
      "jackpot": lotteryData["jackpot"],
      "participants": lotteryData["ticketsSold"],
      "numberOfWinners": lotteryData["numberOfWinners"],
      "lotteryType": lotteryData["lotteryType"],
      "drawFrequency": lotteryData["drawFrequency"],
    });
  }

  //==============================
  // Archive Old Tickets
  //==============================
  Future<void> archiveOldTickets({
    required String lotteryId,
  }) async {
    final tickets = await _firestore
        .collectionGroup("tickets")
        .where("lotteryID", isEqualTo: lotteryId)
        .where("status", whereIn: ["WON", "LOST"])
        .get();

    final batch = _firestore.batch();

    for (final ticket in tickets.docs) {
      final data = ticket.data();
      final userId = data["userId"];

      final historyRef = _firestore
          .collection("users")
          .doc(userId)
          .collection("ticketHistory")
          .doc(ticket.id);

      batch.set(
        historyRef,
        {
          ...data,
          "archivedAt": FieldValue.serverTimestamp(),
        },
      );

      batch.delete(ticket.reference);
    }

    await batch.commit();
  }
}