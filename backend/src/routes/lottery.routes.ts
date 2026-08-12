import { Router } from "express";
import {
  getLotteries,
  getLottery,
} from "../controllers/lottery.controller";

const router = Router();

router.get("/", getLotteries);

router.get("/:id", getLottery);

export default router;