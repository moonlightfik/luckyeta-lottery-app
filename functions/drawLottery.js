const admin = require("firebase-admin");

const db = admin.firestore();

async function drawLottery(lotteryId) {
  const lotteryRef = db.collection("lotteries").doc(lotteryId);

  const lotterySnapshot = await lotteryRef.get();

  if (!lotterySnapshot.exists) {
    throw new Error("Lottery does not exist.");
  }

  const lottery = lotterySnapshot.data();

  if (lottery.status !== "ACTIVE") {
    return;
  }

  const winnersNeeded = lottery.numberOfWinners || 1;

  const ticketsSnapshot = await db
    .collectionGroup("tickets")
    .where("lotteryID", "==", lotteryId)
    .where("status", "==", "ACTIVE")
    .get();

  if (ticketsSnapshot.empty) {
    console.log("No tickets found.");

    return;
  }

  let tickets = [];

  ticketsSnapshot.forEach((doc) => {
    tickets.push({
      id: doc.id,
      ref: doc.ref,
      userId: doc.data().userId,
      ticketNumber: doc.data().ticketNumber,
    });
  });

  shuffle(tickets);

  let winners = [];

  const usedUsers = new Set();

  for (const ticket of tickets) {
    if (usedUsers.has(ticket.userId)) {
      continue;
    }

    winners.push(ticket);

    usedUsers.add(ticket.userId);

    if (winners.length >= winnersNeeded) {
      break;
    }
  }

  if (winners.length === 0) {
    return;
  }

  const batch = db.batch();

  const winnerIds = [];

  const winningTicketIds = [];

  const winningNumbers = [];

  for (const winner of winners) {
    batch.update(winner.ref, {
      status: "WON",
      wonAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    winnerIds.push(winner.userId);

    winningTicketIds.push(winner.id);

    winningNumbers.push(winner.ticketNumber);
  }

  for (const ticket of tickets) {
    if (!winningTicketIds.includes(ticket.id)) {
      batch.update(ticket.ref, {
        status: "LOST",
      });
    }
  }

  await batch.commit();

  return {
    lottery,
    lotteryRef,
    winnerIds,
    winningNumbers,
  };
}

function shuffle(array) {
  for (let i = array.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));

    [array[i], array[j]] = [array[j], array[i]];
  }
}

module.exports = {
  drawLottery,
};