import 'package:flutter/material.dart';

class CategorySelector extends StatelessWidget {
  final String selectedCategory;
  final ValueChanged<String> onChanged;

  const CategorySelector({
    super.key,
    required this.selectedCategory,
    required this.onChanged,
  });

  static const List<Map<String, dynamic>> categories = [
    {
      "title": "Cash",
      "icon": Icons.attach_money,
      "color": Color(0xff16A34A),
    },
    {
      "title": "Electronics",
      "icon": Icons.phone_android,
      "color": Color(0xff2563EB),
    },
    {
      "title": "Vehicle",
      "icon": Icons.directions_car,
      "color": Color(0xffDC2626),
    },
    {
      "title": "Property",
      "icon": Icons.home,
      "color": Color(0xff7C3AED),
    },
    {
      "title": "Travel",
      "icon": Icons.flight_takeoff,
      "color": Color(0xffF97316),
    },
    {
      "title": "Gift",
      "icon": Icons.card_giftcard,
      "color": Color(0xffEC4899),
    },
    {
      "title": "Other",
      "icon": Icons.category,
      "color": Color(0xff6B7280),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Prize Category",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: categories.length,
          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 2.3,
          ),
          itemBuilder: (context, index) {
            final item = categories[index];

            final bool selected =
                selectedCategory == item["title"];

            final Color color = item["color"];

            return InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                onChanged(item["title"]);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
                      radius: 18,
                      backgroundColor: color.withOpacity(.15),
                      child: Icon(
                        item["icon"],
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item["title"],
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