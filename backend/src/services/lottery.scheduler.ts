import cron from "node-cron";
import {
  startDueLotteries,
  processExpiredLotteries,
} from "./lottery.service";

export function startLotteryScheduler() {
  // Runs every minute
  cron.schedule("* * * * *", async () => {
    console.log("🎰 Checking lottery statuses...");

    try {
      /**
       * STEP 1
       *
       * ACTIVE → DRAWING
       *
       * Find lotteries whose nextDrawAt
       * has arrived.
       */
      const drawingResults =
        await startDueLotteries();

      if (drawingResults.length > 0) {
        console.log(
          `🎯 Started ${drawingResults.length} lottery/lotteries.`,
        );
      } else {
        console.log(
          "ℹ️ No lotteries ready to start drawing.",
        );
      }

      /**
       * STEP 2
       *
       * DRAWING → COMPLETED
       *
       * Process lotteries that are ready
       * to have their winners selected.
       */
      const results =
        await processExpiredLotteries();

      if (results.length > 0) {
        console.log(
          `✅ Processed ${results.length} lottery/lotteries.`,
        );
      } else {
        console.log(
          "ℹ️ No lotteries ready to be completed.",
        );
      }
    } catch (error) {
      console.error(
        "❌ Error processing lottery scheduler:",
        error,
      );
    }
  });

  console.log(
    "⏰ Lottery scheduler started.",
  );
}