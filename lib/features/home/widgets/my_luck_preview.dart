import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../navigation/bottom_nav_screen.dart';

class MyLuckPreview extends StatelessWidget {
  const MyLuckPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const SizedBox();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('tickets')
          .orderBy('purchasedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        DocumentSnapshot? running;
        DocumentSnapshot? won;
        DocumentSnapshot? lost;

        for (final doc in docs) {
          final data = doc.data() as Map<String, dynamic>;

          switch (data['status']) {
            case 'ACTIVE':
              running ??= doc;
              break;

            case 'WON':
              won ??= doc;
              break;

            case 'LOST':
              lost ??= doc;
              break;
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
            const BottomNavScreen(initialIndex: 2),
      ),
    );
  },
  style: TextButton.styleFrom(
    foregroundColor: Colors.green,
  ),
  child: const Text("View All"),
),
              ],
            ),

            const SizedBox(height: 10),

            _buildRunningCard(context, running),

            const SizedBox(height: 10),

            _buildWonCard(context, won),

            const SizedBox(height: 10),

            _buildLostCard(context, lost),
          ],
        );
      },
    );
  }

  Widget _buildRunningCard(
      BuildContext context, DocumentSnapshot? ticket) {
    if (ticket == null) {
      return _emptyCard(
        context,
        icon: Icons.local_activity,
        color: Colors.green,
        title: "Running",
        message: "🎟 Buy a ticket and win a prize!",
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const BottomNavScreen(initialIndex: 1),
            ),
          );
        },
      );
    }

    final data = ticket.data() as Map<String, dynamic>;

    return _ticketCard(
      context,
      icon: Icons.local_activity,
      color: Colors.green,
      title: "Running",
      lottery: data['lotteryTitle'],
      subtitle: "Ticket #${data['ticketNumber']}",
      status: "Waiting for draw",
    );
  }

  Widget _buildWonCard(
      BuildContext context, DocumentSnapshot? ticket) {
    if (ticket == null) {
      return _emptyCard(
        context,
        icon: Icons.workspace_premium,
        color: Colors.amber,
        title: "Won",
        message: "No lotteries won yet.\n✨ Your first win could be next!",
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const BottomNavScreen(initialIndex: 2),
            ),
          );
        },
      );
    }

    final data = ticket.data() as Map<String, dynamic>;

    return _ticketCard(
      context,
      icon: Icons.workspace_premium,
      color: Colors.amber,
      title: "Won",
      lottery: data['lotteryTitle'],
      subtitle: "Ticket #${data['ticketNumber']}",
      status: "Winner 🎉",
    );
  }

  Widget _buildLostCard(
      BuildContext context, DocumentSnapshot? ticket) {
    if (ticket == null) {
      return _emptyCard(
        context,
        icon: Icons.cancel,
        color: Colors.red,
        title: "Lost",
        message: "No lotteries lost yet.\n🍀 Better luck is coming!",
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const BottomNavScreen(initialIndex: 2),
            ),
          );
        },
      );
    }

    final data = ticket.data() as Map<String, dynamic>;

    return _ticketCard(
      context,
      icon: Icons.cancel,
      color: Colors.red,
      title: "Lost",
      lottery: data['lotteryTitle'],
      subtitle: "Ticket #${data['ticketNumber']}",
      status: "Better luck next time",
    );
  }

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
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const BottomNavScreen(initialIndex: 2),
          ),
        );
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(.15),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lottery,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(subtitle),
                  ],
                ),
              ),
              Text(
                status,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

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
      borderRadius: BorderRadius.circular(18),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(.15),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
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