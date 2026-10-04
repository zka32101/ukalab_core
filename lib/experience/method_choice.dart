import '../question/question.dart' show QuestionSource;
import '../src/json_util.dart';

/// 手法・モデル・評価指標の選択肢1つ。
class MethodChoiceOption {
  const MethodChoiceOption({
    required this.optionId,
    required this.text,
    required this.isCorrect,
  });

  final String optionId;
  final String text;
  final bool isCorrect;

  factory MethodChoiceOption.fromJson(Map<String, dynamic> j, String where) {
    return MethodChoiceOption(
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

/// 手法の選び方（事例仕分け、画期的な機能6）の1場面。
///
/// 体験: [caseDescription] の事例に対して、適切な手法・モデル・評価指標を
/// [options] から選ぶ→正解すると [explanation] で理由を見る。
class MethodChoiceScenario {
  const MethodChoiceScenario({
    required this.scenarioId,
    required this.examId,
    required this.title,
    required this.caseDescription,
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

  /// 場面の見出し。
  final String title;

  /// 事例の説明。
  final String caseDescription;

  /// 手法・モデル・評価指標の選択肢。ちょうど1つが正解。
  final List<MethodChoiceOption> options;

  /// 正解をタップしたあとに見せる解説（理由）。
  final String explanation;

  final QuestionSource source;
  final String sourceRef;
  final String contentVer;
  final bool disabled;

  MethodChoiceOption get correctOption =>
      options.firstWhere((o) => o.isCorrect);

  factory MethodChoiceScenario.fromJson(Map<String, dynamic> j) {
    final scenarioId = reqString(j, 'scenarioId', 'methodChoiceScenario');
    final where = 'methodChoiceScenario[$scenarioId]';

    final sourceName = reqString(j, 'source', where);
    final source = QuestionSource.values.where((s) => s.name == sourceName);
    if (source.isEmpty) {
      fail(where, '"source" は original / statute / licensed のいずれか');
    }

    final options = reqObjectList(j, 'options', where)
        .map((o) => MethodChoiceOption.fromJson(o, where))
        .toList();

    return MethodChoiceScenario(
      scenarioId: scenarioId,
      examId: reqString(j, 'examId', where),
      subjectId: optString(j, 'subjectId', where),
      title: reqString(j, 'title', where),
      caseDescription: reqString(j, 'caseDescription', where),
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
        'caseDescription': caseDescription,
        'options': options.map((o) => o.toJson()).toList(),
        'explanation': explanation,
        'source': source.name,
        'sourceRef': sourceRef,
        'contentVer': contentVer,
        if (disabled) 'disabled': true,
      };
}
