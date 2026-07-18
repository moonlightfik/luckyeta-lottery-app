import 'package:cloud_firestore/cloud_firestore.dart';

class Lottery {
  final String id;

  final String title;
  final String? imageUrl;

  final double jackpot;
  final double pricePerTicket;

  final int totalTickets;
  final int ticketsSold;
  final int maxTicketsPerUser;

  final String drawFrequency;
  final bool isPublic;

  final DateTime nextDrawAt;

  final String status;

  final String creatorId;
  final String creatorName;
  final DateTime createdAt;


  // HOME CARD DISPLAY
  final double progress;
  final int themeColor;


  // DRAWING SYSTEM
  final int numberOfWinners;
  final List<String> winnerIds;
  final DateTime? drawCompletedAt;



  Lottery({

    required this.id,

    required this.title,
    this.imageUrl,

    required this.jackpot,
    required this.pricePerTicket,

    required this.totalTickets,
    required this.ticketsSold,
    required this.maxTicketsPerUser,

    required this.drawFrequency,
    required this.isPublic,

    required this.nextDrawAt,

    this.status = 'ACTIVE',

    required this.creatorId,
    required this.creatorName,
    required this.createdAt,


    required this.progress,
    required this.themeColor,


    required this.numberOfWinners,
    required this.winnerIds,
    this.drawCompletedAt,

  });



  // FIRESTORE → APP

  factory Lottery.fromFirestore(
      String id,
      Map<String, dynamic> data,
      ) {


    final Timestamp? nextDrawTs =
        data['nextDrawAt'];

    final Timestamp? createdTs =
        data['createdAt'];

    final Timestamp? completedTs =
        data['drawCompletedAt'];



    final int sold =
        data['ticketsSold'] ?? 0;

    final int total =
        data['totalTickets'] ?? 0;



    return Lottery(

      id: id,


      title:
          data['title'] ??
          'Untitled Lottery',


      imageUrl:
          data['imageUrl'],



      jackpot:
          (data['jackpot'] as num?)
              ?.toDouble() ??
          0.0,



      pricePerTicket:
          (data['pricePerTicket'] as num?)
              ?.toDouble() ??
          0.0,



      totalTickets:
          total,



      ticketsSold:
          sold,



      maxTicketsPerUser:
          data['maxTicketsPerUser']
              ?? 1,



      drawFrequency:
          data['drawFrequency']
              ?? 'Unknown',



      isPublic:
          data['isPublic']
              ?? true,



      nextDrawAt:
          nextDrawTs != null
              ? nextDrawTs.toDate()
              : DateTime.now(),



      status:
          data['status']
              ?? 'ACTIVE',



      creatorId:
          data['creatorId']
              ?? '',



      creatorName:
          data['creatorName']
              ?? 'Unknown Creator',



      createdAt:
          createdTs != null
              ? createdTs.toDate()
              : DateTime.now(),



      // CARD DATA

      progress:
          data['progress'] != null
              ? (data['progress'] as num)
                  .toDouble()
              : total > 0
                  ? sold / total
                  : 0.0,



      themeColor:
          data['themeColor']
              ?? 0xFF4CAF50,



      // DRAW DATA

      numberOfWinners:
          data['numberOfWinners']
              ?? 1,



      winnerIds:
          List<String>.from(
            data['winnerIds'] ?? [],
          ),



      drawCompletedAt:
          completedTs != null
              ? completedTs.toDate()
              : null,

    );

  }





  // APP → FIRESTORE

  Map<String, dynamic> toMap(
      String userId,
      ) {


    return {

      'title':
          title,


      'imageUrl':
          imageUrl,


      'jackpot':
          jackpot,


      'pricePerTicket':
          pricePerTicket,


      'totalTickets':
          totalTickets,


      'ticketsSold':
          ticketsSold,


      'maxTicketsPerUser':
          maxTicketsPerUser,


      'drawFrequency':
          drawFrequency,


      'isPublic':
          isPublic,


      'nextDrawAt':
          nextDrawAt,


      'status':
          status,


      'creatorId':
          userId,


      'creatorName':
          creatorName,


      'createdAt':
          createdAt,



      // CARD DISPLAY

      'progress':
          progress,


      'themeColor':
          themeColor,



      // DRAW SYSTEM

      'numberOfWinners':
          numberOfWinners,


      'winnerIds':
          winnerIds,


      'drawCompletedAt':
          drawCompletedAt,

    };

  }
}