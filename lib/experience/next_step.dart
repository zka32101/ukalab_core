import '../src/json_util.dart';

/// 合格後の次の一手: ある試験に合格した人へ提案する関連資格1件。
class NextStepRule {
  const NextStepRule({
    required this.fromExamId,
    required this.toExamId,
    required this.reason,
  });

  final String fromExamId;
  final String toExamId;

  /// 提案の理由（例:「簿記3級の次は、2級で商業簿記を深める」）。
  final String reason;

  factory NextStepRule.fromJson(Map<String, dynamic> j) {
    final from = reqString(j, 'fromExamId', 'nextStep');
    final where = 'nextStep[$from]';
    return NextStepRule(
      fromExamId: from,
      toExamId: reqString(j, 'toExamId', where),
      reason: reqString(j, 'reason', where),
    );
  }

  Map<String, dynamic> toJson() => {
        'fromExamId': fromExamId,
        'toExamId': toExamId,
        'reason': reason,
      };
}

/// [fromExamId] に合格した人へ提案する資格。公開済み（[publishedExamIds]）の資格だけを、
/// 対応表の並び順で返す（未公開の資格は出さない）。同じ提案先は1回だけ。
List<NextStepRule> suggestNextSteps(
  String fromExamId,
  List<NextStepRule> rules,
  Set<String> publishedExamIds,
) {
  final seen = <String>{};
  return [
    for (final r in rules)
      if (r.fromExamId == fromExamId &&
          r.toExamId != fromExamId &&
          publishedExamIds.contains(r.toExamId) &&
          seen.add(r.toExamId))
        r,
  ];
}
