import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:yourwish_kentei/yourwish_kentei.dart';

final exam = ExamConfig.fromJson(
  jsonDecode(File('example/sample_exam.json').readAsStringSync())
      as Map<String, dynamic>,
);

const _defaultTokens = ['猫', 'が', '魚', 'を', '食べた'];
const _defaultAttention = [
  [0.6, 0.1, 0.1, 0.05, 0.15],
  [0.5, 0.3, 0.05, 0.05, 0.1],
  [0.1, 0.05, 0.55, 0.15, 0.15],
  [0.05, 0.05, 0.5, 0.3, 0.1],
  [0.35, 0.05, 0.35, 0.05, 0.2],
];

AttentionVizScenario scenario({
  String scenarioId = 's1',
  String examId = 'sample',
  String? subjectId = 'math',
  String title = 'Attention',
  String description = '誰が何を食べたかに注目する。',
  List<String> tokens = _defaultTokens,
  List<List<double>> attention = _defaultAttention,
  QuestionSource source = QuestionSource.original,
  String sourceRef = '自作（教育用の仮データ）',
  String contentVer = '1',
}) =>
    AttentionVizScenario(
      scenarioId: scenarioId,
      examId: examId,
      subjectId: subjectId,
      title: title,
      description: description,
      tokens: tokens,
      attention: attention,
      source: source,
      sourceRef: sourceRef,
      contentVer: contentVer,
    );

Set<String> codes(List<ContentIssue> issues) => {for (final i in issues) i.code};

void main() {
  test('正しい場面は指摘なし', () {
    expect(validateAttentionVizScenarios([scenario()], exam: exam), isEmpty);
  });

  test('scenarioId の重複', () {
    expect(
      codes(validateAttentionVizScenarios([scenario(), scenario()])),
      contains('duplicate-id'),
    );
  });

  group('必須項目', () {
    test('description が空', () {
      expect(
        codes(validateAttentionVizScenarios([scenario(description: ' ')])),
        contains('empty-description'),
      );
    });
    test('sourceRef が空', () {
      expect(
        codes(validateAttentionVizScenarios([scenario(sourceRef: ' ')])),
        contains('no-source'),
      );
    });
    test('contentVer が空', () {
      expect(
        codes(validateAttentionVizScenarios([scenario(contentVer: '')])),
        contains('no-content-ver'),
      );
    });
  });

  group('注意行列', () {
    test('トークンが2語以下では不足', () {
      expect(
        codes(validateAttentionVizScenarios([
          scenario(tokens: const ['猫', 'が'], attention: const [
            [0.5, 0.5],
            [0.5, 0.5],
          ]),
        ])),
        contains('too-few-tokens'),
      );
    });

    test('行数がtokens数と不一致', () {
      expect(
        codes(validateAttentionVizScenarios([
          scenario(attention: _defaultAttention.sublist(0, 4)),
        ])),
        contains('matrix-size-mismatch'),
      );
    });

    test('列数がtokens数と不一致', () {
      expect(
        codes(validateAttentionVizScenarios([
          scenario(attention: [
            [0.6, 0.1, 0.1, 0.05, 0.15],
            [0.5, 0.3, 0.05, 0.05, 0.1],
            [0.1, 0.05, 0.55, 0.15, 0.15],
            [0.05, 0.05, 0.5, 0.3, 0.1],
            [0.35, 0.05, 0.35, 0.05],
          ]),
        ])),
        contains('matrix-size-mismatch'),
      );
    });

    test('値が範囲外', () {
      expect(
        codes(validateAttentionVizScenarios([
          scenario(attention: [
            [1.5, -0.5, 0, 0, 0],
            [0.5, 0.3, 0.05, 0.05, 0.1],
            [0.1, 0.05, 0.55, 0.15, 0.15],
            [0.05, 0.05, 0.5, 0.3, 0.1],
            [0.35, 0.05, 0.35, 0.05, 0.2],
          ]),
        ])),
        contains('out-of-range'),
      );
    });

    test('行の合計が1.0から大きく外れる', () {
      expect(
        codes(validateAttentionVizScenarios([
          scenario(attention: [
            [0.1, 0.1, 0.1, 0.05, 0.05],
            [0.5, 0.3, 0.05, 0.05, 0.1],
            [0.1, 0.05, 0.55, 0.15, 0.15],
            [0.05, 0.05, 0.5, 0.3, 0.1],
            [0.35, 0.05, 0.35, 0.05, 0.2],
          ]),
        ])),
        contains('row-not-normalized'),
      );
    });
  });

  test('試験定義との整合', () {
    expect(
      codes(validateAttentionVizScenarios([scenario(examId: 'other')], exam: exam)),
      contains('exam-mismatch'),
    );
    expect(
      codes(validateAttentionVizScenarios([scenario(subjectId: 'zzz')], exam: exam)),
      contains('unknown-subject'),
    );
    expect(
      validateAttentionVizScenarios([scenario(subjectId: null)], exam: exam),
      isEmpty,
    );
  });

  group('JSON Lines の読み込み', () {
    test('壊れた行は行番号つきの issue になり、他の行は読み込まれる', () {
      final good = jsonEncode(scenario().toJson());
      final parsed = parseAttentionVizScenariosJsonl('$good\nこれはJSONではない\n\n[1,2]\n');
      expect(parsed.scenarios, hasLength(1));
      expect(parsed.issues.map((i) => i.qid), ['line:2', 'line:4']);
      expect(parsed.issues.every((i) => i.code == 'parse'), isTrue);
    });
  });
}
