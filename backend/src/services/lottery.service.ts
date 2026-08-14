import { db } from "../config/firebase";

/**
 * Get all lotteries
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
 * Get a single lottery by ID
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
 * Find lotteries whose draw time has passed.
 *
 * Only ACTIVE lotteries are considered.
 */
/**
 * Find lotteries that are currently DRAWING
 * and whose draw time has arrived.
 *
 * These lotteries are ready to be processed
 * and completed.
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
 * Move lotteries whose draw time has arrived
 * from ACTIVE → DRAWING.
 *
 * This function does NOT select winners.
 * It only changes the Firebase status.
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
 * Process one expired lottery.
 *
 * This:
 *
 * 1. Gets all tickets purchased for the lottery.
 * 2. Randomly selects the winner(s).
 * 3. Saves the winning ticket numbers.
 * 4. Saves the winner user IDs.
 * 5. Saves the draw result.
 * 6. Changes the lottery status to COMPLETED.
 * 7. Marks winning tickets as WON.
 * 8. Marks other tickets as LOST.
 */
export async function processLottery(lotteryId: string) {
  const lotteryRef = db
    .collection("lotteries")
    .doc(lotteryId);

  const lotterySnapshot = await lotteryRef.get();

  if (!lotterySnapshot.exists) {
    throw new Error("Lottery not found");
  }

  const lottery = lotterySnapshot.data();

  if (!lottery) {
    throw new Error("Lottery data is missing");
  }

  /**
   * Prevent the same lottery from being drawn twice.
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
   * Get every user.
   */
  const usersSnapshot = await db
    .collection("users")
    .get();

  const allTickets: Array<{
    ticketId: string;
    ticketNumber: number;
    userId: string;
  }> = [];

  /**
   * Find tickets belonging to this lottery.
   */
  for (const userDoc of usersSnapshot.docs) {
    const ticketsSnapshot = await userDoc.ref
      .collection("tickets")
      .where("lotteryID", "==", lotteryId)
      .where("status", "==", "ACTIVE")
      .get();

    for (const ticketDoc of ticketsSnapshot.docs) {
      const ticketData = ticketDoc.data();

      if (ticketData.ticketNumber == null) {
        continue;
      }

      allTickets.push({
        ticketId: ticketDoc.id,
        ticketNumber: Number(ticketData.ticketNumber),
        userId: userDoc.id,
      });
    }
  }

  /**
   * No tickets were purchased.
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
   * Number of winners.
   *
   * Default = 1.
   */
  const requestedWinners =
    Number(lottery.numberOfWinners) || 1;

  const winnerCount = Math.min(
    requestedWinners,
    allTickets.length,
  );

  /**
   * Fisher-Yates shuffle.
   */
  const shuffledTickets = [...allTickets];

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
   * Select winners.
   */
  const winners = shuffledTickets.slice(
    0,
    winnerCount,
  );

  const winnerIds = winners.map(
    (winner) => winner.userId,
  );

  const winningTicketNumbers =
    winners.map(
      (winner) => winner.ticketNumber,
    );

  const drawnAt = new Date();

  const resultMessage =
    winnerCount === 1
      ? "Lottery completed. A winner has been selected!"
      : `${winnerCount} winners have been selected!`;

  /**
   * Save lottery result.
   */
  await lotteryRef.update({
    status: "COMPLETED",
    winnerIds,
    winningTicketNumbers,
    drawnAt,
    resultMessage,
  });

  /**
   * Update every ticket.
   */
  for (const ticket of allTickets) {
    const ticketRef = db
      .collection("users")
      .doc(ticket.userId)
      .collection("tickets")
      .doc(ticket.ticketId);

    const isWinner = winners.some(
      (winner) =>
        winner.ticketId === ticket.ticketId,
    );

    await ticketRef.update({
      status: isWinner
        ? "WON"
        : "LOST",

      result: isWinner
        ? "WINNER"
        : "NOT_WINNER",

      drawnAt,
    });
  }

  /**
   * Return the complete draw result.
   *
   * This will later be used by the
   * notification system.
   */
  return {
    success: true,
    lotteryId,
    lotteryTitle: lottery.title,
    jackpot: lottery.jackpot,
    winnerCount,
    winnerIds,
    winningTicketNumbers,
    drawnAt,
    resultMessage,
  };
}

/**
 * Process every expired lottery.
 */
export async function processExpiredLotteries() {
  const expiredLotteries =
    await getExpiredLotteries();

  const results = [];

  for (const lottery of expiredLotteries) {
    try {
      const result =
        await processLottery(lottery.id);

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
 * Get lotteries that should appear on
 * the user's Home page.
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
 *    → visible to the creator, including COMPLETED.
 *
 * 4. Lotteries purchased by the user
 *    → visible to the buyer.
 *
 * 5. COMPLETED lotteries
 *    → remain visible for 30 days after drawnAt
 *      if public or purchased by the user.
 */
export async function getHomeLotteries(
  userId: string,
) {
  const now = new Date();

  const thirtyDaysAgo = new Date(
    now.getTime() -
      30 * 24 * 60 * 60 * 1000,
  );

  const snapshot = await db
    .collection("lotteries")
    .get();

  const lotteries = [];

  for (const doc of snapshot.docs) {
    const lottery = doc.data();

    const isPublic =
      lottery.isPublic === true;

    const isCreator =
      lottery.creatorId === userId;

    /**
     * Check whether this user has
     * purchased a ticket.
     */
    const ticketsSnapshot = await db
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
     * ACTIVE / DRAWING public lotteries
     */
    if (
      isPublic &&
      (
        lottery.status === "ACTIVE" ||
        lottery.status === "DRAWING"
      )
    ) {
      lotteries.push({
        id: doc.id,
        ...lottery,
      });

      continue;
    }

    /**
     * Creator's lottery.
     *
     * The creator should always be able
     * to see their own lottery, even
     * after it becomes COMPLETED.
     */
    if (isCreator) {
      lotteries.push({
        id: doc.id,
        ...lottery,
      });

      continue;
    }

    /**
     * Lottery the user purchased tickets for.
     */
    if (
      hasPurchasedTicket &&
      (
        lottery.status === "ACTIVE" ||
        lottery.status === "DRAWING"
      )
    ) {
      lotteries.push({
        id: doc.id,
        ...lottery,
      });

      continue;
    }

    /**
     * COMPLETED lotteries.
     *
     * Keep them for 30 days after the draw
     * if they are public or purchased by
     * the current user.
     */
    if (
      lottery.status === "COMPLETED"
    ) {
      const drawnAt =
        lottery.drawnAt?.toDate?.();

      if (
        drawnAt &&
        drawnAt >= thirtyDaysAgo &&
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
   * Newest lotteries first.
   */
  lotteries.sort((a: any, b: any) => {
    const aTime =
      a.createdAt?.toMillis?.() ?? 0;

    const bTime =
      b.createdAt?.toMillis?.() ?? 0;

    return bTime - aTime;
  });

  return lotteries;
}
