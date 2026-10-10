import 'package:flutter_test/flutter_test.dart';
import 'package:ukalab_core/ukalab_core.dart';

void main() {
  const config = PaceRunConfig(questionCount: 20, timeLimitSec: 840); // 20問×14分
  const runner = PaceRunner(config);

  test('開始直後(経過0秒)は、経過問題数ぶんだけ先行する', () {
    final status = runner.statusAt(answeredCount: 0, elapsed: Duration.zero);
    expect(status.expectedAnswered, 0);
    expect(status.aheadBy, 0);
    expect(status.projectedTotal, 20);
    expect(status.onTrack, isTrue);
  });

  test('ペースどおり(半分の時間で半分の問題)なら、ちょうどのペース', () {
    final status = runner.statusAt(
      answeredCount: 10,
      elapsed: const Duration(seconds: 420),
    );
    expect(status.expectedAnswered, 10);
    expect(status.aheadBy, 0);
    expect(status.projectedTotal, 20);
    expect(status.onTrack, isTrue);
  });

  test('遅れている場合、projectedTotal が問題数を下回り onTrack が false になる', () {
    final status = runner.statusAt(
      answeredCount: 5,
      elapsed: const Duration(seconds: 420),
    );
    expect(status.expectedAnswered, 10);
    expect(status.aheadBy, -5);
    expect(status.projectedTotal, 10);
    expect(status.onTrack, isFalse);
  });

  test('先行している場合、aheadBy が正になる', () {
    final status = runner.statusAt(
      answeredCount: 15,
      elapsed: const Duration(seconds: 420),
    );
    expect(status.expectedAnswered, 10);
    expect(status.aheadBy, 5);
    expect(status.projectedTotal, 30);
    expect(status.onTrack, isTrue);
  });
}
