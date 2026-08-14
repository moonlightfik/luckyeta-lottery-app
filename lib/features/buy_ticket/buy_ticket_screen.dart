import 'dart:math';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/lottery_model.dart';
import '../../services/notification_service.dart';

class BuyTicketScreen extends StatefulWidget {
  final Lottery lottery;

  const BuyTicketScreen({
    super.key,
    required this.lottery,
  });

  @override
  State<BuyTicketScreen> createState() => _BuyTicketScreenState();
}

class _BuyTicketScreenState extends State<BuyTicketScreen> {
  // ============================================================
  // STATE
  // ============================================================

  final Set<int> selectedTickets = {};

  bool isPurchasing = false;

  late final String userId;

  final NotificationService _notificationService =
      NotificationService();

  String? errorMessage;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    userId =
        FirebaseAuth.instance.currentUser?.uid ?? '';

    if (userId.isEmpty) {
      errorMessage = 'User not logged in';
    }
  }

  // ============================================================
  // QUICK PICK
  // ============================================================

  void _quickPick(
    Set<int> taken,
    Set<int> mine,
  ) {
    final random = Random();

    final remaining =
        widget.lottery.maxTicketsPerUser -
        mine.length;

    final available = List.generate(
      widget.lottery.totalTickets,
      (i) => i + 1,
    ).where(
      (ticket) =>
          !taken.contains(ticket) &&
          !mine.contains(ticket),
    ).toList();

    selectedTickets.clear();

    while (
        selectedTickets.length < remaining &&
        available.isNotEmpty) {
      final pick =
          available[random.nextInt(available.length)];

      selectedTickets.add(pick);

      available.remove(pick);
    }

    setState(() {});
  }

  // ============================================================
  // PURCHASE TICKETS
  // ============================================================

  Future<void> _purchaseTickets() async {
    if (selectedTickets.isEmpty) {
      return;
    }

    if (userId.isEmpty) {
      _showErrorDialog(
        'Not Logged In',
        'Please log in before buying tickets.',
      );

      return;
    }

    setState(() {
      isPurchasing = true;
      errorMessage = null;
    });

    try {
      final firestore =
          FirebaseFirestore.instance;

      final lotteryRef = firestore
          .collection('lotteries')
          .doc(widget.lottery.id);

      final userTicketsRef = firestore
          .collection('users')
          .doc(userId)
          .collection('tickets');

      await firestore.runTransaction(
        (transaction) async {
          // ------------------------------------------------------
          // GET LATEST LOTTERY DATA
          // ------------------------------------------------------

          final lotterySnapshot =
              await transaction.get(lotteryRef);

          if (!lotterySnapshot.exists) {
            throw Exception(
              'Lottery no longer exists.',
            );
          }

          final data =
              lotterySnapshot.data()
                  as Map<String, dynamic>;

          // ------------------------------------------------------
          // CHECK LOTTERY STATUS
          // ------------------------------------------------------

          final String status =
              data['status'] ?? 'ACTIVE';

          if (status != 'ACTIVE') {
            throw Exception(
              'This lottery is no longer active.',
            );
          }

          // ------------------------------------------------------
          // GET TICKET COUNTS
          // ------------------------------------------------------

          final int totalTickets =
              (data['totalTickets'] as num?)
                      ?.toInt() ??
                  0;

          final int currentSold =
              (data['ticketsSold'] as num?)
                      ?.toInt() ??
                  0;

          final int buyingAmount =
              selectedTickets.length;

          final int newSold =
              currentSold + buyingAmount;

          final int remaining =
              totalTickets - newSold;

          // ------------------------------------------------------
          // CHECK AVAILABLE TICKETS
          // ------------------------------------------------------

          if (remaining < 0) {
            throw Exception(
              'Not enough tickets available.',
            );
          }

          // ------------------------------------------------------
          // CHECK USER'S EXISTING TICKETS
          // ------------------------------------------------------

          final existingTicketsSnapshot =
              await userTicketsRef
                  .where(
                    'lotteryID',
                    isEqualTo: widget.lottery.id,
                  )
                  .get();

          final int existingTicketCount =
              existingTicketsSnapshot.docs.length;

          final int maxTicketsPerUser =
              (data['maxTicketsPerUser'] as num?)
                      ?.toInt() ??
                  1;

          if (existingTicketCount +
                  buyingAmount >
              maxTicketsPerUser) {
            throw Exception(
              'You can only purchase '
              '$maxTicketsPerUser tickets '
              'for this lottery.',
            );
          }

          // ------------------------------------------------------
          // CHECK THAT SELECTED TICKETS ARE NOT ALREADY TAKEN
          // ------------------------------------------------------

          final existingLotteryTicketsSnapshot =
              await firestore
                  .collectionGroup('tickets')
                  .where(
                    'lotteryID',
                    isEqualTo: widget.lottery.id,
                  )
                  .get();

          final Set<int> alreadyTaken = {};

          for (final doc
              in existingLotteryTicketsSnapshot.docs) {
            final ticketData =
                doc.data();

            final ticketNumber =
                (ticketData['ticketNumber']
                        as num?)
                    ?.toInt();

            if (ticketNumber != null) {
              alreadyTaken.add(ticketNumber);
            }
          }

          for (final selectedTicket
              in selectedTickets) {
            if (alreadyTaken
                .contains(selectedTicket)) {
              throw Exception(
                'Ticket #$selectedTicket has already been taken. '
                'Please select another ticket.',
              );
            }
          }

          // ------------------------------------------------------
          // CREATE USER TICKET DOCUMENTS
          // ------------------------------------------------------

          for (final ticket
              in selectedTickets) {
            final ticketRef =
                userTicketsRef.doc();

            transaction.set(
              ticketRef,
              {
                'userId': userId,

                'lotteryID':
                    widget.lottery.id,

                'lotteryTitle':
                    widget.lottery.title,

                'ticketNumber':
                    ticket,

                'pricePerTicket':
                    widget.lottery.pricePerTicket,

                'status':
                    'ACTIVE',

                'purchasedAt':
                    FieldValue.serverTimestamp(),
              },
            );
          }

          // ------------------------------------------------------
          // UPDATE LOTTERY
          // ------------------------------------------------------

          transaction.update(
            lotteryRef,
            {
              'ticketsSold':
                  newSold,

              'remainingTickets':
                  remaining,

              'status':
                  remaining <= 0
                      ? 'SOLD_OUT'
                      : 'ACTIVE',
            },
          );

          // ------------------------------------------------------
          // NOTIFY CREATOR IF SOLD OUT
          // ------------------------------------------------------

          if (remaining <= 0) {
            await _notificationService
                .notifyLotterySoldOut(
              creatorId:
                  data['creatorId'] ?? '',

              creatorName:
                  data['creatorName'] ??
                      'Creator',

              lotteryId:
                  widget.lottery.id,

              lotteryTitle:
                  data['title'] ??
                      widget.lottery.title,

              totalTickets:
                  totalTickets,
            );
          }
        },
      );

      // ==========================================================
      // PURCHASE SUCCESS
      // ==========================================================

      if (!mounted) {
        return;
      }

      setState(() {
        selectedTickets.clear();
        isPurchasing = false;
      });

      _showReceipt();
    } catch (e) {
      // ==========================================================
      // PURCHASE ERROR
      // ==========================================================

      if (!mounted) {
        return;
      }

      setState(() {
        isPurchasing = false;

        errorMessage =
            'Failed to purchase: $e';
      });

      _showErrorDialog(
        'Purchase Failed',
        e.toString().replaceFirst(
          'Exception: ',
          '',
        ),
      );
    }
  }

  // ============================================================
  // SUCCESS DIALOG
  // ============================================================

  void _showReceipt() {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text(
            'Purchase Successful 🎉',
          ),
          content: const Text(
            'Your tickets have been purchased successfully.\n\n'
            'Good luck! 🍀',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // ERROR DIALOG
  // ============================================================

  void _showErrorDialog(
    String title,
    String message,
  ) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.lottery.title,
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [
            // ====================================================
            // ERROR MESSAGE
            // ====================================================

            if (errorMessage != null)
              Container(
                width: double.infinity,

                padding:
                    const EdgeInsets.all(12),

                margin:
                    const EdgeInsets.only(
                  bottom: 12,
                ),

                color:
                    Colors.red.shade100,

                child: Text(
                  errorMessage!,

                  style: TextStyle(
                    color:
                        Colors.red.shade900,
                  ),
                ),
              ),

            // ====================================================
            // TICKET STREAM
            // ====================================================

            Expanded(
              child:
                  StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore
                        .instance
                        .collectionGroup(
                          'tickets',
                        )
                        .where(
                          'lotteryID',
                          isEqualTo:
                              widget.lottery.id,
                        )
                        .snapshots(),

                builder:
                    (context, snapshot) {
                  // ------------------------------------------------
                  // LOADING
                  // ------------------------------------------------

                  if (snapshot
                          .connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child:
                          CircularProgressIndicator(),
                    );
                  }

                  // ------------------------------------------------
                  // ERROR
                  // ------------------------------------------------

                  if (snapshot.hasError) {
                    print(
                      'Firestore Error: '
                      '${snapshot.error}',
                    );

                    print(
                      'Error Details: '
                      '${snapshot.error?.runtimeType}',
                    );

                    String errorMsg =
                        'Something went wrong.';

                    if (snapshot.error
                        .toString()
                        .contains(
                          'index',
                        )) {
                      errorMsg =
                          'Firestore index required. '
                          'Please create the required index.';
                    } else if (snapshot.error
                        .toString()
                        .contains(
                          'permission',
                        )) {
                      errorMsg =
                          'Permission denied. '
                          'Please check your Firestore security rules.';
                    } else if (snapshot.error
                        .toString()
                        .contains(
                          'collection group',
                        )) {
                      errorMsg =
                          'Collection group query error. '
                          'Please check your ticket structure.';
                    }

                    return Center(
                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .center,

                        children: [
                          Icon(
                            Icons
                                .error_outline,
                            size: 64,
                            color: Colors
                                .red.shade300,
                          ),

                          const SizedBox(
                            height: 16,
                          ),

                          Text(
                            errorMsg,
                            textAlign:
                                TextAlign
                                    .center,
                            style:
                                const TextStyle(
                              fontSize: 16,
                            ),
                          ),

                          const SizedBox(
                            height: 16,
                          ),

                          ElevatedButton(
                            onPressed: () {
                              setState(
                                () {},
                              );
                            },
                            child:
                                const Text(
                              'Retry',
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // ------------------------------------------------
                  // NO DATA
                  // ------------------------------------------------

                  if (!snapshot.hasData) {
                    return const Center(
                      child:
                          CircularProgressIndicator(),
                    );
                  }

                  // ==================================================
                  // PROCESS TICKETS
                  // ==================================================

                  final takenTickets =
                      <int>{};

                  final userTickets =
                      <int>{};

                  for (final doc
                      in snapshot
                          .data!.docs) {
                    final data =
                        doc.data()
                            as Map<String,
                                dynamic>;

                    final ticket =
                        (data['ticketNumber']
                                as num?)
                            ?.toInt();

                    if (ticket == null) {
                      print(
                        'Warning: Document missing '
                        'ticketNumber: ${doc.id}',
                      );

                      continue;
                    }

                    if (data['userId'] ==
                        userId) {
                      userTickets
                          .add(ticket);
                    } else {
                      takenTickets
                          .add(ticket);
                    }
                  }

                  print(
                    'Lottery ID: '
                    '${widget.lottery.id}',
                  );

                  print(
                    'Total Tickets: '
                    '${widget.lottery.totalTickets}',
                  );

                  print(
                    'Purchased Tickets: '
                    '${snapshot.data!.docs.length}',
                  );

                  // ==================================================
                  // USER LIMIT
                  // ==================================================

                  final reachedLimit =
                      userTickets.length >=
                          widget.lottery
                              .maxTicketsPerUser;

                  // ==================================================
                  // MAIN CONTENT
                  // ==================================================

                  return Column(
                    children: [
                      // ------------------------------------------------
                      // HEADER
                      // ------------------------------------------------

                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .spaceBetween,

                        children: [
                          Text(
                            'Pick your tickets',

                            style: Theme.of(
                              context,
                            )
                                .textTheme
                                .titleMedium,
                          ),

                          Row(
                            children: [
                              Text(
                                '${selectedTickets.length + userTickets.length}'
                                '/${widget.lottery.maxTicketsPerUser}',

                                style:
                                    const TextStyle(
                                  fontSize: 14,
                                ),
                              ),

                              const SizedBox(
                                width: 8,
                              ),

                              TextButton(
                                onPressed:
                                    reachedLimit
                                        ? null
                                        : () {
                                            _quickPick(
                                              takenTickets,
                                              userTickets,
                                            );
                                          },

                                child:
                                    const Text(
                                  'Quick Pick',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      // ------------------------------------------------
                      // TICKET GRID
                      // ------------------------------------------------

                      Expanded(
                        child:
                            GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount:
                                5,

                            crossAxisSpacing:
                                8,

                            mainAxisSpacing:
                                8,
                          ),

                          itemCount:
                              widget.lottery
                                  .totalTickets,

                          itemBuilder:
                              (context,
                                  index) {
                            final ticket =
                                index + 1;

                            final isMine =
                                userTickets
                                    .contains(
                              ticket,
                            );

                            final isTaken =
                                takenTickets
                                    .contains(
                              ticket,
                            );

                            final isSelected =
                                selectedTickets
                                    .contains(
                              ticket,
                            );

                            Color color;

                            if (isMine) {
                              color = Colors
                                  .green
                                  .shade200;
                            } else if (isTaken) {
                              color = Colors
                                  .grey
                                  .shade300;
                            } else if (isSelected) {
                              color =
                                  Colors.green;
                            } else {
                              color = Colors
                                  .grey
                                  .shade200;
                            }

                            return GestureDetector(
                              onTap:
                                  isMine ||
                                          isTaken ||
                                          reachedLimit
                                      ? null
                                      : () {
                                          setState(
                                            () {
                                              if (isSelected) {
                                                selectedTickets
                                                    .remove(
                                                  ticket,
                                                );
                                              } else if (selectedTickets.length +
                                                      userTickets.length <
                                                  widget
                                                      .lottery
                                                      .maxTicketsPerUser) {
                                                selectedTickets
                                                    .add(
                                                  ticket,
                                                );
                                              }
                                            },
                                          );
                                        },

                              child:
                                  Container(
                                alignment:
                                    Alignment
                                        .center,

                                decoration:
                                    BoxDecoration(
                                  color:
                                      color,

                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    8,
                                  ),

                                  border:
                                      isSelected
                                          ? Border.all(
                                              color: Colors
                                                  .green
                                                  .shade800,
                                              width:
                                                  2,
                                            )
                                          : null,
                                ),

                                child:
                                    Text(
                                  ticket
                                      .toString(),

                                  style:
                                      TextStyle(
                                    fontWeight:
                                        FontWeight
                                            .bold,

                                    color:
                                        isTaken
                                            ? Colors
                                                .grey
                                            : Colors
                                                .black,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      // ------------------------------------------------
                      // INFO ROW
                      // ------------------------------------------------

                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .spaceBetween,

                        children: [
                          Text(
                            'Selected: '
                            '${selectedTickets.length}',

                            style:
                                const TextStyle(
                              fontSize: 14,
                            ),
                          ),

                          Text(
                            'Price: \$'
                            '${(selectedTickets.length * widget.lottery.pricePerTicket).toStringAsFixed(2)}',

                            style:
                                const TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  FontWeight
                                      .bold,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      // ------------------------------------------------
                      // BUY BUTTON
                      // ------------------------------------------------

                      ElevatedButton(
                        onPressed:
                            reachedLimit ||
                                    selectedTickets
                                        .isEmpty ||
                                    isPurchasing
                                ? null
                                : _purchaseTickets,

                        style:
                            ElevatedButton
                                .styleFrom(
                          minimumSize:
                              const Size(
                            double.infinity,
                            50,
                          ),
                        ),

                        child:
                            isPurchasing
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child:
                                        CircularProgressIndicator(
                                      color:
                                          Colors
                                              .white,
                                    ),
                                  )
                                : Text(
                                    reachedLimit
                                        ? 'Limit Reached (${widget.lottery.maxTicketsPerUser})'
                                        : 'Buy Tickets',
                                  ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}