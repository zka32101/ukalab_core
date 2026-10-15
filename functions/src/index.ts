// デプロイしない（人が配備チェックリストに沿って行う）。docs/peer_stats.md 参照。
import { initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { EXAM_IDS, INSTALL_ID_RE } from './exams';
import { eraseInstall, PeerStore, runDailyAggregation } from './job';
import { PeerSummary } from './aggregate';

initializeApp();
const REGION = 'asia-northeast1';

function firestoreStore(): PeerStore {
  const db = getFirestore();
  const col = (examId: string) => db.collection('peer_devices').doc(examId).collection('devices');
  return {
    async listDevices(examId) {
      const snap = await col(examId).select('day', 'streakDays', 'totalQuestions', 'examDate').get();
      return snap.docs.map((d) => ({ id: d.id, data: d.data() }));
    },
    async deleteDevices(examId, ids) {
      const w = db.bulkWriter();
      for (const id of ids) w.delete(col(examId).doc(id));
      await w.close();
    },
    async deleteDevice(examId, id) {
      const ref = col(examId).doc(id);
      const exists = (await ref.get()).exists;
      if (exists) await ref.delete();
      return exists;
    },
    async writeSummary(examId, summary: PeerSummary) {
      await db.collection('peer_summaries').doc(examId).set(summary); // 全置換（古い区分を残さない）
    },
  };
}

/** 毎日 日本時間 5:00。 */
export const aggregatePeerStats = onSchedule(
  { schedule: '0 5 * * *', timeZone: 'Asia/Tokyo', region: REGION, timeoutSeconds: 540, memory: '512MiB' },
  async () => {
    const r = await runDailyAggregation(firestoreStore(), EXAM_IDS, new Date());
    console.log('peer stats aggregated', JSON.stringify(r));
  },
);

/**
 * 自分の installId のデータを削除する。App Check 必須（enforceAppCheck）＋ ログイン済み（匿名認証で可）。
 * installId は推測不能なランダム UUID で、本人の端末だけが知る。
 * 入力: { installId: string, examId?: string }
 */
export const erasePeerStats = onCall(
  { region: REGION, enforceAppCheck: true },
  async (request) => {
    if (!request.auth) throw new HttpsError('unauthenticated', 'ログインが必要です');
    const { installId, examId } = (request.data ?? {}) as { installId?: unknown; examId?: unknown };
    if (typeof installId !== 'string' || !INSTALL_ID_RE.test(installId)) {
      throw new HttpsError('invalid-argument', 'installId の形式が正しくありません');
    }
    if (examId !== undefined && (typeof examId !== 'string' || !EXAM_IDS.includes(examId))) {
      throw new HttpsError('invalid-argument', 'examId が正しくありません');
    }
    const deleted = await eraseInstall(firestoreStore(), EXAM_IDS, installId, examId as string | undefined);
    return { deleted };
  },
);
