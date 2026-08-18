import { db } from "../config/firebase";

export type NotificationType =
  | "LOTTERY_STARTED"
  | "LOTTERY_COMPLETED"
  | "LOTTERY_WON"
  | "LOTTERY_LOST"
  | "LOTTERY_SOLD_OUT";

export class NotificationService {
  /**
   * Create a notification for a user.
   */
  async createNotification({
    userId,
    title,
    message,
    type,
    lotteryId,
    lotteryTitle,
    data = {},
  }: {
    userId: string;
    title: string;
    message: string;
    type: NotificationType;
    lotteryId: string;
    lotteryTitle: string;
    data?: Record<string, any>;
  }) {
    if (!userId) {
      console.warn(
        "⚠️ Notification skipped: missing userId",
      );
      return;
    }

    await db.collection("notifications").add({
      userId,

      title,

      message,

      type,

      lotteryId,

      lotteryTitle,

      isRead: false,

      data,

      createdAt: new Date(),
    });
  }

  /**
   * Notify the creator that their lottery
   * has started drawing.
   */
  async notifyLotteryStarted({
    creatorId,
    lotteryId,
    lotteryTitle,
  }: {
    creatorId: string;
    lotteryId: string;
    lotteryTitle: string;
  }) {
    await this.createNotification({
      userId: creatorId,

      title: "🎰 Lottery Draw Started",

      message:
        `"${lotteryTitle}" is now being drawn. ` +
        "Good luck to all participants!",

      type: "LOTTERY_STARTED",

      lotteryId,

      lotteryTitle,

      data: {
        status: "DRAWING",
      },
    });
  }

  /**
   * Notify the creator that the lottery
   * has been completed.
   */
  async notifyLotteryCompleted({
    creatorId,
    lotteryId,
    lotteryTitle,
    winnerCount,
    winningTicketNumbers,
    winnerIds,
  }: {
    creatorId: string;
    lotteryId: string;
    lotteryTitle: string;
    winnerCount: number;
    winningTicketNumbers: number[];
    winnerIds: string[];
  }) {
    await this.createNotification({
      userId: creatorId,

      title: "🏆 Lottery Completed",

      message:
        winnerCount === 1
          ? `"${lotteryTitle}" has been completed and a winner has been selected!`
          : `"${lotteryTitle}" has been completed and ${winnerCount} winners have been selected!`,

      type: "LOTTERY_COMPLETED",

      lotteryId,

      lotteryTitle,

      data: {
        winnerCount,
        winnerIds,
        winningTicketNumbers,
        status: "COMPLETED",
      },
    });
  }

  /**
   * Notify a user that they WON.
   */
  async notifyWinner({
    userId,
    lotteryId,
    lotteryTitle,
    ticketNumber,
    jackpot,
  }: {
    userId: string;
    lotteryId: string;
    lotteryTitle: string;
    ticketNumber: number;
    jackpot: number;
  }) {
    await this.createNotification({
      userId,

      title: "🎉 YOU WON!",

      message:
        `Congratulations! Your ticket #${ticketNumber} ` +
        `won "${lotteryTitle}"!`,

      type: "LOTTERY_WON",

      lotteryId,

      lotteryTitle,

      data: {
        ticketNumber,
        jackpot,
        result: "WINNER",
      },
    });
  }

  /**
   * Notify a user that they did NOT win.
   */
  async notifyLoser({
    userId,
    lotteryId,
    lotteryTitle,
    ticketNumber,
  }: {
    userId: string;
    lotteryId: string;
    lotteryTitle: string;
    ticketNumber: number;
  }) {
    await this.createNotification({
      userId,

      title: "Lottery Result",

      message:
        `Ticket #${ticketNumber} did not win ` +
        `"${lotteryTitle}". Better luck next time! 💜`,

      type: "LOTTERY_LOST",

      lotteryId,

      lotteryTitle,

      data: {
        ticketNumber,
        result: "NOT_WINNER",
      },
    });
  }

  /**
   * Notify the creator that all tickets
   * have been sold.
   */
  async notifyLotterySoldOut({
    creatorId,
    lotteryId,
    lotteryTitle,
    totalTickets,
  }: {
    creatorId: string;
    lotteryId: string;
    lotteryTitle: string;
    totalTickets: number;
  }) {
    await this.createNotification({
      userId: creatorId,

      title: "🎟️ Lottery Sold Out",

      message:
        `"${lotteryTitle}" has sold all ` +
        `${totalTickets} tickets!`,

      type: "LOTTERY_SOLD_OUT",

      lotteryId,

      lotteryTitle,

      data: {
        totalTickets,
        status: "SOLD_OUT",
      },
    });
  }

  /**
   * Get all notifications for a user.
   */
  async getUserNotifications(
    userId: string,
  ) {
    const snapshot = await db
      .collection("notifications")
      .where("userId", "==", userId)
      .get();

    const notifications =
      snapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
      }));

    /**
     * Newest notifications first.
     */
    notifications.sort(
      (a: any, b: any) => {
        const aTime =
          a.createdAt?.toMillis?.() ?? 0;

        const bTime =
          b.createdAt?.toMillis?.() ?? 0;

        return bTime - aTime;
      },
    );

    return notifications;
  }

  /**
   * Mark one notification as read.
   */
  async markAsRead(
    notificationId: string,
  ) {
    await db
      .collection("notifications")
      .doc(notificationId)
      .update({
        isRead: true,
      });
  }

  /**
   * Mark all notifications belonging
   * to a user as read.
   */
  async markAllAsRead(
    userId: string,
  ) {
    const snapshot = await db
      .collection("notifications")
      .where("userId", "==", userId)
      .where("isRead", "==", false)
      .get();

    if (snapshot.empty) {
      return;
    }

    const batch = db.batch();

    for (
      const doc of snapshot.docs
    ) {
      batch.update(doc.ref, {
        isRead: true,
      });
    }

    await batch.commit();
  }
}