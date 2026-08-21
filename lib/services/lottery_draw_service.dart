import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/notification_service.dart';

class LotteryDrawService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService =
      NotificationService();

  final Random _random = Random();

  // ============================================================
  // LOCK LOTTERY
  // ============================================================

  Future<void> lockLottery(String lotteryId) async {
    await _firestore
        .collection('lotteries')
        .doc(lotteryId)
        .update({
      'status': 'DRAWING',
    });
  }

  // ============================================================
  // GET ALL ACTIVE TICKETS FOR A LOTTERY
  //
  // IMPORTANT:
  // We get the tickets BEFORE changing the lottery status to
  // DRAWING.
  //
  // This guarantees that tickets belonging to ALL users are
  // collected.
  // ============================================================

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      getActiveTickets(String lotteryId) async {
    final snapshot = await _firestore
        .collectionGroup('tickets')
        .where(
          'lotteryID',
          isEqualTo: lotteryId,
        )
        .where(
          'status',
          isEqualTo: 'ACTIVE',
        )
        .get();

    return snapshot.docs;
  }

  // ============================================================
  // PICK WINNING TICKETS
  // ============================================================

  List<QueryDocumentSnapshot<Map<String, dynamic>>>
      pickWinningTickets({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>>
        tickets,
    required int winnersNeeded,
  }) {
    if (tickets.isEmpty) {
      return [];
    }

    final shuffled = List<
        QueryDocumentSnapshot<Map<String, dynamic>>>.from(
      tickets,
    );

    // Every ticket gets an equal chance.
    shuffled.shuffle(_random);

    final actualWinners =
        min(winnersNeeded, shuffled.length);

    return shuffled
        .take(actualWinners)
        .toList();
  }

  // ============================================================
  // DRAW LOTTERY
  // ============================================================

  Future<void> drawLottery(String lotteryId) async {
    final lotteryRef =
        _firestore.collection('lotteries').doc(lotteryId);

    // ----------------------------------------------------------
    // GET LOTTERY
    // ----------------------------------------------------------

    final lotterySnapshot = await lotteryRef.get();

    if (!lotterySnapshot.exists) {
      throw Exception('Lottery does not exist.');
    }

    final lottery = lotterySnapshot.data()!;

    final currentStatus =
        (lottery['status'] ?? '').toString().toUpperCase();

    // Don't draw a lottery that is no longer ACTIVE.
    if (currentStatus != 'ACTIVE') {
      return;
    }

    // ----------------------------------------------------------
    // GET ALL ACTIVE TICKETS FIRST
    // ----------------------------------------------------------
    //
    // THIS IS THE IMPORTANT FIX.
    //
    // We must retrieve all users' tickets while they are still
    // ACTIVE.
    // ----------------------------------------------------------

    final allActiveTickets =
        await getActiveTickets(lotteryId);

    if (allActiveTickets.isEmpty) {
      await lotteryRef.update({
        'status': 'COMPLETED',
        'drawCompletedAt':
            FieldValue.serverTimestamp(),
        'message': 'No participants',
      });

      return;
    }

    // ----------------------------------------------------------
    // LOCK LOTTERY
    // ----------------------------------------------------------

    await lockLottery(lotteryId);

    // ----------------------------------------------------------
    // NUMBER OF WINNERS
    // ----------------------------------------------------------

    final int winnersNeeded =
        (lottery['numberOfWinners'] as num?)?.toInt() ?? 1;

    // ----------------------------------------------------------
    // PICK WINNERS
    // ----------------------------------------------------------

    final winners = pickWinningTickets(
      tickets: allActiveTickets,
      winnersNeeded: winnersNeeded,
    );

    if (winners.isEmpty) {
      await lotteryRef.update({
        'status': 'COMPLETED',
        'drawCompletedAt':
            FieldValue.serverTimestamp(),
        'message': 'No participants',
      });

      return;
    }

    // ----------------------------------------------------------
    // WINNER REFERENCES
    // ----------------------------------------------------------
    //
    // We identify winners by their actual Firestore document
    // reference instead of matching ticket numbers.
    // ----------------------------------------------------------

    final Set<String> winningTicketIds = winners
        .map((ticket) => ticket.id)
        .toSet();

    final List<String> winningUserIds = winners
        .map(
          (ticket) =>
              ticket.data()['userId']?.toString() ?? '',
        )
        .where((id) => id.isNotEmpty)
        .toList();

    final List<int> winningTicketNumbers = winners
        .map(
          (ticket) =>
              (ticket.data()['ticketNumber'] as num?)?.toInt() ??
              0,
        )
        .toList();

    // ==========================================================
    // BATCH UPDATE
    // ==========================================================

    final batch = _firestore.batch();

    // ----------------------------------------------------------
    // MARK EVERY TICKET
    // ----------------------------------------------------------
    //
    // Because allActiveTickets contains tickets from ALL users,
    // every participant gets updated.
    // ----------------------------------------------------------

    for (final ticket in allActiveTickets) {
      final ticketData = ticket.data();

      final isWinner =
          winningTicketIds.contains(ticket.id);

      if (isWinner) {
        batch.update(
          ticket.reference,
          {
            'status': 'WON',
            'wonAt':
                FieldValue.serverTimestamp(),
          },
        );
      } else {
        batch.update(
          ticket.reference,
          {
            'status': 'LOST',
            'lostAt':
                FieldValue.serverTimestamp(),
          },
        );
      }
    }

    // ----------------------------------------------------------
    // UPDATE LOTTERY
    // ----------------------------------------------------------

    batch.update(
      lotteryRef,
      {
        'winnerIds': winningUserIds,
        'winningTickets': winningTicketNumbers,
        'drawCompletedAt':
            FieldValue.serverTimestamp(),
        'status': 'COMPLETED',
      },
    );

    // ----------------------------------------------------------
    // COMMIT EVERYTHING TO FIRESTORE
    // ----------------------------------------------------------

    await batch.commit();

    // ----------------------------------------------------------
    // COMPLETE LOTTERY
    // ----------------------------------------------------------

    await completeLottery(
      lotteryId: lotteryId,
      lotteryData: lottery,
      winnerIds: winningUserIds,
      winningNumbers: winningTicketNumbers,
    );
  }

  // ============================================================
  // COMPLETE LOTTERY
  // ============================================================

  Future<void> completeLottery({
    required String lotteryId,
    required Map<String, dynamic> lotteryData,
    required List<String> winnerIds,
    required List<int> winningNumbers,
  }) async {
    final lotteryType =
        (lotteryData['lotteryType'] ?? '')
            .toString()
            .toLowerCase();

    final bool recurring =
        lotteryType == 'recurring';

    // ----------------------------------------------------------
    // SAVE DRAW HISTORY
    // ----------------------------------------------------------

    await saveDrawHistory(
      lotteryId: lotteryId,
      lotteryData: lotteryData,
      winnerIds: winnerIds,
      winningTickets: winningNumbers,
    );

    // ----------------------------------------------------------
    // ARCHIVE RESULTS
    // ----------------------------------------------------------
    //
    // We COPY the WON/LOST tickets to ticketHistory.
    //
    // We DO NOT delete the original tickets because
    // MyLotteriesScreen listens to users/{uid}/tickets.
    // ----------------------------------------------------------

    await archiveOldTickets(
      lotteryId: lotteryId,
    );

    // ----------------------------------------------------------
    // RECURRING LOTTERY
    // ----------------------------------------------------------

    if (recurring) {
      await resetRecurringLottery(
        lotteryId: lotteryId,
        lotteryData: lotteryData,
      );
    }

    // ----------------------------------------------------------
    // NOTIFICATIONS
    // ----------------------------------------------------------

    await _sendNotifications(
      lotteryId: lotteryId,
      lotteryData: lotteryData,
      winnerIds: winnerIds,
      winningNumbers: winningNumbers,
    );
  }

  // ============================================================
  // SEND NOTIFICATIONS
  // ============================================================

  Future<void> _sendNotifications({
    required String lotteryId,
    required Map<String, dynamic> lotteryData,
    required List<String> winnerIds,
    required List<int> winningNumbers,
  }) async {
    // ----------------------------------------------------------
    // CREATOR
    // ----------------------------------------------------------

    await _notificationService.notifyDrawCompleted(
      creatorId:
          lotteryData['creatorId']?.toString() ?? '',
      creatorName:
          lotteryData['creatorName']?.toString() ??
              'Creator',
      lotteryId: lotteryId,
      lotteryTitle:
          lotteryData['title']?.toString() ??
              'Lottery',
    );

    // ----------------------------------------------------------
    // WINNERS
    // ----------------------------------------------------------

    for (final winnerId in winnerIds) {
      await _notificationService.notifyWinner(
        userId: winnerId,
        lotteryId: lotteryId,
        lotteryTitle:
            lotteryData['title']?.toString() ??
                'Lottery',
      );
    }

    // ----------------------------------------------------------
    // LOSERS
    // ----------------------------------------------------------
    //
    // At this point the batch has already committed, so the
    // WON/LOST statuses are actually present in Firestore.
    // ----------------------------------------------------------

    final losers = await _firestore
        .collectionGroup('tickets')
        .where(
          'lotteryID',
          isEqualTo: lotteryId,
        )
        .where(
          'status',
          isEqualTo: 'LOST',
        )
        .get();

    for (final loser in losers.docs) {
      final userId =
          loser.data()['userId']?.toString();

      if (userId == null || userId.isEmpty) {
        continue;
      }

      await _notificationService.notifyLoser(
        userId: userId,
        lotteryId: lotteryId,
        lotteryTitle:
            lotteryData['title']?.toString() ??
                'Lottery',
      );
    }
  }

  // ============================================================
  // RESET RECURRING LOTTERY
  // ============================================================

  Future<void> resetRecurringLottery({
    required String lotteryId,
    required Map<String, dynamic> lotteryData,
  }) async {
    final lotteryRef =
        _firestore.collection('lotteries').doc(lotteryId);

    final nextDrawTimestamp =
        lotteryData['nextDrawAt'];

    if (nextDrawTimestamp is! Timestamp) {
      throw Exception(
        'Recurring lottery is missing nextDrawAt.',
      );
    }

    DateTime nextDraw =
        nextDrawTimestamp.toDate();

    final frequency =
        lotteryData['drawFrequency']
            ?.toString();

    // ----------------------------------------------------------
    // DAILY
    // ----------------------------------------------------------

    if (frequency == 'Daily') {
      nextDraw =
          nextDraw.add(const Duration(days: 1));
    }

    // ----------------------------------------------------------
    // WEEKLY
    // ----------------------------------------------------------

    else if (frequency == 'Weekly') {
      nextDraw =
          nextDraw.add(const Duration(days: 7));
    }

    // ----------------------------------------------------------
    // HOURLY
    // ----------------------------------------------------------

    else if (frequency == 'Hourly') {
      nextDraw =
          nextDraw.add(const Duration(hours: 1));
    }

    // ----------------------------------------------------------
    // UNKNOWN FREQUENCY
    // ----------------------------------------------------------

    else {
      throw Exception(
        'Unknown recurring draw frequency: $frequency',
      );
    }

    // ----------------------------------------------------------
    // RESET LOTTERY FOR THE NEXT ROUND
    // ----------------------------------------------------------
    //
    // IMPORTANT:
    // We DO NOT reset old tickets to ACTIVE.
    //
    // Old tickets remain:
    //
    // WON / LOST
    //
    // New purchases create NEW ticket documents with ACTIVE
    // status.
    // ----------------------------------------------------------

    await lotteryRef.update({
      'ticketsSold': 0,
      'remainingTickets':
          lotteryData['totalTickets'],
      'status': 'ACTIVE',
      'nextDrawAt':
          Timestamp.fromDate(nextDraw),
      'winnerIds': [],
      'winningTickets': [],
    });
  }

  // ============================================================
  // CHECK ALL LOTTERIES
  // ============================================================

  Future<void> checkAndDrawLotteries() async {
    final now = Timestamp.now();

    final snapshot = await _firestore
        .collection('lotteries')
        .where(
          'status',
          isEqualTo: 'ACTIVE',
        )
        .where(
          'nextDrawAt',
          isLessThanOrEqualTo: now,
        )
        .get();

    for (final lottery in snapshot.docs) {
      try {
        await drawLottery(lottery.id);
      } catch (e) {
        print(
          'Failed drawing ${lottery.id}: $e',
        );
      }
    }
  }

  // ============================================================
  // SAVE DRAW HISTORY
  // ============================================================

  Future<void> saveDrawHistory({
    required String lotteryId,
    required Map<String, dynamic> lotteryData,
    required List<String> winnerIds,
    required List<int> winningTickets,
  }) async {
    await _firestore
        .collection('lotteries')
        .doc(lotteryId)
        .collection('history')
        .add({
      'drawDate':
          FieldValue.serverTimestamp(),
      'winnerIds': winnerIds,
      'winningTickets': winningTickets,
      'jackpot': lotteryData['jackpot'],
      'participants':
          lotteryData['ticketsSold'],
      'numberOfWinners':
          lotteryData['numberOfWinners'],
      'lotteryType':
          lotteryData['lotteryType'],
      'drawFrequency':
          lotteryData['drawFrequency'],
    });
  }

  // ============================================================
  // ARCHIVE OLD TICKETS
  // ============================================================
  //
  // COPY WON/LOST tickets into:
  //
  // users/{userId}/ticketHistory
  //
  // BUT KEEP THE ORIGINAL TICKET DOCUMENT.
  //
  // This is important because your MyLotteriesScreen reads:
  //
  // users/{userId}/tickets
  //
  // ============================================================

  Future<void> archiveOldTickets({
    required String lotteryId,
  }) async {
    final tickets = await _firestore
        .collectionGroup('tickets')
        .where(
          'lotteryID',
          isEqualTo: lotteryId,
        )
        .where(
          'status',
          whereIn: ['WON', 'LOST'],
        )
        .get();

    if (tickets.docs.isEmpty) {
      return;
    }

    final batch = _firestore.batch();

    for (final ticket in tickets.docs) {
      final data = ticket.data();

      final userId =
          data['userId']?.toString();

      if (userId == null || userId.isEmpty) {
        continue;
      }

      final historyRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('ticketHistory')
          .doc(ticket.id);

      batch.set(
        historyRef,
        {
          ...data,
          'archivedAt':
              FieldValue.serverTimestamp(),
        },
      );
    }

    await batch.commit();
  }
}