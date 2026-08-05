import { Module } from '@nestjs/common';

import { FirebaseModule } from './firebase/firebase.module';
import { LotteriesModule } from './lotteries/lotteries.module';

@Module({
  imports: [
    FirebaseModule,
    LotteriesModule,
  ],
})
export class AppModule {}