import 'package:flutter/material.dart';
import '../features/home/home_screen.dart';
import '../features/explore/explore_screen.dart';
import '../features/my_lotteries/my_lotteries_screen.dart';
import '../features/profile/profile_screen.dart';

class BottomNavScreen extends StatefulWidget {
  const BottomNavScreen({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<BottomNavScreen> createState() => _BottomNavScreenState();
}

class _BottomNavScreenState extends State<BottomNavScreen> {
  late int _currentIndex;

  // Example user info
  final String userName = "John Doe";
  final String luckLevel = "Gold";
  final int activeTickets = 3;
  final int lotteriesCreated = 12;
  final double totalWinnings = 1250.0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;

    _screens = [
      const HomeScreen(), // index 0
      ExploreScreen(userName: userName), // index 1 - pass the required argument
      const MyLotteriesScreen(), // index 2
      ProfilePage(                // index 3
        userName: userName,
        luckLevel: luckLevel,
        activeTickets: activeTickets,
        lotteriesCreated: lotteriesCreated,
        totalWinnings: totalWinnings,
      ),
    ];
  }

  void _onNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Explore'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'My Lotteries'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
