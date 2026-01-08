import 'package:flutter/material.dart';

class AuthProviders extends StatelessWidget {
  final VoidCallback onAppleTap;
  final VoidCallback onGoogleTap;
  
  const AuthProviders({
    super.key, 
    required this.onAppleTap, 
    required this.onGoogleTap
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _AuthButton(
          iconPath: "assets/icons/google.png",
          label: "Google",
          color: Colors.white,
          textColor: Colors.black87,
          onTap: onGoogleTap, 
        ),
        _AuthButton(
          iconPath: "assets/icons/apple.png",
          label: "Apple",
          color: Colors.white,
          textColor: Colors.black,
          onTap: onAppleTap, 
        ),
      ],
    );
  }
}

class _AuthButton extends StatelessWidget {
  final String iconPath;
  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback onTap; // Callback parameter

  const _AuthButton({
    required this.iconPath,
    required this.label,
    required this.color,
    required this.textColor,
    required this.onTap, // Required parameter
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap, // Using the passed callback
        child: Container(
          height: 50,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade300,
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              
              Image.asset(
                iconPath,
                height: 24,
                width: 24,
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}