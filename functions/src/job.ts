import { DeviceDoc, isStale, jstDateKey, parseDevice, PeerSummary, summarize } from './aggregate';

/** Firestore へのアクセス（テストではメモリ上のフェイクに差し替える）。 */
export interface PeerStore {
  /** peer_devices/{examId}/devices の全件。 */
  listDevices(examId: string): Promise<Array<{ id: string; data: unknown }>>;
  deleteDevices(examId: string, ids: string[]): Promise<void>;
  /** peer_devices/{examId}/devices/{id} を消す。無ければ false。 */
  deleteDevice(examId: string, id: string): Promise<boolean>;
  writeSummary(examId: string, summary: PeerSummary): Promise<void>;
}

export interface JobResult {
  exams: number;
  summaries: number;
  deleted: number;
}

/** 日次ジョブ: 走査 → 要約を書く → 古い端末と壊れたドキュメントを物理削除。 */
export async function runDailyAggregation(store: PeerStore, examIds: readonly string[], now: Date): Promise<JobResult> {
  const runDate = jstDateKey(now);
  const result: JobResult = { exams: examIds.length, summaries: 0, deleted: 0 };
  for (const examId of examIds) {
    const rows = await store.listDevices(examId);
    const devices: DeviceDoc[] = [];
    const remove: string[] = [];
    for (const r of rows) {
      const d = parseDevice(r.data);
      if (d === null || isStale(d.day, runDate)) remove.push(r.id);
      else devices.push(d);
    }
    if (rows.length > 0) {
      await store.writeSummary(examId, summarize(devices, runDate));
      result.summaries++;
    }
    if (remove.length > 0) {
      await store.deleteDevices(examId, remove);
      result.deleted += remove.length;
    }
  }
  return result;
}

/** callable の本体: installId を指定して削除（examId 省略時は全資格）。 */
export async function eraseInstall(store: PeerStore, examIds: readonly string[], installId: string, examId?: string): Promise<number> {
  const targets = examId ? [examId] : examIds;
  let n = 0;
  for (const e of targets) if (await store.deleteDevice(e, installId)) n++;
  return n;
}
