import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:yourwish_kentei/yourwish_kentei.dart';

/// 乙種第4類の試験定義が、公式の合格基準
/// 「試験科目ごとの成績が、それぞれ60％以上」を正しく表せることを確かめる。
/// 出典: 消防試験研究センター 試験の方法 / 試験科目及び問題数
/// （https://www.shoubo-shiken.or.jp/kikenbutsu/annai/way.html ほか、2026-10-04確認）
ExamConfig otsu4() => ExamConfig.fromJson(
      jsonDecode(File('example/otsu4_exam.json').readAsStringSync())
          as Map<String, dynamic>,
    );

Question q(String qid, String subject) => Question(
      qid: qid,
      examId: 'otsu4',
      subjectId: subject,
      topicId: 't',
      prompt: 'p',
      choices: const ['a', 'b', 'c', 'd', 'e'],
      answerIndex: 0,
      explanation: 'e',
      source: QuestionSource.original,
      sourceRef: '自作',
      contentVer: '1',
    );

/// 科目ごとに先頭 [correct] 問だけ正解した答案で採点する。
MockExamResult score(
  ExamConfig exam, {
  required int law,
  required int phys,
  required int prop,
}) {
  final level = exam.level('otsu4')!;
  final qs = [
    for (var i = 0; i < 15; i++) q('l$i', 'law'),
    for (var i = 0; i < 10; i++) q('p$i', 'phys'),
    for (var i = 0; i < 10; i++) q('r$i', 'prop'),
  ];
  final correctCount = {'law': law, 'phys': phys, 'prop': prop};
  final seen = <String, int>{};
  final answers = <String, int?>{
    for (final x in qs)
      x.qid: (seen[x.subjectId] = (seen[x.subjectId] ?? 0) + 1) <=
              correctCount[x.subjectId]!
          ? 0
          : 1,
  };
  return scoreMockExam(questions: qs, answers: answers, rule: level.passRule);
}

void main() {
  sampleQuestionTests();
  test('試験定義: 35問・2時間・科目別15/10/10', () {
    final exam = otsu4();
    final level = exam.level('otsu4')!;
    expect(level.questionCount, 35);
    expect(level.timeLimitSec, 2 * 60 * 60);
    expect(level.subjectQuestionCounts, {'law': 15, 'phys': 10, 'prop': 10});
    expect(level.passRule.subjectMinPct, 60);
  });

  test('必要得点は 法令9/15・物化6/10・性消6/10', () {
    expect(requiredScore(60, 15), 9);
    expect(requiredScore(60, 10), 6);
  });

  test('各科目ちょうど60%なら合格', () {
    final r = score(otsu4(), law: 9, phys: 6, prop: 6);
    expect(r.passed, isTrue);
    expect(r.subjectShortfalls, isEmpty);
  });

  test('法令が1問足りない(8/15)と、他が満点でも不合格(足切り)', () {
    final r = score(otsu4(), law: 8, phys: 10, prop: 10);
    expect(r.passed, isFalse);
    expect(r.subjectShortfalls, {'law': 1});
    expect(r.failedBySubjectCutoff, isTrue);
  });

  test('物化5/10・性消5/10 はそれぞれ1問不足', () {
    final r = score(otsu4(), law: 15, phys: 5, prop: 5);
    expect(r.passed, isFalse);
    expect(r.subjectShortfalls, {'phys': 1, 'prop': 1});
  });

  test('全問正解は合格、全問不正解は不合格', () {
    expect(score(otsu4(), law: 15, phys: 10, prop: 10).passed, isTrue);
    expect(score(otsu4(), law: 0, phys: 0, prop: 0).passed, isFalse);
  });

  test('模擬試験の出題は科目別15/10/10問', () {
    final exam = otsu4();
    final level = exam.level('otsu4')!;
    final pool = [
      for (var i = 0; i < 30; i++) q('l$i', 'law'),
      for (var i = 0; i < 20; i++) q('p$i', 'phys'),
      for (var i = 0; i < 20; i++) q('r$i', 'prop'),
    ];
    final picked = pickMockExamQuestions(pool: pool, level: level);
    int n(String s) => picked.where((x) => x.subjectId == s).length;
    expect(picked.length, 35);
    expect([n('law'), n('phys'), n('prop')], [15, 10, 10]);
  });
}

void sampleQuestionTests() {
  test('条文に基づくサンプル問題は配信前検証を通り、全て statute・lawVersion付き', () {
    final parsed = parseQuestionsJsonl(
      File('example/otsu4_sample_questions.jsonl').readAsStringSync(),
    );
    expect(parsed.questions, hasLength(15));
    expect(validateQuestions(parsed.questions, exam: otsu4()), isEmpty);
    for (final x in parsed.questions) {
      expect(x.source, QuestionSource.statute);
      expect(x.lawVersion, isNotEmpty);
      expect(x.choices, hasLength(5));
    }
  });
}
