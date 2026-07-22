import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../models/lottery_model.dart';

import 'card_style_selector.dart';
import 'category_selector.dart';
import 'cover_image_picker.dart';
import 'theme_selector.dart';



enum LotteryFormMode {

  create,

  edit,

}




class LotteryForm extends StatefulWidget {


  final LotteryFormMode mode;


  final Lottery? lottery;



  const LotteryForm({

    super.key,

    required this.mode,

    this.lottery,

  });



  @override
  State<LotteryForm> createState() =>
      _LotteryFormState();

}





class _LotteryFormState
    extends State<LotteryForm> {



  //------------------------------------
  // CONTROLLERS
  //------------------------------------


  final titleController =
      TextEditingController();


  final descriptionController =
      TextEditingController();


  final jackpotController =
      TextEditingController();



  final totalTicketsController =
      TextEditingController();



  final maxTicketsController =
      TextEditingController();




  //------------------------------------
  // IMAGE
  //------------------------------------


  File? coverImage;



  String? imageUrl;





  //------------------------------------
  // THEME
  //------------------------------------


  Color selectedTheme =
      const Color(0xff16A34A);





  //------------------------------------
  // STYLE
  //------------------------------------


  String selectedStyle =
      "Modern";





  //------------------------------------
  // CATEGORY
  //------------------------------------


  String selectedCategory =
      "Cash";





  //------------------------------------
  // TICKETS
  //------------------------------------


  double pricePerTicket =
      5;



  int totalTickets =
      100;



  int maxTicketsPerUser =
      5;



  bool limitPerUser =
      true;





  //------------------------------------
  // WINNERS
  //------------------------------------


  int numberOfWinners =
      1;






  //------------------------------------
  // TYPE
  //------------------------------------


  String lotteryType =
      "oneTime";



  String drawFrequency =
      "Daily";



  DateTime nextDrawAt =
      DateTime.now();






  //------------------------------------
  // VISIBILITY
  //------------------------------------


  bool isPublic =
      true;






  //------------------------------------
  // GETTERS
  //------------------------------------


  bool get editing =>

      widget.mode ==
      LotteryFormMode.edit;





  bool get hasSoldTickets {


    if(!editing) {

      return false;

    }


    return widget.lottery!.ticketsSold > 0;


  }






  // When tickets are sold:
  // lock jackpot, price,
  // category, total tickets,
  // lottery type, winners


  bool get canEditPrizeFields =>

      !hasSoldTickets;





  //------------------------------------
  // INIT
  //------------------------------------


  @override
  void initState(){

    super.initState();


    if(editing){

      loadLottery();

    }

    else{


      totalTicketsController.text =
          "100";


      maxTicketsController.text =
          "5";


      calculateNextDraw();


    }


  }







  //------------------------------------
  // LOAD EXISTING LOTTERY
  //------------------------------------


  void loadLottery(){


    final lottery =
        widget.lottery!;




    titleController.text =
        lottery.title;



    descriptionController.text =
        lottery.description;



    jackpotController.text =
        lottery.jackpot
            .toString();



    totalTicketsController.text =
        lottery.totalTickets
            .toString();



    maxTicketsController.text =
        lottery.maxTicketsPerUser
            .toString();




    pricePerTicket =
        lottery.pricePerTicket;



    totalTickets =
        lottery.totalTickets;



    maxTicketsPerUser =
        lottery.maxTicketsPerUser;



    selectedCategory =
        lottery.category;



    selectedStyle =
        lottery.cardStyle;



    selectedTheme =
        Color(lottery.themeColor);



    imageUrl =
        lottery.imageUrl;



    numberOfWinners =
        lottery.numberOfWinners;



    lotteryType =
        lottery.lotteryType;



    drawFrequency =
        lottery.drawFrequency;



    nextDrawAt =
        lottery.nextDrawAt;



    isPublic =
        lottery.isPublic;



  }






  //------------------------------------
  // DRAW CALCULATION
  //------------------------------------


  void calculateNextDraw(){


    final now =
        DateTime.now();



    if(lotteryType=="oneTime"){


      nextDrawAt =
          now.add(
            const Duration(days:1),
          );


    }

    else{


      switch(drawFrequency){


        case "Hourly":

          nextDrawAt =
              now.add(
                const Duration(hours:1),
              );

          break;



        case "Daily":

          nextDrawAt =
              DateTime(
                now.year,
                now.month,
                now.day + 1,
                20,
              );

          break;



        case "Weekly":

          nextDrawAt =
              now.add(
                const Duration(days:7),
              );

          break;



      }


    }



    setState((){});


  }
    //------------------------------------
  // CALCULATIONS
  //------------------------------------


  double get jackpot =>

      double.tryParse(
        jackpotController.text,
      ) ?? 0;




  double get revenue =>

      pricePerTicket *
      totalTickets;




  double get fee =>

      revenue *
      0.02;




  double get creatorProfit =>

      revenue -
      jackpot -
      fee;






  //------------------------------------
  // CREATE LOTTERY
  //------------------------------------


  Future<void> launchLottery() async {


    final user =
        FirebaseAuth.instance.currentUser;


    if(user == null) return;




    await FirebaseFirestore.instance
        .collection("lotteries")
        .add({



      "title":
          titleController.text.trim(),



      "description":
          descriptionController.text.trim(),



      "jackpot":
          jackpot,



      "pricePerTicket":
          pricePerTicket,



      "totalTickets":
          totalTickets,



      "ticketsSold":
          0,



      "remainingTickets":
          totalTickets,



      "maxTicketsPerUser":
          maxTicketsPerUser,



      "numberOfWinners":
          numberOfWinners,



      "winnerIds":
          [],



      "lotteryType":
          lotteryType,



      "drawFrequency":
          lotteryType == "oneTime"
              ? null
              : drawFrequency,



      "nextDrawAt":
          Timestamp.fromDate(
            nextDrawAt,
          ),



      "category":
          selectedCategory,



      "cardStyle":
          selectedStyle,



      "themeColor":
          selectedTheme.value,



      "imageUrl":
          imageUrl,



      "isPublic":
          isPublic,



      "status":
          "ACTIVE",



      "creatorId":
          user.uid,



      "creatorName":
          user.displayName ??
          "LuckyEta User",



      "createdAt":
          FieldValue.serverTimestamp(),



    });




    if(!mounted) return;



    Navigator.pop(context);


  }







  //------------------------------------
  // UPDATE LOTTERY
  //------------------------------------

Future<void> updateLottery() async {

  if (widget.lottery == null) return;

  final id = widget.lottery!.id;

  await FirebaseFirestore.instance
      .collection("lotteries")
      .doc(id)
      .update({

    // ALWAYS EDITABLE
    "title": titleController.text.trim(),

    "description": descriptionController.text.trim(),

    "cardStyle": selectedStyle,

    "themeColor": selectedTheme.value,

    "imageUrl": imageUrl,

    "isPublic": isPublic,

    // ⭐ ALSO ALWAYS EDITABLE
    "drawFrequency":
        lotteryType == "oneTime"
            ? null
            : drawFrequency,

    "nextDrawAt":
        Timestamp.fromDate(nextDrawAt),

    // ONLY IF NO TICKETS HAVE BEEN SOLD
    if (canEditPrizeFields) ...{

      "jackpot": jackpot,

      "pricePerTicket": pricePerTicket,

      "totalTickets": totalTickets,

      "maxTicketsPerUser": maxTicketsPerUser,

      "category": selectedCategory,

      "numberOfWinners": numberOfWinners,

      "lotteryType": lotteryType,

    }

  });

  if (!mounted) return;

  Navigator.pop(context);
}
 








  //------------------------------------
  // BUILD
  //------------------------------------


  @override
  Widget build(BuildContext context){


    return SingleChildScrollView(

      padding:
          const EdgeInsets.all(20),


      child: Column(

        crossAxisAlignment:
            CrossAxisAlignment.start,


        children:[



          //--------------------------------
          // IMAGE
          //--------------------------------


          CoverImagePicker(

            onImageSelected:(file){


              setState((){

                coverImage =
                    file;


              });


            },


          ),




          const SizedBox(height:24),






          //--------------------------------
          // THEME
          //--------------------------------


          ThemeSelector(

            selectedColor:
                selectedTheme,


            onChanged:(color){


              setState((){


                selectedTheme =
                    color;


              });


            },


          ),





          const SizedBox(height:24),






          //--------------------------------
          // STYLE
          //--------------------------------


          CardStyleSelector(

            selectedStyle:
                selectedStyle,


            onChanged:(style){


              setState((){


                selectedStyle =
                    style;


              });


            },


          ),





          const SizedBox(height:24),






          //--------------------------------
          // CATEGORY
          //--------------------------------


         

           

            CategorySelector(

              selectedCategory:
                  selectedCategory,


              onChanged:(category){


                setState((){


                  selectedCategory =
                      category;


                });


              },


            ),


          




          const SizedBox(height:30),






          const Text(

            "Lottery Details",

            style:TextStyle(

              fontSize:20,

              fontWeight:
                  FontWeight.bold,

            ),

          ),






          const SizedBox(height:18),




          TextField(

            controller:
                titleController,


            decoration:
                InputDecoration(

                  labelText:
                      "Lottery Name",


                  border:
                      OutlineInputBorder(

                        borderRadius:
                            BorderRadius.circular(16),

                      ),

                ),


          ),





          const SizedBox(height:18),





          TextField(

            controller:
                descriptionController,


            maxLines:4,


            decoration:
                InputDecoration(

                  labelText:
                      "Description",


                  border:
                      OutlineInputBorder(

                        borderRadius:
                            BorderRadius.circular(16),

                      ),


                ),


          ),





          const SizedBox(height:18),






          TextField(

            controller:
                jackpotController,


            enabled:
                canEditPrizeFields,


            keyboardType:
                TextInputType.number,


            decoration:
                InputDecoration(

                  labelText:
                      "Jackpot Prize",


                  prefixText:
                      "\$ ",


                  border:
                      OutlineInputBorder(

                        borderRadius:
                            BorderRadius.circular(16),

                      ),


                ),


          ),
                    const SizedBox(height:30),


          //--------------------------------
          // TICKET PRICE
          //--------------------------------


          const Text(

            "Ticket Price",

            style:TextStyle(

              fontSize:20,

              fontWeight:
                  FontWeight.bold,

            ),

          ),



          const SizedBox(height:15),




          Card(

            shape:
                RoundedRectangleBorder(

                  borderRadius:
                      BorderRadius.circular(18),

                ),


            child:

            Padding(

              padding:
                  const EdgeInsets.all(18),


              child:Column(

                children:[



                  Text(

                    "\$${pricePerTicket.toStringAsFixed(0)}",

                    style:
                        const TextStyle(

                          fontSize:32,

                          fontWeight:
                              FontWeight.bold,

                          color:
                              Colors.green,

                        ),

                  ),





                  Slider(

                    value:
                        pricePerTicket,


                    min:
                        1,


                    max:
                        100,


                    divisions:
                        99,


                    activeColor:
                        Colors.green,



                    onChanged:

                    canEditPrizeFields

                    ? (value){


                        setState((){


                          pricePerTicket =
                              value;


                        });


                      }

                    : null,



                  ),



                ],

              ),

            ),

          ),






          const SizedBox(height:30),






          //--------------------------------
          // TICKET SETTINGS
          //--------------------------------


          const Text(

            "Ticket Settings",

            style:
                TextStyle(

                  fontSize:20,

                  fontWeight:
                      FontWeight.bold,

                ),

          ),




          const SizedBox(height:15),




          TextField(

            controller:
                totalTicketsController,


            enabled:
                canEditPrizeFields,


            keyboardType:
                TextInputType.number,



            decoration:
                InputDecoration(

                  labelText:
                      "Total Tickets",


                  border:
                      OutlineInputBorder(

                        borderRadius:
                            BorderRadius.circular(16),

                      ),

                ),



            onChanged:(value){


              setState((){


                totalTickets =
                    int.tryParse(value)
                    ?? 100;


              });


            },


          ),






          const SizedBox(height:15),






          SwitchListTile(

            value:
                limitPerUser,


            activeColor:
                Colors.green,



            title:
                const Text(
                  "Limit tickets per user",
                ),



            onChanged:

            canEditPrizeFields

            ? (value){


                setState((){


                  limitPerUser =
                      value;


                });


              }

            : null,



          ),






          if(limitPerUser)

          Padding(

            padding:
                const EdgeInsets.only(
                  top:10,
                ),


            child:

            TextField(

              controller:
                  maxTicketsController,


              enabled:
                  canEditPrizeFields,



              keyboardType:
                  TextInputType.number,



              decoration:
                  InputDecoration(

                    labelText:
                        "Maximum Per User",


                    border:
                        OutlineInputBorder(

                          borderRadius:
                              BorderRadius.circular(16),

                        ),

                  ),



              onChanged:(value){


                setState((){


                  maxTicketsPerUser =
                      int.tryParse(value)
                      ?? 5;



                });


              },

            ),

          ),







          const SizedBox(height:30),






          //--------------------------------
          // WINNERS
          //--------------------------------



          const Text(

            "Number of Winners",

            style:
                TextStyle(

                  fontSize:20,

                  fontWeight:
                      FontWeight.bold,

                ),

          ),





          const SizedBox(height:15),





          Card(

            child:

            Row(

              children:[



                IconButton(

                  onPressed:

                  canEditPrizeFields

                  ? (){


                      if(numberOfWinners > 1){


                        setState((){


                          numberOfWinners--;


                        });


                      }


                    }

                  : null,



                  icon:
                      const Icon(
                        Icons.remove_circle,
                      ),

                ),





                Expanded(

                  child:

                  Center(

                    child:

                    Text(

                      "$numberOfWinners Winner${numberOfWinners == 1 ? "" : "s"}",


                      style:
                          const TextStyle(

                            fontSize:18,

                            fontWeight:
                                FontWeight.bold,

                          ),


                    ),

                  ),

                ),






                IconButton(

                  onPressed:

                  canEditPrizeFields

                  ? (){


                      setState((){


                        numberOfWinners++;


                      });


                    }

                  : null,



                  icon:
                      const Icon(
                        Icons.add_circle,
                      ),


                ),



              ],


            ),

          ),






          const SizedBox(height:30),






          //--------------------------------
          // LOTTERY TYPE
          //--------------------------------



          const Text(

            "Lottery Type",

            style:
                TextStyle(

                  fontSize:20,

                  fontWeight:
                      FontWeight.bold,

                ),

          ),





          const SizedBox(height:15),





         

            SegmentedButton<String>(


              segments:

              const [



                ButtonSegment(

                  value:
                      "oneTime",

                  label:
                      Text(
                        "One Time",
                      ),

                ),



                ButtonSegment(

                  value:
                      "Daily",

                  label:
                      Text(
                        "Daily",
                      ),

                ),



                ButtonSegment(

                  value:
                      "Weekly",

                  label:
                      Text(
                        "Weekly",
                      ),

                ),



              ],



              selected:{


                lotteryType == "oneTime"

                ? "oneTime"

                : drawFrequency,


              },



              onSelectionChanged:(value){



                setState((){



                  if(value.first=="oneTime"){


                    lotteryType =
                        "oneTime";


                  }

                  else{


                    lotteryType =
                        "recurring";


                    drawFrequency =
                        value.first;



                  }



                  calculateNextDraw();



                });


              },


            ),

         
                    const SizedBox(height:30),






          //--------------------------------
          // DRAW DATE
          //--------------------------------


          if(lotteryType == "oneTime")

          Card(

            child:

            ListTile(

              leading:
                  const Icon(
                    Icons.calendar_today,
                  ),



              title:

                  Text(

                    "${nextDrawAt.day}/"
                    "${nextDrawAt.month}/"
                    "${nextDrawAt.year}",

                  ),



              subtitle:

                  const Text(
                    "Tap to choose draw date",
                  ),




              trailing:

                  const Icon(
                    Icons.edit,
                  ),



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


          ),







          const SizedBox(height:30),






          //--------------------------------
          // VISIBILITY
          //--------------------------------


          const Text(

            "Visibility",

            style:

                TextStyle(

                  fontSize:20,

                  fontWeight:
                      FontWeight.bold,

                ),

          ),





          const SizedBox(height:15),






          Row(

            children:[



              Expanded(

                child:

                GestureDetector(

                  onTap:


                  (){


                    setState((){


                      isPublic =
                          true;


                    });


                  },


                  child:

                  AnimatedContainer(

                    duration:

                        const Duration(
                          milliseconds:250,
                        ),



                    padding:

                        const EdgeInsets.all(20),




                    decoration:

                        BoxDecoration(

                          color:

                              isPublic

                              ? Colors.green.shade50

                              : Colors.white,



                          borderRadius:

                              BorderRadius.circular(18),




                          border:

                              Border.all(

                                color:

                                    isPublic

                                    ? Colors.green

                                    : Colors.grey.shade300,

                                width:2,

                              ),



                        ),




                    child:

                    const Column(

                      children:[



                        Icon(
                          Icons.public,
                        ),



                        SizedBox(height:10),




                        Text(
                          "Public",
                          style:
                              TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                              ),
                        ),



                      ],


                    ),



                  ),



                ),


              ),






              const SizedBox(width:15),






              Expanded(

                child:

                GestureDetector(

                  onTap:


                  (){


                    setState((){


                      isPublic =
                          false;


                    });


                  },



                  child:

                  AnimatedContainer(

                    duration:

                        const Duration(
                          milliseconds:250,
                        ),



                    padding:

                        const EdgeInsets.all(20),




                    decoration:

                        BoxDecoration(

                          color:

                              !isPublic

                              ? Colors.green.shade50

                              : Colors.white,



                          borderRadius:

                              BorderRadius.circular(18),




                          border:

                              Border.all(

                                color:

                                    !isPublic

                                    ? Colors.green

                                    : Colors.grey.shade300,

                                width:2,

                              ),



                        ),




                    child:

                    const Column(

                      children:[



                        Icon(
                          Icons.lock,
                        ),



                        SizedBox(height:10),




                        Text(
                          "Private",
                          style:
                              TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                              ),
                        ),



                      ],


                    ),



                  ),



                ),


              ),



            ],

          ),







          const SizedBox(height:35),







          //--------------------------------
          // SUMMARY
          //--------------------------------



          Card(

            shape:

                RoundedRectangleBorder(

                  borderRadius:
                      BorderRadius.circular(20),

                ),




            child:

            Padding(

              padding:
                  const EdgeInsets.all(20),



              child:

              Column(

                children:[



                  const Text(

                    "Summary",

                    style:

                        TextStyle(

                          fontSize:22,

                          fontWeight:
                              FontWeight.bold,

                        ),

                  ),




                  const Divider(
                    height:30,
                  ),





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

                    bold:true,

                  ),



                ],


              ),


            ),


          ),







          const SizedBox(height:35),







          //--------------------------------
          // SAVE BUTTON
          //--------------------------------



          SizedBox(

            width:
                double.infinity,


            height:
                58,



            child:

            ElevatedButton.icon(


              style:

                  ElevatedButton.styleFrom(

                    backgroundColor:
                        Colors.green,


                    foregroundColor:
                        Colors.white,



                    shape:

                        RoundedRectangleBorder(

                          borderRadius:
                              BorderRadius.circular(18),

                        ),



                  ),




              onPressed:


              editing

              ? updateLottery

              : launchLottery,





              icon:

                  Icon(

                    editing

                    ? Icons.save

                    : Icons.rocket_launch,

                  ),





              label:

                  Text(

                    editing

                    ? "Save Changes"

                    : "Launch Lottery",



                    style:

                        const TextStyle(

                          fontSize:18,

                        ),

                  ),



            ),



          ),




          const SizedBox(height:40),
                    ],

        ),

    
      );

  }

 //------------------------------------
  // SUMMARY ROW
  //------------------------------------


  Widget summaryRow(

    String title,

    String value, {

    bool bold = false,

  }) {



    return Padding(

      padding:

          const EdgeInsets.symmetric(

            vertical:8,

          ),



      child:

      Row(

        children:[



          Expanded(

            child:

            Text(

              title,

              style:

                  TextStyle(

                    fontWeight:

                        bold

                        ? FontWeight.bold

                        : FontWeight.w500,

                  ),

            ),

          ),




          Text(

            value,


            style:

                TextStyle(

                  fontSize:

                      bold ? 18 : 16,



                  fontWeight:

                      bold

                      ? FontWeight.bold

                      : FontWeight.w700,

                ),


          ),



        ],


      ),


    );


  }









  //------------------------------------
  // DISPOSE
  //------------------------------------


  @override
  void dispose(){


    titleController.dispose();


    descriptionController.dispose();


    jackpotController.dispose();


    totalTicketsController.dispose();


    maxTicketsController.dispose();



    super.dispose();


  }





}