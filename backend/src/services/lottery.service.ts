import { db } from "../config/firebase";

export async function getAllLotteries() {
  const snapshot = await db
    .collection("lotteries")
    .get();

  return snapshot.docs.map((doc) => ({
    id: doc.id,
    ...doc.data(),
  }));
}

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