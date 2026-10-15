// 匿名集計の純粋ロジック（Firestore に依存しない）。
// 定義は lib/peer/peer_stats.dart の PeerStatsPolicy / PeerStatsSnapshot.toJson と揃える。

/** 表示側 PeerStatsPolicy.minVisible と同じ。この人数「以下」の項目は要約に書かない。 */
export const MIN_VISIBLE = 100;
/** この日数以上更新の無い端末は集計から外し、物理削除する。 */
export const STALE_DAYS = 60;
/** 連続日数の上限（これ以上は 365 に丸める）。 */
export const STREAK_CAP = 365;

export interface DeviceDoc {
  day: string; // yyyy-MM-dd（日本時間）
  streakDays: number;
  totalQuestions: number;
  examDate?: string;
}

export interface PeerSummary {
  asOf: string;
  activeToday?: number;
  participants?: number;
  totalQuestions?: number;
  medianQuestions?: number;
  streakCounts: Record<string, number>;
  examDateCounts: Record<string, number>;
}

const DATE_RE = /^\d{4}-\d{2}-\d{2}$/;

/** 日本時間（UTC+9）の暦日 yyyy-MM-dd。 */
export function jstDateKey(now: Date): string {
  const j = new Date(now.getTime() + 9 * 3600 * 1000);
  return j.toISOString().slice(0, 10);
}

/** yyyy-MM-dd 同士の日数差（a - b）。不正な形式は NaN。 */
export function daysBetween(a: string, b: string): number {
  if (!DATE_RE.test(a) || !DATE_RE.test(b)) return NaN;
  return Math.round((Date.parse(`${a}T00:00:00Z`) - Date.parse(`${b}T00:00:00Z`)) / 86400000);
}

/** 端末の値として妥当か（Firestore ルールと同じ値域）。壊れた値は集計に入れない。 */
export function parseDevice(raw: unknown): DeviceDoc | null {
  if (typeof raw !== 'object' || raw === null) return null;
  const r = raw as Record<string, unknown>;
  if (typeof r.day !== 'string' || !DATE_RE.test(r.day)) return null;
  const s = r.streakDays;
  const t = r.totalQuestions;
  if (!Number.isInteger(s) || (s as number) < 0 || (s as number) > 3650) return null;
  if (!Number.isInteger(t) || (t as number) < 0 || (t as number) > 1000000) return null;
  const d: DeviceDoc = { day: r.day, streakDays: s as number, totalQuestions: t as number };
  if (typeof r.examDate === 'string' && DATE_RE.test(r.examDate)) d.examDate = r.examDate;
  return d;
}

/** 古い端末か（集計から外し、物理削除する）。壊れた日付も古い扱い。 */
export function isStale(day: string, runDate: string): boolean {
  const age = daysBetween(runDate, day);
  return Number.isNaN(age) || age >= STALE_DAYS;
}

/** 偶数個なら中央 2 つの平均を切り捨て。空は 0（PeerStatsPolicy.median と同じ）。 */
export function median(values: number[]): number {
  const v = [...values].sort((a, b) => a - b);
  if (v.length === 0) return 0;
  const mid = Math.floor(v.length / 2);
  return v.length % 2 === 1 ? v[mid] : Math.floor((v[mid - 1] + v[mid]) / 2);
}

/**
 * 連続日数の度数分布。連続日数 1 以上のみ、365 に丸める。
 * 人数が 100 以下の細かい区分は書かない代わりに、連続日数の高い側から隣の区分とまとめて
 * 「100 人を超える区分」だけを作る（区分のキー = まとめた中で最小の連続日数）。
 * 合計が 100 以下なら空。表示側の「自分以上の人の割合」が、細かい値を出さずに計算できる。
 */
export function bucketStreaks(streaks: number[]): Record<string, number> {
  const freq = new Map<number, number>();
  for (const s of streaks) {
    if (s < 1) continue;
    const k = Math.min(s, STREAK_CAP);
    freq.set(k, (freq.get(k) ?? 0) + 1);
  }
  const days = [...freq.keys()].sort((a, b) => b - a);
  const out: Array<[number, number]> = [];
  let acc = 0;
  let lowest = 0;
  for (const d of days) {
    acc += freq.get(d)!;
    lowest = d;
    if (acc > MIN_VISIBLE) {
      out.push([lowest, acc]);
      acc = 0;
    }
  }
  if (acc > 0 && out.length > 0) {
    const last = out[out.length - 1];
    out[out.length - 1] = [lowest, last[1] + acc]; // 残りは最後の区分にまとめる
  }
  const rec: Record<string, number> = {};
  for (const [k, n] of out) rec[String(k)] = n;
  return rec;
}

/**
 * 1 試験分の要約を作る。
 * - activeToday: 集計日（asOf = 実行日の前日）以降に学習した人数。
 * - 100 人以下の項目は書かない（activeToday / 参加者ベースの値 / 試験日 / 連続日数の区分）。
 */
export function summarize(devices: DeviceDoc[], runDate: string): PeerSummary {
  const asOf = shiftDate(runDate, -1);
  const live = devices.filter((d) => !isStale(d.day, runDate) && daysBetween(d.day, runDate) <= 1);
  const summary: PeerSummary = { asOf, streakCounts: {}, examDateCounts: {} };

  const active = live.filter((d) => daysBetween(d.day, asOf) >= 0).length;
  if (active > MIN_VISIBLE) summary.activeToday = active;

  if (live.length > MIN_VISIBLE) {
    summary.participants = live.length;
    summary.totalQuestions = live.reduce((a, d) => a + d.totalQuestions, 0);
    summary.medianQuestions = median(live.map((d) => d.totalQuestions));
  }

  summary.streakCounts = bucketStreaks(live.map((d) => d.streakDays));

  const dates = new Map<string, number>();
  for (const d of live) {
    if (d.examDate && daysBetween(d.examDate, runDate) >= 0) {
      dates.set(d.examDate, (dates.get(d.examDate) ?? 0) + 1);
    }
  }
  for (const [date, n] of dates) if (n > MIN_VISIBLE) summary.examDateCounts[date] = n;
  return summary;
}

export function shiftDate(day: string, delta: number): string {
  return new Date(Date.parse(`${day}T00:00:00Z`) + delta * 86400000).toISOString().slice(0, 10);
}
