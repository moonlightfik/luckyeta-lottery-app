import 'package:cloud_firestore/cloud_firestore.dart';

class Lottery {
  final String id;

  final String title;
  final String description;

  final double jackpot;
  final double pricePerTicket;

  final int totalTickets;
  final int ticketsSold;
  final int remainingTickets;
  final int maxTicketsPerUser;

  final int numberOfWinners;

  final String drawFrequency;
  final String lotteryType;

  final bool isPublic;

  final DateTime nextDrawAt;

  final String status;

  final String creatorId;
  final String creatorName;

  final String category;
  final String cardStyle;

  final String? imageUrl;

  final int themeColor;

  final List<String> winnerIds;

  final DateTime createdAt;

  Lottery({
    required this.id,
    required this.title,
    this.description = "",
    required this.jackpot,
    required this.pricePerTicket,
    required this.totalTickets,
    this.ticketsSold = 0,
    this.remainingTickets = 0,
    required this.maxTicketsPerUser,
    this.numberOfWinners = 1,
    required this.drawFrequency,
    this.lotteryType = "recurring",
    required this.isPublic,
    required this.nextDrawAt,
    this.status = "ACTIVE",
    required this.creatorId,
    this.creatorName = "",
    this.category = "Cash",
    this.cardStyle = "Modern",
    this.imageUrl,
    this.themeColor = 0xFF16A34A,
    this.winnerIds = const [],
    required this.createdAt,
  });

  factory Lottery.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    final Timestamp? nextDrawTs = data["nextDrawAt"];
    final Timestamp? createdTs = data["createdAt"];

    return Lottery(
      id: id,

      title: data["title"] ?? "Untitled Lottery",

      description: data["description"] ?? "",

      jackpot: (data["jackpot"] as num?)?.toDouble() ?? 0,

      pricePerTicket:
          (data["pricePerTicket"] as num?)?.toDouble() ?? 0,

      totalTickets: data["totalTickets"] ?? 0,

      ticketsSold: data["ticketsSold"] ?? 0,

      remainingTickets: data["remainingTickets"] ??
          ((data["totalTickets"] ?? 0) -
              (data["ticketsSold"] ?? 0)),

      maxTicketsPerUser:
          data["maxTicketsPerUser"] ?? 1,

      numberOfWinners:
          data["numberOfWinners"] ?? 1,

      drawFrequency:
          data["drawFrequency"] ?? "Daily",

      lotteryType:
          data["lotteryType"] ?? "recurring",

      isPublic:
          data["isPublic"] ?? true,

      nextDrawAt: nextDrawTs != null
          ? nextDrawTs.toDate()
          : DateTime.now(),

      status:
          data["status"] ?? "ACTIVE",

      creatorId:
          data["creatorId"] ?? "",

      creatorName:
          data["creatorName"] ?? "Unknown",

      category:
          data["category"] ?? "Cash",

      cardStyle:
          data["cardStyle"] ?? "Modern",

      imageUrl:
          data["imageUrl"],

      themeColor:
          data["themeColor"] ?? 0xFF16A34A,

      winnerIds:
          List<String>.from(
              data["winnerIds"] ?? []),

      createdAt: createdTs != null
          ? createdTs.toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap(String userId) {
    return {
      "title": title,
      "description": description,
      "jackpot": jackpot,
      "pricePerTicket": pricePerTicket,
      "totalTickets": totalTickets,
      "ticketsSold": ticketsSold,
      "remainingTickets": remainingTickets,
      "maxTicketsPerUser": maxTicketsPerUser,
      "numberOfWinners": numberOfWinners,
      "drawFrequency": drawFrequency,
      "lotteryType": lotteryType,
      "isPublic": isPublic,
      "nextDrawAt": nextDrawAt,
      "status": status,
      "creatorId": userId,
      "creatorName": creatorName,
      "category": category,
      "cardStyle": cardStyle,
      "imageUrl": imageUrl,
      "themeColor": themeColor,
      "winnerIds": winnerIds,
      "createdAt": DateTime.now(),
    };
  }

  double get progress {
    if (totalTickets == 0) return 0;
    return ticketsSold / totalTickets;
  }

  bool get soldOut => remainingTickets <= 0;

  bool get isActive => status == "ACTIVE";

  bool get isEnded => status == "ENDED";

  bool get isDrawing => status == "DRAWING";
}