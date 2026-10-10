import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ukalab_core/ukalab_core.dart';

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

  group('subjectQuestionCounts（科目別の出題数配分）', () {
    Map<String, dynamic> sampleWithCounts(Map<String, int> counts) {
      final j = sample();
      ((j['levels'] as List<dynamic>).first as Map<String, dynamic>)
          ['subjectQuestionCounts'] = counts;
      return j;
    }

    test('指定すれば読み込め、合計は questionCount と一致する', () {
      final exam = ExamConfig.fromJson(sampleWithCounts({'math': 2, 'word': 2}));
      final level = exam.level('basic')!;
      expect(level.questionCount, 4);
      expect(level.subjectQuestionCounts, {'math': 2, 'word': 2});
    });

    test('指定しなければ null（全体から抽出する従来の挙動）', () {
      final exam = ExamConfig.fromJson(sample());
      expect(exam.level('basic')!.subjectQuestionCounts, isNull);
    });

    test('toJson → fromJson で往復できる', () {
      final exam = ExamConfig.fromJson(sampleWithCounts({'math': 2, 'word': 2}));
      final again = ExamConfig.fromJson(
        jsonDecode(jsonEncode(exam.toJson())) as Map<String, dynamic>,
      );
      expect(again.toJson(), exam.toJson());
    });

    test('合計が questionCount と一致しなければ FormatException', () {
      expect(
        () => ExamConfig.fromJson(sampleWithCounts({'math': 2, 'word': 3})),
        throwsFormatException,
      );
    });

    test('未知の subjectId を含むと FormatException', () {
      expect(
        () => ExamConfig.fromJson(sampleWithCounts({'math': 2, 'nazo': 2})),
        throwsFormatException,
      );
    });

    test('値が0以下だと FormatException', () {
      expect(
        () => ExamConfig.fromJson(sampleWithCounts({'math': 4, 'word': 0})),
        throwsFormatException,
      );
    });
  });
}
