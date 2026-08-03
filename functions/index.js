const {setGlobalOptions} = require("firebase-functions");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");
const { drawLottery } = require("./drawLottery");
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

      console.log("No lotteries ready.");

      return;

    }

    for (const lotteryDoc of lotteriesSnapshot.docs) {

      try {

        console.log(
          "Drawing:",
          lotteryDoc.id,
        );

        await drawLottery(
          lotteryDoc.id,
        );

      } catch (e) {

        console.error(
          "Draw failed:",
          lotteryDoc.id,
          e,
        );

      }

    }

  }
);