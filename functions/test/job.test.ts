import * as fs from 'fs';
import * as path from 'path';
import { EXAM_IDS } from '../src/exams';
import { eraseInstall, PeerStore, runDailyAggregation } from '../src/job';
import { PeerSummary } from '../src/aggregate';

class FakeStore implements PeerStore {
  devices = new Map<string, Map<string, unknown>>();
  summaries = new Map<string, PeerSummary>();
  put(examId: string, id: string, data: unknown) {
    if (!this.devices.has(examId)) this.devices.set(examId, new Map());
    this.devices.get(examId)!.set(id, data);
  }
  async listDevices(examId: string) {
    return [...(this.devices.get(examId) ?? new Map()).entries()].map(([id, data]) => ({ id, data }));
  }
  async deleteDevices(examId: string, ids: string[]) {
    ids.forEach((i) => this.devices.get(examId)?.delete(i));
  }
  async deleteDevice(examId: string, id: string) {
    return this.devices.get(examId)?.delete(id) ?? false;
  }
  async writeSummary(examId: string, s: PeerSummary) {
    this.summaries.set(examId, s);
  }
}

const NOW = new Date('2026-10-14T20:00:00Z'); // JST 2026-10-15 05:00

test('日次ジョブ: 要約を書き、60日以上前と壊れたドキュメントを物理削除', async () => {
  const st = new FakeStore();
  for (let i = 0; i < 101; i++) st.put('fe', `a${i}`, { day: '2026-10-14', streakDays: 2, totalQuestions: 10 });
  st.put('fe', 'old', { day: '2026-08-01', streakDays: 2, totalQuestions: 10 });
  st.put('fe', 'bad', { day: '2026-10-14', streakDays: 'x', totalQuestions: 10 });
  const r = await runDailyAggregation(st, ['fe', 'boki3'], NOW);
  expect(r).toEqual({ exams: 2, summaries: 1, deleted: 2 });
  expect(st.devices.get('fe')!.has('old')).toBe(false);
  expect(st.devices.get('fe')!.has('bad')).toBe(false);
  const s = st.summaries.get('fe')!;
  expect(s.participants).toBe(101);
  expect(s.activeToday).toBe(101);
  expect(st.summaries.has('boki3')).toBe(false);
});

test('要約には個人を特定する値が入らない（キーは仕様のものだけ）', async () => {
  const st = new FakeStore();
  for (let i = 0; i < 101; i++) st.put('fe', `id${i}`, { day: '2026-10-14', streakDays: 2, totalQuestions: 10, examDate: '2026-12-06' });
  await runDailyAggregation(st, ['fe'], NOW);
  const s = st.summaries.get('fe')!;
  expect(Object.keys(s).sort()).toEqual(
    ['activeToday', 'asOf', 'examDateCounts', 'medianQuestions', 'participants', 'streakCounts', 'totalQuestions']);
  expect(JSON.stringify(s)).not.toMatch(/id\d/);
});

describe('削除 callable の本体', () => {
  test('examId 指定', async () => {
    const st = new FakeStore();
    st.put('fe', 'x', {});
    st.put('boki3', 'x', {});
    expect(await eraseInstall(st, EXAM_IDS, 'x', 'fe')).toBe(1);
    expect(st.devices.get('boki3')!.has('x')).toBe(true);
  });
  test('examId 省略は全資格', async () => {
    const st = new FakeStore();
    st.put('fe', 'x', {});
    st.put('boki3', 'x', {});
    st.put('boki3', 'y', {});
    expect(await eraseInstall(st, EXAM_IDS, 'x')).toBe(2);
    expect(st.devices.get('boki3')!.has('y')).toBe(true);
  });
  test('無ければ 0', async () => expect(await eraseInstall(new FakeStore(), EXAM_IDS, 'x')).toBe(0));
});

test('EXAM_IDS は firestore.rules の examIds() と一致', () => {
  const rules = fs.readFileSync(path.join(__dirname, '../../firebase/firestore.rules'), 'utf8');
  const body = /function examIds\(\) \{\s*return \[([\s\S]*?)\];/.exec(rules)![1];
  const ids = [...body.matchAll(/'([a-z0-9_]+)'/g)].map((m) => m[1]);
  expect([...EXAM_IDS].sort()).toEqual(ids.sort());
});
