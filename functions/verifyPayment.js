const axios = require("axios");
const admin = require("firebase-admin");

const db = admin.firestore();

const CHAPA_SECRET_KEY = process.env.CHAPA_SECRET_KEY;

async function verifyChapaPayment(txRef) {
  if (!CHAPA_SECRET_KEY) {
    throw new Error("CHAPA_SECRET_KEY is missing.");
  }

  const response = await axios.get(
    `https://api.chapa.co/v1/transaction/verify/${txRef}`,
    {
      headers: {
        Authorization: `Bearer ${CHAPA_SECRET_KEY}`,
      },
    }
  );

  return response.data;
}

async function processSuccessfulPayment(txRef) {
  const paymentRef = db.collection("payments").doc(txRef);

  const paymentSnapshot = await paymentRef.get();

  if (!paymentSnapshot.exists) {
    throw new Error("Payment record not found.");
  }

  const payment = paymentSnapshot.data();

  // Prevent processing the same payment twice.
  if (payment.status === "SUCCESS") {
    console.log("Payment already processed:", txRef);
    return;
  }

  const chapaResult = await verifyChapaPayment(txRef);

  console.log(
    "Chapa verification result:",
    JSON.stringify(chapaResult)
  );

  const chapaStatus =
    chapaResult?.data?.status;

  if (chapaStatus !== "success") {
    await paymentRef.update({
      status: "FAILED",
      verifiedAt:
        admin.firestore.FieldValue.serverTimestamp(),
    });

    throw new Error("Chapa payment was not successful.");
  }

  const {
    userId,
    lotteryId,
    ticketCount,
    amount,
  } = payment;

  const lotteryRef =
    db.collection("lotteries").doc(lotteryId);

  const lotterySnapshot =
    await lotteryRef.get();

  if (!lotterySnapshot.exists) {
    throw new Error("Lottery not found.");
  }

  const lottery = lotterySnapshot.data();

  const pricePerTicket =
    Number(lottery.pricePerTicket);

  const expectedAmount =
    pricePerTicket * Number(ticketCount);

  // IMPORTANT: verify the amount ourselves.
  if (Number(amount) !== expectedAmount) {
    throw new Error("Payment amount mismatch.");
  }

  const ticketsSold =
    Number(lottery.ticketsSold || 0);

  const totalTickets =
    Number(lottery.totalTickets || 0);

  const requestedTickets =
    Number(ticketCount);

  if (
    ticketsSold + requestedTickets >
    totalTickets
  ) {
    throw new Error("Not enough tickets available.");
  }

  const batch = db.batch();

  // Create tickets.
  for (let i = 0; i < requestedTickets; i++) {
    const ticketRef = db
      .collection("users")
      .doc(userId)
      .collection("tickets")
      .doc();

    const ticketNumber =
      ticketsSold + i + 1;

    batch.set(ticketRef, {
      ticketId: ticketRef.id,
      lotteryID: lotteryId,
      lotteryTitle: lottery.title,
      userId,
      ticketNumber,
      pricePerTicket,
      status: "ACTIVE",
      purchasedAt:
        admin.firestore.FieldValue.serverTimestamp(),
      paymentTxRef: txRef,
    });
  }

  // Update lottery counters.
  batch.update(lotteryRef, {
    ticketsSold:
      ticketsSold + requestedTickets,

    remainingTickets:
      totalTickets -
      (ticketsSold + requestedTickets),
  });

  // Mark payment successful.
  batch.update(paymentRef, {
    status: "SUCCESS",
    verifiedAt:
      admin.firestore.FieldValue.serverTimestamp(),
  });

  await batch.commit();

  console.log(
    `Payment ${txRef} processed successfully.`
  );
}

module.exports = {
  verifyChapaPayment,
  processSuccessfulPayment,
};