import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // <-- use the generated file

import 'features/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase using the generated options
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    runApp(const LuckyEtaApp());
  } catch (e, stack) {
    runApp(ErrorApp(e.toString(), stack.toString()));
  }
}

class LuckyEtaApp extends StatelessWidget {
  const LuckyEtaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LuckyEta',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const SplashScreen(), // Start with your splash screen
    );
  }
}

class ErrorApp extends StatelessWidget {
  final String error;
  final String stack;
  const ErrorApp(this.error, this.stack, {super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Text(
            'Error initializing Firebase:\n\n$error\n\n$stack',
            style: const TextStyle(color: Colors.red, fontSize: 16),
          ),
        ),
      ),
    );
  }
}
