import 'package:test/test.dart';
import 'package:ukalab_core/ukalab_core.dart';

void main() {
  late InMemoryKeyValueStore store;
  late DateTime now;

  UsageQuota quota({
    int? limit = 1,
    QuotaPeriod period = QuotaPeriod.monthly,
    String id = 'q',
  }) =>
      UsageQuota(
        id: id,
        period: period,
        limit: limit,
        store: store,
        clock: () => now,
      );

  setUp(() {
    store = InMemoryKeyValueStore();
    now = DateTime(2026, 10, 2, 9);
  });

  group('UsageQuota', () {
    test('上限まで消費でき、超えると false で状態不変', () async {
      final q = quota(limit: 2);
      expect(q.used, 0);
      expect(q.remaining, 2);
      expect(await q.tryConsume(), isTrue);
      expect(await q.tryConsume(), isTrue);
      expect(q.canUse, isFalse);
      expect(await q.tryConsume(), isFalse);
      expect(q.used, 2);
      expect(q.remaining, 0);
    });

    test('月次は月が変わるとリセット、同じ月の別の日はリセットしない', () async {
      final q = quota();
      expect(await q.tryConsume(), isTrue);
      now = DateTime(2026, 10, 31, 23, 59);
      expect(q.canUse, isFalse);
      now = DateTime(2026, 11, 1);
      expect(q.canUse, isTrue);
      expect(q.used, 0);
    });

    test('日次は日付が変わるとリセット', () async {
      final q = quota(limit: 10, period: QuotaPeriod.daily);
      for (var i = 0; i < 10; i++) {
        expect(await q.tryConsume(), isTrue);
      }
      expect(q.canUse, isFalse);
      now = DateTime(2026, 10, 3, 0, 1);
      expect(q.canUse, isTrue);
      expect(q.remaining, 10);
    });

    test('年が変わる同じ月番号でもリセットされる', () async {
      final q = quota();
      await q.tryConsume();
      now = DateTime(2027, 10, 2);
      expect(q.canUse, isTrue);
    });

    test('limit が null なら無制限（remaining は null）', () async {
      final q = quota(limit: null);
      for (var i = 0; i < 50; i++) {
        expect(await q.tryConsume(), isTrue);
      }
      expect(q.canUse, isTrue);
      expect(q.remaining, isNull);
    });

    test('limit が 0 なら一切使えない', () async {
      final q = quota(limit: 0);
      expect(q.canUse, isFalse);
      expect(await q.tryConsume(), isFalse);
    });

    test('別の id・別の期間とは回数を共有しない', () async {
      final a = quota(id: 'a');
      final b = quota(id: 'b');
      final aDaily = quota(id: 'a', period: QuotaPeriod.daily);
      await a.tryConsume();
      expect(b.canUse, isTrue);
      expect(aDaily.canUse, isTrue);
    });

    test('保存が壊れていても落ちず 0 回として扱う', () {
      store.write('usage_quota.q.monthly', 'garbage');
      expect(quota().used, 0);
      store.write('usage_quota.q.monthly', '2026-10|x');
      expect(quota().used, 0);
    });

    test('同じ保存先を使う別インスタンスに状態が引き継がれる（再起動相当）', () async {
      await quota().tryConsume();
      expect(quota().canUse, isFalse);
    });
  });

  group('FreeTierLimits', () {
    const limits = FreeTierLimits.standard;

    test('既定値（暫定）', () {
      expect(limits.mockExamsPerMonth, 1);
      expect(limits.weakTopicsShown, 3);
      expect(limits.reviewQuestionsPerDay, 10);
      expect(limits.generatedQuestionsPerDay, 10);
    });

    test('無料は模擬試験が月1回、プレミアムは無制限', () async {
      final free = limits.mockExamQuota(isPremium: false, store: store, clock: () => now);
      expect(await free.tryConsume(), isTrue);
      expect(free.canUse, isFalse);

      final premium = limits.mockExamQuota(isPremium: true, store: store, clock: () => now);
      expect(premium.canUse, isTrue, reason: '同じ保存先でもプレミアムは上限なし');
      expect(premium.remaining, isNull);
    });

    test('復習は無料が1日10問、プレミアムは無制限', () async {
      final free = limits.reviewQuota(isPremium: false, store: store, clock: () => now);
      for (var i = 0; i < 10; i++) {
        await free.tryConsume();
      }
      expect(free.canUse, isFalse);
      expect(limits.reviewQuota(isPremium: true, store: store, clock: () => now).canUse, isTrue);
    });

    test('苦手分析の表示数は無料3、プレミアムは全分野(null)', () {
      expect(limits.weakTopicLimit(isPremium: false), 3);
      expect(limits.weakTopicLimit(isPremium: true), isNull);
    });

    test('値を変えられる', () {
      const custom = FreeTierLimits(mockExamsPerMonth: 3, weakTopicsShown: 5);
      expect(custom.mockExamQuota(isPremium: false, store: store).limit, 3);
      expect(custom.weakTopicLimit(isPremium: false), 5);
    });
  });
}
