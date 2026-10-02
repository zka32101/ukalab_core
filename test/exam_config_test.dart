import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:yourwish_kentei/yourwish_kentei.dart';

Map<String, dynamic> sample() =>
    jsonDecode(File('example/sample_exam.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  test('サンプルの試験定義を読み込める', () {
    final exam = ExamConfig.fromJson(sample());
    expect(exam.examId, 'sample');
    expect(exam.audience, Audience.adult);
    expect(exam.subjects.map((s) => s.subjectId), ['math', 'word']);
    final level = exam.level('basic')!;
    expect(level.passRule.totalPct, 70);
    expect(level.passRule.subjectMinPct, 60);
    expect(level.timeLimitSec, 600);
    expect(exam.examDates.single, DateTime(2027, 3, 14));
  });

  test('toJson → fromJson で往復できる', () {
    final exam = ExamConfig.fromJson(sample());
    final again = ExamConfig.fromJson(
      jsonDecode(jsonEncode(exam.toJson())) as Map<String, dynamic>,
    );
    expect(again.toJson(), exam.toJson());
  });

  group('不正な定義は FormatException', () {
    void expectInvalid(String name, void Function(Map<String, dynamic>) mutate) {
      test(name, () {
        final j = sample();
        mutate(j);
        expect(() => ExamConfig.fromJson(j), throwsFormatException);
      });
    }

    expectInvalid('examId が無い', (j) => j.remove('examId'));
    expectInvalid('audience が不正', (j) => j['audience'] = 'teen');
    expectInvalid('subjects が空', (j) => j['subjects'] = <dynamic>[]);
    expectInvalid('subjectId が重複', (j) {
      (j['subjects'] as List<dynamic>).add({'subjectId': 'math', 'name': '重複'});
    });
    expectInvalid('合格ラインが範囲外', (j) {
      ((j['levels'] as List<dynamic>).first as Map<String, dynamic>)['passRule'] =
          {'totalPct': 120};
    });
    expectInvalid('出題数が0', (j) {
      ((j['levels'] as List<dynamic>).first as Map<String, dynamic>)['questionCount'] = 0;
    });
    expectInvalid('試験日が不正', (j) => j['examDates'] = ['明日']);
  });
}
