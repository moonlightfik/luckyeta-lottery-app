import express from "express";
import lotteryRoutes from "./routes/lottery.routes";

const app = express();

app.use(express.json());

app.get("/", (req, res) => {
  res.json({
    message: "LuckyEta Backend is running 🎰",
  });
});

app.use("/lotteries", lotteryRoutes);

const PORT = 3000;

app.listen(PORT, () => {
  console.log(
    `LuckyEta backend running on http://localhost:${PORT}`,
  );
});