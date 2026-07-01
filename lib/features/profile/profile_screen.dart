import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth/auth_screen.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final user = FirebaseAuth.instance.currentUser;
  int activeTickets = 0;
  int lotteriesCreated = 0;
  double totalWinnings = 0.0;
  String luckLevel = "Novice";

  @override
  void initState() {
    super.initState();
    _fetchUserStats();
  }

  Future<void> _fetchUserStats() async {
    final userId = user!.uid;

    // Active Tickets
    final ticketsSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('tickets')
        .where('status', isEqualTo: 'ACTIVE')
        .get();

    // Lotteries Created
    final lotteriesSnap = await FirebaseFirestore.instance
        .collection('lotteries')
        .where('creatorId', isEqualTo: userId)
        .get();

    // Total Winnings (tickets marked as 'WON')
    final wonTicketsSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('tickets')
        .where('status', isEqualTo: 'WON')
        .get();

    double winnings = 0;
    for (var doc in wonTicketsSnap.docs) {
      winnings += (doc.data()['pricePerTicket'] ?? 0) * 2; // Example: double the ticket price as winning
    }

    setState(() {
      activeTickets = ticketsSnap.docs.length;
      lotteriesCreated = lotteriesSnap.docs.length;
      totalWinnings = winnings;
      luckLevel = _computeLuckLevel(activeTickets, totalWinnings);
    });
  }

  String _computeLuckLevel(int tickets, double winnings) {
    if (winnings > 1000) return "Legend";
    if (winnings > 500) return "Pro";
    if (tickets > 10) return "Lucky";
    return "Novice";
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AuthScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // HEADER
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 24),
                    const Text(
                      "My Profile",
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.notifications_none),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),

              // AVATAR
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: const AssetImage("assets/avatar.png"),
                    backgroundColor: Colors.grey[200],
                  ),
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.green,
                    child:
                        const Icon(Icons.edit, color: Colors.white, size: 20),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // NAME
              Text(
                user?.displayName ?? 'Player',
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold),
              ),

              // LUCK LEVEL
              Container(
                margin: const EdgeInsets.symmetric(vertical: 5),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.yellow[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 18),
                    const SizedBox(width: 5),
                    Text(
                      "Luck Level: $luckLevel",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // STATS ROW
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatCard(
                        "Active Tickets", activeTickets.toString(), Colors.grey[100]!),
                    _buildStatCard(
                        "Lotteries Created", lotteriesCreated.toString(), Colors.grey[100]!),
                    _buildStatCard("Total Winnings", "\$${totalWinnings.toStringAsFixed(0)}",
                        Colors.yellow[100]!),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ACCOUNT SECTION
              _buildSectionTitle("ACCOUNT"),
              _buildListTile(Icons.person, "Edit Profile", () {}),
              _buildListTile(Icons.settings, "Account Settings", () {}),

              const SizedBox(height: 10),

              // SECURITY & SUPPORT
              _buildSectionTitle("SECURITY & SUPPORT"),
              _buildListTile(Icons.lock, "Privacy & Security", () {}),
              _buildListTile(Icons.help_outline, "Help & Support", () {}),

              const SizedBox(height: 10),

              // LOG OUT
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label:
                      const Text("Log Out", style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ),

              const SizedBox(height: 5),

              // APP VERSION
              const Text("Version 1.0.2", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(15),
      ),
      width: 100,
      child: Column(
        children: [
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 5),
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 5),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title,
            style: TextStyle(
                color: Colors.grey[600], fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildListTile(IconData icon, String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: ListTile(
        tileColor: Colors.grey[100],
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(icon, color: Colors.black),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
