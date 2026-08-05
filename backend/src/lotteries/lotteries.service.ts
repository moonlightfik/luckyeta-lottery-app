import { Injectable } from '@nestjs/common';
import { FirebaseService } from '../firebase/firebase.service';

@Injectable()
export class LotteriesService {
  constructor(
    private readonly firebaseService: FirebaseService,
  ) {}

  async getAllLotteries() {
    const snapshot = await this.firebaseService.db
      .collection('lotteries')
      .get();

    return snapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    }));
  }
}