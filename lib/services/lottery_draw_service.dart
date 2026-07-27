import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/notification_service.dart';

class LotteryDrawService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;
      final NotificationService _notificationService =
    NotificationService();

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
  // Pick Winning Tickets
  //==============================

  Future<List<Map<String, dynamic>>> pickWinningTickets({
    required String lotteryId,
    required int winnersNeeded,
  }) async {
    final snapshot = await _firestore
        .collectionGroup("tickets")
        .where(
          "lotteryID",
          isEqualTo: lotteryId,
        )
        .where(
          "status",
          isEqualTo: "ACTIVE",
        )
        .get();

    if (snapshot.docs.isEmpty) {
      throw Exception(
        "No purchased tickets found.",
      );
    }

    final tickets = snapshot.docs
        .map(
          (doc) => {
            "reference": doc.reference,
            "userId": doc["userId"],
            "ticketNumber": doc["ticketNumber"],
            "data": doc.data(),
          },
        )
        .toList();

    // Shuffle so every ticket has equal chance.
    tickets.shuffle(_random);

    // Every ticket is one chance.
    return tickets.take(winnersNeeded).toList();
  }
    //==============================
  // Draw Lottery
  //==============================

  Future<void> drawLottery(String lotteryId) async {
    final lotteryRef =
        _firestore.collection("lotteries").doc(lotteryId);

    final lotterySnapshot =
        await lotteryRef.get();

    if (!lotterySnapshot.exists) {
      throw Exception("Lottery does not exist.");
    }

    final lottery =
        lotterySnapshot.data()!;

    if (lottery["status"] != "ACTIVE") {
      return;
    }

    // Prevent anyone from purchasing while drawing
    await lockLottery(lotteryId);

    final int winnersNeeded =
        lottery["numberOfWinners"] ?? 1;

    final winners =
        await pickWinningTickets(
      lotteryId: lotteryId,
      winnersNeeded: winnersNeeded,
    );

    final batch = _firestore.batch();

    List<String> winnerIds = [];

    List<int> winningNumbers = [];

    // -------------------------
    // Winners
    // -------------------------

    for (final winner in winners) {
      batch.update(
        winner["reference"],
        {
          "status": "WON",
          "wonAt":
              FieldValue.serverTimestamp(),
        },
      );

      winnerIds.add(
        winner["userId"],
      );

      winningNumbers.add(
        winner["ticketNumber"],
      );
    }

    // -------------------------
    // Losers
    // -------------------------

    final allTickets =
        await _firestore
            .collectionGroup("tickets")
            .where(
              "lotteryID",
              isEqualTo: lotteryId,
            )
            .where(
              "status",
              isEqualTo: "ACTIVE",
            )
            .get();

    for (final doc in allTickets.docs) {
      if (!winnerIds.contains(
            doc["userId"],
          ) ||
          !winningNumbers.contains(
            doc["ticketNumber"],
          )) {
        batch.update(doc.reference, {
          "status": "LOST",
        });
      }
    }

    await batch.commit();

    await completeLottery(
      lotteryId: lotteryId,
      lotteryData: lottery,
      winnerIds: winnerIds,
      winningNumbers: winningNumbers,
    );
  }
    //==============================
  // Complete Lottery
  //==============================

  Future<void> completeLottery({
    required String lotteryId,
    required Map<String, dynamic> lotteryData,
    required List<String> winnerIds,
    required List<int> winningNumbers,
  }) async {

    final lotteryRef =
        _firestore.collection("lotteries").doc(lotteryId);

    final bool recurring =
        lotteryData["lotteryType"] == "recurring";

    if (recurring) {

      await resetRecurringLottery(
        lotteryId: lotteryId,
        lotteryData: lotteryData,
        winnerIds: winnerIds,
        winningNumbers: winningNumbers,
      );

    } else {

      await lotteryRef.update({

        "status": "COMPLETED",

        "winnerIds": winnerIds,

        "winningTickets": winningNumbers,

        "drawCompletedAt":
            FieldValue.serverTimestamp(),

      });

    }

   //==============================
// Send Notifications
//==============================

// Notify creator

await _notificationService.notifyDrawCompleted(
  creatorId: lotteryData["creatorId"],
  creatorName: lotteryData["creatorName"],
  lotteryId: lotteryId,
  lotteryTitle: lotteryData["title"],
);
for (final winnerId in winnerIds) {

  await _notificationService.notifyWinner(

    userId: winnerId,

    lotteryId: lotteryId,

    lotteryTitle: lotteryData["title"],

  );}
  final losers = await _firestore
    .collectionGroup("tickets")
    .where(
      "lotteryID",
      isEqualTo: lotteryId,
    )
    .where(
      "status",
      isEqualTo: "LOST",
    )
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

    final lotteryRef =
        _firestore.collection("lotteries").doc(lotteryId);

    DateTime nextDraw =
        (lotteryData["nextDrawAt"] as Timestamp)
            .toDate();

    if (lotteryData["drawFrequency"] == "Daily") {

      nextDraw = nextDraw.add(
        const Duration(days: 1),
      );

    } else {

      nextDraw = nextDraw.add(
        const Duration(days: 7),
      );

    }

    await lotteryRef.update({

      // Save previous draw

      "winnerIds": winnerIds,

      "winningTickets": winningNumbers,

      "drawCompletedAt":
          FieldValue.serverTimestamp(),

      // Reset lottery

      "ticketsSold": 0,

      "remainingTickets":
          lotteryData["totalTickets"],

      "status": "ACTIVE",

      "nextDrawAt":
          Timestamp.fromDate(nextDraw),

    });

    // Later we'll also clear old ticket documents
    // and save the completed draw into a History
    // subcollection so previous winners are preserved.
  }
    //==============================
  // Check All Lotteries
  //==============================

  Future<void> checkAndDrawLotteries() async {

    final now = Timestamp.now();

    final snapshot = await _firestore
        .collection("lotteries")
        .where(
          "status",
          isEqualTo: "ACTIVE",
        )
        .where(
          "nextDrawAt",
          isLessThanOrEqualTo: now,
        )
        .get();

    for (final lottery in snapshot.docs) {

      try {

        await drawLottery(
          lottery.id,
        );

      } catch (e) {

        print(
          "Failed drawing ${lottery.id}: $e",
        );

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

      "drawDate":
          FieldValue.serverTimestamp(),

      "winnerIds":
          winnerIds,

      "winningTickets":
          winningTickets,

      "jackpot":
          lotteryData["jackpot"],

      "participants":
          lotteryData["ticketsSold"],

      "numberOfWinners":
          lotteryData["numberOfWinners"],

      "lotteryType":
          lotteryData["lotteryType"],

      "drawFrequency":
          lotteryData["drawFrequency"],

    });

  }

}