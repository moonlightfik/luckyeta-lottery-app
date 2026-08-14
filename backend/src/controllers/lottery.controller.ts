import { Request, Response } from "express";
import {
  getAllLotteries,
  getLotteryById,
} from "../services/lottery.service";
import { getHomeLotteries } from "../services/lottery.service";

export async function getLotteries(
  req: Request,
  res: Response,
) {
  try {
    const lotteries = await getAllLotteries();

    res.status(200).json({
      success: true,
      data: lotteries,
    });
  } catch (error) {
    console.error("Failed to fetch lotteries:", error);

    res.status(500).json({
      success: false,
      message: "Failed to fetch lotteries",
    });
  }
}

export async function getLottery(
  req: Request,
  res: Response,
) {
  try {
   const id = req.params.id;

if (Array.isArray(id)) {
  return res.status(400).json({
    success: false,
    message: "Invalid lottery ID",
  });
}

const lottery = await getLotteryById(id);
    if (!lottery) {
      return res.status(404).json({
        success: false,
        message: "Lottery not found",
      });
    }

    return res.status(200).json({
      success: true,
      data: lottery,
    });
  } catch (error) {
    console.error("Failed to fetch lottery:", error);

    return res.status(500).json({
      success: false,
      message: "Failed to fetch lottery",
    });
  }
}
export async function getHomeLotteriesController(
  req: Request,
  res: Response,
) {
  try {
    const userId = req.query.userId;

    if (typeof userId !== "string") {
      return res.status(400).json({
        success: false,
        message: "userId is required",
      });
    }

    const lotteries = await getHomeLotteries(userId);

    return res.json({
      success: true,
      data: lotteries,
    });
  } catch (error) {
    console.error("Error getting home lotteries:", error);

    return res.status(500).json({
      success: false,
      message: "Failed to load home lotteries",
    });
  }
}