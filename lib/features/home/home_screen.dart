import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'widgets/lottery_card.dart';
import 'widgets/my_luck_preview.dart';
import '../notifications/notification_screen.dart';
import '../../navigation/bottom_nav_screen.dart';
import '../lottery_details/lottery_details.dart';
import '../create_lottery/create_lottery.dart';
import '../../models/lottery_model.dart';
import '../../services/lottery_draw_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
  });

  @override
  State<HomeScreen> createState() =>
      _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final user =
      FirebaseAuth.instance.currentUser;

  final LotteryDrawService _drawService =
      LotteryDrawService();

  Timer? _drawCheckerTimer;

  late String username;

  // Stores the IDs of lotteries
  // that the current user has purchased.
  final Set<String> _purchasedLotteryIds =
      <String>{};

  @override
  void initState() {
    super.initState();

    username =
        user?.displayName ?? "Player";

    // Load lotteries purchased by
    // the current user.
    _loadPurchasedLotteryIds();

    // Check lottery draws.
    _checkLotteryDraws();

    // Keep checking every 30 seconds
    // for now.
    _drawCheckerTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) async {
        try {
          await LotteryDrawService()
              .checkAndDrawLotteries();
        } catch (e) {
          debugPrint(
            "Draw checker error: $e",
          );
        }
      },
    );
  }

  // --------------------------------------------------
  // LOAD PURCHASED LOTTERY IDS
  // --------------------------------------------------

  Future<void> _loadPurchasedLotteryIds() async {
    final currentUser =
        FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return;
    }

    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection("users")
              .doc(currentUser.uid)
              .collection("tickets")
              .get();

      final ids = snapshot.docs
          .map((doc) {
            final data = doc.data();

            return data["lotteryID"]
                as String?;
          })
          .whereType<String>()
          .toSet();

      if (!mounted) return;

      setState(() {
        _purchasedLotteryIds
          ..clear()
          ..addAll(ids);
      });

      debugPrint(
        "Purchased lottery IDs: "
        "$_purchasedLotteryIds",
      );
    } catch (e) {
      debugPrint(
        "Error loading purchased lotteries: $e",
      );
    }
  }

  // --------------------------------------------------
  // CHECK LOTTERY DRAWS
  // --------------------------------------------------

  Future<void> _checkLotteryDraws() async {
    try {
      await _drawService
          .checkAndDrawLotteries();
    } catch (e) {
      debugPrint(
        "Lottery draw error: $e",
      );
    }
  }

  // --------------------------------------------------
  // BUILD
  // --------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.all(16),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [

              // ----------------------------------------
              // HEADER
              // ----------------------------------------

              Row(
                children: [

                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const BottomNavScreen(
                            initialIndex: 3,
                          ),
                        ),
                      );
                    },

                    child: const CircleAvatar(
                      radius: 25,

                      backgroundImage:
                          AssetImage(
                        "assets/avatar.png",
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [

                      const Text(
                        "WELCOME BACK",

                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),

                      Text(
                        "Good Luck, $username!",

                        style:
                            const TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  IconButton(
                    icon: const Icon(
                      Icons.notifications_none,
                      size: 30,
                    ),

                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const NotificationScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ----------------------------------------
              // ACTION BUTTONS
              // ----------------------------------------

              Row(
                children: [

                  Expanded(
                    child:
                        ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const CreateLotteryScreen(),
                          ),
                        );
                      },

                      icon:
                          const Icon(Icons.add),

                      label:
                          const Text(
                        "Create Lottery",
                      ),

                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors.green,

                        foregroundColor:
                            Colors.white,

                        padding:
                            const EdgeInsets.symmetric(
                          vertical: 14,
                        ),

                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            12,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child:
                        OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const BottomNavScreen(
                              initialIndex: 1,
                            ),
                          ),
                        );
                      },

                      icon: const Icon(
                        Icons.confirmation_num,
                        color: Colors.green,
                      ),

                      label: const Text(
                        "Buy Tickets",

                        style: TextStyle(
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ----------------------------------------
              // FEATURED JACKPOTS
              // ----------------------------------------

              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,

                children: [

                  const Text(
                    "Featured Jackpots",

                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const BottomNavScreen(
                            initialIndex: 1,
                          ),
                        ),
                      );
                    },

                    child: const Text(
                      "View All",

                      style: TextStyle(
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ----------------------------------------
              // LOTTERIES
              // ----------------------------------------

              SizedBox(
                height: 500,

                child:
                    StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection(
                            "lotteries",
                          )
                          .orderBy(
                            "createdAt",
                            descending: true,
                          )
                          .snapshots(),

                  builder:
                      (context, snapshot) {

                    // ----------------------------------
                    // LOADING
                    // ----------------------------------

                    if (snapshot
                            .connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child:
                            CircularProgressIndicator(
                          color: Colors.green,
                        ),
                      );
                    }

                    // ----------------------------------
                    // ERROR
                    // ----------------------------------

                    if (snapshot.hasError) {
                      debugPrint(
                        "Home lottery error: "
                        "${snapshot.error}",
                      );

                      return const Center(
                        child: Text(
                          "Error loading lotteries",
                        ),
                      );
                    }

                    // ----------------------------------
                    // NO DATA
                    // ----------------------------------

                    if (!snapshot.hasData) {
                      return const Center(
                        child: Text(
                          "No lotteries available",
                        ),
                      );
                    }

                    final allDocs =
                        snapshot.data!.docs;

                    final currentUserId =
                        FirebaseAuth
                            .instance
                            .currentUser
                            ?.uid;

                    // ----------------------------------
                    // FILTER LOTTERIES
                    // ----------------------------------

                    final lotteries =
                        allDocs.where((doc) {

                      final data =
                          doc.data()
                              as Map<String, dynamic>;

                      final lotteryId =
                          doc.id;

                      final isPublic =
                          data["isPublic"] == true;

                      final status =
                          data["status"];

                      final creatorId =
                          data["creatorId"];

                      // Is this lottery created
                      // by the current user?
                      final isCreator =
                          creatorId ==
                              currentUserId;

                      // Did this user purchase
                      // a ticket for this lottery?
                      final wasPurchased =
                          _purchasedLotteryIds
                              .contains(
                            lotteryId,
                          );

                      // --------------------------------
                      // PUBLIC LOTTERIES
                      // --------------------------------
                      //
                      // Public ACTIVE/DRAWING lotteries
                      // are visible to everyone.

                      final isPublicVisible =
                          isPublic &&
                          (
                            status == "ACTIVE" ||
                            status == "DRAWING"
                          );

                      // --------------------------------
                      // CREATOR LOTTERIES
                      // --------------------------------
                      //
                      // The creator can see their lottery
                      // regardless of status.

                      final isOwnLottery =
                          isCreator;

                      // --------------------------------
                      // PURCHASED LOTTERIES
                      // --------------------------------
                      //
                      // A user can see every lottery
                      // they purchased a ticket for,
                      // regardless of status.

                      final isPurchasedLottery =
                          wasPurchased;

                      return isPublicVisible ||
                          isOwnLottery ||
                          isPurchasedLottery;

                    }).toList();

                    // ----------------------------------
                    // NO MATCHING LOTTERIES
                    // ----------------------------------

                    if (lotteries.isEmpty) {
                      return const Center(
                        child: Text(
                          "No lotteries available",
                        ),
                      );
                    }

                    // ----------------------------------
                    // LOTTERY LIST
                    // ----------------------------------

                    return ListView.builder(
                      scrollDirection:
                          Axis.horizontal,

                      itemCount:
                          lotteries.length,

                      itemBuilder:
                          (context, index) {

                        final doc =
                            lotteries[index];

                        final lottery =
                            Lottery.fromFirestore(
                          doc.id,

                          doc.data()
                              as Map<String, dynamic>,
                        );

                        return SizedBox(
                          width: 300,

                          child:
                              GestureDetector(
                            // --------------------------------
                            // LOTTERY CARD → DETAILS
                            // --------------------------------
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      LotteryDetails(
                                    lotteryId:
                                        lottery.id,
                                  ),
                                ),
                              );
                            },

                            child:
                                LotteryCard(
                              lottery:
                                  lottery,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 30),

              // ----------------------------------------
              // MY LUCK PREVIEW
              // ----------------------------------------

              const MyLuckPreview(),
            ],
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------
  // DISPOSE
  // --------------------------------------------------

  @override
  void dispose() {
    _drawCheckerTimer?.cancel();

    super.dispose();
  }
}

