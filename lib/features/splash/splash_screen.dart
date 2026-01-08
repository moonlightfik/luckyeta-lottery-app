import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/local_storage_service.dart';
import '../onboarding/onboarding_screen.dart';
import '../auth/auth_screen.dart';
import '../home/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _luckyController;
  late final Animation<double> _luckyScale;

  late final AnimationController _etaController;
  late final Animation<Offset> _etaSlide;
  late final Animation<double> _etaFade;

  late final AnimationController _bgController;
  late final Animation<Alignment> _alignmentAnimation;

  final LocalStorageService _storage = LocalStorageService();

  @override
  void initState() {
    super.initState();

    // Lucky pop animation
    _luckyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _luckyScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _luckyController, curve: Curves.elasticOut),
    );
    _luckyController.forward();

    // Eta slide + fade
    _etaController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _etaSlide =
        Tween<Offset>(begin: const Offset(1.5, 0), end: Offset.zero).animate(
      CurvedAnimation(parent: _etaController, curve: Curves.easeOutBack),
    );
    _etaFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _etaController, curve: Curves.easeIn),
    );

    Future.delayed(const Duration(milliseconds: 700), () {
      _etaController.forward();
    });

    // Animated gradient background
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
    _alignmentAnimation = AlignmentTween(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).animate(
      CurvedAnimation(parent: _bgController, curve: Curves.easeInOut),
    );

    // Navigate after splash
    _navigateNext();
  }

  Future<void> _navigateNext() async {
    await Future.delayed(const Duration(seconds: 3));

    final seenOnboarding = await _storage.getSeenOnboarding();
    final user = FirebaseAuth.instance.currentUser;

    if (!seenOnboarding) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    } else if (user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
    }
  }

  @override
  void dispose() {
    _luckyController.dispose();
    _etaController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gradient = const LinearGradient(colors: [Colors.green, Colors.red]);
    final screenWidth = MediaQuery.of(context).size.width;
    final fontSize = screenWidth * 0.12;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _alignmentAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade300, Colors.red.shade300],
                begin: _alignmentAnimation.value,
                end: Alignment.center,
              ),
            ),
            child: child,
          );
        },
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScaleTransition(
                  scale: _luckyScale,
                  child: ShaderMask(
                    shaderCallback: (bounds) => gradient.createShader(
                      Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                    ),
                    child: Text(
                      'Lucky',
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SlideTransition(
                  position: _etaSlide,
                  child: FadeTransition(
                    opacity: _etaFade,
                    child: ShaderMask(
                      shaderCallback: (bounds) => gradient.createShader(
                        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                      ),
                      child: Text(
                        'Eta',
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
