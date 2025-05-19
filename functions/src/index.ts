import {onSchedule} from "firebase-functions/v2/scheduler";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";

admin.initializeApp();

export const cleanupOldLobbies = onSchedule("every 1 hours", async () => {
  const firestore = admin.firestore();
  const now = Date.now();
  const lobbyTimeout = 24 * 60 * 60 * 1000; // 24 Stunden in ms

  // 1. Lobbys aufräumen
  const lobbiesSnap = await firestore.collection("lobbies").get();
  for (const doc of lobbiesSnap.docs) {
    const data = doc.data();
    const lastActivity = data.lastActivity?.toDate?.() ?? data.lastActivity;
    if (lastActivity && now - lastActivity.getTime() > lobbyTimeout) {
      await doc.ref.delete();
      logger.info(`Lobby ${doc.id} gelöscht`);
    }
  }

  // 2. Reconnect-Daten aufräumen
  const reconnectSnap = await firestore.collection("reconnect").get();
  for (const doc of reconnectSnap.docs) {
    const data = doc.data();
    const lobbyId = data.lobbyId;
    if (lobbyId) {
      const lobbyDoc = await firestore.collection("lobbies").doc(lobbyId).get();
      if (!lobbyDoc.exists) {
        await doc.ref.delete();
        logger.info(`Reconnect-Datensatz ${doc.id} gelöscht`);
      }
    }
  }

  return;
});
