import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../features/home/home_screen.dart';
import '../features/explore/explore_screen.dart';
import '../features/my_lotteries/my_lotteries_screen.dart';
import '../features/profile/profile_screen.dart';

class BottomNavScreen extends StatefulWidget {
  final int initialIndex;
  const BottomNavScreen({super.key, this.initialIndex = 0});

  @override
  State<BottomNavScreen> createState() => _BottomNavScreenState();
}

class _BottomNavScreenState extends State<BottomNavScreen> {
  int _currentIndex = 0;
  late String username;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;

    final user = FirebaseAuth.instance.currentUser;
    username = user?.displayName ?? 'Guest';
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      const HomeScreen(),
      ExploreScreen(userName: username),
      const MyLotteriesScreen(),
      ProfilePage(
        userName: username,
        luckLevel: 'Beginner',
        activeTickets: 0,
        lotteriesCreated: 0,
        totalWinnings: 0.0,
      ),
    ];

    return Scaffold(
      body: tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Explore'),
          BottomNavigationBarItem(icon: Icon(Icons.card_giftcard), label: 'My Luck'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
