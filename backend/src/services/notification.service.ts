import { db } from '../config/firebase';

export class NotificationService {
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
    type: string;
    lotteryId: string;
    lotteryTitle: string;
    data?: Record<string, any>;
  }) {
    await db.collection('notifications').add({
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
}