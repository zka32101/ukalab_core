import 'package:flutter_test/flutter_test.dart';
import 'package:ukalab_core/ukalab_core.dart';

final _today = DateTime(2026, 10, 14, 9);

PeerStatsSnapshot _snap({
  int active = 500,
  int participants = 500,
  Map<int, int> streaks = const {1: 300, 5: 150, 30: 50},
  Map<String, int> dates = const {'2026-12-06': 200},
}) =>
    PeerStatsSnapshot(
      asOf: '2026-10-14',
      activeToday: active,
      participants: participants,
      totalQuestions: 123456,
      medianQuestions: 77,
      streakCounts: streaks,
      examDateCounts: dates,
    );

void main() {
  group('閾値（100 人を超えるまで表示しない）', () {
    test('境界 99 / 100 / 101', () {
      expect(PeerStatsPolicy.isVisible(99), isFalse);
      expect(PeerStatsPolicy.isVisible(100), isFalse);
      expect(PeerStatsPolicy.isVisible(101), isTrue);
      expect(PeerStatsPolicy.isVisible(0), isFalse);
    });

    test('今日の学習人数は項目ごとに判定', () {
      for (final (n, shown) in [(99, false), (100, false), (101, true)]) {
        final v = PeerStatsView.from(_snap(active: n, participants: 0, streaks: {}, dates: {}), today: _today);
        expect(v.todayLearners, shown ? n : isNull, reason: '$n');
        expect(v.isEmpty, !shown);
      }
    });

    test('累計・中央値は母数が 101 以上のときだけ', () {
      expect(PeerStatsView.from(_snap(participants: 100), today: _today).totalQuestions, isNull);
      expect(PeerStatsView.from(_snap(participants: 100), today: _today).medianQuestions, isNull);
      final v = PeerStatsView.from(_snap(participants: 101), today: _today);
      expect(v.totalQuestions, 123456);
      expect(v.medianQuestions, 77);
    });

    test('同じ試験日の仲間: 人数 101 以上・試験日が今日以降のときだけ', () {
      PeerStatsView at(int n, DateTime? d) =>
          PeerStatsView.from(_snap(dates: {'2026-12-06': n}), examDate: d, today: _today);
      expect(at(100, DateTime(2026, 12, 6)).examMates, isNull);
      final m = at(101, DateTime(2026, 12, 6)).examMates!;
      expect(m.count, 101);
      expect(m.daysLeft, 53);
      expect(at(101, null).examMates, isNull);
      expect(at(101, DateTime(2026, 12, 7)).examMates, isNull); // その日の集計なし
      expect(at(101, DateTime(2026, 10, 14)).examMates, isNull); // 集計なし（別日）
    });

    test('試験日を過ぎたら仲間は出さない', () {
      final v = PeerStatsView.from(_snap(dates: {'2026-10-01': 500}), examDate: DateTime(2026, 10, 1), today: _today);
      expect(v.examMates, isNull);
    });

    test('snapshot が null なら空', () {
      expect(PeerStatsView.from(null, today: _today).isEmpty, isTrue);
    });

    test('連続日数の母数が 100 以下なら上位 % は出さない', () {
      final v = PeerStatsView.from(_snap(streaks: {1: 60, 5: 40}), streakDays: 5, today: _today);
      expect(v.streakTopPercent, isNull);
      final v2 = PeerStatsView.from(_snap(streaks: {1: 60, 5: 41}), streakDays: 5, today: _today);
      expect(v2.streakTopPercent, isNotNull);
    });
  });

  group('中央値', () {
    test('奇数個', () => expect(PeerStatsPolicy.median([5, 1, 3]), 3));
    test('偶数個は中央2つの平均（切り捨て）', () {
      expect(PeerStatsPolicy.median([4, 1, 3, 2]), 2);
      expect(PeerStatsPolicy.median([10, 20]), 15);
      expect(PeerStatsPolicy.median([1, 2]), 1);
    });
    test('1 個・空・同値', () {
      expect(PeerStatsPolicy.median([7]), 7);
      expect(PeerStatsPolicy.median(<int>[]), 0);
      expect(PeerStatsPolicy.median([2, 2, 2, 2]), 2);
    });
    test('入力を壊さない', () {
      final l = [3, 1, 2];
      PeerStatsPolicy.median(l);
      expect(l, [3, 1, 2]);
    });
  });

  group('連続日数の上位 %', () {
    const counts = {1: 50, 2: 30, 3: 15, 10: 5}; // 計 100
    test('最長は上位 5%（同順位を含む）', () => expect(PeerStatsPolicy.topPercent(10, counts), 5));
    test('中間', () {
      expect(PeerStatsPolicy.topPercent(3, counts), 20);
      expect(PeerStatsPolicy.topPercent(2, counts), 50);
    });
    test('最短（全員以上）は 100%', () => expect(PeerStatsPolicy.topPercent(1, counts), 100));
    test('自分が最長を超えていても 1% 以上', () {
      expect(PeerStatsPolicy.topPercent(11, counts), 1);
      expect(PeerStatsPolicy.topPercent(99, const {1: 1000}), 1);
    });
    test('切り上げ', () => expect(PeerStatsPolicy.topPercent(2, const {1: 2, 2: 1}), 34));
    test('連続 0 日・母数 0 は null', () {
      expect(PeerStatsPolicy.topPercent(0, counts), isNull);
      expect(PeerStatsPolicy.topPercent(-1, counts), isNull);
      expect(PeerStatsPolicy.topPercent(3, const {}), isNull);
    });
    test('下位半分では出さない（50% 超は null）', () {
      final v = PeerStatsView.from(_snap(streaks: {1: 300, 5: 150, 30: 50}), streakDays: 1, today: _today);
      expect(v.streakTopPercent, isNull); // 100%
      final v2 = PeerStatsView.from(_snap(streaks: {1: 300, 5: 150, 30: 50}), streakDays: 5, today: _today);
      expect(v2.streakTopPercent, 40);
      final v3 = PeerStatsView.from(_snap(streaks: {1: 300, 5: 150, 30: 50}), streakDays: 0, today: _today);
      expect(v3.streakTopPercent, isNull);
    });
  });

  group('JSON', () {
    test('往復', () {
      final s = _snap();
      final r = PeerStatsSnapshot.fromJson(s.toJson());
      expect(r.activeToday, 500);
      expect(r.streakCounts, s.streakCounts);
      expect(r.examDateCounts, s.examDateCounts);
      expect(r.medianQuestions, 77);
    });
    test('不正な値は 0 / 空', () {
      final r = PeerStatsSnapshot.fromJson({
        'activeToday': 'x',
        'streakCounts': {'a': 5, '0': 3, '2': -1, '3': 4},
        'examDateCounts': {'2026-12-06': 0},
      });
      expect(r.activeToday, 0);
      expect(r.streakCounts, {3: 4});
      expect(r.examDateCounts, isEmpty);
    });
  });

  group('PeerStatsStrings', () {
    final v = PeerStatsView.from(_snap(), streakDays: 30, examDate: DateTime(2026, 12, 6), today: _today);
    test('ja の行', () {
      final l = PeerStatsStrings.ja.lines(v);
      expect(l, hasLength(4));
      expect(l[0], '今日、500人が学習しています');
      expect(l[1], contains('200人'));
      expect(l[1], contains('あと53日'));
      expect(l[2], contains('123,456問'));
      expect(l[2], contains('中央値'));
      expect(l[3], contains('上位10%'));
    });
    test('en の行', () {
      final l = PeerStatsStrings.en.lines(v);
      expect(l[0], '500 people studied today');
      expect(l[2], contains('123,456'));
    });
    test('3 桁区切り', () {
      expect(PeerStatsStrings.fmt(0), '0');
      expect(PeerStatsStrings.fmt(999), '999');
      expect(PeerStatsStrings.fmt(1000), '1,000');
      expect(PeerStatsStrings.fmt(1234567), '1,234,567');
    });
    test('煽る・比べて責める語を含まない', () {
      const ban = ['負け', '遅れ', '劣', '急いで', '最下位', 'behind', 'lose', 'lazy', 'hurry', 'worst'];
      for (final s in [PeerStatsStrings.ja, PeerStatsStrings.en]) {
        for (final t in s.allTexts) {
          for (final w in ban) {
            expect(t.toLowerCase().contains(w), isFalse, reason: '"$t" contains "$w"');
          }
        }
      }
    });
    test('個人を特定しそうな語を含まない', () {
      for (final t in [...PeerStatsStrings.ja.allTexts, ...PeerStatsStrings.en.allTexts]) {
        expect(t.contains('@'), isFalse);
      }
    });
  });
}
