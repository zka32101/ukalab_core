import { bucketStreaks, daysBetween, DeviceDoc, jstDateKey, median, parseDevice, summarize } from '../src/aggregate';

const RUN = '2026-10-15'; // 実行日（JST）。asOf は 2026-10-14
const dev = (o: Partial<DeviceDoc> = {}): DeviceDoc => ({ day: '2026-10-14', streakDays: 1, totalQuestions: 10, ...o });
const many = (n: number, f: (i: number) => Partial<DeviceDoc> = () => ({})) =>
  Array.from({ length: n }, (_, i) => dev(f(i)));

describe('日付', () => {
  test('JST 暦日', () => {
    expect(jstDateKey(new Date('2026-10-14T14:59:59Z'))).toBe('2026-10-14');
    expect(jstDateKey(new Date('2026-10-14T15:00:00Z'))).toBe('2026-10-15');
  });
  test('日数差', () => {
    expect(daysBetween('2026-10-15', '2026-10-14')).toBe(1);
    expect(daysBetween('x', '2026-10-14')).toBeNaN();
  });
});

describe('median（PeerStatsPolicy.median と同じ定義）', () => {
  test.each([
    [[], 0],
    [[5], 5],
    [[3, 1, 2], 2],
    [[1, 2], 1], // (1+2)/2 を切り捨て
    [[1, 2, 3, 10], 2],
  ])('%j -> %d', (v, e) => expect(median(v as number[])).toBe(e));
});

describe('parseDevice', () => {
  test('正常', () => expect(parseDevice({ day: '2026-10-14', streakDays: 3, totalQuestions: 5 })).not.toBeNull());
  test.each([
    [{ day: 'x', streakDays: 3, totalQuestions: 5 }],
    [{ day: '2026-10-14', streakDays: -1, totalQuestions: 5 }],
    [{ day: '2026-10-14', streakDays: 3651, totalQuestions: 5 }],
    [{ day: '2026-10-14', streakDays: 3, totalQuestions: 1000001 }],
    [{ day: '2026-10-14', streakDays: 1.5, totalQuestions: 5 }],
    [null],
  ])('不正は null %j', (raw) => expect(parseDevice(raw)).toBeNull());
  test('不正な examDate は落とす', () =>
    expect(parseDevice({ day: '2026-10-14', streakDays: 0, totalQuestions: 0, examDate: 'soon' })?.examDate).toBeUndefined());
});

describe('summarize 閾値（100 人以下は書かない）', () => {
  test('100 人ちょうどは何も書かない', () => {
    const s = summarize(many(100), RUN);
    expect(s.asOf).toBe('2026-10-14');
    expect(s.activeToday).toBeUndefined();
    expect(s.participants).toBeUndefined();
    expect(s.totalQuestions).toBeUndefined();
    expect(s.medianQuestions).toBeUndefined();
    expect(s.streakCounts).toEqual({});
    expect(s.examDateCounts).toEqual({});
  });
  test('101 人で書く', () => {
    const s = summarize(many(101, (i) => ({ totalQuestions: i })), RUN);
    expect(s.activeToday).toBe(101);
    expect(s.participants).toBe(101);
    expect(s.totalQuestions).toBe((100 * 101) / 2);
    expect(s.medianQuestions).toBe(50);
  });
  test('activeToday と participants は別々に判定', () => {
    const s = summarize([...many(101, () => ({ day: '2026-09-01' })), ...many(50)], RUN);
    expect(s.participants).toBe(151);
    expect(s.activeToday).toBeUndefined();
  });
  test('実行日当日(早朝)の学習も activeToday に入る。未来すぎる日付は除外', () => {
    const s = summarize([...many(60), ...many(41, () => ({ day: '2026-10-15' })), ...many(10, () => ({ day: '2026-10-20' }))], RUN);
    expect(s.activeToday).toBe(101);
    expect(s.participants).toBe(101);
  });
});

describe('古い端末', () => {
  test('59 日前は入り、60 日前は外れる', () => {
    expect(summarize(many(101, () => ({ day: '2026-08-17' })), RUN).participants).toBe(101); // 59 日前
    expect(summarize(many(101, () => ({ day: '2026-08-16' })), RUN).participants).toBeUndefined(); // 60 日前
  });
});

describe('試験日', () => {
  test('101 人以上の日付だけ。過去の日付は出さない', () => {
    const s = summarize(
      [...many(101, () => ({ examDate: '2026-12-06' })), ...many(100, () => ({ examDate: '2027-01-01' })), ...many(150, () => ({ examDate: '2026-10-01' }))],
      RUN,
    );
    expect(s.examDateCounts).toEqual({ '2026-12-06': 101 });
  });
});

describe('連続日数', () => {
  test('合計 100 以下は空', () => expect(bucketStreaks(Array(100).fill(3))).toEqual({}));
  test('0 は数えず、365 に丸める', () => {
    expect(bucketStreaks([...Array(101).fill(400), ...Array(500).fill(0)])).toEqual({ '365': 101 });
  });
  test('100 人以下の区分はまとめて、すべて 101 以上。合計は保たれる', () => {
    const streaks = [...Array(60).fill(10), ...Array(60).fill(9), ...Array(30).fill(2), ...Array(40).fill(1)];
    const b = bucketStreaks(streaks);
    expect(Object.values(b).every((n) => n > 100)).toBe(true);
    expect(Object.values(b).reduce((a, n) => a + n, 0)).toBe(190);
    expect(b).toEqual({ '1': 190 }); // 120 で区分が成立 → 残り 70 は最後の区分にまとめ、キーは最小の 1
  });
  test('十分な人数があれば複数の区分に分かれる', () => {
    const b = bucketStreaks([...Array(120).fill(10), ...Array(130).fill(3), ...Array(10).fill(1)]);
    expect(b).toEqual({ '10': 120, '1': 140 });
  });
  test('残りが 100 以下でも最後の区分にまとめる(値は最小キー)', () => {
    const b = bucketStreaks([...Array(150).fill(5), ...Array(20).fill(1)]);
    expect(b).toEqual({ '1': 170 });
  });
  test('summarize に反映', () => {
    const s = summarize(many(300, (i) => ({ streakDays: 1 + (i % 3) })), RUN);
    expect(Object.values(s.streakCounts).reduce((a, n) => a + n, 0)).toBe(300);
  });
});
