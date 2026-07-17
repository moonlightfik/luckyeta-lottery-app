import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'widgets/card_style_selector.dart';
import 'widgets/category_selector.dart';
import 'widgets/cover_image_picker.dart';
import 'widgets/theme_selector.dart';

class CreateLotteryScreen extends StatefulWidget {
  const CreateLotteryScreen({super.key});

  @override
  State<CreateLotteryScreen> createState() =>
      _CreateLotteryScreenState();
}

class _CreateLotteryScreenState
    extends State<CreateLotteryScreen> {
  //-----------------------------------------
  // CONTROLLERS
  //-----------------------------------------

  final titleController = TextEditingController();

  final descriptionController =
      TextEditingController();

  final jackpotController =
      TextEditingController();

  final totalTicketsController =
      TextEditingController(text: "100");

  final maxTicketsController =
      TextEditingController(text: "5");

  //-----------------------------------------
  // IMAGE
  //-----------------------------------------

  File? coverImage;

  //-----------------------------------------
  // THEME
  //-----------------------------------------

  Color selectedTheme =
      const Color(0xff16A34A);

  //-----------------------------------------
  // STYLE
  //-----------------------------------------

  String selectedStyle = "Modern";

  //-----------------------------------------
  // CATEGORY
  //-----------------------------------------

  String selectedCategory = "Cash";

  //-----------------------------------------
  // LOTTERY
  //-----------------------------------------

  double pricePerTicket = 5;

  int totalTickets = 100;

  bool limitPerUser = true;

  int maxTicketsPerUser = 5;

  int numberOfWinners = 1;

  //-----------------------------------------
  // TYPE
  //-----------------------------------------

  String lotteryType = "recurring";

  String drawFrequency = "Daily";

  DateTime nextDrawAt =
      DateTime.now();

  //-----------------------------------------
  // VISIBILITY
  //-----------------------------------------

  bool isPublic = true;

  //-----------------------------------------

  @override
  void initState() {
    super.initState();
    calculateNextDraw();
  }

  //-----------------------------------------

  void calculateNextDraw() {
    final now = DateTime.now();

    if (lotteryType == "oneTime") {
      nextDrawAt =
          now.add(const Duration(days: 1));
    } else {
      switch (drawFrequency) {
        case "Hourly":
          nextDrawAt =
              now.add(const Duration(hours: 1));
          break;

        case "Daily":
          nextDrawAt = DateTime(
            now.year,
            now.month,
            now.day + 1,
            20,
          );
          break;

        case "Weekly":
          final days =
              (5 - now.weekday) % 7;

          nextDrawAt = DateTime(
            now.year,
            now.month,
            now.day + days,
            20,
          );

          break;
      }
    }

    setState(() {});
  }

  //-----------------------------------------

  double get jackpot {
    return double.tryParse(
            jackpotController.text) ??
        0;
  }

  //-----------------------------------------

  double get revenue {
    return pricePerTicket *
        totalTickets;
  }

  //-----------------------------------------

  double get fee {
    return revenue * .02;
  }

  //-----------------------------------------

  double get creatorProfit {
    return revenue -
        jackpot -
        fee;
  }

  //-----------------------------------------

  Future<void> launchLottery() async {
    if (titleController.text.isEmpty ||
        jackpotController.text.isEmpty) {
      return;
    }

    // Firebase Storage upload
    // will be added later

    String? imageUrl;

    await FirebaseFirestore.instance
        .collection("lotteries")
        .add({
  // -------------------------------
  // Basic Information
  // -------------------------------
  "title": titleController.text.trim(),
  "description": descriptionController.text.trim(),

  // -------------------------------
  // Prize
  // -------------------------------
  "jackpot": jackpot,

  // -------------------------------
  // Ticket Settings
  // -------------------------------
  "pricePerTicket": pricePerTicket,
  "totalTickets": totalTickets,
  "ticketsSold": 0,
  "remainingTickets": totalTickets,
  "maxTicketsPerUser": maxTicketsPerUser,

  // -------------------------------
  // Winners
  // -------------------------------
  "numberOfWinners": numberOfWinners,
  "winnerIds": [],

  // -------------------------------
  // Lottery Type
  // -------------------------------
  "lotteryType": lotteryType,

  "drawFrequency":
      lotteryType == "recurring"
          ? drawFrequency
          : null,

  "nextDrawAt":
      Timestamp.fromDate(nextDrawAt),

  // -------------------------------
  // Appearance
  // -------------------------------
  "category": selectedCategory,
  "cardStyle": selectedStyle,
  "themeColor": selectedTheme.value,
  "imageUrl": imageUrl,

  // -------------------------------
  // Visibility
  // -------------------------------
  "isPublic": isPublic,

  // -------------------------------
  // Status
  // -------------------------------
  "status": "ACTIVE",

  // -------------------------------
  // Creator
  // -------------------------------
  "creatorId":
      FirebaseAuth.instance.currentUser!.uid,

  "creatorName":
      FirebaseAuth.instance.currentUser?.displayName ??
      "LuckyEta User",

  // -------------------------------
  // Time
  // -------------------------------
  "createdAt":
      FieldValue.serverTimestamp(),
});

    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content:
            Text("Lottery Created 🎉"),
      ),
    );

    Navigator.pop(context);
  }

  //-----------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xffF7F8FA),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Create Lottery",
          style: TextStyle(
            color: Colors.black,
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding:
            const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            //---------------------------------------------------
            // COVER IMAGE
            //---------------------------------------------------

            CoverImagePicker(
              onImageSelected: (file) {
                coverImage = file;
              },
            ),

            const SizedBox(height: 24),

            //---------------------------------------------------
            // THEME
            //---------------------------------------------------

            ThemeSelector(
              selectedColor:
                  selectedTheme,
              onChanged: (color) {
                setState(() {
                  selectedTheme =
                      color;
                });
              },
            ),

            const SizedBox(height: 24),

            //---------------------------------------------------
            // STYLE
            //---------------------------------------------------

            CardStyleSelector(
              selectedStyle:
                  selectedStyle,
              onChanged: (style) {
                setState(() {
                  selectedStyle =
                      style;
                });
              },
            ),

            const SizedBox(height: 24),

            //---------------------------------------------------
            // CATEGORY
            //---------------------------------------------------

            CategorySelector(
              selectedCategory:
                  selectedCategory,
              onChanged:
                  (category) {
                setState(() {
                  selectedCategory =
                      category;
                });
              },
            ),

            const SizedBox(height: 30),
                        //---------------------------------------------------
            // LOTTERY DETAILS
            //---------------------------------------------------

            const Text(
              "Lottery Details",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 18),

            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: "Lottery Name",
                hintText: "Summer Jackpot",
                prefixIcon: const Icon(Icons.emoji_events),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),

            const SizedBox(height: 18),

            TextField(
              controller: descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: "Description (Optional)",
                hintText:
                    "Tell people what they can win...",
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),

            const SizedBox(height: 18),

            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: InputDecoration(
                labelText: "Prize Category",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              items: const [
                DropdownMenuItem(
                    value: "Cash",
                    child: Text("💵 Cash")),
                DropdownMenuItem(
                    value: "Electronics",
                    child: Text("📱 Electronics")),
                DropdownMenuItem(
                    value: "Vehicle",
                    child: Text("🚗 Vehicle")),
                DropdownMenuItem(
                    value: "Property",
                    child: Text("🏠 Property")),
                DropdownMenuItem(
                    value: "Travel",
                    child: Text("✈ Travel")),
                DropdownMenuItem(
                    value: "Gift",
                    child: Text("🎁 Gift")),
                DropdownMenuItem(
                    value: "Other",
                    child: Text("🎟 Other")),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  selectedCategory = value;
                });
              },
            ),

            const SizedBox(height: 18),

            TextField(
              controller: jackpotController,
              keyboardType:
                  const TextInputType.numberWithOptions(
                      decimal: true),
              decoration: InputDecoration(
                labelText: "Jackpot Prize",
                prefixText: "\$ ",
                prefixIcon:
                    const Icon(Icons.workspace_premium),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),

            const SizedBox(height: 30),

            //---------------------------------------------------
            // TICKET PRICE
            //---------------------------------------------------

            const Text(
              "Ticket Price",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(18),
                side: BorderSide(
                  color: Colors.grey.shade300,
                ),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.all(18),
                child: Column(
                  children: [
                    Text(
                      "\$${pricePerTicket.toStringAsFixed(0)}",
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  Slider(
  value: pricePerTicket,
  min: 1,
  max: 100,
  divisions: 99,
  activeColor: Colors.green,
  inactiveColor: Colors.green.shade100,
  thumbColor: Colors.green,
  onChanged: (value) {
    setState(() {
      pricePerTicket = value;
    });
  },
),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            //---------------------------------------------------
            // TICKET SETTINGS
            //---------------------------------------------------

            const Text(
              "Ticket Settings",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 18),

            TextField(
              controller: totalTicketsController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Total Tickets",
                prefixIcon: const Icon(Icons.confirmation_number),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  totalTickets =
                      int.tryParse(value) ?? 100;
                });
              },
            ),

            const SizedBox(height: 18),

          SwitchListTile(
  activeColor: Colors.green,
  activeTrackColor: Colors.green.shade300,
              value: limitPerUser,
              title: const Text("Limit tickets per user"),
              onChanged: (value) {
                setState(() {
                  limitPerUser = value;
                });
              },
            ),

            if (limitPerUser) ...[
              const SizedBox(height: 12),

              TextField(
                controller: maxTicketsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Maximum Per User",
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(16),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    maxTicketsPerUser =
                        int.tryParse(value) ?? 5;
                  });
                },
              ),
            ],

            const SizedBox(height: 30),
                        //---------------------------------------------------
            // WINNERS
            //---------------------------------------------------

            const Text(
              "Number of Winners",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                child: Row(
                  children: [

                    IconButton(
                      onPressed: () {
                        if (numberOfWinners > 1) {
                          setState(() {
                            numberOfWinners--;
                          });
                        }
                      },
                      icon: const Icon(Icons.remove_circle),
                    ),

                    Expanded(
                      child: Center(
                        child: Text(
                          "$numberOfWinners Winner${numberOfWinners == 1 ? "" : "s"}",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    IconButton(
                      onPressed: () {
                        setState(() {
                          numberOfWinners++;
                        });
                      },
                      icon: const Icon(Icons.add_circle),
                    ),

                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            //---------------------------------------------------
            // LOTTERY TYPE
            //---------------------------------------------------

            const Text(
              "Lottery Type",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

          SegmentedButton<String>(
  style: ButtonStyle(
    backgroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return Colors.green;
      }
      return Colors.white;
    }),
    foregroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return Colors.white;
      }
      return Colors.black;
    }),
    side: WidgetStateProperty.all(
      const BorderSide(color: Colors.green),
    ),
  ),
              segments: const [

                ButtonSegment(
                  value: "oneTime",
                  label: Text("One-Time"),
                  icon: Icon(Icons.event),
                ),

                ButtonSegment(
                  value: "Hourly",
                  label: Text("Hourly"),
                ),

                ButtonSegment(
                  value: "Daily",
                  label: Text("Daily"),
                ),

                ButtonSegment(
                  value: "Weekly",
                  label: Text("Weekly"),
                ),

              ],

              selected: {
                lotteryType == "oneTime"
                    ? "oneTime"
                    : drawFrequency
              },

              onSelectionChanged: (value) {

                setState(() {

                  if (value.first == "oneTime") {

                    lotteryType = "oneTime";

                  } else {

                    lotteryType = "recurring";

                    drawFrequency = value.first;

                  }

                  calculateNextDraw();

                });

              },

            ),

            const SizedBox(height: 25),

            if (lotteryType == "oneTime")

              ListTile(

                leading: const Icon(Icons.calendar_today),

                title: Text(

                  "${nextDrawAt.day}/${nextDrawAt.month}/${nextDrawAt.year}",

                ),

                subtitle: const Text("Tap to choose draw date"),

                trailing: const Icon(Icons.edit),

                onTap: () async {

                  final picked = await showDatePicker(

                    context: context,

                    initialDate: nextDrawAt,

                    firstDate: DateTime.now(),

                    lastDate: DateTime(2100),

                  );

                  if (picked == null) return;

                  setState(() {

                    nextDrawAt = DateTime(

                      picked.year,

                      picked.month,

                      picked.day,

                      nextDrawAt.hour,

                      nextDrawAt.minute,

                    );

                  });

                },

              ),

            const SizedBox(height: 30),

            //---------------------------------------------------
            // VISIBILITY
            //---------------------------------------------------

            const Text(
              "Visibility",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            Row(

              children: [

                Expanded(

                  child: GestureDetector(

                    onTap: () {

                      setState(() {

                        isPublic = true;

                      });

                    },

                    child: AnimatedContainer(

                      duration: const Duration(milliseconds: 250),

                      padding: const EdgeInsets.all(20),

                      decoration: BoxDecoration(

                        color: isPublic
                            ? Colors.green.shade50
                            : Colors.white,

                        borderRadius: BorderRadius.circular(18),

                        border: Border.all(

                          color: isPublic
                              ? Colors.green
                              : Colors.grey.shade300,

                          width: 2,

                        ),

                      ),

                      child: const Column(

                        children: [

                          Icon(Icons.public),

                          SizedBox(height: 10),

                          Text(

                            "Public",

                            style: TextStyle(

                              fontWeight: FontWeight.bold,

                            ),

                          ),

                        ],

                      ),

                    ),

                  ),

                ),

                const SizedBox(width: 15),

                Expanded(

                  child: GestureDetector(

                    onTap: () {

                      setState(() {

                        isPublic = false;

                      });

                    },

                    child: AnimatedContainer(

                      duration: const Duration(milliseconds: 250),

                      padding: const EdgeInsets.all(20),

                      decoration: BoxDecoration(

                        color: !isPublic
                            ? Colors.green.shade50
                            : Colors.white,

                        borderRadius: BorderRadius.circular(18),

                        border: Border.all(

                          color: !isPublic
                              ? Colors.green
                              : Colors.grey.shade300,

                          width: 2,

                        ),

                      ),

                      child: const Column(

                        children: [

                          Icon(Icons.lock),

                          SizedBox(height: 10),

                          Text(

                            "Private",

                            style: TextStyle(

                              fontWeight: FontWeight.bold,

                            ),

                          ),

                        ],

                      ),

                    ),

                  ),

                ),

              ],

            ),

            const SizedBox(height: 30),

            //---------------------------------------------------
            // SUMMARY
            //---------------------------------------------------

            Card(

              shape: RoundedRectangleBorder(

                borderRadius: BorderRadius.circular(20),

              ),

              child: Padding(

                padding: const EdgeInsets.all(20),

                child: Column(

                  children: [

                    const Text(

                      "Summary",

                      style: TextStyle(

                        fontSize: 22,

                        fontWeight: FontWeight.bold,

                      ),

                    ),

                    const Divider(height: 30),

                    summaryRow(
                      "Revenue",
                      "\$${revenue.toStringAsFixed(2)}",
                    ),

                    summaryRow(
                      "Jackpot",
                      "\$${jackpot.toStringAsFixed(2)}",
                    ),

                    summaryRow(
                      "LuckyEta Fee",
                      "\$${fee.toStringAsFixed(2)}",
                    ),

                    const Divider(),

                    summaryRow(
                      "Creator Profit",
                      "\$${creatorProfit.toStringAsFixed(2)}",
                      bold: true,
                    ),

                  ],

                ),

              ),

            ),

            const SizedBox(height: 35),

            SizedBox(

              width: double.infinity,

              height: 58,

              child: ElevatedButton.icon(
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.green,
    foregroundColor: Colors.white,
    minimumSize: const Size(double.infinity, 60),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
    ),
  ),

                onPressed: launchLottery,

                icon: const Icon(Icons.rocket_launch),

                label: const Text(

                  "Launch Lottery",

                  style: TextStyle(
                    fontSize: 18,
                  ),

                ),

              ),

            ),

            const SizedBox(height: 40),

          ],

        ),

      ),

    );

  }

  Widget summaryRow(
    String title,
    String value, {
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontWeight:
                    bold ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight:
                  bold ? FontWeight.bold : FontWeight.w700,
              fontSize: bold ? 18 : 16,
            ),
          ),
        ],
      ),
    );
  }
}