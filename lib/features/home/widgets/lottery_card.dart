import 'dart:async';

import 'package:flutter/material.dart';

import '../../../models/lottery_model.dart';


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

  Duration remaining = Duration.zero;


  @override
  void initState() {
    super.initState();

    updateCountdown();

    timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        updateCountdown();
      },
    );
  }



  void updateCountdown() {

    final difference =
        widget.lottery.nextDrawAt
            .difference(DateTime.now());


    if(mounted){

      setState(() {

        remaining =
            difference.isNegative
                ? Duration.zero
                : difference;

      });

    }

  }



  @override
  void dispose(){

    timer?.cancel();

    super.dispose();

  }



  String formatTime(){

    String two(int n)=>
        n.toString().padLeft(2,'0');


    return
      "${two(remaining.inHours)}:"
      "${two(remaining.inMinutes.remainder(60))}:"
      "${two(remaining.inSeconds.remainder(60))}";
  }



  @override
  Widget build(BuildContext context){


    final lottery = widget.lottery;


    return Card(

      elevation: 5,

      margin:
          const EdgeInsets.symmetric(
              horizontal:16,
              vertical:10),

      shape:
          RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(22),
          ),


      child: Column(

        crossAxisAlignment:
            CrossAxisAlignment.start,


        children:[


          // IMAGE AREA

          Container(

            height:180,

            decoration: BoxDecoration(

              borderRadius:
                  const BorderRadius.vertical(
                    top: Radius.circular(22),
                  ),


              image:
                lottery.imageUrl != null
                ?
                DecorationImage(

                  image:
                    NetworkImage(
                      lottery.imageUrl!,
                    ),

                  fit: BoxFit.cover,

                )

                : null,


              color:
                  Color(lottery.themeColor),

            ),



            child:
              Stack(

                children:[


                  Positioned(

                    top:15,

                    left:15,

                    child: Container(

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


                      child: Text(

                        lottery.status ==
                            "SOLD_OUT"

                        ?

                        "🎟 SOLD OUT"

                        :

                        "⏱ ${formatTime()}",


                        style:
                            const TextStyle(
                              color:Colors.white,
                              fontWeight:
                                  FontWeight.bold,
                            ),

                      ),

                    ),

                  ),



                  Positioned(

                    top:15,

                    right:15,

                    child: Container(

                      padding:
                          const EdgeInsets.all(8),

                      decoration:
                          const BoxDecoration(

                            color:
                                Colors.black54,

                            shape:
                                BoxShape.circle,

                          ),


                      child:
                          const Icon(
                            Icons.person,
                            color:Colors.white,
                          ),

                    ),

                  ),


                ],

              ),

          ),



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

                      fontSize:22,

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

                      "🏆 ${lottery.numberOfWinners} Winners",

                    ),


                  ],

                ),



                const SizedBox(height:15),



                LinearProgressIndicator(

                  value:
                    lottery.progress.clamp(0,1),


                  minHeight:8,


                ),



                const SizedBox(height:8),



                Text(

                  "${lottery.ticketsSold}/${lottery.totalTickets} Tickets Sold",

                ),



                const SizedBox(height:15),



                if(lottery.status=="SOLD_OUT")

                  Container(

                    width:
                        double.infinity,

                    padding:
                        const EdgeInsets.all(12),


                    decoration:
                        BoxDecoration(

                          borderRadius:
                            BorderRadius.circular(14),

                          color:
                            Colors.red.shade50,

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

                  )


               else

Column(

  crossAxisAlignment:
      CrossAxisAlignment.start,

  children: [

    const SizedBox(height:10),


    Row(

      mainAxisAlignment:
          MainAxisAlignment.spaceBetween,

      children: [

        Text(
          "🎟 \$${lottery.pricePerTicket} / ticket",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),


        Text(
          "🏆 ${lottery.numberOfWinners} Winners",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

      ],

    ),


    const SizedBox(height:10),


    Row(

      children: [

        const Icon(
          Icons.schedule,
          size:18,
        ),

        const SizedBox(width:5),


        Text(
          lottery.drawFrequency,
        ),

      ],

    ),


    const SizedBox(height:10),


    Row(

      children:[

        const Icon(
          Icons.confirmation_num,
          size:18,
        ),

        const SizedBox(width:5),


        Text(
          "${lottery.ticketsSold}/${lottery.totalTickets} Tickets Sold",
        ),

      ],

    ),

  ],

)

              ],

            ),

          )

        ],

      ),

    );

  }

}