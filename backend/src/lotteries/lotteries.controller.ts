import { Controller, Get } from '@nestjs/common';
import { LotteriesService } from './lotteries.service';

@Controller('lotteries')
export class LotteriesController {
  constructor(
    private readonly lotteriesService: LotteriesService,
  ) {}

  @Get()
  async getAll() {
    return this.lotteriesService.getAllLotteries();
  }
}
