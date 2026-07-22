import 'package:cloud_firestore/cloud_firestore.dart';


class Lottery {

  final String id;


  final String title;
  final String description;
  final String? imageUrl;


  final double jackpot;
  final double pricePerTicket;


  final int totalTickets;
  final int ticketsSold;
  final int maxTicketsPerUser;


  final String category;
  final String cardStyle;
  final String lotteryType;


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



  // DRAW SYSTEM

  final int numberOfWinners;
  final List<String> winnerIds;
  final DateTime? drawCompletedAt;




  Lottery({

    required this.id,


    required this.title,
    required this.description,
    this.imageUrl,


    required this.jackpot,
    required this.pricePerTicket,


    required this.totalTickets,
    required this.ticketsSold,
    required this.maxTicketsPerUser,


    required this.category,
    required this.cardStyle,
    required this.lotteryType,


    required this.drawFrequency,
    required this.isPublic,


    required this.nextDrawAt,


    this.status = "ACTIVE",


    required this.creatorId,
    required this.creatorName,
    required this.createdAt,


    required this.progress,
    required this.themeColor,


    required this.numberOfWinners,
    required this.winnerIds,


    this.drawCompletedAt,

  });






  factory Lottery.fromFirestore(

      String id,

      Map<String,dynamic> data,

  ){

    final Timestamp? nextDraw =
        data['nextDrawAt'];


    final Timestamp? created =
        data['createdAt'];


    final Timestamp? completed =
        data['drawCompletedAt'];



    final int sold =
        data['ticketsSold'] ?? 0;


    final int total =
        data['totalTickets'] ?? 0;





    return Lottery(


      id:id,



      title:
          data['title'] ?? 
          'Untitled Lottery',



      description:
          data['description'] ??
          '',



      imageUrl:
          data['imageUrl'],




      jackpot:
          (data['jackpot'] as num?)
              ?.toDouble() ??
          0,



      pricePerTicket:
          (data['pricePerTicket'] as num?)
              ?.toDouble() ??
          0,




      totalTickets:
          total,



      ticketsSold:
          sold,



      maxTicketsPerUser:
          data['maxTicketsPerUser'] ??
          1,





      category:
          data['category'] ??
          'Cash',



      cardStyle:
          data['cardStyle'] ??
          'Modern',



      lotteryType:
          data['lotteryType'] ??
          'oneTime',





      drawFrequency:
          data['drawFrequency'] ??
          'Unknown',



      isPublic:
          data['isPublic'] ??
          true,





      nextDrawAt:

          nextDraw != null

          ? nextDraw.toDate()

          : DateTime.now(),





      status:
          data['status'] ??
          'ACTIVE',





      creatorId:
          data['creatorId'] ??
          '',



      creatorName:
          data['creatorName'] ??
          'Unknown Creator',





      createdAt:

          created != null

          ? created.toDate()

          : DateTime.now(),






      progress:

          total > 0

          ? sold / total

          : 0,






      themeColor:

          data['themeColor'] ??
          0xFF16A34A,







      numberOfWinners:

          data['numberOfWinners'] ??
          1,






      winnerIds:

          List<String>.from(
            data['winnerIds'] ?? [],
          ),






      drawCompletedAt:

          completed != null

          ? completed.toDate()

          : null,


    );

  }






  Map<String,dynamic> toMap(

      String userId,

  ){

    return {


      "title":
          title,


      "description":
          description,



      "imageUrl":
          imageUrl,



      "jackpot":
          jackpot,



      "pricePerTicket":
          pricePerTicket,



      "totalTickets":
          totalTickets,



      "ticketsSold":
          ticketsSold,



      "maxTicketsPerUser":
          maxTicketsPerUser,




      "category":
          category,



      "cardStyle":
          cardStyle,



      "lotteryType":
          lotteryType,




      "drawFrequency":
          drawFrequency,



      "isPublic":
          isPublic,



      "nextDrawAt":
          nextDrawAt,



      "status":
          status,



      "creatorId":
          userId,



      "creatorName":
          creatorName,



      "createdAt":
          createdAt,



      "progress":
          progress,



      "themeColor":
          themeColor,



      "numberOfWinners":
          numberOfWinners,



      "winnerIds":
          winnerIds,



      "drawCompletedAt":
          drawCompletedAt,


    };

  }

}