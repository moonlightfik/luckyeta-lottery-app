import express from "express";
import lotteryRoutes from "./routes/lottery.routes";
import { startLotteryScheduler } from "./services/lottery.scheduler";
const app = express();

app.use(express.json());

app.get("/", (req, res) => {
  res.json({
    message: "LuckyEta Backend is running 🎰",
  });
});

app.use("/lotteries", lotteryRoutes);

startLotteryScheduler();

app.listen(3000, () => {
  console.log(
    "LuckyEta backend running on http://localhost:3000",
  );
});