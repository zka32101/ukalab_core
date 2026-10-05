import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:yourwish_kentei/yourwish_kentei.dart';

final exam = ExamConfig.fromJson(
  jsonDecode(File('example/sample_exam.json').readAsStringSync())
      as Map<String, dynamic>,
);

Question q({
  String qid = 'q1',
  String examId = 'sample',
  String? levelId,
  String subjectId = 'math',
  List<String> choices = const ['a', 'b', 'c', 'd'],
  int answerIndex = 0,
  String explanation = '解説',
  QuestionSource source = QuestionSource.original,
  String sourceRef = '自作',
  String? license,
  String? lawVersion,
  int difficulty = 3,
  int points = 1,
  String contentVer = '1',
}) =>
    Question(
      qid: qid,
      examId: examId,
      levelId: levelId,
      subjectId: subjectId,
      topicId: 't',
      prompt: '問題',
      choices: choices,
      answerIndex: answerIndex,
      explanation: explanation,
      source: source,
      sourceRef: sourceRef,
      license: license,
      lawVersion: lawVersion,
      difficulty: difficulty,
      points: points,
      contentVer: contentVer,
    );

Set<String> codes(List<ContentIssue> issues) => {for (final i in issues) i.code};

void main() {
  test('サンプル問題データは検証を通る', () {
    final parsed = parseQuestionsJsonl(
      File('example/sample_questions.jsonl').readAsStringSync(),
    );
    expect(parsed.issues, isEmpty);
    expect(parsed.questions, hasLength(4));
    expect(validateQuestions(parsed.questions, exam: exam), isEmpty);
  });

  test('正しい問題は指摘なし', () {
    expect(validateQuestions([q()], exam: exam), isEmpty);
  });

  test('qid の重複', () {
    expect(codes(validateQuestions([q(), q()])), contains('duplicate-id'));
  });

  group('出典', () {
    test('sourceRef が空', () {
      expect(codes(validateQuestions([q(sourceRef: ' ')])), {'no-source'});
    });
    test('licensed は license が必要', () {
      expect(
        codes(validateQuestions([q(source: QuestionSource.licensed)])),
        {'no-license'},
      );
      expect(
        validateQuestions([q(source: QuestionSource.licensed, license: '許諾済 2026-10-01')]),
        isEmpty,
      );
    });
    test('statute は lawVersion が必要', () {
      expect(
        codes(validateQuestions([q(source: QuestionSource.statute)])),
        {'no-law-version'},
      );
      expect(
        validateQuestions([q(source: QuestionSource.statute, lawVersion: '2026-04')]),
        isEmpty,
      );
    });
  });

  group('選択肢と正解の一意性', () {
    test('選択肢が少なすぎる・多すぎる', () {
      expect(codes(validateQuestions([q(choices: ['a'])])), contains('choice-count'));
      expect(
        codes(validateQuestions([q(choices: List.generate(7, (i) => 'c$i'))])),
        contains('choice-count'),
      );
    });
    test('同じ文面の選択肢（空白違いを含む）', () {
      expect(
        codes(validateQuestions([q(choices: ['a', 'b', 'b ', 'd'])])),
        contains('duplicate-choice'),
      );
    });
    test('空の選択肢', () {
      expect(codes(validateQuestions([q(choices: ['a', '', 'c', 'd'])])),
          contains('empty-choice'));
    });
    test('answerIndex が範囲外', () {
      expect(codes(validateQuestions([q(answerIndex: 4)])), {'answer-range'});
      expect(codes(validateQuestions([q(answerIndex: -1)])), {'answer-range'});
    });
    test('選択肢数の許容範囲を変えられる', () {
      final three = q(choices: ['a', 'b', 'c']);
      expect(
        codes(validateQuestions([three],
            options: const ValidationOptions(minChoices: 4, maxChoices: 4))),
        {'choice-count'},
      );
    });
  });

  test('解説・難易度・配点・contentVer', () {
    expect(codes(validateQuestions([q(explanation: ' ')])), {'empty-explanation'});
    expect(codes(validateQuestions([q(difficulty: 6)])), {'difficulty'});
    expect(codes(validateQuestions([q(points: 0)])), {'points'});
    expect(codes(validateQuestions([q(contentVer: '')])), {'no-content-ver'});
  });

  group('仕訳(journal)の検証', () {
    Question journalQ({
      List<JournalLine> lines = const [
        JournalLine(side: JournalSide.debit, account: 'cash', amount: 1000),
        JournalLine(side: JournalSide.credit, account: 'sales', amount: 1000),
      ],
    }) =>
        Question(
          qid: 'j1',
          examId: 'sample',
          subjectId: 'math',
          topicId: 't',
          prompt: '仕訳せよ',
          type: QuestionType.journal,
          journalAnswer: JournalAnswer(lines: lines),
          explanation: '解説',
          source: QuestionSource.original,
          sourceRef: '自作',
          contentVer: '1',
        );

    test('正しい仕訳は指摘なし', () {
      expect(validateQuestions([journalQ()]), isEmpty);
    });

    test('借方合計と貸方合計が不一致', () {
      expect(
        codes(validateQuestions([
          journalQ(lines: const [
            JournalLine(side: JournalSide.debit, account: 'cash', amount: 1000),
            JournalLine(side: JournalSide.credit, account: 'sales', amount: 900),
          ])
        ])),
        contains('journal-unbalanced'),
      );
    });

    test('行が空', () {
      expect(codes(validateQuestions([journalQ(lines: const [])])), contains('journal-empty'));
    });

    test('金額が0以下', () {
      expect(
        codes(validateQuestions([
          journalQ(lines: const [
            JournalLine(side: JournalSide.debit, account: 'cash', amount: 0),
            JournalLine(side: JournalSide.credit, account: 'sales', amount: 0),
          ])
        ])),
        contains('journal-amount'),
      );
    });

    test('toJson → fromJson で往復できる', () {
      final original = journalQ();
      final again = Question.fromJson(
        jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>,
      );
      expect(again.toJson(), original.toJson());
    });
  });

  group('表埋め(worksheet)の検証', () {
    Question worksheetQ({
      List<WorksheetCell> given = const [
        WorksheetCell(account: 'cash', column: WorksheetColumn.trialBalanceDebit, amount: 100000),
      ],
      List<WorksheetCell> blank = const [
        WorksheetCell(
          account: 'depreciation_expense',
          column: WorksheetColumn.incomeStatementDebit,
          amount: 5000,
        ),
      ],
    }) =>
        Question(
          qid: 'w1',
          examId: 'sample',
          subjectId: 'math',
          topicId: 't',
          prompt: '精算表を完成させよ',
          type: QuestionType.worksheet,
          worksheetAnswer: WorksheetAnswer(givenCells: given, blankCells: blank),
          explanation: '解説',
          source: QuestionSource.original,
          sourceRef: '自作',
          contentVer: '1',
        );

    test('正しい表埋め問題は指摘なし', () {
      expect(validateQuestions([worksheetQ()]), isEmpty);
    });

    test('blankCells が空', () {
      expect(
        codes(validateQuestions([worksheetQ(blank: const [])])),
        contains('worksheet-empty'),
      );
    });

    test('金額が0以下', () {
      expect(
        codes(validateQuestions([
          worksheetQ(blank: const [
            WorksheetCell(
              account: 'depreciation_expense',
              column: WorksheetColumn.incomeStatementDebit,
              amount: 0,
            ),
          ])
        ])),
        contains('worksheet-amount'),
      );
    });

    test('勘定科目が空', () {
      expect(
        codes(validateQuestions([
          worksheetQ(blank: const [
            WorksheetCell(
              account: '',
              column: WorksheetColumn.incomeStatementDebit,
              amount: 5000,
            ),
          ])
        ])),
        contains('worksheet-account'),
      );
    });

    test('givenCells と blankCells で同じセルが重複', () {
      expect(
        codes(validateQuestions([
          worksheetQ(
            given: const [
              WorksheetCell(account: 'cash', column: WorksheetColumn.trialBalanceDebit, amount: 100000),
            ],
            blank: const [
              WorksheetCell(account: 'cash', column: WorksheetColumn.trialBalanceDebit, amount: 999),
            ],
          )
        ])),
        contains('worksheet-duplicate-cell'),
      );
    });

    test('toJson → fromJson で往復できる', () {
      final original = worksheetQ();
      final again = Question.fromJson(
        jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>,
      );
      expect(again.toJson(), original.toJson());
    });
  });

  group('補助簿(ledger)の検証', () {
    Question ledgerQ({
      List<LedgerRowMeta> rows = const [
        LedgerRowMeta(rowIndex: 0, date: '4/1', description: '前月繰越'),
        LedgerRowMeta(rowIndex: 1, date: '4/10', description: '売上げ'),
      ],
      List<LedgerCell> given = const [
        LedgerCell(
          rowIndex: 0,
          group: LedgerColumnGroup.balance,
          field: LedgerField.quantity,
          value: 10,
        ),
      ],
      List<LedgerCell> blank = const [
        LedgerCell(
          rowIndex: 1,
          group: LedgerColumnGroup.issue,
          field: LedgerField.amount,
          value: 500,
        ),
      ],
    }) =>
        Question(
          qid: 'l1',
          examId: 'sample',
          subjectId: 'math',
          topicId: 't',
          prompt: '商品有高帳に記入せよ',
          type: QuestionType.ledger,
          ledgerAnswer: LedgerAnswer(rows: rows, givenCells: given, blankCells: blank),
          explanation: '解説',
          source: QuestionSource.original,
          sourceRef: '自作',
          contentVer: '1',
        );

    test('正しい補助簿問題は指摘なし', () {
      expect(validateQuestions([ledgerQ()]), isEmpty);
    });

    test('blankCells が空', () {
      expect(
        codes(validateQuestions([ledgerQ(blank: const [])])),
        contains('ledger-empty'),
      );
    });

    test('値が0以下', () {
      expect(
        codes(validateQuestions([
          ledgerQ(blank: const [
            LedgerCell(
              rowIndex: 1,
              group: LedgerColumnGroup.issue,
              field: LedgerField.amount,
              value: 0,
            ),
          ])
        ])),
        contains('ledger-value'),
      );
    });

    test('rows に無い rowIndex を参照', () {
      expect(
        codes(validateQuestions([
          ledgerQ(blank: const [
            LedgerCell(
              rowIndex: 99,
              group: LedgerColumnGroup.issue,
              field: LedgerField.amount,
              value: 500,
            ),
          ])
        ])),
        contains('ledger-unknown-row'),
      );
    });

    test('givenCells と blankCells で同じセルが重複', () {
      expect(
        codes(validateQuestions([
          ledgerQ(
            given: const [
              LedgerCell(
                rowIndex: 0,
                group: LedgerColumnGroup.balance,
                field: LedgerField.quantity,
                value: 10,
              ),
            ],
            blank: const [
              LedgerCell(
                rowIndex: 0,
                group: LedgerColumnGroup.balance,
                field: LedgerField.quantity,
                value: 999,
              ),
            ],
          )
        ])),
        contains('ledger-duplicate-cell'),
      );
    });

    test('toJson → fromJson で往復できる', () {
      final original = ledgerQ();
      final again = Question.fromJson(
        jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>,
      );
      expect(again.toJson(), original.toJson());
    });
  });

  test('試験定義との整合', () {
    expect(codes(validateQuestions([q(examId: 'other')], exam: exam)), {'exam-mismatch'});
    expect(codes(validateQuestions([q(subjectId: 'zzz')], exam: exam)), {'unknown-subject'});
    expect(codes(validateQuestions([q(levelId: 'zzz')], exam: exam)), {'unknown-level'});
    // 試験定義を渡さなければ整合は検査しない
    expect(validateQuestions([q(examId: 'other', subjectId: 'zzz')]), isEmpty);
  });

  group('JSON Lines の読み込み', () {
    test('壊れた行は行番号つきの issue になり、他の行は読み込まれる', () {
      const good =
          '{"qid":"a","examId":"sample","subjectId":"math","topicId":"t","prompt":"p","choices":["1","2"],"answerIndex":0,"explanation":"e","source":"original","sourceRef":"自作","contentVer":"1"}';
      final parsed = parseQuestionsJsonl('$good\nこれはJSONではない\n\n[1,2]\n');
      expect(parsed.questions, hasLength(1));
      expect(parsed.issues.map((i) => i.qid), ['line:2', 'line:4']);
      expect(parsed.issues.every((i) => i.code == 'parse'), isTrue);
    });

    test('source が不正だと読み込みエラー', () {
      final parsed = parseQuestionsJsonl(
        '{"qid":"a","examId":"sample","subjectId":"math","topicId":"t","prompt":"p","choices":["1","2"],"answerIndex":0,"explanation":"e","source":"unknown","sourceRef":"x","contentVer":"1"}',
      );
      expect(parsed.questions, isEmpty);
      expect(parsed.issues.single.message, contains('source'));
    });

    test('toJson → fromJson で往復できる', () {
      final original = q(
        levelId: 'basic',
        source: QuestionSource.statute,
        lawVersion: '2026-04',
        points: 2,
      );
      final again = Question.fromJson(
        jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>,
      );
      expect(again.toJson(), original.toJson());
    });
  });
}
