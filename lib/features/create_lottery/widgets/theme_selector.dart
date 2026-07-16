import 'package:flutter/material.dart';

class ThemeSelector extends StatelessWidget {
  final Color selectedColor;
  final ValueChanged<Color> onChanged;

  const ThemeSelector({
    super.key,
    required this.selectedColor,
    required this.onChanged,
  });

  static final List<Map<String, dynamic>> colors = [
    {
      "name": "Emerald",
      "color": const Color(0xFF16A34A),
    },
    {
      "name": "Ocean",
      "color": const Color(0xFF2563EB),
    },
    {
      "name": "Royal",
      "color": const Color(0xFF7C3AED),
    },
    {
      "name": "Sunset",
      "color": const Color(0xFFF97316),
    },
    {
      "name": "Ruby",
      "color": const Color(0xFFDC2626),
    },
    {
      "name": "Midnight",
      "color": const Color(0xFF374151),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Theme Color",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 15),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: colors.length,
          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.8,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemBuilder: (_, index) {
            final item = colors[index];

            final Color color = item["color"];

            final bool selected =
                color.value == selectedColor.value;

            return InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => onChanged(color),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding:
                    const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: selected
                      ? color.withOpacity(.12)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: selected
                        ? color
                        : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: color,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item["name"],
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? color
                              : Colors.black87,
                        ),
                      ),
                    ),
                    if (selected)
                      Icon(
                        Icons.check_circle,
                        color: color,
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}