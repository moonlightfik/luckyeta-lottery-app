import { Injectable } from '@nestjs/common';

import { initializeApp, cert, getApps } from 'firebase-admin/app';

import { getFirestore } from 'firebase-admin/firestore';

@Injectable()
export class FirebaseService {
  readonly db;

  constructor() {
    if (!getApps().length) {
      initializeApp({
        credential: cert(require('../../serviceAccountKey.json')),
      });
    }

    this.db = getFirestore();
  }
}