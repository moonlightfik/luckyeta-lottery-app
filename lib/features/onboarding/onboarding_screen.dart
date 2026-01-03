import 'package:flutter/material.dart';
import '../auth/login_screen.dart';
import '../../services/local_storage_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final LocalStorageService _storage = LocalStorageService();

  // onboarding data-image paths and text
  final List<Map<String, String>> _onboardingData = [
    {
      "image": "assets/images/onboarding1.png",
      "title": "Welcome to LuckyEta",
      "desc": "Discover your luck anywhere & anytime.",
    },
    {
      "image": "assets/images/onboarding2.png",
      "title": "Buy Tickets Easily",
      "desc": "Purchase your favorite lottery tickets in seconds.",
    },
    {
      "image": "assets/images/onboarding3.png",
      "title": "create lotteries easily",
      "desc": "discover your luck with family,friends,coworkers and more.",
    },
  ];

  void _finishOnboarding() async {
    await _storage.setSeenOnboarding(true);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _onboardingData.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              final data = _onboardingData[index];
              return Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                     mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: screenHeight * 0.45,
                      child: Image.asset(
                        data['image']!,
                        fit: BoxFit.contain,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.05),
                    Text(
                      data['title']!,
                      style: TextStyle(
                        fontSize: screenWidth * 0.07,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    Text(
                      data['desc']!,
                      style: TextStyle(
                        fontSize: screenWidth * 0.045,
                        color: Colors.grey[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
       ),

// Bottom controls
 Positioned(
            bottom: screenHeight * 0.08,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Skip button
                _currentPage != _onboardingData.length - 1
                    ? TextButton(
                        onPressed: _finishOnboarding,
                        child: const Text(
                          'Skip',
                          style: TextStyle(color: Colors.black),
                        ),
                      )
                    : const SizedBox(width: 60), // Placeholder

                // Page indicators
                Row(
                  children: List.generate(
                    _onboardingData.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == index ? 20 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index ? Colors.green : Colors.grey,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),

                // Next / Get Started button
                TextButton(
                  onPressed: () {
                    if (_currentPage == _onboardingData.length - 1) {
                      _finishOnboarding();
                    } else {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.ease,
                      );
                    }
                  },
                  child: Text(
                    _currentPage == _onboardingData.length - 1
                        ? 'Get Started'
                        : 'Next',
                    style: const TextStyle(color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
