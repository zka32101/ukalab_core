import 'package:test/test.dart';
import 'package:yourwish_kentei/yourwish_kentei.dart';

Question q(String qid, String subject, {int points = 1}) => Question(
      qid: qid,
      examId: 'sample',
      subjectId: subject,
      topicId: 't',
      prompt: 'p',
      choices: const ['a', 'b'],
      answerIndex: 0,
      explanation: 'e',
      source: QuestionSource.original,
      sourceRef: '自作',
      points: points,
      contentVer: '1',
    );

/// 正解=0。correct に含まれる qid だけ正解を選ぶ。
Map<String, int?> answers(List<Question> qs, Set<String> correct) => {
      for (final x in qs) x.qid: correct.contains(x.qid) ? 0 : 1,
    };

void main() {
  const rule = PassRule(totalPct: 70, subjectMinPct: 60);

  // 計算5問 + 言葉5問 = 10問
  final qs = [
    for (var i = 0; i < 5; i++) q('m$i', 'math'),
    for (var i = 0; i < 5; i++) q('w$i', 'word'),
  ];

  test('合格ラインちょうどで合格（7/10、科目とも60%以上）', () {
    final r = scoreMockExam(
      questions: qs,
      answers: answers(qs, {'m0', 'm1', 'm2', 'm3', 'w0', 'w1', 'w2'}),
      rule: rule,
    );
    expect(r.total.score, 7);
    expect(r.passed, isTrue);
    expect(r.shortBy, 0);
    expect(r.subjectShortfalls, isEmpty);
  });

  test('総合が1点足りない → あと1点で不合格', () {
    final r = scoreMockExam(
      questions: qs,
      answers: answers(qs, {'m0', 'm1', 'm2', 'm3', 'w0', 'w1'}),
      rule: rule,
    );
    expect(r.total.score, 6);
    expect(r.passed, isFalse);
    expect(r.shortBy, 1);
  });

  test('総合は届いても科目が足切り未満なら不合格', () {
    // 計算5/5、言葉2/5(40%) → 総合7/10=70%だが言葉が60%未満
    final r = scoreMockExam(
      questions: qs,
      answers: answers(qs, {'m0', 'm1', 'm2', 'm3', 'm4', 'w0', 'w1'}),
      rule: rule,
    );
    expect(r.total.pct, 70);
    expect(r.shortBy, 0);
    expect(r.passed, isFalse);
    expect(r.failedBySubjectCutoff, isTrue);
    expect(r.subjectShortfalls, {'word': 1}); // 60%=3点に対し2点
  });

  test('足切りなしの試験では総合だけで判定', () {
    final r = scoreMockExam(
      questions: qs,
      answers: answers(qs, {'m0', 'm1', 'm2', 'm3', 'm4', 'w0', 'w1'}),
      rule: const PassRule(totalPct: 70),
    );
    expect(r.passed, isTrue);
  });

  test('配点が異なる問題は点数で集計する', () {
    final weighted = [q('a', 'math', points: 3), q('b', 'math'), q('c', 'word')];
    final r = scoreMockExam(
      questions: weighted,
      answers: answers(weighted, {'a'}),
      rule: const PassRule(totalPct: 60),
    );
    expect(r.total.score, 3);
    expect(r.total.max, 5);
    expect(r.passed, isTrue); // 60%ちょうど（3/5）
    expect(r.bySubject['math']!.max, 4);
  });

  test('未回答は不正解扱い、全問未回答は不合格', () {
    final r = scoreMockExam(questions: qs, answers: const {}, rule: rule);
    expect(r.total.score, 0);
    expect(r.passed, isFalse);
    expect(r.shortBy, 7);
  });

  test('問題が0件のときは不合格・例外なし', () {
    final r = scoreMockExam(questions: const [], answers: const {}, rule: rule);
    expect(r.passed, isFalse);
    expect(r.total.pct, 0);
  });

  test('小数の合格ラインでも整数点で比較（浮動小数の誤差で落とさない）', () {
    expect(requiredScore(60, 30), 18);
    expect(requiredScore(70, 10), 7);
    expect(requiredScore(66.7, 3), 3); // 2.001 → 3
    expect(requiredScore(0, 10), 0);
  });
}
