import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ukalab_core/ukalab_core.dart';

final exam = ExamConfig.fromJson(
  jsonDecode(File('example/sample_exam.json').readAsStringSync()) as Map<String, dynamic>,
);

CompanyTurn turn({
  String turnId = 'turn1',
  String eventText = '現金10万円を元入れした',
  List<JournalLine> lines = const [
    JournalLine(side: JournalSide.debit, account: 'cash', amount: 100000),
    JournalLine(side: JournalSide.credit, account: 'capital_stock', amount: 100000),
  ],
  String explanation = '元入れは資本金の増加として貸方に記録する。',
}) =>
    CompanyTurn(
      turnId: turnId,
      eventText: eventText,
      answer: JournalAnswer(lines: lines),
      explanation: explanation,
    );

CompanyScenario scenario({
  String scenarioId = 's1',
  String examId = 'sample',
  String companyName = 'カフェどんぐり',
  String industry = '飲食業',
  String introText = '開業しました。',
  int initialCapital = 100000,
  List<CompanyTurn> turns = const [],
  QuestionSource source = QuestionSource.original,
  String sourceRef = '自作',
  String contentVer = '1',
}) =>
    CompanyScenario(
      scenarioId: scenarioId,
      examId: examId,
      companyName: companyName,
      industry: industry,
      introText: introText,
      initialCapital: initialCapital,
      turns: turns.isEmpty ? [turn()] : turns,
      source: source,
      sourceRef: sourceRef,
      contentVer: contentVer,
    );

Set<String> codes(List<ContentIssue> issues) => {for (final i in issues) i.code};

void main() {
  test('正しいシナリオは指摘なし', () {
    expect(validateCompanyScenarios([scenario()]), isEmpty);
  });

  test('scenarioId の重複', () {
    expect(
      codes(validateCompanyScenarios([scenario(), scenario()])),
      contains('duplicate-id'),
    );
  });

  group('必須項目', () {
    test('会社名が空', () {
      expect(
        codes(validateCompanyScenarios([scenario(companyName: ' ')])),
        contains('empty-company-name'),
      );
    });
    test('導入文が空', () {
      expect(
        codes(validateCompanyScenarios([scenario(introText: ' ')])),
        contains('empty-intro'),
      );
    });
    test('初期資本金が0以下', () {
      expect(
        codes(validateCompanyScenarios([scenario(initialCapital: 0)])),
        contains('invalid-capital'),
      );
    });
    test('ターンが1件もない', () {
      final empty = CompanyScenario(
        scenarioId: 's2',
        examId: 'sample',
        companyName: 'X',
        industry: 'Y',
        introText: 'Z',
        initialCapital: 1,
        turns: const [],
        source: QuestionSource.original,
        sourceRef: '自作',
        contentVer: '1',
      );
      expect(codes(validateCompanyScenarios([empty])), contains('no-turns'));
    });
    test('contentVer が空', () {
      expect(
        codes(validateCompanyScenarios([scenario(contentVer: '')])),
        contains('no-content-ver'),
      );
    });
    test('sourceRef が空', () {
      expect(
        codes(validateCompanyScenarios([scenario(sourceRef: ' ')])),
        contains('no-source'),
      );
    });
  });

  group('ターンの検査', () {
    test('turnId の重複', () {
      expect(
        codes(validateCompanyScenarios([
          scenario(turns: [turn(turnId: 't1'), turn(turnId: 't1')])
        ])),
        contains('duplicate-turn-id'),
      );
    });
    test('イベント文が空', () {
      expect(
        codes(validateCompanyScenarios([
          scenario(turns: [turn(eventText: ' ')])
        ])),
        contains('empty-event-text'),
      );
    });
    test('解説が空', () {
      expect(
        codes(validateCompanyScenarios([
          scenario(turns: [turn(explanation: ' ')])
        ])),
        contains('empty-turn-explanation'),
      );
    });
    test('仕訳が空', () {
      expect(
        codes(validateCompanyScenarios([
          scenario(turns: [turn(lines: const [])])
        ])),
        contains('empty-journal'),
      );
    });
    test('貸借不一致', () {
      expect(
        codes(validateCompanyScenarios([
          scenario(turns: [
            turn(lines: const [
              JournalLine(side: JournalSide.debit, account: 'cash', amount: 100),
              JournalLine(side: JournalSide.credit, account: 'capital_stock', amount: 200),
            ])
          ])
        ])),
        contains('unbalanced-journal'),
      );
    });
    test('0以下の金額', () {
      expect(
        codes(validateCompanyScenarios([
          scenario(turns: [
            turn(lines: const [
              JournalLine(side: JournalSide.debit, account: 'cash', amount: 0),
              JournalLine(side: JournalSide.credit, account: 'capital_stock', amount: 0),
            ])
          ])
        ])),
        contains('invalid-amount'),
      );
    });
  });

  test('試験定義との整合', () {
    expect(
      codes(validateCompanyScenarios([scenario(examId: 'other')], exam: exam)),
      contains('exam-mismatch'),
    );
    expect(validateCompanyScenarios([scenario(examId: 'sample')], exam: exam), isEmpty);
  });

  group('JSON Lines の読み込み', () {
    test('壊れた行は行番号つきの issue になり、他の行は読み込まれる', () {
      const good =
          '{"scenarioId":"s1","examId":"sample","companyName":"店","industry":"小売業","introText":"開業","initialCapital":1000,"turns":[{"turnId":"t1","eventText":"元入れ","answer":[{"side":"debit","account":"cash","amount":1000},{"side":"credit","account":"capital_stock","amount":1000}],"explanation":"解説"}],"source":"original","sourceRef":"自作","contentVer":"1"}';
      final parsed = parseCompanyScenariosJsonl('$good\nこれはJSONではない\n\n[1,2]\n');
      expect(parsed.scenarios, hasLength(1));
      expect(parsed.issues.map((i) => i.qid), ['line:2', 'line:4']);
      expect(parsed.issues.every((i) => i.code == 'parse'), isTrue);
    });

    test('toJson → fromJson で往復できる', () {
      final original = scenario();
      final again = CompanyScenario.fromJson(
        jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>,
      );
      expect(again.toJson(), original.toJson());
    });
  });
}
