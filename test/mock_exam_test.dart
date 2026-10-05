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

  group('journal型の採点', () {
    final correctAnswer = JournalAnswer(lines: const [
      JournalLine(side: JournalSide.debit, account: 'cash', amount: 1000),
      JournalLine(side: JournalSide.credit, account: 'sales', amount: 1000),
    ]);
    final journalQuestion = Question(
      qid: 'j1',
      examId: 'sample',
      subjectId: 'shiwake',
      topicId: 't',
      prompt: '仕訳せよ',
      type: QuestionType.journal,
      journalAnswer: correctAnswer,
      explanation: 'e',
      source: QuestionSource.original,
      sourceRef: '自作',
      points: 3,
      contentVer: '1',
    );

    test('仕訳が正解なら満点', () {
      final r = scoreMockExam(
        questions: [journalQuestion],
        answers: {
          'j1': const [
            JournalLine(side: JournalSide.debit, account: 'cash', amount: 1000),
            JournalLine(side: JournalSide.credit, account: 'sales', amount: 1000),
          ],
        },
        rule: const PassRule(totalPct: 100),
      );
      expect(r.total.score, 3);
      expect(r.passed, isTrue);
    });

    test('仕訳が不正解なら0点', () {
      final r = scoreMockExam(
        questions: [journalQuestion],
        answers: {
          'j1': const [
            JournalLine(side: JournalSide.debit, account: 'cash', amount: 999),
            JournalLine(side: JournalSide.credit, account: 'sales', amount: 999),
          ],
        },
        rule: const PassRule(totalPct: 60),
      );
      expect(r.total.score, 0);
    });

    test('未回答・型違いは不正解扱い（例外にならない）', () {
      final r1 = scoreMockExam(questions: [journalQuestion], answers: const {}, rule: const PassRule(totalPct: 60));
      expect(r1.total.score, 0);
      final r2 = scoreMockExam(
        questions: [journalQuestion],
        answers: {'j1': 0},
        rule: const PassRule(totalPct: 60),
      );
      expect(r2.total.score, 0);
    });

    test('choice型とjournal型が混在する模試を採点できる', () {
      final choiceQuestion = q('c1', 'riron');
      final r = scoreMockExam(
        questions: [choiceQuestion, journalQuestion],
        answers: {
          'c1': 0,
          'j1': const [
            JournalLine(side: JournalSide.debit, account: 'cash', amount: 1000),
            JournalLine(side: JournalSide.credit, account: 'sales', amount: 1000),
          ],
        },
        rule: const PassRule(totalPct: 100),
      );
      expect(r.total.score, 4); // choice 1点 + journal 3点
      expect(r.passed, isTrue);
    });
  });

  group('worksheet型の採点', () {
    final worksheetQuestion = Question(
      qid: 'w1',
      examId: 'sample',
      subjectId: 'kessan',
      topicId: 't',
      prompt: '精算表を完成させよ',
      type: QuestionType.worksheet,
      worksheetAnswer: const WorksheetAnswer(blankCells: [
        WorksheetCell(
          account: 'depreciation_expense',
          column: WorksheetColumn.incomeStatementDebit,
          amount: 5000,
        ),
      ]),
      explanation: 'e',
      source: QuestionSource.original,
      sourceRef: '自作',
      points: 3,
      contentVer: '1',
    );

    test('全セル正解なら満点', () {
      final r = scoreMockExam(
        questions: [worksheetQuestion],
        answers: {
          'w1': const [
            WorksheetCell(
              account: 'depreciation_expense',
              column: WorksheetColumn.incomeStatementDebit,
              amount: 5000,
            ),
          ],
        },
        rule: const PassRule(totalPct: 100),
      );
      expect(r.total.score, 3);
      expect(r.passed, isTrue);
    });

    test('未回答・型違いは不正解扱い（例外にならない）', () {
      final r1 = scoreMockExam(questions: [worksheetQuestion], answers: const {}, rule: const PassRule(totalPct: 60));
      expect(r1.total.score, 0);
      final r2 = scoreMockExam(
        questions: [worksheetQuestion],
        answers: {'w1': 0},
        rule: const PassRule(totalPct: 60),
      );
      expect(r2.total.score, 0);
    });
  });

  group('ledger型の採点', () {
    final ledgerQuestion = Question(
      qid: 'l1',
      examId: 'sample',
      subjectId: 'choubo',
      topicId: 't',
      prompt: '商品有高帳に記入せよ',
      type: QuestionType.ledger,
      ledgerAnswer: const LedgerAnswer(
        rows: [LedgerRowMeta(rowIndex: 0, date: '4/10', description: '売上げ')],
        blankCells: [
          LedgerCell(
            rowIndex: 0,
            group: LedgerColumnGroup.issue,
            field: LedgerField.amount,
            value: 500,
          ),
        ],
      ),
      explanation: 'e',
      source: QuestionSource.original,
      sourceRef: '自作',
      points: 3,
      contentVer: '1',
    );

    test('全セル正解なら満点', () {
      final r = scoreMockExam(
        questions: [ledgerQuestion],
        answers: {
          'l1': const [
            LedgerCell(
              rowIndex: 0,
              group: LedgerColumnGroup.issue,
              field: LedgerField.amount,
              value: 500,
            ),
          ],
        },
        rule: const PassRule(totalPct: 100),
      );
      expect(r.total.score, 3);
      expect(r.passed, isTrue);
    });

    test('未回答・型違いは不正解扱い（例外にならない）', () {
      final r1 = scoreMockExam(questions: [ledgerQuestion], answers: const {}, rule: const PassRule(totalPct: 60));
      expect(r1.total.score, 0);
      final r2 = scoreMockExam(
        questions: [ledgerQuestion],
        answers: {'l1': 0},
        rule: const PassRule(totalPct: 60),
      );
      expect(r2.total.score, 0);
    });
  });

  group('pickMockExamQuestions', () {
    const levelWithoutCounts = LevelConfig(
      levelId: 'l',
      name: 'レベル',
      questionCount: 6,
      passRule: PassRule(totalPct: 60),
    );
    const levelWithCounts = LevelConfig(
      levelId: 'l',
      name: 'レベル',
      questionCount: 6,
      passRule: PassRule(totalPct: 60),
      subjectQuestionCounts: {'math': 4, 'word': 2},
    );

    test('配分指定が無ければ全体から questionCount 問をランダムに選ぶ', () {
      final picked = pickMockExamQuestions(pool: qs, level: levelWithoutCounts);
      expect(picked.length, 6);
      expect(picked.toSet().length, 6); // 重複なし
    });

    test('配分指定があれば科目ごとに指定数だけ選ぶ', () {
      final picked = pickMockExamQuestions(pool: qs, level: levelWithCounts);
      expect(picked.where((q) => q.subjectId == 'math').length, 4);
      expect(picked.where((q) => q.subjectId == 'word').length, 2);
    });

    test('同じ seed なら同じ出題になる', () {
      final a = pickMockExamQuestions(pool: qs, level: levelWithCounts, seed: 1);
      final b = pickMockExamQuestions(pool: qs, level: levelWithCounts, seed: 1);
      expect(a.map((q) => q.qid).toList(), b.map((q) => q.qid).toList());
    });

    test('無効（disabled）の問題は選ばれない', () {
      final disabled = Question(
        qid: 'm_disabled',
        examId: 'sample',
        subjectId: 'math',
        topicId: 't',
        prompt: 'p',
        choices: const ['a', 'b'],
        answerIndex: 0,
        explanation: 'e',
        source: QuestionSource.original,
        sourceRef: '自作',
        contentVer: '1',
        disabled: true,
      );
      final picked = pickMockExamQuestions(
        pool: [...qs, disabled],
        level: levelWithCounts,
      );
      expect(picked.any((q) => q.qid == 'm_disabled'), isFalse);
    });

    test('科目の問題が足りない場合はあるだけ返す（例外にならない）', () {
      const shortLevel = LevelConfig(
        levelId: 'l',
        name: 'レベル',
        questionCount: 100,
        passRule: PassRule(totalPct: 60),
        subjectQuestionCounts: {'math': 50, 'word': 50},
      );
      final picked = pickMockExamQuestions(pool: qs, level: shortLevel);
      expect(picked.length, 10); // math5 + word5 しかない
    });
  });
}
