import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../models/lottery_model.dart';
import '../../create_lottery/edit_lottery_screen.dart';
import 'creator_lottery_menu.dart';

class LotteryCard extends StatefulWidget {
  final Lottery lottery;

  const LotteryCard({
    super.key,
    required this.lottery,
  });

  @override
  State<LotteryCard> createState() => _LotteryCardState();
}

class _LotteryCardState extends State<LotteryCard> {
  Timer? timer;
  StreamSubscription<DocumentSnapshot>? lotterySubscription;

  late Lottery _lottery;

  Duration remaining = Duration.zero;

  @override
  void initState() {
    super.initState();

    _lottery = widget.lottery;

    updateCountdown();

    timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => updateCountdown(),
    );

    listenForLotteryUpdates();
  }

  // ============================================================
  // LISTEN FOR FIRESTORE CHANGES
  // ============================================================

  void listenForLotteryUpdates() {
    lotterySubscription = FirebaseFirestore.instance
        .collection("lotteries")
        .doc(widget.lottery.id)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) return;

      final data = snapshot.data();

      if (data == null) return;

      if (!mounted) return;

      setState(() {
        _lottery = Lottery.fromFirestore(
          snapshot.id,
          data,
        );

        updateCountdown();
      });
    });
  }

  // ============================================================
  // COUNTDOWN
  // ============================================================

  void updateCountdown() {
    if (_lottery.nextDrawAt == null) {
      if (mounted && remaining != Duration.zero) {
        setState(() {
          remaining = Duration.zero;
        });
      }

      return;
    }

    final difference =
        _lottery.nextDrawAt!.difference(DateTime.now());

    if (!mounted) return;

    final newRemaining =
        difference.isNegative ? Duration.zero : difference;

    if (remaining != newRemaining) {
      setState(() {
        remaining = newRemaining;
      });
    }
  }

  // ============================================================
  // STATUS BADGE
  // ============================================================

  Widget _buildStatusBadge() {
    final status = _lottery.status;

    Color color;
    String text;
    IconData icon;

    switch (status) {
      case "DRAWING":
        color = Colors.orange;
        text = "DRAWING";
        icon = Icons.casino;
        break;

      case "COMPLETED":
        color = Colors.blue;
        text = "COMPLETED";
        icon = Icons.check_circle;
        break;

      case "SOLD_OUT":
        color = Colors.red;
        text = "SOLD OUT";
        icon = Icons.confirmation_number;
        break;

      case "ACTIVE":
      default:
        color = Colors.green;
        text = "ACTIVE";
        icon = Icons.play_circle;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RESET RECURRING LOTTERY
  // ============================================================

  Future<void> resetRecurringLottery() async {
    if (_lottery.drawFrequency != "Daily" &&
        _lottery.drawFrequency != "Weekly") {
      return;
    }

    if (_lottery.nextDrawAt == null) {
      return;
    }

    DateTime newDrawTime;

    if (_lottery.drawFrequency == "Daily") {
      newDrawTime =
          _lottery.nextDrawAt!.add(
        const Duration(days: 1),
      );
    } else {
      newDrawTime =
          _lottery.nextDrawAt!.add(
        const Duration(days: 7),
      );
    }

    await FirebaseFirestore.instance
        .collection("lotteries")
        .doc(_lottery.id)
        .update({
      "nextDrawAt": Timestamp.fromDate(newDrawTime),
      "ticketsSold": 0,
      "remainingTickets": _lottery.totalTickets,
      "status": "ACTIVE",
    });
  }

  // ============================================================
  // FORMAT TIME
  // ============================================================

  String formatTime() {
    String two(int n) =>
        n.toString().padLeft(2, '0');

    return "${two(remaining.inHours)}:"
        "${two(remaining.inMinutes.remainder(60))}:"
        "${two(remaining.inSeconds.remainder(60))}";
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    timer?.cancel();
    lotterySubscription?.cancel();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final lottery = _lottery;

    return Card(
      elevation: 5,
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 10,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [

          // ======================================================
          // IMAGE
          // ======================================================

          Container(
            height: 180,
            decoration: BoxDecoration(
              borderRadius:
                  const BorderRadius.vertical(
                top: Radius.circular(22),
              ),
              image: lottery.imageUrl != null
                  ? DecorationImage(
                      image: NetworkImage(
                        lottery.imageUrl!,
                      ),
                      fit: BoxFit.cover,
                    )
                  : null,
              color: Color(
                lottery.themeColor,
              ),
            ),
            child: Stack(
              children: [

                // =================================================
                // STATUS
                // =================================================

                Positioned(
                  top: 15,
                  left: 15,
                  child: _buildStatusBadge(),
                ),

                // =================================================
                // CATEGORY
                // =================================================

                Positioned(
                  top: 15,
                  right: 15,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                    child: Text(
                      "🎁 ${lottery.category}",
                      style:
                          const TextStyle(
                        color: Colors.white,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // =================================================
                // CREATOR MENU
                // =================================================

                Positioned(
                  bottom: 15,
                  right: 15,
                  child:
                      FirebaseAuth.instance.currentUser?.uid ==
                              lottery.creatorId
                          ? CreatorLotteryMenu(
                              onEdit: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        EditLotteryScreen(
                                      lottery: lottery,
                                    ),
                                  ),
                                );
                              },
                              onDelete: () {
                                showDialog(
                                  context: context,
                                  builder:
                                      (context) {
                                    return AlertDialog(
                                      title:
                                          const Text(
                                        "Delete Lottery?",
                                      ),
                                      content:
                                          lottery.ticketsSold >
                                                  0
                                              ? const Text(
                                                  "Tickets have already been purchased. You cannot delete this lottery.",
                                                )
                                              : const Text(
                                                  "Are you sure you want to delete this lottery?",
                                                ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () {
                                            Navigator.pop(
                                                context);
                                          },
                                          child:
                                              const Text(
                                            "Cancel",
                                          ),
                                        ),
                                        if (lottery
                                                .ticketsSold ==
                                            0)
                                          TextButton(
                                            onPressed:
                                                () async {
                                              await FirebaseFirestore
                                                  .instance
                                                  .collection(
                                                      "lotteries")
                                                  .doc(
                                                      lottery.id)
                                                  .delete();

                                              if (context
                                                  .mounted) {
                                                Navigator.pop(
                                                    context);
                                              }
                                            },
                                            child:
                                                const Text(
                                              "Delete",
                                              style:
                                                  TextStyle(
                                                color:
                                                    Colors.red,
                                              ),
                                            ),
                                          ),
                                      ],
                                    );
                                  },
                                );
                              },
                            )
                          : const SizedBox(),
                ),
              ],
            ),
          ),

          // ======================================================
          // DETAILS
          // ======================================================

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [

                Text(
                  lottery.title,
                  style:
                      const TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  "👤 ${lottery.creatorName}",
                  style: TextStyle(
                    color:
                        Colors.grey.shade700,
                    fontWeight:
                        FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  lottery.description,
                  maxLines: 2,
                  overflow:
                      TextOverflow.ellipsis,
                  style: TextStyle(
                    color:
                        Colors.grey.shade700,
                  ),
                ),

                const SizedBox(height: 15),

                // =================================================
                // JACKPOT / TICKET PRICE
                // =================================================

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .spaceBetween,
                  children: [
                    Text(
                      "\$${lottery.jackpot}",
                      style:
                          const TextStyle(
                        fontSize: 24,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    Text(
                      "🎟 \$${lottery.pricePerTicket}/ticket",
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                // =================================================
                // PROGRESS
                // =================================================

                LinearProgressIndicator(
                  value: lottery.progress
                      .clamp(0, 1),
                  minHeight: 8,
                  borderRadius:
                      BorderRadius.circular(
                    10,
                  ),
                  backgroundColor:
                      Colors.grey.shade300,
                  valueColor:
                      AlwaysStoppedAnimation<
                          Color>(
                    Color(
                      lottery.themeColor,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  "${lottery.ticketsSold}/${lottery.totalTickets} Tickets Sold",
                  style: TextStyle(
                    color:
                        Colors.grey.shade700,
                    fontWeight:
                        FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 15),

                // =================================================
                // DRAW INFO
                // =================================================

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule,
                          size: 18,
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        Text(
                          lottery.lotteryType ==
                                  "oneTime"
                              ? "One Time"
                              : lottery
                                      .drawFrequency ??
                                  "Unknown",
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    Row(
                      children: [
                        const Icon(
                          Icons.emoji_events,
                          size: 18,
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        Text(
                          "${lottery.numberOfWinners} Winner${lottery.numberOfWinners > 1 ? "s" : ""}",
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                // =================================================
                // SOLD OUT
                // =================================================

                if (lottery.status ==
                    "SOLD_OUT")
                  Container(
                    width:
                        double.infinity,
                    padding:
                        const EdgeInsets.all(
                      12,
                    ),
                    decoration:
                        BoxDecoration(
                      color:
                          Colors.red.shade50,
                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),
                    ),
                    child:
                        const Center(
                      child: Text(
                        "🎟 SOLD OUT\nTry Next Time",
                        textAlign:
                            TextAlign.center,
                        style:
                            TextStyle(
                          color:
                              Colors.red,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}