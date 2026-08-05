import { Module } from '@nestjs/common';

import { FirebaseModule } from '../firebase/firebase.module';

import { LotteriesController } from './lotteries.controller';
import { LotteriesService } from './lotteries.service';

@Module({
  imports: [FirebaseModule],
  controllers: [LotteriesController],
  providers: [LotteriesService],
})
export class LotteriesModule {}