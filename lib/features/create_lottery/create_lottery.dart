import 'package:flutter/material.dart';

import 'widgets/lottery_form.dart';



class CreateLotteryScreen extends StatelessWidget {

  const CreateLotteryScreen({
    super.key,
  });



  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor:
          const Color(0xffF7F8FA),



      appBar: AppBar(

        backgroundColor:
            Colors.white,


        elevation:
            0,


        centerTitle:
            true,


        title:

            const Text(

              "Create Lottery",

              style:

                  TextStyle(

                    color:
                        Colors.black,


                    fontWeight:
                        FontWeight.bold,

                  ),

            ),

      ),



      body:

          const LotteryForm(

            mode:
                LotteryFormMode.create,

          ),


    );

  }

}