import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateLotteryScreen extends StatefulWidget {
  const CreateLotteryScreen({super.key});

  @override
  State<CreateLotteryScreen> createState() => _CreateLotteryScreenState();
}

class _CreateLotteryScreenState extends State<CreateLotteryScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController jackpotController = TextEditingController();

  double pricePerTicket = 5;
  int totalTickets = 100;
  bool limitPerUser = true;
  int maxTicketsPerUser = 5;

  String drawFrequency = 'Daily';
  bool isPublic = true;

  DateTime nextDrawAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    calculateNextDraw();
  }

  void calculateNextDraw() {
    final now = DateTime.now();

    switch (drawFrequency) {
      case 'Hourly':
        nextDrawAt = now.add(const Duration(hours: 1));
        break;
      case 'Daily':
        nextDrawAt = DateTime(now.year, now.month, now.day + 1, 20, 0);
        break;
      case 'Weekly':
        int daysToFriday = (5 - now.weekday) % 7;
        nextDrawAt = DateTime(now.year, now.month, now.day + daysToFriday, 20, 0);
        break;
    }
    setState(() {});
  }

  String get formattedDrawTime {
    return "${nextDrawAt.day.toString().padLeft(2, '0')}/"
        "${nextDrawAt.month.toString().padLeft(2, '0')}/"
        "${nextDrawAt.year} "
        "${nextDrawAt.hour.toString().padLeft(2, '0')}:"
        "${nextDrawAt.minute.toString().padLeft(2, '0')}";
  }

  Future<void> launchLottery() async {
    if (titleController.text.isEmpty || jackpotController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter title and jackpot")),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('lotteries').add({
        'title': titleController.text.trim(),
        'jackpot': double.parse(jackpotController.text),
        'pricePerTicket': pricePerTicket,
        'totalTickets': totalTickets,
        'maxTicketsPerUser': limitPerUser ? maxTicketsPerUser : null,
        'drawFrequency': drawFrequency,
        'nextDrawAt': Timestamp.fromDate(nextDrawAt),
        'isPublic': isPublic,
        'creatorId': FirebaseAuth.instance.currentUser!.uid,
        'status': 'ACTIVE',
        'createdAt': FieldValue.serverTimestamp(),
      });

      final createNew = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Lottery Launched!"),
          content: const Text("Do you want to create a new lottery?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("No"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Yes"),
            ),
          ],
        ),
      );

      if (createNew == true) {
        titleController.clear();
        jackpotController.clear();
        pricePerTicket = 5;
        totalTickets = 100;
        maxTicketsPerUser = 5;
        limitPerUser = true;
        drawFrequency = 'Daily';
        isPublic = true;
        calculateNextDraw();
      } else {
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to launch lottery: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button and title
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'New Lottery',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Title
              const Text(
                "LOTTERY NAME",
                style: TextStyle(color: Colors.green),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  hintText: "Enter lottery name",
                ),
              ),
              const SizedBox(height: 16),

              // Total jackpot
              const Text(
                "TOTAL JACKPOT PRIZE",
                style: TextStyle(color: Colors.green),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: jackpotController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  prefixText: "\$ ",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  hintText: "0.00",
                ),
              ),
              const SizedBox(height: 16),

              // Price per ticket
              const Text("Price per Ticket"),
              Slider(
                min: 1,
                max: 50,
                value: pricePerTicket,
                activeColor: Colors.green,
                onChanged: (val) {
                  setState(() {
                    pricePerTicket = val;
                  });
                },
                divisions: 49,
                label: "\$${pricePerTicket.toInt()}",
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("\$1"),
                  Text("\$${pricePerTicket.toInt()}"),
                  const Text("\$50"),
                ],
              ),
              const SizedBox(height: 16),

              // Ticket supply
              const Text("TICKET SUPPLY & LIMITS"),
              const SizedBox(height: 8),
              TextField(
                controller: TextEditingController(text: "$totalTickets"),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Total Tickets",
                  suffixText: "pcs",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: (val) {
                  setState(() {
                    totalTickets = int.tryParse(val) ?? 0;
                  });
                },
              ),
              const SizedBox(height: 8),

              // Limit per user
              SwitchListTile(
                title: const Text("Limit per User"),
                value: limitPerUser,
                activeThumbColor: Colors.green,
                onChanged: (val) {
                  setState(() {
                    limitPerUser = val;
                  });
                },
              ),
              if (limitPerUser)
                TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Max Tickets per User",
                    suffixText: "pcs",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onChanged: (val) {
                    setState(() {
                      maxTicketsPerUser = int.tryParse(val) ?? 5;
                    });
                  },
                ),
              const SizedBox(height: 16),

              // Draw frequency
              const Text("When does it draw?"),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: ['Hourly', 'Daily', 'Weekly'].map((freq) {
                  final isSelected = drawFrequency == freq;
                  return ChoiceChip(
                    label: Text(freq),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() {
                        drawFrequency = freq;
                        calculateNextDraw();
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              Text("Next draw: $formattedDrawTime"),
              const SizedBox(height: 16),

              // Public / Private buttons with icons and description
              const Text("Who can play?"),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => isPublic = true),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isPublic ? Colors.green.shade50 : Colors.grey.shade200,
                          border: Border.all(
                              color: isPublic ? Colors.green : Colors.grey),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: const [
                            Icon(Icons.public, color: Colors.green),
                            SizedBox(height: 4),
                            Text("Public", style: TextStyle(fontWeight: FontWeight.bold)),
                            Text("Anyone on LuckyLink", style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => isPublic = false),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: !isPublic ? Colors.green.shade50 : Colors.grey.shade200,
                          border: Border.all(
                              color: !isPublic ? Colors.green : Colors.grey),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: const [
                            Icon(Icons.lock, color: Colors.green),
                            SizedBox(height: 4),
                            Text("Private", style: TextStyle(fontWeight: FontWeight.bold)),
                            Text("Invite link only", style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Publishing tax
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text("Publishing Tax (2%)"),
                    Text("\$0.00"),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Launch button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: launchLottery,
                  icon: const Icon(Icons.rocket_launch),
                  label: const Text("Launch Lottery"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
