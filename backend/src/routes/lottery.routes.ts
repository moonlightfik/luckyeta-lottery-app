import { Router } from "express";
import {
  getLotteries,
  getLottery,
} from "../controllers/lottery.controller";
import {
  getHomeLotteriesController,
} from "../controllers/lottery.controller";

const router = Router();

router.get("/", getLotteries);

router.get("/:id", getLottery);
router.get(
  "/home",
  getHomeLotteriesController,
);

export default router;