import 'package:flutter/material.dart';

import '../../models/lottery_model.dart';
import 'widgets/lottery_form.dart';


class EditLotteryScreen extends StatelessWidget {

  final Lottery lottery;


  const EditLotteryScreen({
    super.key,
    required this.lottery,
  });



  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text(
          "Edit Lottery",
        ),
      ),


      body: LotteryForm(
        mode: LotteryFormMode.edit,
        lottery: lottery,
      ),

    );

  }

}