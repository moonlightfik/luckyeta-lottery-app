import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/lottery_model.dart';
import 'widgets/explore_lottery_card.dart';

class ExploreScreen extends StatefulWidget {
  final VoidCallback? onProfileTap; // ← Added this callback
  
  const ExploreScreen({super.key, this.onProfileTap});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController searchController = TextEditingController();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;
  
  String searchText = "";
  String selectedType = "All";
  String selectedCategory = "All";
  List<String> categories = ["All"];
  
  String? _profileImageUrl;
  bool _isLoadingImage = false;

  @override
  void initState() {
    super.initState();
    loadCategories();
    _loadProfileImage();

    searchController.addListener(() {
      setState(() {
        searchText = searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  //==============================
  // LOAD PROFILE IMAGE
  //==============================
  Future<void> _loadProfileImage() async {
    final user = auth.currentUser;
    if (user == null) return;

    setState(() => _isLoadingImage = true);

    try {
      final doc = await firestore
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (doc.exists && doc.data()?['profileImageUrl'] != null) {
        setState(() {
          _profileImageUrl = doc.data()?['profileImageUrl'];
        });
      }
    } catch (e) {
      print('Error loading profile image: $e');
    }

    setState(() => _isLoadingImage = false);
  }

  //==============================
  // LOAD CATEGORIES
  //==============================
  Future<void> loadCategories() async {
    final snapshot = await firestore
        .collection("lotteries")
        .where("isPublic", isEqualTo: true)
        .get();

    final Set<String> unique = {"All"};

    for (final doc in snapshot.docs) {
      final category = doc["category"];
      if (category != null && category.toString().isNotEmpty) {
        unique.add(category);
      }
    }

    setState(() {
      categories = unique.toList();
    });
  }

  //==============================
  // FILTER METHODS
  //==============================
  bool matchesType(Lottery lottery, String type) {
    if (type == "All") return true;
    if (type == "One Time") return lottery.lotteryType == "oneTime";
    if (type == "Daily") return lottery.drawFrequency == "Daily";
    if (type == "Weekly") return lottery.drawFrequency == "Weekly";
    return true;
  }

  bool matchesCategory(Lottery lottery, String category) {
    if (category == "All") return true;
    return lottery.category == category;
  }

  bool matchesSearch(Lottery lottery, String text) {
    if (text.isEmpty) return true;
    return lottery.title.toLowerCase().contains(text) ||
        lottery.creatorName.toLowerCase().contains(text) ||
        lottery.category.toLowerCase().contains(text) ||
        lottery.description.toLowerCase().contains(text);
  }

  //==============================
  // LOTTERIES STREAM
  //==============================
  Stream<List<Lottery>> get lotteries {
    return firestore
        .collection("lotteries")
        .where("isPublic", isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Lottery.fromFirestore(doc.id, doc.data());
      }).toList();
    });
  }

  //==============================
  // BUILD
  //==============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      body: SafeArea(
        child: Column(
          children: [
            //==========================
            // HEADER
            //==========================
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Explore",
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Find lotteries waiting for you",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  //==========================
                  // AVATAR - Navigates to Profile using Callback
                  //==========================
                  GestureDetector(
                    onTap: widget.onProfileTap, // ← Use callback instead of Navigator.push
                    child: _profileImageUrl != null
                        ? CircleAvatar(
                            radius: 24,
                            backgroundImage: NetworkImage(_profileImageUrl!),
                            backgroundColor: Colors.transparent,
                            onBackgroundImageError: (_, __) {
                              setState(() {
                                _profileImageUrl = null;
                              });
                            },
                          )
                        : Container(
                            width: 48,
                            height: 48,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.transparent,
                            ),
                            child: _isLoadingImage
                                ? const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.green,
                                  )
                                : Icon(
                                    Icons.person_outline,
                                    size: 32,
                                    color: Colors.grey.shade400,
                                  ),
                          ),
                  ),
                ],
              ),
            ),

            //==========================
            // SEARCH BAR
            //==========================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: "Search lotteries...",
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            //==========================
            // LOTTERY TYPE FILTER
            //==========================
            SizedBox(
              height: 45,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  "All",
                  "One Time",
                  "Daily",
                  "Weekly",
                ].map(
                  (type) {
                    final selected = selectedType == type;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: ChoiceChip(
                        label: Text(type),
                        selected: selected,
                        selectedColor: Colors.green,
                        labelStyle: TextStyle(
                          color: selected ? Colors.white : Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                        onSelected: (_) {
                          setState(() {
                            selectedType = type;
                          });
                        },
                      ),
                    );
                  },
                ).toList(),
              ),
            ),

            const SizedBox(height: 18),

            //==========================
            // CATEGORY FILTER
            //==========================
            SizedBox(
              height: 45,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final selected = selectedCategory == category;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: selected,
                      selectedColor: Colors.green,
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : Colors.black,
                      ),
                      onSelected: (_) {
                        setState(() {
                          selectedCategory = category;
                        });
                      },
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 15),

            //==========================
            // LOTTERY LIST
            //==========================
            Expanded(
              child: StreamBuilder<List<Lottery>>(
                stream: lotteries,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text("No lotteries found."),
                    );
                  }

                  List<Lottery> filtered = snapshot.data!
                      .where(
                        (lottery) =>
                            matchesSearch(lottery, searchText) &&
                            matchesType(lottery, selectedType) &&
                            matchesCategory(lottery, selectedCategory),
                      )
                      .toList();

                  if (filtered.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 70,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 15),
                          Text(
                            "No matching lotteries found.",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: filtered.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: .60,
                    ),
                    itemBuilder: (context, index) {
                      final lottery = filtered[index];
                      return ExploreLotteryCard(
                        lottery: lottery,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}