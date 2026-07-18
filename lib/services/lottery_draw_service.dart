import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class LotteryDrawService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;


  /// Draw a single lottery manually
  Future<void> drawLottery(String lotteryId) async {

    final lotteryRef =
        _firestore.collection('lotteries').doc(lotteryId);


    final lotterySnapshot =
        await lotteryRef.get();


    if (!lotterySnapshot.exists) {
      throw Exception('Lottery does not exist');
    }


    final lottery =
        lotterySnapshot.data()!;


    if (lottery['status'] != 'ACTIVE') {
      throw Exception('Lottery already completed');
    }


    final winnersNeeded =
        lottery['numberOfWinners'] ?? 1;



    // Get all active tickets for this lottery

    final ticketsSnapshot =
        await _firestore
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



    if (ticketsSnapshot.docs.isEmpty) {
      throw Exception('No tickets purchased');
    }



    List<Map<String, dynamic>> tickets = [];


    for (final doc in ticketsSnapshot.docs) {

      tickets.add({

        'ref': doc.reference,

        'userId':
            doc['userId'],

        'ticketNumber':
            doc['ticketNumber'],

      });

    }



    // Random shuffle

    tickets.shuffle(Random());



    List<Map<String, dynamic>> winners = [];

    Set<String> usedUsers = {};



    for (final ticket in tickets) {


      if (usedUsers.contains(
          ticket['userId']
      )) {
        continue;
      }


      winners.add(ticket);


      usedUsers.add(
          ticket['userId']
      );


      if (winners.length >= winnersNeeded) {
        break;
      }

    }



    if (winners.isEmpty) {
      throw Exception('Could not select winners');
    }



    final batch =
        _firestore.batch();



    List<String> winnerIds = [];



    // Mark winners

    for (final winner in winners) {


      batch.update(

        winner['ref'],

        {

          'status': 'WON',

          'wonAt':
              FieldValue.serverTimestamp(),

        },

      );


      winnerIds.add(
          winner['userId']
      );

    }




    // Mark losers

    for (final ticket in tickets) {


      if (!winnerIds.contains(
          ticket['userId']
      )) {


        batch.update(

          ticket['ref'],

          {

            'status': 'LOST',

          },

        );

      }

    }




    // Update lottery

    batch.update(

      lotteryRef,

      {

        'status': 'DRAWN',

        'winnerIds':
            winnerIds,

        'drawCompletedAt':
            FieldValue.serverTimestamp(),

      },

    );



    await batch.commit();

  }



  /// Automatically check all lotteries
  Future<void> checkAndDrawLotteries() async {


    final now =
        Timestamp.now();



    final snapshot =
        await _firestore
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



    for (final doc in snapshot.docs) {

      await drawLottery(
        doc.id,
      );

    }

  }

}