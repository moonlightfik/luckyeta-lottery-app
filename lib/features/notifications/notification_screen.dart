import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),

      appBar: AppBar(
        title: const Text(
          "Notifications",
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),

      body: const Center(
        child: Text(
          "No notifications yet",
          style: TextStyle(
            color: Colors.grey,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}