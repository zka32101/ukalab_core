import 'dart:convert';

import 'package:test/test.dart';
import 'package:yourwish_kentei/yourwish_kentei.dart';

MisconceptionScenario scenario({
  String scenarioId = 'm1',
  String examId = 'sample',
  String? subjectId = 'law',
  String title = '学習用データの収集',
  String statementTemplate = 'この学習データの収集は、{blank}だから問題ない',
  List<MisconceptionOption> options = const [
    MisconceptionOption(optionId: 'wrong', text: '非営利', isCorrect: false),
    MisconceptionOption(optionId: 'right', text: '享受目的を含まない', isCorrect: true),
  ],
  String explanation = '著作権法30条の4は享受目的かどうかが要件で、営利/非営利は直接の要件ではない。',
  QuestionSource source = QuestionSource.original,
  String sourceRef = '自作',
  String contentVer = '1',
}) =>
    MisconceptionScenario(
      scenarioId: scenarioId,
      examId: examId,
      subjectId: subjectId,
      title: title,
      statementTemplate: statementTemplate,
      options: options,
      explanation: explanation,
      source: source,
      sourceRef: sourceRef,
      contentVer: contentVer,
    );

void main() {
  test('correctOption は isCorrect:true の選択肢', () {
    expect(scenario().correctOption.optionId, 'right');
  });

  test('statementWith は {blank} を選択肢の文言で埋める', () {
    final s = scenario();
    expect(
      s.statementWith(s.options.first),
      'この学習データの収集は、非営利だから問題ない',
    );
    expect(
      s.statementWith(s.correctOption),
      'この学習データの収集は、享受目的を含まないだから問題ない',
    );
  });

  test('toJson → fromJson で往復できる', () {
    final original = scenario();
    final again = MisconceptionScenario.fromJson(
      jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>,
    );
    expect(again.toJson(), original.toJson());
  });
}
