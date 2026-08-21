require("dotenv").config();

const {setGlobalOptions} = require("firebase-functions");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");
const { drawLottery } = require("./drawLottery");
const { onCall } = require("firebase-functions/v2/https");
const { onRequest } = require("firebase-functions/v2/https");

const {
  processSuccessfulPayment,
} = require("./verifyPayment");

const {
  initializeChapaPayment,
} = require("./chapaPayment");
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
exports.initializePayment = onCall(async (request) => {
  try {
    // Make sure the user is authenticated
    if (!request.auth) {
      throw new Error("You must be logged in to make a payment.");
    }

    const userId = request.auth.uid;

    const {
      amount,
      email,
      firstName,
      lastName,
      lotteryId,
      ticketCount,
    } = request.data;

    if (
      !amount ||
      !email ||
      !lotteryId ||
      !ticketCount
    ) {
      throw new Error(
        "Missing required payment information."
      );
    }

    // Get the lottery
    const lotteryRef = db
      .collection("lotteries")
      .doc(lotteryId);

    const lotterySnapshot =
      await lotteryRef.get();

    if (!lotterySnapshot.exists) {
      throw new Error("Lottery not found.");
    }

    const lottery =
      lotterySnapshot.data();

    // Calculate the price on the SERVER.
    // Do NOT trust the amount sent by Flutter.
    const pricePerTicket =
      Number(lottery.pricePerTicket);

    const totalAmount =
      pricePerTicket * Number(ticketCount);

    // Create a unique Chapa transaction reference
    const txRef =
      `LUCKYETA-${lotteryId}-${userId}-${Date.now()}`;

    // Save pending payment
    await db
      .collection("payments")
      .doc(txRef)
      .set({
        txRef,
        userId,
        lotteryId,
        ticketCount: Number(ticketCount),
        amount: totalAmount,
        status: "PENDING",
        provider: "CHAPA",
        createdAt:
          admin.firestore.FieldValue.serverTimestamp(),
      });

    // Ask Chapa to initialize payment
    const chapaResponse =
      await initializeChapaPayment({
        amount: totalAmount,
        email,
        firstName: firstName || "LuckyEta",
        lastName: lastName || "User",
        txRef,

        callbackUrl:
          "YOUR_CALLBACK_URL",

        returnUrl:
          "YOUR_RETURN_URL",
      });

    console.log(
      "Chapa payment initialized:",
      txRef
    );

    return {
      success: true,
      txRef,
      checkoutUrl:
        chapaResponse?.data?.checkout_url,
    };
  } catch (error) {
    console.error(
      "Payment initialization failed:",
      error.message
    );

    throw new Error(
      error.message ||
        "Unable to initialize payment."
    );
  }
});
exports.chapaCallback = onRequest(
  async (req, res) => {
    try {
      console.log(
        "Chapa callback received:",
        req.body
      );

      const txRef =
        req.body?.tx_ref ||
        req.query?.tx_ref;

      if (!txRef) {
        res.status(400).json({
          success: false,
          message: "Missing transaction reference.",
        });
        return;
      }

      await processSuccessfulPayment(txRef);

      res.status(200).json({
        success: true,
        message: "Payment processed successfully.",
      });
    } catch (error) {
      console.error(
        "Chapa callback failed:",
        error
      );

      res.status(500).json({
        success: false,
        message:
          error.message ||
          "Payment processing failed.",
      });
    }
  }
);