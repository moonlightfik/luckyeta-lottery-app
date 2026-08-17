import { db } from "../config/firebase";

/**
 * ============================================================
 * NOTIFICATION HELPER
 * ============================================================
 *
 * Creates a notification inside:
 *
 * users/{userId}/notifications
 *
 * This matches the structure used by the Flutter
 * AppNotification model.
 */
async function createNotification({
  userId,
  title,
  message,
  type,
  lotteryId,
  action,
  extraData,
}: {
  userId: string;
  title: string;
  message: string;
  type: string;
  lotteryId: string;
  action?: string;
  extraData?: Record<string, any>;
}) {
  await db
    .collection("users")
    .doc(userId)
    .collection("notifications")
    .add({
      title,
      message,
      type,
      lotteryId,
      action: action ?? null,
      isRead: false,
      createdAt: new Date(),
      extraData: extraData ?? {},
    });
}

/**
 * ============================================================
 * GET ALL LOTTERIES
 * ============================================================
 */
export async function getAllLotteries() {
  const snapshot = await db
    .collection("lotteries")
    .get();

  return snapshot.docs.map((doc) => ({
    id: doc.id,
    ...doc.data(),
  }));
}

/**
 * ============================================================
 * GET SINGLE LOTTERY
 * ============================================================
 */
export async function getLotteryById(id: string) {
  const doc = await db
    .collection("lotteries")
    .doc(id)
    .get();

  if (!doc.exists) {
    return null;
  }

  return {
    id: doc.id,
    ...doc.data(),
  };
}

/**
 * ============================================================
 * GET EXPIRED LOTTERIES
 * ============================================================
 *
 * Finds lotteries that:
 *
 * - are DRAWING
 * - have reached their nextDrawAt time
 */
export async function getExpiredLotteries() {
  const now = new Date();

  const snapshot = await db
    .collection("lotteries")
    .where("status", "==", "DRAWING")
    .where("nextDrawAt", "<=", now)
    .get();

  return snapshot.docs.map((doc) => ({
    id: doc.id,
    ...doc.data(),
  }));
}

/**
 * ============================================================
 * START DUE LOTTERIES
 * ============================================================
 *
 * Moves:
 *
 * ACTIVE → DRAWING
 *
 * This does NOT select winners.
 */
export async function startDueLotteries() {
  const now = new Date();

  const snapshot = await db
    .collection("lotteries")
    .where("status", "==", "ACTIVE")
    .where("nextDrawAt", "<=", now)
    .get();

  const results = [];

  for (const doc of snapshot.docs) {
    const lottery = doc.data();

    await doc.ref.update({
      status: "DRAWING",
      drawingStartedAt: now,
    });

    console.log(
      `Lottery "${lottery.title}" (${doc.id}) changed ACTIVE → DRAWING`,
    );

    results.push({
      lotteryId: doc.id,
      title: lottery.title,
      status: "DRAWING",
    });
  }

  return results;
}

/**
 * ============================================================
 * PROCESS ONE LOTTERY
 * ============================================================
 *
 * This function:
 *
 * 1. Gets the lottery.
 * 2. Finds all ACTIVE tickets.
 * 3. Selects random winner(s).
 * 4. Saves winning ticket numbers.
 * 5. Saves winner user IDs.
 * 6. Changes lottery → COMPLETED.
 * 7. Changes winning tickets → WON.
 * 8. Changes losing tickets → LOST.
 * 9. Sends winner notifications.
 * 10. Sends loser notifications.
 * 11. Sends creator draw-completed notification.
 */
export async function processLottery(lotteryId: string) {
  const lotteryRef = db
    .collection("lotteries")
    .doc(lotteryId);

  const lotterySnapshot =
    await lotteryRef.get();

  if (!lotterySnapshot.exists) {
    throw new Error("Lottery not found");
  }

  const lottery =
    lotterySnapshot.data();

  if (!lottery) {
    throw new Error("Lottery data is missing");
  }

  /**
   * Prevent duplicate draws.
   */
  if (
    lottery.status !== "ACTIVE" &&
    lottery.status !== "DRAWING"
  ) {
    return {
      success: false,
      message: "Lottery has already been processed",
    };
  }

  /**
   * ==========================================================
   * GET ALL USERS
   * ==========================================================
   */
  const usersSnapshot =
    await db.collection("users").get();

  const allTickets: Array<{
    ticketId: string;
    ticketNumber: number;
    userId: string;
  }> = [];

  /**
   * ==========================================================
   * FIND ALL TICKETS FOR THIS LOTTERY
   * ==========================================================
   */
  for (const userDoc of usersSnapshot.docs) {
    const ticketsSnapshot =
      await userDoc.ref
        .collection("tickets")
        .where(
          "lotteryID",
          "==",
          lotteryId,
        )
        .where(
          "status",
          "==",
          "ACTIVE",
        )
        .get();

    for (const ticketDoc of ticketsSnapshot.docs) {
      const ticketData =
        ticketDoc.data();

      if (
        ticketData.ticketNumber == null
      ) {
        continue;
      }

      allTickets.push({
        ticketId: ticketDoc.id,
        ticketNumber: Number(
          ticketData.ticketNumber,
        ),
        userId: userDoc.id,
      });
    }
  }

  /**
   * ==========================================================
   * NO TICKETS
   * ==========================================================
   */
  if (allTickets.length === 0) {
    const drawnAt = new Date();

    await lotteryRef.update({
      status: "COMPLETED",
      winnerIds: [],
      winningTicketNumbers: [],
      drawnAt,
      resultMessage:
        "Lottery completed. No tickets were purchased.",
    });

    /**
     * Notify creator even when nobody participated.
     */
    if (lottery.creatorId) {
      await createNotification({
        userId: lottery.creatorId,
        title: "🏁 Draw Completed",
        message:
          `The draw for "${lottery.title}" has finished, ` +
          `but no tickets were purchased.`,
        type: "draw_complete",
        lotteryId,
        action: "view_lottery",
        extraData: {
          winnersCount: 0,
          totalParticipants: 0,
          winnerIds: [],
          winningNumbers: [],
          creatorName:
            lottery.creatorName ?? "Creator",
        },
      });
    }

    return {
      success: true,
      lotteryId,
      lotteryTitle: lottery.title,
      jackpot: lottery.jackpot,
      winnerCount: 0,
      winnerIds: [],
      winningTicketNumbers: [],
      drawnAt,
      resultMessage:
        "Lottery completed. No tickets were purchased.",
    };
  }

  /**
   * ==========================================================
   * NUMBER OF WINNERS
   * ==========================================================
   */
  const requestedWinners =
    Number(lottery.numberOfWinners) || 1;

  const winnerCount = Math.min(
    requestedWinners,
    allTickets.length,
  );

  /**
   * ==========================================================
   * FISHER-YATES SHUFFLE
   * ==========================================================
   */
  const shuffledTickets =
    [...allTickets];

  for (
    let i = shuffledTickets.length - 1;
    i > 0;
    i--
  ) {
    const j = Math.floor(
      Math.random() * (i + 1),
    );

    [
      shuffledTickets[i],
      shuffledTickets[j],
    ] = [
      shuffledTickets[j],
      shuffledTickets[i],
    ];
  }

  /**
   * ==========================================================
   * SELECT WINNERS
   * ==========================================================
   */
  const winners =
    shuffledTickets.slice(
      0,
      winnerCount,
    );

  const winnerIds =
    winners.map(
      (winner) => winner.userId,
    );

  const winningTicketNumbers =
    winners.map(
      (winner) =>
        winner.ticketNumber,
    );

  const drawnAt = new Date();

  const resultMessage =
    winnerCount === 1
      ? "Lottery completed. A winner has been selected!"
      : `${winnerCount} winners have been selected!`;

  /**
   * ==========================================================
   * SAVE LOTTERY RESULT
   * ==========================================================
   */
  await lotteryRef.update({
    status: "COMPLETED",
    winnerIds,
    winningTicketNumbers,
    drawnAt,
    resultMessage,
  });

  /**
   * ==========================================================
   * UPDATE EVERY TICKET
   * ==========================================================
   */
  for (const ticket of allTickets) {
    const ticketRef =
      db
        .collection("users")
        .doc(ticket.userId)
        .collection("tickets")
        .doc(ticket.ticketId);

    const isWinner =
      winners.some(
        (winner) =>
          winner.ticketId ===
          ticket.ticketId,
      );

    /**
     * Update ticket status.
     */
    await ticketRef.update({
      status: isWinner
        ? "WON"
        : "LOST",

      result: isWinner
        ? "WINNER"
        : "NOT_WINNER",

      drawnAt,
    });

    /**
     * ========================================================
     * WINNER NOTIFICATION
     * ========================================================
     */
    if (isWinner) {
      await createNotification({
        userId: ticket.userId,

        title:
          "🎉 Congratulations!",

        message:
          `You won "${lottery.title}" ` +
          `with ticket #${ticket.ticketNumber}! ` +
          `Tap here to claim your prize.`,

        type: "winner",

        lotteryId,

        action: "claim_prize",

        extraData: {
          ticketNumber:
            ticket.ticketNumber,

          lotteryTitle:
            lottery.title,

          jackpot:
            lottery.jackpot,
        },
      });
    }

    /**
     * ========================================================
     * LOSER NOTIFICATION
     * ========================================================
     */
    else {
      await createNotification({
        userId: ticket.userId,

        title:
          "🍀 Better Luck Next Time",

        message:
          `The draw for "${lottery.title}" ` +
          `has ended. Your ticket #${ticket.ticketNumber} ` +
          `wasn't selected this time.`,

        type: "loser",

        lotteryId,

        action: "buy_again",

        extraData: {
          ticketNumber:
            ticket.ticketNumber,

          lotteryTitle:
            lottery.title,
        },
      });
    }
  }

  /**
   * ==========================================================
   * CREATOR DRAW COMPLETED NOTIFICATION
   * ==========================================================
   */
  if (lottery.creatorId) {
    await createNotification({
      userId:
        lottery.creatorId,

      title:
        "🏆 Draw Completed!",

      message:
        `The draw for "${lottery.title}" ` +
        `has finished!\n\n` +
        `🎯 ${winnerCount} winner(s) ` +
        `selected from ${allTickets.length} ` +
        `participants.\n\n` +
        `Tap to view the winners.`,

      type:
        "draw_complete",

      lotteryId,

      action:
        "view_winners",

      extraData: {
        winnersCount:
          winnerCount,

        totalParticipants:
          allTickets.length,

        winnerIds,

        winningNumbers:
          winningTicketNumbers,

        creatorName:
          lottery.creatorName ??
          "Creator",
      },
    });
  }

  /**
   * ==========================================================
   * RETURN DRAW RESULT
   * ==========================================================
   */
  return {
    success: true,

    lotteryId,

    lotteryTitle:
      lottery.title,

    jackpot:
      lottery.jackpot,

    winnerCount,

    winnerIds,

    winningTicketNumbers,

    drawnAt,

    resultMessage,
  };
}

/**
 * ============================================================
 * PROCESS ALL EXPIRED LOTTERIES
 * ============================================================
 */
export async function processExpiredLotteries() {
  const expiredLotteries =
    await getExpiredLotteries();

  const results = [];

  for (
    const lottery
    of expiredLotteries
  ) {
    try {
      const result =
        await processLottery(
          lottery.id,
        );

      results.push(result);
    } catch (error) {
      console.error(
        `Failed to process lottery ${lottery.id}:`,
        error,
      );
    }
  }

  return results;
}

/**
 * ============================================================
 * GET HOME LOTTERIES
 * ============================================================
 *
 * Home visibility rules:
 *
 * 1. Public ACTIVE lotteries
 *    → visible to everyone.
 *
 * 2. Public DRAWING lotteries
 *    → visible to everyone.
 *
 * 3. User-created lotteries
 *    → visible to creator, including COMPLETED.
 *
 * 4. Purchased lotteries
 *    → visible to buyer.
 *
 * 5. COMPLETED lotteries
 *    → remain visible for 30 days after draw
 *      if public or purchased.
 */
export async function getHomeLotteries(
  userId: string,
) {
  const now = new Date();

  const thirtyDaysAgo =
    new Date(
      now.getTime() -
        30 *
          24 *
          60 *
          60 *
          1000,
    );

  const snapshot =
    await db
      .collection("lotteries")
      .get();

  const lotteries = [];

  for (
    const doc of snapshot.docs
  ) {
    const lottery =
      doc.data();

    const isPublic =
      lottery.isPublic === true;

    const isCreator =
      lottery.creatorId ===
      userId;

    /**
     * Check whether this user purchased
     * a ticket.
     */
    const ticketsSnapshot =
      await db
        .collection("users")
        .doc(userId)
        .collection("tickets")
        .where(
          "lotteryID",
          "==",
          doc.id,
        )
        .limit(1)
        .get();

    const hasPurchasedTicket =
      !ticketsSnapshot.empty;

    /**
     * ========================================================
     * PUBLIC ACTIVE / DRAWING
     * ========================================================
     */
    if (
      isPublic &&
      (
        lottery.status ===
          "ACTIVE" ||
        lottery.status ===
          "DRAWING"
      )
    ) {
      lotteries.push({
        id: doc.id,
        ...lottery,
      });

      continue;
    }

    /**
     * ========================================================
     * CREATOR'S LOTTERY
     * ========================================================
     */
    if (isCreator) {
      lotteries.push({
        id: doc.id,
        ...lottery,
      });

      continue;
    }

    /**
     * ========================================================
     * PURCHASED LOTTERY
     * ========================================================
     *
     * Keep purchased lotteries visible while active/drawing.
     */
    if (
      hasPurchasedTicket &&
      (
        lottery.status ===
          "ACTIVE" ||
        lottery.status ===
          "DRAWING"
      )
    ) {
      lotteries.push({
        id: doc.id,
        ...lottery,
      });

      continue;
    }

    /**
     * ========================================================
     * COMPLETED LOTTERY
     * ========================================================
     *
     * Keep completed lotteries for 30 days.
     */
    if (
      lottery.status ===
      "COMPLETED"
    ) {
      const drawnAt =
        lottery.drawnAt
          ?.toDate?.();

      if (
        drawnAt &&
        drawnAt >=
          thirtyDaysAgo &&
        (
          isPublic ||
          hasPurchasedTicket
        )
      ) {
        lotteries.push({
          id: doc.id,
          ...lottery,
        });
      }
    }
  }

  /**
   * ==========================================================
   * NEWEST FIRST
   * ==========================================================
   */
  lotteries.sort(
    (a: any, b: any) => {
      const aTime =
        a.createdAt
          ?.toMillis?.() ??
        0;

      const bTime =
        b.createdAt
          ?.toMillis?.() ??
        0;

      return bTime - aTime;
    },
  );

  return lotteries;
}