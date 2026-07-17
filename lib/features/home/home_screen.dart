import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'widgets/lottery_card.dart';

import '../../navigation/bottom_nav_screen.dart';
import '../buy_ticket/buy_ticket_screen.dart';
import '../create_lottery/create_lottery.dart';
import '../../models/lottery_model.dart';


class HomeScreen extends StatefulWidget {

  const HomeScreen({
    super.key,
  });


  @override
  State<HomeScreen> createState() =>
      _HomeScreenState();

}



class _HomeScreenState extends State<HomeScreen> {


  final user =
      FirebaseAuth.instance.currentUser;


  late String username;



  @override
  void initState() {

    super.initState();

    username =
        user?.displayName ?? "Player";

  }



  @override
  Widget build(BuildContext context) {

    return Scaffold(

      body: SafeArea(

        child: SingleChildScrollView(

          padding:
              const EdgeInsets.all(16),


          child: Column(

            crossAxisAlignment:
                CrossAxisAlignment.start,


            children: [


              // HEADER

              Row(

                children: [


                  GestureDetector(

                    onTap: () {

                      Navigator.push(

                        context,

                        MaterialPageRoute(

                          builder: (_) =>
                              const BottomNavScreen(
                                initialIndex: 3,
                              ),

                        ),

                      );

                    },


                    child: const CircleAvatar(

                      radius: 25,

                      backgroundImage:
                          AssetImage(
                            "assets/avatar.png",
                          ),

                    ),

                  ),



                  const SizedBox(width:12),



                  Column(

                    crossAxisAlignment:
                        CrossAxisAlignment.start,


                    children:[


                      const Text(

                        "WELCOME BACK",

                        style:
                            TextStyle(

                              fontSize:12,

                              color:
                                  Colors.grey,

                            ),

                      ),



                      Text(

                        "Good Luck, $username!",

                        style:
                            const TextStyle(

                              fontSize:18,

                              fontWeight:
                                  FontWeight.bold,

                            ),

                      ),


                    ],

                  ),


                ],

              ),



              const SizedBox(height:24),



              // ACTION BUTTONS

              Row(

                children:[


                  Expanded(

                    child:
                    ElevatedButton.icon(

                      onPressed:(){

                        Navigator.push(

                          context,

                          MaterialPageRoute(

                            builder:(_)=>
                                const CreateLotteryScreen(),

                          ),

                        );

                      },


                      icon:
                          const Icon(Icons.add),


                      label:
                          const Text(
                            "Create Lottery",
                          ),


                      style:
                          ElevatedButton.styleFrom(

                            backgroundColor:
                                Colors.green,

                            foregroundColor:
                                Colors.white,

                            padding:
                                const EdgeInsets.symmetric(
                                  vertical:14,
                                ),

                            shape:
                                RoundedRectangleBorder(

                                  borderRadius:
                                      BorderRadius.circular(12),

                                ),

                          ),

                    ),

                  ),



                  const SizedBox(width:12),



                  Expanded(

                    child:
                    OutlinedButton.icon(

                      onPressed:(){

                        Navigator.push(

                          context,

                          MaterialPageRoute(

                            builder:(_)=>
                                const BottomNavScreen(
                                  initialIndex:1,
                                ),

                          ),

                        );

                      },


                      icon:
                          const Icon(
                            Icons.confirmation_num,
                            color:Colors.green,
                          ),


                      label:
                          const Text(

                            "Buy Tickets",

                            style:
                                TextStyle(
                                  color:Colors.green,
                                ),

                          ),

                    ),

                  ),


                ],

              ),



              const SizedBox(height:24),
                            // FEATURED JACKPOTS

              Row(

                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,

                children: [

                  const Text(

                    "Featured Jackpots",

                    style:
                        TextStyle(

                          fontSize:18,

                          fontWeight:
                              FontWeight.bold,

                        ),

                  ),


                  TextButton(

                    onPressed:(){

                      Navigator.push(

                        context,

                        MaterialPageRoute(

                          builder:(_)=>
                              const BottomNavScreen(
                                initialIndex:1,
                              ),

                        ),

                      );

                    },

                    child:
                        const Text(

                          "View All",

                          style:
                              TextStyle(
                                color:Colors.green,
                              ),

                        ),

                  ),

                ],

              ),



              const SizedBox(height:12),



              SizedBox(

                height:430,

                child:
                StreamBuilder<QuerySnapshot>(

                  stream:
                      FirebaseFirestore.instance
                          .collection("lotteries")
                          .where(
                            "isPublic",
                            isEqualTo:true,
                          )
                          .where(
                            "status",
                            isEqualTo:"ACTIVE",
                          )
                          .orderBy(
                            "createdAt",
                            descending:true,
                          )
                          .snapshots(),


                  builder:(context,snapshot){


                    if(snapshot.connectionState ==
                        ConnectionState.waiting){

                      return const Center(

                        child:
                            CircularProgressIndicator(),

                      );

                    }



                    if(!snapshot.hasData ||
                       snapshot.data!.docs.isEmpty){

                      return const Center(

                        child:
                            Text(
                              "No lotteries available",
                            ),

                      );

                    }



                    final lotteries =
                        snapshot.data!.docs;



                    return ListView.builder(

                      scrollDirection:
                          Axis.horizontal,


                      itemCount:
                          lotteries.length,


                      itemBuilder:(context,index){


                        final doc =
                            lotteries[index];



                        final lottery =
                            Lottery.fromFirestore(

                              doc.id,

                              doc.data()
                                  as Map<String,dynamic>,

                            );



                        return SizedBox(

                          width:300,

                          child:
                          GestureDetector(

                            onTap:(){

                              Navigator.push(

                                context,

                                MaterialPageRoute(

                                  builder:(_)=>
                                      BuyTicketScreen(
                                        lottery:lottery,
                                      ),

                                ),

                              );

                            },


                            child:
                            LotteryCard(

                              lottery:lottery,

                            ),

                          ),

                        );

                      },

                    );

                  },

                ),

              ),



              const SizedBox(height:30),



              // MY LUCK SECTION PLACEHOLDER

              const Text(

                "My Luck",

                style:
                    TextStyle(

                      fontSize:20,

                      fontWeight:
                          FontWeight.bold,

                    ),

              ),



              const SizedBox(height:12),



              Container(

                width:
                    double.infinity,


                padding:
                    const EdgeInsets.all(20),


                decoration:
                    BoxDecoration(

                      borderRadius:
                          BorderRadius.circular(20),

                      color:
                          Colors.grey.shade100,

                    ),


                child:
                    const Column(

                      children:[


                        Text(
                          "🎟 Running",
                        ),


                        SizedBox(height:12),


                        Text(
                          "🏆 Won",
                        ),


                        SizedBox(height:12),


                        Text(
                          "❌ Lost",
                        ),


                      ],

                    ),

              ),


            ],

          ),

        ),

      ),

    );

  }

}