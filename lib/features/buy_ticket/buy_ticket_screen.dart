import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/lottery_model.dart';

class BuyTicketScreen extends StatefulWidget {
  final Lottery lottery;
  const BuyTicketScreen({super.key, required this.lottery});

  @override
  State<BuyTicketScreen> createState() => _BuyTicketScreenState();
}

class _BuyTicketScreenState extends State<BuyTicketScreen> {
  final Set<int> selectedTickets = {};
  bool isPurchasing = false;
  late final String userId;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (userId.isEmpty) {
      setState(() {
        errorMessage = 'User not logged in';
      });
    }
  }

  // ================= QUICK PICK =================
  void _quickPick(Set<int> taken, Set<int> mine) {
    final random = Random();
    final remaining = widget.lottery.maxTicketsPerUser - mine.length;

    final available = List.generate(
      widget.lottery.totalTickets,
      (i) => i + 1,
    ).where((t) => !taken.contains(t) && !mine.contains(t)).toList();

    selectedTickets.clear();

    while (selectedTickets.length < remaining && available.isNotEmpty) {
      final pick = available[random.nextInt(available.length)];
      selectedTickets.add(pick);
      available.remove(pick);
    }

    setState(() {});
  }

  // ================= PURCHASE =================
  Future<void> _purchaseTickets() async {
    if (selectedTickets.isEmpty) return;

    setState(() => isPurchasing = true);

    try {
      final batch = FirebaseFirestore.instance.batch();
      final ref = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('tickets');

      for (final ticket in selectedTickets) {
        batch.set(ref.doc(), {
          'userId': userId,
          'lotteryID': widget.lottery.id,
          'lotteryTitle': widget.lottery.title,
          'ticketNumber': ticket,
          'pricePerTicket': widget.lottery.pricePerTicket,
          'status': 'ACTIVE',
          'purchasedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      setState(() {
        selectedTickets.clear();
        isPurchasing = false;
      });

      _showReceipt();
    } catch (e) {
      setState(() {
        isPurchasing = false;
        errorMessage = 'Failed to purchase: $e';
      });
      _showErrorDialog('Purchase Failed', 'Could not complete purchase. Please try again.');
    }
  }

  void _showReceipt() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Purchase Successful 🎉'),
        content: const Text('Good luck!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.lottery.title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                color: Colors.red.shade100,
                child: Text(
                  errorMessage!,
                  style: TextStyle(color: Colors.red.shade900),
                ),
              ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collectionGroup('tickets')
                    .where('lotteryID', isEqualTo: widget.lottery.id)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    // Show detailed error
                    print('Firestore Error: ${snapshot.error}');
                    print('Error Details: ${snapshot.error?.runtimeType}');
                    
                    // Check for specific errors
                    String errorMsg = 'Something went wrong';
                    if (snapshot.error.toString().contains('index')) {
                      errorMsg = 'Firestore index required. Please create the required index.';
                    } else if (snapshot.error.toString().contains('permission')) {
                      errorMsg = 'Permission denied. Please check security rules.';
                    } else if (snapshot.error.toString().contains('collection group')) {
                      errorMsg = 'Collection group query error. Please check your data structure.';
                    }
                    
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                          const SizedBox(height: 16),
                          Text(
                            errorMsg,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => setState(() {}),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

     if (!snapshot.hasData) {
  return const Center(
    child: CircularProgressIndicator(),
  );
}

print('Lottery ID: ${widget.lottery.id}');
print('Total Tickets: ${widget.lottery.totalTickets}');
print('Purchased Tickets: ${snapshot.data!.docs.length}');

final takenTickets = <int>{};
final userTickets = <int>{};

for (final doc in snapshot.data!.docs) {
  final data = doc.data() as Map<String, dynamic>;

  final ticket = data['ticketNumber'] as int?;

  if (ticket == null) {
    print('Warning: Document missing ticketNumber: ${doc.id}');
    continue;
  }

  if (data['userId'] == userId) {
    userTickets.add(ticket);
  } else {
    takenTickets.add(ticket);
  }
}


                  for (final doc in snapshot.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final ticket = data['ticketNumber'] as int?;
                    
                    if (ticket == null) {
                      print('Warning: Document missing ticketNumber: ${doc.id}');
                      continue;
                    }

                    if (data['userId'] == userId) {
                      userTickets.add(ticket);
                    } else {
                      takenTickets.add(ticket);
                    }
                  }

                  final reachedLimit = userTickets.length >= widget.lottery.maxTicketsPerUser;

                  return Column(
                    children: [
                      // HEADER
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Pick your tickets',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Row(
                            children: [
                              Text(
                                '${selectedTickets.length + userTickets.length}/${widget.lottery.maxTicketsPerUser}',
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: reachedLimit
                                    ? null
                                    : () => _quickPick(takenTickets, userTickets),
                                child: const Text('Quick Pick'),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // GRID
                      Expanded(
                        child: GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 5,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: widget.lottery.totalTickets,
                          itemBuilder: (context, index) {
                            final ticket = index + 1;

                            final isMine = userTickets.contains(ticket);
                            final isTaken = takenTickets.contains(ticket);
                            final isSelected = selectedTickets.contains(ticket);

                            Color color;
                            if (isMine) {
                              color = Colors.green.shade200;
                            } else if (isTaken) {
                              color = Colors.grey.shade300;
                            } else if (isSelected) {
                              color = Colors.green;
                            } else {
                              color = Colors.grey.shade200;
                            }

                            return GestureDetector(
                              onTap: isMine || isTaken || reachedLimit
                                  ? null
                                  : () {
                                      if (isSelected) {
                                        selectedTickets.remove(ticket);
                                      } else if (selectedTickets.length + userTickets.length <
                                          widget.lottery.maxTicketsPerUser) {
                                        selectedTickets.add(ticket);
                                      }
                                      setState(() {});
                                    },
                              child: Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(8),
                                  border: isSelected ? Border.all(color: Colors.green.shade800, width: 2) : null,
                                ),
                                child: Text(
                                  ticket.toString(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isTaken ? Colors.grey : Colors.black,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 12),

                      // INFO ROW
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Selected: ${selectedTickets.length}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          Text(
                            'Price: \$${selectedTickets.length * widget.lottery.pricePerTicket}',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // BUY BUTTON
                      ElevatedButton(
                        onPressed: reachedLimit ||
                                selectedTickets.isEmpty ||
                                isPurchasing
                            ? null
                            : _purchaseTickets,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: isPurchasing
                            ? const CircularProgressIndicator(
                                color: Colors.white,
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