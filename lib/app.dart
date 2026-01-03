import 'package:flutter/material.dart';
import 'features/splash/splash_screen.dart';
import 'core/theme.dart';

class LuckyEtaApp extends StatelessWidget {
  const LuckyEtaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LuckyEta',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const SplashScreen(),
    );
  }
}

