import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../models/lottery_model.dart';

import 'creator_lottery_menu.dart';
import '../../create_lottery/edit_lottery_screen.dart';



class LotteryCard extends StatefulWidget {

  final Lottery lottery;


  const LotteryCard({

    super.key,

    required this.lottery,

  });



  @override
  State<LotteryCard> createState() =>
      _LotteryCardState();

}





class _LotteryCardState extends State<LotteryCard> {


  Timer? timer;


  Duration remaining =
      Duration.zero;




  @override
  void initState(){

    super.initState();


    updateCountdown();


    timer =
        Timer.periodic(

          const Duration(seconds:1),

          (_) {

            updateCountdown();

          },

        );

  }






  void updateCountdown(){


    final difference =
        widget.lottery.nextDrawAt
            .difference(
              DateTime.now(),
            );



    if(mounted){


      setState((){


        if(difference.isNegative){


          resetRecurringLottery();


          remaining =
              Duration.zero;


        }

        else{


          remaining =
              difference;


        }


      });


    }


  }







  Future<void> resetRecurringLottery() async {


    final lottery =
        widget.lottery;



    if(lottery.drawFrequency != "Daily" &&
       lottery.drawFrequency != "Weekly"){


      return;


    }




    DateTime newDrawTime;



    if(lottery.drawFrequency == "Daily"){


      newDrawTime =

          lottery.nextDrawAt.add(

            const Duration(
              days:1,
            ),

          );


    }

    else{


      newDrawTime =

          lottery.nextDrawAt.add(

            const Duration(
              days:7,
            ),

          );


    }





    await FirebaseFirestore.instance

        .collection("lotteries")

        .doc(lottery.id)

        .update({



          "nextDrawAt":

              Timestamp.fromDate(
                newDrawTime,
              ),




          "ticketsSold":
              0,




          "remainingTickets":

              lottery.totalTickets,




          "status":
              "ACTIVE",


        });


  }






  @override
  void dispose(){

    timer?.cancel();

    super.dispose();

  }







  String formatTime(){


    String two(int n)=>

        n.toString()
        .padLeft(2,'0');



    return

      "${two(remaining.inHours)}:"

      "${two(remaining.inMinutes.remainder(60))}:"

      "${two(remaining.inSeconds.remainder(60))}";


  }
    @override
  Widget build(BuildContext context){


    final lottery =
        widget.lottery;



    return Card(

      elevation:5,


      margin:

          const EdgeInsets.symmetric(

            horizontal:16,

            vertical:10,

          ),



      shape:

          RoundedRectangleBorder(

            borderRadius:

                BorderRadius.circular(22),

          ),



      child:

      Column(

        crossAxisAlignment:

            CrossAxisAlignment.start,



        children:[





          // ================= IMAGE =================


          Container(

            height:180,



            decoration:

                BoxDecoration(



              borderRadius:

                  const BorderRadius.vertical(

                    top:

                        Radius.circular(22),

                  ),




              image:

              lottery.imageUrl != null


              ?


              DecorationImage(

                image:

                    NetworkImage(

                      lottery.imageUrl!,

                    ),


                fit:

                    BoxFit.cover,


              )


              : null,




              color:

                  Color(

                    lottery.themeColor,

                  ),



            ),





            child:

            Stack(

              children:[





                // COUNTDOWN


                Positioned(

                  top:15,

                  left:15,


                  child:

                  Container(

                    padding:

                        const EdgeInsets.symmetric(

                          horizontal:12,

                          vertical:6,

                        ),



                    decoration:

                        BoxDecoration(

                          color:

                              Colors.black54,


                          borderRadius:

                              BorderRadius.circular(20),

                        ),



                    child:

                    Text(


                      lottery.status == "SOLD_OUT"


                      ?

                      "🎟 SOLD OUT"


                      :

                      "⏱ ${formatTime()}",




                      style:

                          const TextStyle(

                            color:

                                Colors.white,


                            fontWeight:

                                FontWeight.bold,

                          ),


                    ),


                  ),


                ),








                // CATEGORY BADGE


                Positioned(

                  top:15,

                  right:15,


                  child:

                  Container(


                    padding:

                        const EdgeInsets.symmetric(

                          horizontal:12,

                          vertical:6,

                        ),



                    decoration:

                        BoxDecoration(

                          color:

                              Colors.black54,


                          borderRadius:

                              BorderRadius.circular(20),

                        ),




                    child:

                    Text(


                      "🎁 ${lottery.category}",



                      style:

                          const TextStyle(

                            color:

                                Colors.white,


                            fontWeight:

                                FontWeight.bold,

                          ),


                    ),



                  ),


                ),







                // CREATOR MENU


                Positioned(

                  bottom:15,

                  right:15,


                  child:



                  FirebaseAuth.instance.currentUser?.uid ==

                      lottery.creatorId




                  ?



                  CreatorLotteryMenu(


                    onEdit:(){


                      Navigator.push(

                        context,


                        MaterialPageRoute(

                          builder:(_)=>

                              EditLotteryScreen(

                                lottery:

                                    lottery,

                              ),

                        ),


                      );


                    },




                    onDelete:(){


                      showDialog(

                        context:context,


                        builder:(context){


                          return AlertDialog(

                            title:

                                const Text(

                                  "Delete Lottery?"

                                ),




                            content:


                            lottery.ticketsSold > 0


                            ?


                            const Text(

                              "Tickets have already been purchased. You cannot delete this lottery."

                            )



                            :



                            const Text(

                              "Are you sure you want to delete this lottery?"

                            ),





                            actions:[



                              TextButton(

                                onPressed:(){

                                  Navigator.pop(context);

                                },


                                child:

                                    const Text(

                                      "Cancel"

                                    ),


                              ),





                              if(lottery.ticketsSold == 0)



                              TextButton(

                                onPressed:() async {



                                  await FirebaseFirestore.instance

                                      .collection("lotteries")

                                      .doc(lottery.id)

                                      .delete();



                                  Navigator.pop(context);


                                },



                                child:

                                    const Text(

                                      "Delete",


                                      style:

                                          TextStyle(

                                            color:

                                                Colors.red,

                                          ),

                                    ),


                              ),



                            ],


                          );


                        },

                      );


                    },



                  )



                  :

                  const SizedBox(),



                ),




              ],

            ),



          ),







          // ================= DETAILS =================


          Padding(

            padding:

                const EdgeInsets.all(16),



            child:

            Column(

              crossAxisAlignment:

                  CrossAxisAlignment.start,



              children:[





                Text(

                  lottery.title,


                  style:

                      const TextStyle(

                        fontSize:18,


                        fontWeight:

                            FontWeight.bold,

                      ),


                ),





                const SizedBox(height:8),






                Text(

                  "👤 ${lottery.creatorName}",


                  style:

                      TextStyle(

                        color:

                            Colors.grey.shade700,

                        fontWeight:

                            FontWeight.w500,

                      ),


                ),






                const SizedBox(height:10),






                Text(

                  lottery.description,


                  maxLines:2,


                  overflow:

                      TextOverflow.ellipsis,



                  style:

                      TextStyle(

                        color:

                            Colors.grey.shade700,

                      ),


                ),






                const SizedBox(height:15),





                Row(

                  mainAxisAlignment:

                      MainAxisAlignment.spaceBetween,



                  children:[



                    Text(

                      "\$${lottery.jackpot}",



                      style:

                          const TextStyle(

                            fontSize:24,


                            fontWeight:

                                FontWeight.bold,

                          ),


                    ),




                    Text(

                      "🎟 \$${lottery.pricePerTicket}/ticket",


                      style:

                          const TextStyle(

                            fontWeight:

                                FontWeight.bold,

                          ),


                    ),



                  ],


                ),






                const SizedBox(height:15),





                LinearProgressIndicator(


                  value:

                      lottery.progress.clamp(0,1),



                  minHeight:

                      8,



                  borderRadius:

                      BorderRadius.circular(10),




                  backgroundColor:

                      Colors.grey.shade300,




                  valueColor:

                      AlwaysStoppedAnimation<Color>(

                        Color(

                          lottery.themeColor,

                        ),

                      ),



                ),





                const SizedBox(height:8),





                Text(

                  "${lottery.ticketsSold}/${lottery.totalTickets} Tickets Sold",


                  style:

                      TextStyle(

                        color:

                            Colors.grey.shade700,

                        fontWeight:

                            FontWeight.w500,

                      ),


                ),






                const SizedBox(height:15),
                                // ================= DRAW INFO =================


                Row(

                  mainAxisAlignment:

                      MainAxisAlignment.spaceBetween,



                  children:[





                    Row(

                      children:[



                        const Icon(

                          Icons.schedule,

                          size:18,

                        ),



                        const SizedBox(width:5),




                        Text(


                          lottery.lotteryType == "oneTime"

                          ?

                          "One Time"


                          :

                          lottery.drawFrequency,



                          style:

                              const TextStyle(

                                fontWeight:

                                    FontWeight.bold,

                              ),


                        ),



                      ],

                    ),








                    Row(

                      children:[



                        const Icon(

                          Icons.emoji_events,

                          size:18,

                        ),




                        const SizedBox(width:5),





                        Text(


                          "${lottery.numberOfWinners} Winner${lottery.numberOfWinners > 1 ? "s" : ""}",



                          style:

                              const TextStyle(

                                fontWeight:

                                    FontWeight.bold,

                              ),


                        ),



                      ],

                    ),




                  ],

                ),







                const SizedBox(height:15),








                // ================= SOLD OUT =================


                if(lottery.status == "SOLD_OUT")



                  Container(


                    width:

                        double.infinity,




                    padding:

                        const EdgeInsets.all(12),




                    decoration:

                        BoxDecoration(


                          color:

                              Colors.red.shade50,



                          borderRadius:

                              BorderRadius.circular(14),



                        ),





                    child:


                    const Center(



                      child:


                      Text(



                        "🎟 SOLD OUT\nTry Next Time",




                        textAlign:

                            TextAlign.center,




                        style:

                            TextStyle(



                              color:

                                  Colors.red,



                              fontWeight:

                                  FontWeight.bold,



                            ),




                      ),




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