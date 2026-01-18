import 'package:cloud_firestore/cloud_firestore.dart';

class Lottery {
  final String id; // ✅ REQUIRED for Buy Ticket & Firestore updates
  final String title;
  final double jackpot;
  final double pricePerTicket;
  final int totalTickets;
  final int maxTicketsPerUser;
  final String drawFrequency;
  final bool isPublic;
  final DateTime nextDrawAt; // 🔹 Use DateTime, null-safe
  final String status;
  final String creatorId;
  final DateTime createdAt;

  Lottery({
    required this.id,
    required this.title,
    required this.jackpot,
    required this.pricePerTicket,
    required this.totalTickets,
    required this.maxTicketsPerUser,
    required this.drawFrequency,
    required this.isPublic,
    required this.nextDrawAt,
    this.status = 'ACTIVE',
    required this.creatorId,
    required this.createdAt,
  });

  /// ✅ Firestore → App
  factory Lottery.fromFirestore(String id, Map<String, dynamic> data) {
    // Handle null timestamps safely
    final Timestamp? nextDrawTs = data['nextDrawAt'];
    final Timestamp? createdTs = data['createdAt'];

    return Lottery(
      id: id,
      title: data['title'] ?? 'Untitled Lottery',
      jackpot: (data['jackpot'] as num?)?.toDouble() ?? 0.0,
      pricePerTicket: (data['pricePerTicket'] as num?)?.toDouble() ?? 0.0,
      totalTickets: data['totalTickets'] ?? 0,
      maxTicketsPerUser: data['maxTicketsPerUser'] ?? 1,
      drawFrequency: data['drawFrequency'] ?? 'Unknown',
      isPublic: data['isPublic'] ?? true,
      nextDrawAt: nextDrawTs != null
          ? nextDrawTs.toDate()
          : DateTime.now().add(const Duration(hours: 1)), // fallback
      status: data['status'] ?? 'ACTIVE',
      creatorId: data['creatorId'] ?? '',
      createdAt: createdTs != null
          ? createdTs.toDate()
          : DateTime.now(), // fallback
    );
  }

  /// ✅ App → Firestore
  Map<String, dynamic> toMap(String userId) {
    return {
      'title': title,
      'jackpot': jackpot,
      'pricePerTicket': pricePerTicket,
      'totalTickets': totalTickets,
      'maxTicketsPerUser': maxTicketsPerUser,
      'drawFrequency': drawFrequency,
      'isPublic': isPublic,
      'nextDrawAt': nextDrawAt,
      'status': status,
      'creatorId': userId,
      'createdAt': DateTime.now(),
    };
  }
}
