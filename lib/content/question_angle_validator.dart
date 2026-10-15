import 'dart:convert';

import '../question/question.dart';
import 'question_validator.dart';

/// 観点（[Question.conceptId] / [Question.angle]）の検査。設計は
/// docs/multi_angle_questions_design.md（フェーズ1）。
///
/// 既定ではすべて警告（[ContentSeverity.warning]）で、終了コードに影響しない。
/// [strictAngles] が true のとき `concept-single-angle` だけエラーにする。
///
/// - `concept-without-angle`: `conceptId` があるのに `angle` が無い。
/// - `concept-single-angle`: 概念あたりの異なる `angle` が 2 未満
///   （`conceptId` を持つ有効な問題だけを対象にする。`disabled` は除外。
///   `angle` の無い問題は観点に数えない）。
///
/// 未知の `angle` の値は読み込み時に [parseQuestionsJsonl] が `angle-unknown`
/// （警告）で指摘する。
///
/// `conceptId` を持つ問題が 1 件も無いデータ（既存データ）では何も返さない。
List<ContentIssue> validateQuestionAngles(
  List<Question> questions, {
  bool strictAngles = false,
}) {
  final issues = <ContentIssue>[];
  final anglesByConcept = <String, Set<QuestionAngle>>{};
  final firstQidByConcept = <String, String>{};

  for (final q in questions) {
    final concept = q.conceptId;
    if (concept == null || q.disabled) continue;
    if (q.angle == null) {
      issues.add(
        ContentIssue(
          q.qid,
          'concept-without-angle',
          'conceptId($concept) があるのに angle がありません',
          severity: ContentSeverity.warning,
        ),
      );
    }
    firstQidByConcept.putIfAbsent(concept, () => q.qid);
    final set = anglesByConcept.putIfAbsent(concept, () => <QuestionAngle>{});
    if (q.angle != null) set.add(q.angle!);
  }

  final concepts = anglesByConcept.keys.toList()..sort();
  for (final c in concepts) {
    final n = anglesByConcept[c]!.length;
    if (n < 2) {
      issues.add(
        ContentIssue(
          c,
          'concept-single-angle',
          '概念 $c の異なる angle が $n 種類です（2 種類以上が望ましい。'
              '例: ${firstQidByConcept[c]}）',
          severity: strictAngles
              ? ContentSeverity.error
              : ContentSeverity.warning,
        ),
      );
    }
  }
  return issues;
}

/// 観点のカバレッジ集計（`validate_content --angle-report`）。
///
/// 対象は有効（`disabled` でない）な問題。分母の「概念」は、有効な問題に現れる
/// `conceptId` の種類（用語データ側の概念総数は含めない）。出力は決定的
/// （キーをソート済み）で、CI の差分で変化が見える。
class AngleCoverageReport {
  const AngleCoverageReport({
    required this.totalQuestions,
    required this.questionsWithConcept,
    required this.questionsWithAngle,
    required this.questionsByAngle,
    required this.concepts,
  });

  /// 有効な問題数。
  final int totalQuestions;

  /// `conceptId` を持つ有効な問題数。
  final int questionsWithConcept;

  /// `angle` を持つ有効な問題数。
  final int questionsWithAngle;

  /// 観点別の問題数（全 [QuestionAngle] をキーに持つ。0 も出す）。
  final Map<QuestionAngle, int> questionsByAngle;

  /// 概念別: conceptId → 観点別の問題数（angle の無い問題は `none` キー扱いで [unspecifiedCounts]）。
  final List<ConceptAngleCoverage> concepts;

  int get conceptCount => concepts.length;

  /// 異なる観点が 2 種類以上の概念数。
  int get conceptsWithMultipleAngles =>
      concepts.where((c) => c.angleCount >= 2).length;

  /// 概念のうち 2 観点以上を持つものの割合（0〜1）。概念が 0 のとき null。
  double? get multiAngleRate =>
      conceptCount == 0 ? null : conceptsWithMultipleAngles / conceptCount;

  /// 有効な問題のうち `conceptId` が付いている割合（0〜1）。問題が 0 のとき null。
  double? get conceptIdRate =>
      totalQuestions == 0 ? null : questionsWithConcept / totalQuestions;

  /// 異なる観点が 2 未満の概念（conceptId 昇順）。
  List<ConceptAngleCoverage> get conceptsBelowTwoAngles => [
    for (final c in concepts)
      if (c.angleCount < 2) c,
  ];

  static AngleCoverageReport fromQuestions(List<Question> questions) {
    final active = [
      for (final q in questions)
        if (!q.disabled) q,
    ];
    final byAngle = {for (final a in QuestionAngle.values) a: 0};
    final perConcept = <String, Map<QuestionAngle, int>>{};
    final unspecified = <String, int>{};
    var withConcept = 0;
    var withAngle = 0;
    for (final q in active) {
      if (q.angle != null) {
        withAngle++;
        byAngle[q.angle!] = byAngle[q.angle!]! + 1;
      }
      final c = q.conceptId;
      if (c == null) continue;
      withConcept++;
      final m = perConcept.putIfAbsent(c, () => <QuestionAngle, int>{});
      if (q.angle == null) {
        unspecified[c] = (unspecified[c] ?? 0) + 1;
      } else {
        m[q.angle!] = (m[q.angle!] ?? 0) + 1;
      }
    }
    final ids = perConcept.keys.toList()..sort();
    return AngleCoverageReport(
      totalQuestions: active.length,
      questionsWithConcept: withConcept,
      questionsWithAngle: withAngle,
      questionsByAngle: byAngle,
      concepts: [
        for (final id in ids)
          ConceptAngleCoverage(
            conceptId: id,
            angleCounts: {
              for (final a in QuestionAngle.values)
                if (perConcept[id]!.containsKey(a)) a: perConcept[id]![a]!,
            },
            unspecifiedCount: unspecified[id] ?? 0,
          ),
      ],
    );
  }

  Map<String, dynamic> toJson() => {
    'totalQuestions': totalQuestions,
    'questionsWithConcept': questionsWithConcept,
    'questionsWithAngle': questionsWithAngle,
    'conceptIdRate': conceptIdRate,
    'conceptCount': conceptCount,
    'conceptsWithMultipleAngles': conceptsWithMultipleAngles,
    'multiAngleRate': multiAngleRate,
    'questionsByAngle': {
      for (final a in QuestionAngle.values) a.name: questionsByAngle[a] ?? 0,
    },
    'concepts': [for (final c in concepts) c.toJson()],
    'conceptsBelowTwoAngles': [
      for (final c in conceptsBelowTwoAngles) c.conceptId,
    ],
  };

  String toJsonString() =>
      '${const JsonEncoder.withIndent('  ').convert(toJson())}\n';

  String toMarkdown() {
    String pct(double? r) =>
        r == null ? '-' : '${(r * 100).toStringAsFixed(1)}%';
    final b = StringBuffer()
      ..writeln('# 観点カバレッジ')
      ..writeln()
      ..writeln('| 項目 | 値 |')
      ..writeln('|---|---|')
      ..writeln('| 有効な問題数 | $totalQuestions |')
      ..writeln(
        '| conceptId 付与 | $questionsWithConcept (${pct(conceptIdRate)}) |',
      )
      ..writeln('| angle 付与 | $questionsWithAngle |')
      ..writeln('| 概念数 | $conceptCount |')
      ..writeln(
        '| 2 観点以上の概念 | $conceptsWithMultipleAngles (${pct(multiAngleRate)}) |',
      )
      ..writeln()
      ..writeln('## 観点別の問題数')
      ..writeln()
      ..writeln('| 観点 | 問題数 |')
      ..writeln('|---|---|');
    for (final a in QuestionAngle.values) {
      b.writeln('| ${a.name} | ${questionsByAngle[a] ?? 0} |');
    }
    b
      ..writeln()
      ..writeln('## 概念別')
      ..writeln();
    if (concepts.isEmpty) {
      b.writeln('conceptId を持つ問題がありません。');
    } else {
      b
        ..writeln(
          '| conceptId | 観点数 | ${QuestionAngle.values.map((a) => a.name).join(' | ')} | angle なし |',
        )
        ..writeln('|---|---|${'---|' * (QuestionAngle.values.length + 1)}');
      for (final c in concepts) {
        b.writeln(
          '| ${c.conceptId} | ${c.angleCount} | '
          '${QuestionAngle.values.map((a) => c.angleCounts[a] ?? 0).join(' | ')} | '
          '${c.unspecifiedCount} |',
        );
      }
    }
    b
      ..writeln()
      ..writeln('## 観点が 2 未満の概念')
      ..writeln();
    final below = conceptsBelowTwoAngles;
    if (below.isEmpty) {
      b.writeln('なし');
    } else {
      for (final c in below) {
        b.writeln('- ${c.conceptId}（${c.angleCount} 観点）');
      }
    }
    return b.toString();
  }
}

/// 概念 1 つ分の観点別の問題数。
class ConceptAngleCoverage {
  const ConceptAngleCoverage({
    required this.conceptId,
    required this.angleCounts,
    required this.unspecifiedCount,
  });

  final String conceptId;

  /// 観点 → 問題数（問題がある観点のみ。[QuestionAngle] の宣言順）。
  final Map<QuestionAngle, int> angleCounts;

  /// `angle` が無い問題数。
  final int unspecifiedCount;

  /// 異なる観点の数。
  int get angleCount => angleCounts.length;

  Map<String, dynamic> toJson() => {
    'conceptId': conceptId,
    'angleCount': angleCount,
    'angles': {for (final e in angleCounts.entries) e.key.name: e.value},
    'unspecified': unspecifiedCount,
  };
}
