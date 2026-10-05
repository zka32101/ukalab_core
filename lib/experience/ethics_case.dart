import '../question/question.dart' show QuestionSource;
import '../src/json_util.dart';

/// AI倫理ケース（画期的な機能7）の判断の選択肢1つ。
class EthicsCaseOption {
  const EthicsCaseOption({
    required this.optionId,
    required this.text,
    required this.isCorrect,
  });

  final String optionId;
  final String text;
  final bool isCorrect;

  factory EthicsCaseOption.fromJson(Map<String, dynamic> j, String where) {
    return EthicsCaseOption(
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

/// AI倫理ケース（画期的な機能7）の1場面。
///
/// 体験: [caseDescription] の架空のケースに対して、公平性・プライバシー・
/// 説明責任・著作権などの観点から適切な判断を[options]から選ぶ→正解すると
/// [explanation] で理由を見る。実在の事例を扱う場合は出典明記・運営者確認が
/// 必須（架空のケースを基本とする）。
class EthicsCaseScenario {
  const EthicsCaseScenario({
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

  /// 架空のケースの説明。
  final String caseDescription;

  /// 判断の選択肢。ちょうど1つが正解。
  final List<EthicsCaseOption> options;

  /// 正解をタップしたあとに見せる解説（理由）。
  final String explanation;

  final QuestionSource source;
  final String sourceRef;
  final String contentVer;
  final bool disabled;

  EthicsCaseOption get correctOption =>
      options.firstWhere((o) => o.isCorrect);

  factory EthicsCaseScenario.fromJson(Map<String, dynamic> j) {
    final scenarioId = reqString(j, 'scenarioId', 'ethicsCaseScenario');
    final where = 'ethicsCaseScenario[$scenarioId]';

    final sourceName = reqString(j, 'source', where);
    final source = QuestionSource.values.where((s) => s.name == sourceName);
    if (source.isEmpty) {
      fail(where, '"source" は original / statute / licensed のいずれか');
    }

    final options = reqObjectList(j, 'options', where)
        .map((o) => EthicsCaseOption.fromJson(o, where))
        .toList();

    return EthicsCaseScenario(
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
