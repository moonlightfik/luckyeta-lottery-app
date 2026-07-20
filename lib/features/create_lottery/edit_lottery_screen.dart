import 'package:flutter/material.dart';
import '../../models/lottery_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class EditLotteryScreen extends StatefulWidget {

  final Lottery lottery;


  const EditLotteryScreen({
    super.key,
    required this.lottery,
  });


  @override
  State<EditLotteryScreen> createState() =>
      _EditLotteryScreenState();

}



class _EditLotteryScreenState extends State<EditLotteryScreen> {


  late TextEditingController titleController;
  late TextEditingController descriptionController;
  late TextEditingController jackpotController;
  late TextEditingController priceController;


  bool get canEditMoney =>
      widget.lottery.ticketsSold == 0;



  @override
  void initState(){

    super.initState();


    titleController =
        TextEditingController(
          text: widget.lottery.title,
        );


    descriptionController =
        TextEditingController(
          text: widget.lottery.description,
        );


    jackpotController =
        TextEditingController(
          text: widget.lottery.jackpot.toString(),
        );


    priceController =
        TextEditingController(
          text: widget.lottery.pricePerTicket.toString(),
        );

  }



  Future<void> saveChanges() async {


    await FirebaseFirestore.instance
        .collection("lotteries")
        .doc(widget.lottery.id)
        .update({

      "title":
          titleController.text.trim(),


      "description":
          descriptionController.text.trim(),


      if(canEditMoney)
        "jackpot":
            int.parse(jackpotController.text),


      if(canEditMoney)
        "pricePerTicket":
            int.parse(priceController.text),


    });



    if(mounted){

      Navigator.pop(context);

    }

  }





  @override
  Widget build(BuildContext context){


    return Scaffold(

      appBar: AppBar(
        title:
          const Text("Edit Lottery"),
      ),


      body: Padding(

        padding:
            const EdgeInsets.all(16),


        child: ListView(

          children:[


            TextField(

              controller:titleController,

              decoration:
                const InputDecoration(
                  labelText:"Title",
                ),

            ),



            TextField(

              controller:descriptionController,

              decoration:
                const InputDecoration(
                  labelText:"Description",
                ),

            ),



            TextField(

              controller:jackpotController,

              enabled:
                  canEditMoney,

              decoration:
                const InputDecoration(
                  labelText:"Jackpot",
                ),

            ),



            TextField(

              controller:priceController,

              enabled:
                  canEditMoney,

              decoration:
                const InputDecoration(
                  labelText:"Ticket Price",
                ),

            ),



            const SizedBox(height:20),



            ElevatedButton(

              onPressed:
                  saveChanges,


              child:
                const Text(
                  "Save Changes",
                ),

            )


          ],

        ),

      ),

    );

  }

}