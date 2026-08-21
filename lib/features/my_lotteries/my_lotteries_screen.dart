import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MyLotteriesScreen extends StatefulWidget {
  const MyLotteriesScreen({super.key});

  @override
  State<MyLotteriesScreen> createState() => _MyLotteriesScreenState();
}

class _MyLotteriesScreenState extends State<MyLotteriesScreen> {
  bool showActive = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    // Listen for auth changes
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      setState(() {
        _currentUserId = user?.uid;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      body: SafeArea(
        child: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, authSnapshot) {
            if (authSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Colors.green,
                ),
              );
            }

            final user = authSnapshot.data;

            if (user == null) {
              return const Center(
                child: Text(
                  'Please log in to see your tickets.',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
              );
            }

            // Update current user ID
            if (_currentUserId != user.uid) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                setState(() {
                  _currentUserId = user.uid;
                });
              });
            }

            return Column(
              children: [
                _header(user.displayName ?? 'User'),

                const SizedBox(height: 10),

                _tabs(),

                const SizedBox(height: 10),

                _filters(),

                const SizedBox(height: 5),

                Expanded(
                  child: _ticketList(user.uid),
                ),

                _buyButton(),
              ],
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _header(String userName) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundImage: AssetImage(
              'assets/avatar.png',
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome back,',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  userName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            icon: const Icon(
              Icons.notifications_none,
              size: 28,
            ),
            onPressed: () {
              // Notification screen can be connected here later.
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TABS
  // ============================================================

  Widget _tabs() {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
      ),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _tabButton('Active', true),
          _tabButton('Won / Lost', false),
        ],
      ),
    );
  }

  Widget _tabButton(String title, bool activeTab) {
    final isSelected = (showActive && activeTab) || (!showActive && !activeTab);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            showActive = activeTab;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: isSelected ? Colors.green : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade600,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // FILTER TITLE
  // ============================================================

  Widget _filters() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            showActive ? 'My Active Tickets' : 'Completed Lotteries',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Icon(
            Icons.filter_list,
            color: Colors.grey,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TICKET LIST - FIXED
  // ============================================================

  Widget _ticketList(String userId) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      // 🔥 KEY FIX: Force refresh by using a Unique Key
      key: ValueKey('tickets_$userId'),
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('tickets')
          .orderBy(
            'purchasedAt',
            descending: true,
          )
          .snapshots()
          // 🔥 KEY FIX: Add includeMetadataChanges to detect server updates
          .map((snapshot) {
            print('Tickets updated for user: $userId');
            print('Total tickets: ${snapshot.docs.length}');
            snapshot.docs.forEach((doc) {
              final data = doc.data();
              print('Ticket ${data['ticketNumber']} - Status: ${data['status']}');
            });
            return snapshot;
          }),

      builder: (context, snapshot) {
        // --------------------------------------------------------
        // LOADING
        // --------------------------------------------------------

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Colors.green,
            ),
          );
        }

        // --------------------------------------------------------
        // ERROR
        // --------------------------------------------------------

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 55,
                    color: Colors.red.shade300,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Could not load your tickets.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {});
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(
              color: Colors.green,
            ),
          );
        }

        final allTickets = snapshot.data!.docs;

        // --------------------------------------------------------
        // FILTER ACTIVE / COMPLETED - FIXED
        // --------------------------------------------------------

        final tickets = allTickets.where((doc) {
          final data = doc.data();

          // Normalize the backend status.
          final status = (data['status'] ?? 'ACTIVE').toString().trim().toUpperCase();

          if (showActive) {
            return status == 'ACTIVE' || status == 'DRAWING';
          }

          return status == 'WON' || status == 'LOST' || status == 'COMPLETED';
        }).toList();

        // --------------------------------------------------------
        // EMPTY STATE
        // --------------------------------------------------------

        if (tickets.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  showActive
                      ? Icons.confirmation_number_outlined
                      : Icons.emoji_events_outlined,
                  size: 65,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 14),
                Text(
                  showActive ? 'No active tickets' : 'No completed lotteries',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (!showActive) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Your lottery results will appear here.',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        // --------------------------------------------------------
        // TICKET LIST
        // --------------------------------------------------------

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: tickets.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final data = tickets[index].data();

            final title = data['lotteryTitle']?.toString() ?? 'Lottery';
            final ticketNumber = (data['ticketNumber'] as num?)?.toInt() ?? 0;
            final price = (data['pricePerTicket'] as num?) ?? 0;

            // Always read the CURRENT Firestore status.
            final status = (data['status'] ?? 'ACTIVE').toString().trim().toUpperCase();

            return _ticketCard(
              title: title,
              ticketNumber: ticketNumber,
              price: price,
              status: status,
            );
          },
        );
      },
    );
  }

  // ============================================================
  // TICKET CARD
  // ============================================================

  Widget _ticketCard({
    required String title,
    required int ticketNumber,
    required num price,
    required String status,
  }) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (status) {
      case 'WON':
        statusColor = Colors.amber.shade700;
        statusText = 'WINNER 🎉';
        statusIcon = Icons.emoji_events;
        break;

      case 'LOST':
        statusColor = Colors.red;
        statusText = 'NOT WON';
        statusIcon = Icons.close;
        break;

      case 'ACTIVE':
      default:
        statusColor = Colors.green;
        statusText = 'ACTIVE';
        statusIcon = Icons.confirmation_number;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // ------------------------------------------------------
          // TICKET NUMBER
          // ------------------------------------------------------
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                ticketNumber.toString(),
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // ------------------------------------------------------
          // LOTTERY INFORMATION
          // ------------------------------------------------------
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (status == 'WON') ...[
                  const SizedBox(height: 6),
                  Text(
                    'Congratulations! 🎉',
                    style: TextStyle(
                      color: Colors.amber.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
                if (status == 'LOST') ...[
                  const SizedBox(height: 6),
                  Text(
                    'Better luck next time 💚',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 8),

          // ------------------------------------------------------
          // STATUS
          // ------------------------------------------------------
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  statusIcon,
                  size: 15,
                  color: statusColor,
                ),
                const SizedBox(width: 4),
                Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUY MORE BUTTON
  // ============================================================

  Widget _buyButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: () {
          // Connect to Buy Tickets page.
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: const Text(
          'Buy More Tickets',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}