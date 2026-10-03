import '../question/question.dart' show QuestionSource;
import '../src/json_util.dart';

/// 推しの答案を添削（型③、決定76・77）の選択肢1つ。
class MisconceptionOption {
  const MisconceptionOption({
    required this.optionId,
    required this.text,
    required this.isCorrect,
  });

  final String optionId;

  /// 空欄に入れる短い文言。
  final String text;
  final bool isCorrect;

  factory MisconceptionOption.fromJson(Map<String, dynamic> j, String where) {
    return MisconceptionOption(
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

/// 推しの答案添削の1場面（決定76「推しが『よくある誤り』を含む答え・説明を
/// 出す→誤りをタップして正しい部品に差し替える→推しが理解する」）。
///
/// [statementTemplate] は `{blank}` を1つ含む文。推しは最初、誤った
/// [options] の1つを空欄に入れた状態で答案を出す。正しい選択肢をタップする
/// までは誤りのままで、解説は表示しない。
///
/// 推しの成長（Lv）はこの演出とは別の習得度計算のみに基づく。答案添削は
/// 演出であり、成長そのものには関わらない（決定77）。
class MisconceptionScenario {
  const MisconceptionScenario({
    required this.scenarioId,
    required this.examId,
    required this.title,
    required this.statementTemplate,
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

  /// 場面の見出し（例: "学習用データの収集"）。
  final String title;

  /// `{blank}` を1つ含む文。
  final String statementTemplate;

  /// 選択肢。ちょうど1つが正解。
  final List<MisconceptionOption> options;

  /// 正解をタップしたあとに見せる解説。
  final String explanation;

  final QuestionSource source;
  final String sourceRef;
  final String contentVer;
  final bool disabled;

  MisconceptionOption get correctOption =>
      options.firstWhere((o) => o.isCorrect);

  /// [statementTemplate] の `{blank}` を [option] の文言で埋めた文。
  String statementWith(MisconceptionOption option) =>
      statementTemplate.replaceFirst('{blank}', option.text);

  factory MisconceptionScenario.fromJson(Map<String, dynamic> j) {
    final scenarioId = reqString(j, 'scenarioId', 'misconceptionScenario');
    final where = 'misconceptionScenario[$scenarioId]';

    final sourceName = reqString(j, 'source', where);
    final source = QuestionSource.values.where((s) => s.name == sourceName);
    if (source.isEmpty) {
      fail(where, '"source" は original / statute / licensed のいずれか');
    }

    final options = reqObjectList(j, 'options', where)
        .map((o) => MisconceptionOption.fromJson(o, where))
        .toList();

    return MisconceptionScenario(
      scenarioId: scenarioId,
      examId: reqString(j, 'examId', where),
      subjectId: optString(j, 'subjectId', where),
      title: reqString(j, 'title', where),
      statementTemplate: reqString(j, 'statementTemplate', where),
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
        'statementTemplate': statementTemplate,
        'options': options.map((o) => o.toJson()).toList(),
        'explanation': explanation,
        'source': source.name,
        'sourceRef': sourceRef,
        'contentVer': contentVer,
        if (disabled) 'disabled': true,
      };
}
