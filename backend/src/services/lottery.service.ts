import { db } from "../config/firebase";

/**
 * ============================================================
 * TYPES
 * ============================================================
 */

export interface LotteryData {
  id: string;
  title: string;
  jackpot: number;
  pricePerTicket?: number;
  totalTickets?: number;
  maxTicketsPerUser?: number;
  numberOfWinners?: number;
  lotteryType?: string;
  drawFrequency?: string | null;
  nextDrawAt?: any;
  isPublic?: boolean;
  creatorId?: string;
  creatorName?: string;
  createdAt?: any;
  ticketsSold?: number;
  remainingTickets?: number;
  status?: string;
  winnerIds?: string[];
  winningTicketNumbers?: number[];
  drawnAt?: any;
  resultMessage?: string;
  description?: string;
  category?: string;
  themeColor?: number;
  cardStyle?: string;
  imageUrl?: string | null;

  [key: string]: any;
}

export interface TicketData {
  ticketId: string;
  ticketNumber: number;
  userId: string;
}

export interface LotteryDrawResult {
  success: boolean;
  lotteryId: string;
  lotteryTitle: string;
  jackpot: number;
  winnerCount: number;
  winnerIds: string[];
  winningTicketNumbers: number[];
  drawnAt: Date;
  resultMessage: string;
}

/**
 * ============================================================
 * GET ALL LOTTERIES
 * ============================================================
 */

export async function getAllLotteries(): Promise<LotteryData[]> {
  const snapshot = await db
    .collection("lotteries")
    .get();

  return snapshot.docs.map((doc) => {
    const data = doc.data();

    return {
      id: doc.id,
      ...data,
    } as LotteryData;
  });
}

/**
 * ============================================================
 * GET LOTTERY BY ID
 * ============================================================
 */

export async function getLotteryById(
  id: string,
): Promise<LotteryData | null> {
  const doc = await db
    .collection("lotteries")
    .doc(id)
    .get();

  if (!doc.exists) {
    return null;
  }

  const data = doc.data();

  return {
    id: doc.id,
    ...data,
  } as LotteryData;
}

/**
 * ============================================================
 * GET EXPIRED LOTTERIES
 * ============================================================
 *
 * Finds lotteries whose draw time has arrived.
 *
 * ACTIVE and DRAWING lotteries are accepted because
 * your existing Firestore data contains both statuses.
 */

export async function getExpiredLotteries(): Promise<
  LotteryData[]
> {
  const now = new Date();

  const snapshot = await db
    .collection("lotteries")
    .where("nextDrawAt", "<=", now)
    .get();

  return snapshot.docs
    .map((doc) => {
      const data = doc.data();

      return {
        id: doc.id,
        ...data,
      } as LotteryData;
    })
    .filter(
      (lottery) =>
        lottery.status === "ACTIVE" ||
        lottery.status === "DRAWING",
    );
}

/**
 * ============================================================
 * START DUE LOTTERIES
 * ============================================================
 *
 * ACTIVE → DRAWING
 *
 * This is called by the scheduler when nextDrawAt arrives.
 */

export async function startDueLotteries(): Promise<
  LotteryData[]
> {
  const now = new Date();

  const snapshot = await db
    .collection("lotteries")
    .where("status", "==", "ACTIVE")
    .where("nextDrawAt", "<=", now)
    .get();

  const startedLotteries: LotteryData[] = [];

  for (const doc of snapshot.docs) {
    const data = doc.data();

    await doc.ref.update({
      status: "DRAWING",
      drawingStartedAt: now,
    });

    startedLotteries.push({
      id: doc.id,
      ...data,
      status: "DRAWING",
    } as LotteryData);
  }

  return startedLotteries;
}

/**
 * ============================================================
 * PROCESS ONE LOTTERY
 * ============================================================
 *
 * 1. Find lottery
 * 2. Find all purchased tickets
 * 3. Randomly select winner(s)
 * 4. Save result
 * 5. Mark tickets WON / LOST
 * 6. Return complete result
 */

export async function processLottery(
  lotteryId: string,
): Promise<LotteryDrawResult> {
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
    throw new Error(
      "Lottery data is missing",
    );
  }

  /**
   * Prevent duplicate drawing.
   */

  if (
    lottery.status !== "ACTIVE" &&
    lottery.status !== "DRAWING"
  ) {
    throw new Error(
      "Lottery has already been processed",
    );
  }

  /**
   * ==========================================================
   * GET USERS
   * ==========================================================
   */

  const usersSnapshot =
    await db.collection("users").get();

  const allTickets: TicketData[] = [];

  /**
   * ==========================================================
   * FIND ALL TICKETS
   * ==========================================================
   */

  for (
    const userDoc of usersSnapshot.docs
  ) {
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

    for (
      const ticketDoc of ticketsSnapshot.docs
    ) {
      const ticketData =
        ticketDoc.data();

      if (
        ticketData.ticketNumber ==
        null
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

    const resultMessage =
      "Lottery completed. No tickets were purchased.";

    await lotteryRef.update({
      status: "COMPLETED",

      winnerIds: [],

      winningTicketNumbers: [],

      drawnAt,

      resultMessage,
    });

    return {
      success: true,

      lotteryId,

      lotteryTitle:
        String(
          lottery.title ??
            "LuckyEta Lottery",
        ),

      jackpot:
        Number(
          lottery.jackpot ?? 0,
        ),

      winnerCount: 0,

      winnerIds: [],

      winningTicketNumbers: [],

      drawnAt,

      resultMessage,
    };
  }

  /**
   * ==========================================================
   * DETERMINE WINNER COUNT
   * ==========================================================
   */

  const requestedWinners =
    Number(
      lottery.numberOfWinners ?? 1,
    );

  const winnerCount = Math.min(
    requestedWinners,
    allTickets.length,
  );

  /**
   * ==========================================================
   * FISHER-YATES SHUFFLE
   * ==========================================================
   */

  const shuffledTickets = [
    ...allTickets,
  ];

  for (
    let i =
      shuffledTickets.length - 1;
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
      (winner) =>
        winner.userId,
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
   * UPDATE TICKETS
   * ==========================================================
   */

  for (
    const ticket of allTickets
  ) {
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
   * ==========================================================
   * RETURN RESULT
   * ==========================================================
   */

  return {
    success: true,

    lotteryId,

    lotteryTitle:
      String(
        lottery.title ??
          "LuckyEta Lottery",
      ),

    jackpot:
      Number(
        lottery.jackpot ?? 0,
      ),

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

export async function processExpiredLotteries(): Promise<
  LotteryDrawResult[]
> {
  const expiredLotteries =
    await getExpiredLotteries();

  const results: LotteryDrawResult[] =
    [];

  for (
    const lottery of expiredLotteries
  ) {
    try {
      const result =
        await processLottery(
          lottery.id,
        );

      results.push(result);
    } catch (error) {
      console.error(
        `❌ Failed to process lottery ${lottery.id}:`,
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
 * Home visibility:
 *
 * PUBLIC:
 *   ACTIVE     ✓
 *   DRAWING    ✓
 *   COMPLETED  ✓ for 30 days
 *
 * CREATOR:
 *   ACTIVE     ✓
 *   DRAWING    ✓
 *   COMPLETED  ✓ for 30 days
 *
 * BUYER:
 *   ACTIVE     ✓
 *   DRAWING    ✓
 *   COMPLETED  ✓ for 30 days
 *
 * After 30 days from drawnAt:
 *   COMPLETED lotteries disappear from Home.
 */

export async function getHomeLotteries(
  userId: string,
): Promise<LotteryData[]> {
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

  /**
   * Get all lotteries.
   */

  const lotterySnapshot =
    await db
      .collection("lotteries")
      .get();

  /**
   * Get this user's tickets once.
   */

  const userTicketsSnapshot =
    await db
      .collection("users")
      .doc(userId)
      .collection("tickets")
      .get();

  /**
   * Store purchased lottery IDs.
   */

  const purchasedLotteryIds =
    new Set<string>();

  for (
    const ticketDoc of
      userTicketsSnapshot.docs
  ) {
    const ticketData =
      ticketDoc.data();

    if (
      ticketData.lotteryID
    ) {
      purchasedLotteryIds.add(
        String(
          ticketData.lotteryID,
        ),
      );
    }
  }

  const homeLotteries: LotteryData[] =
    [];

  /**
   * ==========================================================
   * CHECK EVERY LOTTERY
   * ==========================================================
   */

  for (
    const doc of
      lotterySnapshot.docs
  ) {
    const lottery =
      doc.data();

    const lotteryId =
      doc.id;

    const isPublic =
      lottery.isPublic === true;

    const isCreator =
      lottery.creatorId ===
      userId;

    const hasPurchased =
      purchasedLotteryIds.has(
        lotteryId,
      );

    const status =
      lottery.status;

    /**
     * ========================================================
     * ACTIVE / DRAWING
     * ========================================================
     */

    if (
      status === "ACTIVE" ||
      status === "DRAWING"
    ) {
      if (
        isPublic ||
        isCreator ||
        hasPurchased
      ) {
        homeLotteries.push({
          id: lotteryId,
          ...lottery,
        } as LotteryData);

        continue;
      }
    }

    /**
     * ========================================================
     * COMPLETED
     * ========================================================
     */

    if (
      status === "COMPLETED"
    ) {
      let drawnAt:
        | Date
        | null = null;

      /**
       * Firestore Timestamp.
       */

      if (
        lottery.drawnAt &&
        typeof lottery.drawnAt
          .toDate ===
          "function"
      ) {
        drawnAt =
          lottery.drawnAt.toDate();
      }

      /**
       * JS Date.
       */

      else if (
        lottery.drawnAt instanceof
        Date
      ) {
        drawnAt =
          lottery.drawnAt;
      }

      /**
       * Firestore serialized timestamp.
       */

      else if (
        lottery.drawnAt?._seconds
      ) {
        drawnAt =
          new Date(
            Number(
              lottery.drawnAt
                ._seconds,
            ) * 1000,
          );
      }

      /**
       * Without drawnAt we can't
       * determine the 30-day period.
       */

      if (!drawnAt) {
        continue;
      }

      /**
       * Remove after 30 days.
       */

      if (
        drawnAt <
        thirtyDaysAgo
      ) {
        continue;
      }

      /**
       * Completed lottery is visible
       * if public, creator, or buyer.
       */

      if (
        isPublic ||
        isCreator ||
        hasPurchased
      ) {
        homeLotteries.push({
          id: lotteryId,
          ...lottery,
        } as LotteryData);
      }
    }
  }

  /**
   * ==========================================================
   * SORT NEWEST FIRST
   * ==========================================================
   */

  homeLotteries.sort(
    (
      a: LotteryData,
      b: LotteryData,
    ) => {
      const aCreated =
        a.createdAt?.toMillis?.() ??
        a.createdAt?._seconds ??
        0;

      const bCreated =
        b.createdAt?.toMillis?.() ??
        b.createdAt?._seconds ??
        0;

      return (
        Number(bCreated) -
        Number(aCreated)
      );
    },
  );

  return homeLotteries;
}