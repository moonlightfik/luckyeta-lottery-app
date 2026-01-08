import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../navigation/bottom_nav_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {

    final user = FirebaseAuth.instance.currentUser;
    final String username = user?.displayName ?? '!';

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      // Navigate to Profile tab
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const BottomNavScreen(initialIndex: 3),
                        ),
                      );
                    },
                    child: CircleAvatar(
                      radius: 25,
                      backgroundImage: AssetImage('assets/avatar.png'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'WELCOME BACK',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        'Good Luck, $username!',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Featured Jackpots
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Featured Jackpots',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      // Navigate to Explore tab
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const BottomNavScreen(initialIndex: 1),
                        ),
                      );
                    },
                    child: const Text('View All',
                        style: TextStyle(color: Colors.green)),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Horizontal scrollable placeholder for jackpots
              SizedBox(
                height: 180,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: List.generate(
                    5,
                    (index) => Container(
                      width: 250,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.grey.shade300,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Jackpot ${index + 1}',
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('Prize: \$${(index + 1) * 1000}K',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const BottomNavScreen(initialIndex: 1),
                          ),
                        );
                      },
                      icon: const Icon(Icons.confirmation_num),
                      label: const Text('Buy Tickets'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.add, color: Colors.green),
                      label: const Text('Create Lottery',
                          style: TextStyle(color: Colors.green)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Colors.green),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // My Luck Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'My Luck',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
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
                    child: const Text('View All',
                        style: TextStyle(color: Colors.green)),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // My Luck cards
              Column(
                children: const [
                  MyLuckItem(
                    title: 'Golden Ticket',
                    subtitle: 'You won \$10.00!',
                    status: 'WON',
                  ),
                  MyLuckItem(
                    title: 'Office Pool #23',
                    subtitle: 'Draw in 2 days',
                    status: 'WAITING',
                  ),
                  MyLuckItem(
                    title: 'Weekly Charity',
                    subtitle: 'Better luck next time',
                    status: 'ENDED',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MyLuckItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String status;

  const MyLuckItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.status,
  });

  Color getStatusColor() {
    switch (status) {
      case 'WON':
        return Colors.green;
      case 'WAITING':
        return Colors.grey;
      case 'ENDED':
        return Colors.grey.shade400;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.grey.shade300,
          child: const Icon(Icons.confirmation_num, color: Colors.white),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: getStatusColor().withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(status,
              style: TextStyle(color: getStatusColor(), fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
