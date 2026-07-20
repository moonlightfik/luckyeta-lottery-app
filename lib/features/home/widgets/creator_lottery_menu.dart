import 'package:flutter/material.dart';

class CreatorLotteryMenu extends StatelessWidget {

  final VoidCallback onEdit;
  final VoidCallback onDelete;


  const CreatorLotteryMenu({
    super.key,
    required this.onEdit,
    required this.onDelete,
  });


  @override
  Widget build(BuildContext context) {

    return PopupMenuButton<String>(

      icon: const Icon(
        Icons.more_vert,
        color: Colors.black,
      ),


      onSelected: (value){

        if(value == "edit"){
          onEdit();
        }

        if(value == "delete"){
          onDelete();
        }

      },


      itemBuilder: (context){

        return [

          const PopupMenuItem(
            value: "edit",
            child: Row(
              children:[
                Icon(Icons.edit),
                SizedBox(width:10),
                Text("Edit Lottery"),
              ],
            ),
          ),


          const PopupMenuItem(
            value:"delete",
            child: Row(
              children:[
                Icon(
                  Icons.delete,
                  color:Colors.red,
                ),
                SizedBox(width:10),
                Text("Delete Lottery"),
              ],
            ),
          ),

        ];

      },

    );

  }

}