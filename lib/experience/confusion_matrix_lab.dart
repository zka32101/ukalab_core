import '../question/question.dart' show QuestionSource;
import '../src/json_util.dart';

/// 判断の選択肢1つ（場面でどちらの指標を優先すべきか）。
class ConfusionMatrixOption {
  const ConfusionMatrixOption({
    required this.optionId,
    required this.text,
    required this.isCorrect,
  });

  final String optionId;
  final String text;
  final bool isCorrect;

  factory ConfusionMatrixOption.fromJson(Map<String, dynamic> j, String where) {
    return ConfusionMatrixOption(
      optionId: reqString(j, 'optionId', where),
      text: reqString(j, 'text', where),
      isCorrect: j['isCorrect'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'optionId': optionId,
        'text': text,
        'isCorrect': isCorrect,
      };
}

/// 評価指標ラボ（画期的な機能3）の1場面。
///
/// 体験: 混同行列（[initialTp]・[initialFp]・[initialFn]・[initialTn]）の
/// セルを自由に動かして、正解率・適合率・再現率・F値が連動する様子を見る→
/// [title]・[description] の場面で「偽陽性と偽陰性のどちらが重いか」を
/// [options] から選ぶ→正解すると [explanation] を見る。
class ConfusionMatrixScenario {
  const ConfusionMatrixScenario({
    required this.scenarioId,
    required this.examId,
    required this.title,
    required this.description,
    required this.initialTp,
    required this.initialFp,
    required this.initialFn,
    required this.initialTn,
    required this.options,
    required this.explanation,
    required this.source,
    required this.sourceRef,
    required this.contentVer,
    this.subjectId,
    this.disabled = false,
  });

  final String scenarioId;
  final String examId;

  /// null なら分野を問わない。
  final String? subjectId;

  final String title;
  final String description;

  final int initialTp;
  final int initialFp;
  final int initialFn;
  final int initialTn;

  /// 判断の選択肢。ちょうど1つが正解。
  final List<ConfusionMatrixOption> options;

  final String explanation;

  final QuestionSource source;
  final String sourceRef;
  final String contentVer;
  final bool disabled;

  ConfusionMatrixOption get correctOption =>
      options.firstWhere((o) => o.isCorrect);

  factory ConfusionMatrixScenario.fromJson(Map<String, dynamic> j) {
    final scenarioId = reqString(j, 'scenarioId', 'confusionMatrixScenario');
    final where = 'confusionMatrixScenario[$scenarioId]';

    final sourceName = reqString(j, 'source', where);
    final source = QuestionSource.values.where((s) => s.name == sourceName);
    if (source.isEmpty) {
      fail(where, '"source" は original / statute / licensed のいずれか');
    }

    final options = reqObjectList(j, 'options', where)
        .map((o) => ConfusionMatrixOption.fromJson(o, where))
        .toList();

    return ConfusionMatrixScenario(
      scenarioId: scenarioId,
      examId: reqString(j, 'examId', where),
      subjectId: optString(j, 'subjectId', where),
      title: reqString(j, 'title', where),
      description: reqString(j, 'description', where),
      initialTp: reqInt(j, 'initialTp', where),
      initialFp: reqInt(j, 'initialFp', where),
      initialFn: reqInt(j, 'initialFn', where),
      initialTn: reqInt(j, 'initialTn', where),
      options: options,
      explanation: reqString(j, 'explanation', where),
      source: source.first,
      sourceRef: reqString(j, 'sourceRef', where),
      contentVer: reqString(j, 'contentVer', where),
      disabled: j['disabled'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'scenarioId': scenarioId,
        'examId': examId,
        if (subjectId != null) 'subjectId': subjectId,
        'title': title,
        'description': description,
        'initialTp': initialTp,
        'initialFp': initialFp,
        'initialFn': initialFn,
        'initialTn': initialTn,
        'options': options.map((o) => o.toJson()).toList(),
        'explanation': explanation,
        'source': source.name,
        'sourceRef': sourceRef,
        'contentVer': contentVer,
        if (disabled) 'disabled': true,
      };
}
