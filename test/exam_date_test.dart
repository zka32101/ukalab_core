import 'package:test/test.dart';
import 'package:ukalab_core/ukalab_core.dart';

void main() {
  group('daysUntilExam', () {
    test('未来の日付なら正の日数', () {
      expect(daysUntilExam(DateTime(2026, 10, 20), DateTime(2026, 10, 6)), 14);
    });

    test('当日は0（時刻は無視する）', () {
      expect(daysUntilExam(DateTime(2026, 10, 6, 9), DateTime(2026, 10, 6, 23, 59)), 0);
    });

    test('過去なら負の値', () {
      expect(daysUntilExam(DateTime(2026, 10, 2), DateTime(2026, 10, 6)), -4);
    });

    test('月をまたいでも日数で数える', () {
      expect(daysUntilExam(DateTime(2026, 11, 1), DateTime(2026, 10, 31)), 1);
    });
  });

  group('examCountdownText', () {
    test('残り日数・当日・経過で文言が変わる', () {
      expect(examCountdownText(14), '本番まであと14日');
      expect(examCountdownText(0), '本番は今日です');
      expect(examCountdownText(-4), '本番から4日経過しました');
    });
  });

  group('studyPlanQuestionsPerDay', () {
    test('残り日数が0以下ならnull（過去・当日）', () {
      expect(studyPlanQuestionsPerDay(daysLeft: 0, remainingQuestions: 100), isNull);
      expect(studyPlanQuestionsPerDay(daysLeft: -3, remainingQuestions: 100), isNull);
    });

    test('未解答が無ければ0', () {
      expect(studyPlanQuestionsPerDay(daysLeft: 10, remainingQuestions: 0), 0);
    });

    test('割り切れる場合はそのまま、割り切れない場合は切り上げ', () {
      expect(studyPlanQuestionsPerDay(daysLeft: 10, remainingQuestions: 100), 10);
      expect(studyPlanQuestionsPerDay(daysLeft: 3, remainingQuestions: 10), 4);
    });
  });
}
