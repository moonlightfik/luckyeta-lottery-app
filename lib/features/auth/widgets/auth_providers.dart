import 'package:flutter/material.dart';

class AuthProviders extends StatelessWidget {
  const AuthProviders({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: const [
        _AuthButton(
          iconPath: "assets/icons/google.png",
          label: "Google",
          color: Colors.white,
          textColor: Colors.black87,
          provider: "Google",
        ),
        _AuthButton(
          iconPath: "assets/icons/apple.png",
          label: "Apple",
          color: Colors.black,
          textColor: Colors.white,
          provider: "Apple",
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
  final String provider;

  const _AuthButton({
    required this.iconPath,
    required this.label,
    required this.color,
    required this.textColor,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          debugPrint("$provider sign-in tapped");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("$provider sign-in tapped")),
          );
        },
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
