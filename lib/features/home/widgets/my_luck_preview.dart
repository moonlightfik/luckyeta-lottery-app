import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../navigation/bottom_nav_screen.dart';

class MyLuckPreview extends StatelessWidget {
  const MyLuckPreview({super.key});

  @override
  Widget build(BuildContext context) {
    // Listen for login/logout/account changes.
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        // Waiting for Firebase Auth.
        if (authSnapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final user = authSnapshot.data;

        // No user logged in.
        if (user == null) {
          return const SizedBox();
        }

        // IMPORTANT:
        // This stream belongs specifically to the
        // currently logged-in user's UID.
        return _buildMyLuck(
          context,
          user.uid,
        );
      },
    );
  }

  // ============================================================
  // MY LUCK STREAM
  // ============================================================

  Widget _buildMyLuck(
    BuildContext context,
    String userId,
  ) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('tickets')
          .orderBy(
            'purchasedAt',
            descending: true,
          )
          .snapshots(),

      builder: (context, snapshot) {
        // --------------------------------------------------------
        // LOADING
        // --------------------------------------------------------

        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          );
        }

        // --------------------------------------------------------
        // ERROR
        // --------------------------------------------------------

        if (snapshot.hasError) {
          debugPrint(
            'MyLuckPreview error: ${snapshot.error}',
          );

          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Unable to load your lottery results.',
            ),
          );
        }

        final docs =
            snapshot.data?.docs ?? [];

        // --------------------------------------------------------
        // FIND LATEST TICKET FOR EACH RESULT TYPE
        // --------------------------------------------------------

        DocumentSnapshot? running;
        DocumentSnapshot? won;
        DocumentSnapshot? lost;

        for (final doc in docs) {
          final data =
              doc.data() as Map<String, dynamic>;

          final status =
              data['status']?.toString() ?? 'ACTIVE';

          // ------------------------------------------------------
          // RUNNING
          //
          // ACTIVE and DRAWING are both still running.
          // ------------------------------------------------------

          if (
              (status == 'ACTIVE' ||
                  status == 'DRAWING') &&
              running == null) {
            running = doc;
          }

          // ------------------------------------------------------
          // WON
          // ------------------------------------------------------

          if (
              status == 'WON' &&
              won == null) {
            won = doc;
          }

          // ------------------------------------------------------
          // LOST
          // ------------------------------------------------------

          if (
              status == 'LOST' &&
              lost == null) {
            lost = doc;
          }

          // We already found everything.
          if (
              running != null &&
              won != null &&
              lost != null
          ) {
            break;
          }
        }

        // --------------------------------------------------------
        // UI
        // --------------------------------------------------------

        return Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  "My Luck",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const Spacer(),

                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const BottomNavScreen(
                          initialIndex: 2,
                        ),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.green,
                  ),
                  child: const Text(
                    "View All",
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // RUNNING
            _buildRunningCard(
              context,
              running,
            ),

            const SizedBox(height: 10),

            // WON
            _buildWonCard(
              context,
              won,
            ),

            const SizedBox(height: 10),

            // LOST
            _buildLostCard(
              context,
              lost,
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // RUNNING CARD
  // ============================================================

  Widget _buildRunningCard(
    BuildContext context,
    DocumentSnapshot? ticket,
  ) {
    if (ticket == null) {
      return _emptyCard(
        context,
        icon: Icons.local_activity,
        color: Colors.green,
        title: "Running",
        message:
            "🎟 Buy a ticket and win a prize!",
        onTap: () {
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
      );
    }

    final data =
        ticket.data() as Map<String, dynamic>;

    final lotteryTitle =
        data['lotteryTitle']?.toString() ??
            'Lottery';

    final ticketNumber =
        data['ticketNumber']?.toString() ??
            '0';

    final ticketStatus =
        data['status']?.toString() ??
            'ACTIVE';

    // Display the actual current status.
    final statusText =
        ticketStatus == 'DRAWING'
            ? 'Drawing...'
            : 'Waiting for draw';

    return _ticketCard(
      context,
      icon: Icons.local_activity,
      color: Colors.green,
      title: "Running",
      lottery: lotteryTitle,
      subtitle:
          "Ticket #$ticketNumber",
      status: statusText,
    );
  }

  // ============================================================
  // WON CARD
  // ============================================================

  Widget _buildWonCard(
    BuildContext context,
    DocumentSnapshot? ticket,
  ) {
    if (ticket == null) {
      return _emptyCard(
        context,
        icon: Icons.workspace_premium,
        color: Colors.amber,
        title: "Won",
        message:
            "No lotteries won yet.\n"
            "✨ Your first win could be next!",
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const BottomNavScreen(
                initialIndex: 2,
              ),
            ),
          );
        },
      );
    }

    final data =
        ticket.data() as Map<String, dynamic>;

    final lotteryTitle =
        data['lotteryTitle']?.toString() ??
            'Lottery';

    final ticketNumber =
        data['ticketNumber']?.toString() ??
            '0';

    return _ticketCard(
      context,
      icon: Icons.workspace_premium,
      color: Colors.amber,
      title: "Won",
      lottery: lotteryTitle,
      subtitle:
          "Ticket #$ticketNumber",
      status: "Winner 🎉",
    );
  }

  // ============================================================
  // LOST CARD
  // ============================================================

  Widget _buildLostCard(
    BuildContext context,
    DocumentSnapshot? ticket,
  ) {
    if (ticket == null) {
      return _emptyCard(
        context,
        icon: Icons.cancel,
        color: Colors.red,
        title: "Lost",
        message:
            "No lotteries lost yet.\n"
            "🍀 Better luck is coming!",
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const BottomNavScreen(
                initialIndex: 2,
              ),
            ),
          );
        },
      );
    }

    final data =
        ticket.data() as Map<String, dynamic>;

    final lotteryTitle =
        data['lotteryTitle']?.toString() ??
            'Lottery';

    final ticketNumber =
        data['ticketNumber']?.toString() ??
            '0';

    return _ticketCard(
      context,
      icon: Icons.cancel,
      color: Colors.red,
      title: "Lost",
      lottery: lotteryTitle,
      subtitle:
          "Ticket #$ticketNumber",
      status: "Better luck next time",
    );
  }

  // ============================================================
  // TICKET CARD
  // ============================================================

  Widget _ticketCard(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String lottery,
    required String subtitle,
    required String status,
  }) {
    return InkWell(
      borderRadius:
          BorderRadius.circular(18),

      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const BottomNavScreen(
              initialIndex: 2,
            ),
          ),
        );
      },

      child: Card(
        elevation: 2,

        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(18),
        ),

        child: Padding(
          padding:
              const EdgeInsets.all(16),

          child: Row(
            children: [
              CircleAvatar(
                backgroundColor:
                    color.withOpacity(.15),
                child: Icon(
                  icon,
                  color: color,
                ),
              ),

              const SizedBox(width: 15),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 4,
                    ),

                    Text(
                      lottery,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          const TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    Text(subtitle),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Text(
                status,
                textAlign:
                    TextAlign.end,
                style: TextStyle(
                  color: color,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY CARD
  // ============================================================

  Widget _emptyCard(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String message,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius:
          BorderRadius.circular(18),

      child: Card(
        elevation: 2,

        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(18),
        ),

        child: Padding(
          padding:
              const EdgeInsets.all(16),

          child: Row(
            children: [
              CircleAvatar(
                backgroundColor:
                    color.withOpacity(.15),

                child: Icon(
                  icon,
                  color: color,
                ),
              ),

              const SizedBox(width: 15),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 4,
                    ),

                    Text(message),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}