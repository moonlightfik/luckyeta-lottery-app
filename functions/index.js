const {setGlobalOptions} = require("firebase-functions");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");

admin.initializeApp();

const db = admin.firestore();

setGlobalOptions({
  maxInstances: 10,
});


// RUNS EVERY MINUTE AND CHECKS FOR DRAWABLE LOTTERIES

exports.drawLotteries = onSchedule(
  "every 1 minutes",
  async () => {

    const now = admin.firestore.Timestamp.now();


    const lotteriesSnapshot =
      await db
        .collection("lotteries")
        .where("status", "==", "ACTIVE")
        .where("nextDrawAt", "<=", now)
        .get();



    if (lotteriesSnapshot.empty) {
      console.log("No lotteries ready for drawing");
      return;
    }



    for (const lotteryDoc of lotteriesSnapshot.docs) {


      const lottery =
          lotteryDoc.data();



      const lotteryId =
          lotteryDoc.id;



      console.log(
        "Drawing lottery:",
        lotteryId
      );



      const winnersNeeded =
          lottery.numberOfWinners || 1;



      // GET ALL TICKETS

      const ticketsSnapshot =
          await db
            .collectionGroup("tickets")
            .where(
              "lotteryID",
              "==",
              lotteryId
            )
            .where(
              "status",
              "==",
              "ACTIVE"
            )
            .get();



      if (ticketsSnapshot.empty) {

        console.log(
          "No tickets found"
        );

        continue;
      }



      let tickets = [];



      ticketsSnapshot.forEach((doc)=>{

        tickets.push({

          id: doc.id,

          ref: doc.ref,

          userId:
            doc.data().userId,

          ticketNumber:
            doc.data().ticketNumber,

        });

      });



      // SHUFFLE RANDOMLY

      tickets.sort(
        () => Math.random() - 0.5
      );



      let winners = [];

      let usedUsers = new Set();



      for (const ticket of tickets) {


        // ONE WIN PER USER

        if(
          usedUsers.has(
            ticket.userId
          )
        ){

          continue;

        }



        winners.push(ticket);


        usedUsers.add(
          ticket.userId
        );



        if(
          winners.length >= winnersNeeded
        ){

          break;

        }

      }



      if(
        winners.length === 0
      ){

        continue;

      }



      const batch =
          db.batch();



      let winnerIds = [];



      // UPDATE WINNERS

      for(
        const winner of winners
      ){

        batch.update(
          winner.ref,
          {

            status:"WON",

            wonAt:
              admin.firestore.FieldValue.serverTimestamp()

          }
        );


        winnerIds.push(
          winner.userId
        );

      }



      // UPDATE LOSERS

      for(
        const ticket of tickets
      ){

        if(
          !winnerIds.includes(
            ticket.userId
          )
        ){

          batch.update(
            ticket.ref,
            {
              status:"LOST"
            }
          );

        }

      }



      // UPDATE LOTTERY

      batch.update(

        db.collection("lotteries")
          .doc(lotteryId),

        {

          status:"DRAWN",

          winnerIds:

            winnerIds,


          drawCompletedAt:

            admin.firestore.FieldValue.serverTimestamp()

        }

      );



      await batch.commit();



      console.log(
        "Lottery completed:",
        lotteryId
      );

    }

  }
);