import 'package:flutter/material.dart';

class CardStyleSelector extends StatelessWidget {
  final String selectedStyle;
  final ValueChanged<String> onChanged;

  const CardStyleSelector({
    super.key,
    required this.selectedStyle,
    required this.onChanged,
  });

  final List<String> styles = const [
    "Classic",
    "Modern",
    "Luxury",
    "Minimal",
    "Neon",
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Card Style",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 15),

        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: styles.map((style) {
            final selected = selectedStyle == style;

            return GestureDetector(
              onTap: () => onChanged(style),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 150,
                height: 95,
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.green.shade50
                      : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: selected
                        ? Colors.green
                        : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    style,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: selected
                          ? Colors.green
                          : Colors.black87,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}