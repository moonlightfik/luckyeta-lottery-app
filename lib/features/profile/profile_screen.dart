import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  final String userName;
  final String luckLevel;
  final int activeTickets;
  final int lotteriesCreated;
  final double totalWinnings;

  const ProfilePage({
    super.key,
    required this.userName,
    required this.luckLevel,
    required this.activeTickets,
    required this.lotteriesCreated,
    required this.totalWinnings,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView( // <-- wrap in scroll
          child: Column(
            children: [
              // HEADER
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(width: 24),
                    Text(
                      "My Profile",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: Icon(Icons.notifications_none),
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
                    backgroundImage: AssetImage("assets/avatar.png"),
                    backgroundColor: Colors.grey[200],
                  ),
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.green,
                    child: Icon(Icons.edit, color: Colors.white, size: 20),
                  ),
                ],
              ),

              SizedBox(height: 10),

              // NAME
              Text(
                userName,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              // LUCK LEVEL
              Container(
                margin: EdgeInsets.symmetric(vertical: 5),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.yellow[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 18),
                    SizedBox(width: 5),
                    Text(
                      "Luck Level: $luckLevel",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20),

              // STATS ROW
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatCard("Active Tickets", activeTickets.toString(), Colors.grey[100]!),
                    _buildStatCard("Lotteries Created", lotteriesCreated.toString(), Colors.grey[100]!),
                    _buildStatCard("Total Winnings", "\$${totalWinnings.toStringAsFixed(0)}", Colors.yellow[100]!),
                  ],
                ),
              ),

              SizedBox(height: 20),

              // ACCOUNT SECTION
              _buildSectionTitle("ACCOUNT"),
              _buildListTile(Icons.person, "Edit Profile", () {}),
              _buildListTile(Icons.settings, "Account Settings", () {}),

              SizedBox(height: 10),

              // SECURITY & SUPPORT
              _buildSectionTitle("SECURITY & SUPPORT"),
              _buildListTile(Icons.lock, "Privacy & Security", () {}),
              _buildListTile(Icons.help_outline, "Help & Support", () {}),

              SizedBox(height: 10),

              // LOG OUT
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.logout, color: Colors.red),
                  label: Text("Log Out", style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: Size(double.infinity, 50),
                  ),
                ),
              ),

              SizedBox(height: 5),

              // APP VERSION
              Text("Version 1.0.2", style: TextStyle(color: Colors.grey)),
              SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color bgColor) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(15),
      ),
      width: 100,
      child: Column(
        children: [
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          SizedBox(height: 5),
          Text(title, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 5),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title, style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildListTile(IconData icon, String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: ListTile(
        tileColor: Colors.grey[100],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(icon, color: Colors.black),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w500)),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
