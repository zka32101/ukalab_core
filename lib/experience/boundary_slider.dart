import '../question/question.dart' show QuestionSource;
import '../src/json_util.dart';

/// 境界線スライダー（型①、決定76・77）の二値条件。
///
/// [trueLabel]・[falseLabel] はスライダーの両端に出す短い表示名。
class BoundaryCondition {
  const BoundaryCondition({
    required this.conditionId,
    required this.label,
    required this.trueLabel,
    required this.falseLabel,
  });

  final String conditionId;

  /// 条件の説明（例: "営利目的か"）。
  final String label;
  final String trueLabel;
  final String falseLabel;

  factory BoundaryCondition.fromJson(Map<String, dynamic> j, String where) {
    return BoundaryCondition(
      conditionId: reqString(j, 'conditionId', where),
      label: reqString(j, 'label', where),
      trueLabel: reqString(j, 'trueLabel', where),
      falseLabel: reqString(j, 'falseLabel', where),
    );
  }

  Map<String, dynamic> toJson() => {
        'conditionId': conditionId,
        'label': label,
        'trueLabel': trueLabel,
        'falseLabel': falseLabel,
      };
}

/// 条件の組み合わせ1つに対する結論（決定木の1枝）。
///
/// [conditionValues] は条件の一部だけを指定してよい。場面の評価は配列の
/// 先頭から順に調べ、指定された条件がすべて一致した最初のルールを使う。
class BoundaryRule {
  const BoundaryRule({
    required this.conditionValues,
    required this.conclusion,
    required this.lawReference,
  });

  final Map<String, bool> conditionValues;

  /// 判定結果（例: "私的利用として可（目安）"）。断定を避け「目安」と明示する。
  final String conclusion;

  /// 根拠条文・資料（例: "著作権法30条の4"）。
  final String lawReference;

  bool matches(Map<String, bool> values) {
    for (final entry in conditionValues.entries) {
      if (values[entry.key] != entry.value) return false;
    }
    return true;
  }

  factory BoundaryRule.fromJson(Map<String, dynamic> j, String where) {
    final rawValues = j['conditionValues'];
    if (rawValues is! Map || rawValues.isEmpty) {
      fail(where, '"conditionValues" は空でないオブジェクトが必要です');
    }
    final conditionValues = <String, bool>{};
    rawValues.forEach((k, v) {
      if (v is! bool) fail(where, '"conditionValues.$k" は真偽値が必要です');
      conditionValues[k as String] = v;
    });
    return BoundaryRule(
      conditionValues: conditionValues,
      conclusion: reqString(j, 'conclusion', where),
      lawReference: reqString(j, 'lawReference', where),
    );
  }

  Map<String, dynamic> toJson() => {
        'conditionValues': conditionValues,
        'conclusion': conclusion,
        'lawReference': lawReference,
      };
}

/// 境界線スライダーの1場面（決定76「条件を1つずつ動かし、判定が切り替わる
/// 境目を体験」）。条件をすべて指定すると [evaluate] が当てはまる結論を返す。
///
/// 判定は参考用の「目安」であり、法的な助言ではない（決定77）。
class BoundaryScenario {
  const BoundaryScenario({
    required this.scenarioId,
    required this.examId,
    required this.title,
    required this.conditions,
    required this.rules,
    required this.source,
    required this.sourceRef,
    required this.contentVer,
    this.subjectId,
    this.lawVersion,
    this.disabled = false,
  });

  final String scenarioId;
  final String examId;

  /// null なら分野を問わない。
  final String? subjectId;

  /// 場面の見出し（例: "学習用データの収集"）。
  final String title;
  final List<BoundaryCondition> conditions;

  /// 評価順。最初にマッチしたものを使う。
  final List<BoundaryRule> rules;

  final QuestionSource source;
  final String sourceRef;
  final String? lawVersion;
  final String contentVer;
  final bool disabled;

  /// [values] は全ての [conditions] の conditionId をキーに持つ必要がある。
  /// マッチするルールがなければ null（ルール表の不備）。
  BoundaryRule? evaluate(Map<String, bool> values) {
    for (final rule in rules) {
      if (rule.matches(values)) return rule;
    }
    return null;
  }

  factory BoundaryScenario.fromJson(Map<String, dynamic> j) {
    final scenarioId = reqString(j, 'scenarioId', 'boundaryScenario');
    final where = 'boundaryScenario[$scenarioId]';

    final sourceName = reqString(j, 'source', where);
    final source = QuestionSource.values.where((s) => s.name == sourceName);
    if (source.isEmpty) {
      fail(where, '"source" は original / statute / licensed のいずれか');
    }

    final conditions = reqObjectList(j, 'conditions', where)
        .map((c) => BoundaryCondition.fromJson(c, where))
        .toList();
    final rules = reqObjectList(j, 'rules', where)
        .map((r) => BoundaryRule.fromJson(r, where))
        .toList();

    return BoundaryScenario(
      scenarioId: scenarioId,
      examId: reqString(j, 'examId', where),
      subjectId: optString(j, 'subjectId', where),
      title: reqString(j, 'title', where),
      conditions: conditions,
      rules: rules,
      source: source.first,
      sourceRef: reqString(j, 'sourceRef', where),
      lawVersion: optString(j, 'lawVersion', where),
      contentVer: reqString(j, 'contentVer', where),
      disabled: j['disabled'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'scenarioId': scenarioId,
        'examId': examId,
        if (subjectId != null) 'subjectId': subjectId,
        'title': title,
        'conditions': conditions.map((c) => c.toJson()).toList(),
        'rules': rules.map((r) => r.toJson()).toList(),
        'source': source.name,
        'sourceRef': sourceRef,
        if (lawVersion != null) 'lawVersion': lawVersion,
        'contentVer': contentVer,
        if (disabled) 'disabled': true,
      };
}
