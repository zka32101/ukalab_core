import '../src/json_util.dart';

/// 問題タイプ。現時点は選択式のみ（truefalse・numeric・journal 等は後続）。
enum QuestionType { choice }

/// 出典の区分。出典なし（区分なし）の問題は配信しない。
enum QuestionSource { original, statute, licensed }

/// 1問。IDは不変で、削除は [disabled] で表す（解答履歴は残す）。
class Question {
  const Question({
    required this.qid,
    required this.examId,
    required this.subjectId,
    required this.topicId,
    required this.prompt,
    required this.choices,
    required this.answerIndex,
    required this.explanation,
    required this.source,
    required this.sourceRef,
    required this.contentVer,
    this.levelId,
    this.type = QuestionType.choice,
    this.difficulty = 3,
    this.points = 1,
    this.license,
    this.lawVersion,
    this.disabled = false,
  });

  final String qid;
  final String examId;

  /// null なら全ての級で出題対象。
  final String? levelId;
  final String subjectId;
  final String topicId;
  final QuestionType type;
  final String prompt;
  final List<String> choices;
  final int answerIndex;
  final String explanation;

  /// 1〜5。
  final int difficulty;

  /// 配点。
  final int points;
  final QuestionSource source;

  /// 出典の説明（条文番号・公式資料名・自作の根拠など）。必須。
  final String sourceRef;

  /// source が licensed のときの許諾の記録。
  final String? license;

  /// source が statute のときの法令の版。
  final String? lawVersion;
  final String contentVer;
  final bool disabled;

  factory Question.fromJson(Map<String, dynamic> j) {
    final qid = reqString(j, 'qid', 'question');
    final where = 'question[$qid]';

    final typeName = optString(j, 'type', where) ?? 'choice';
    final type = QuestionType.values.where((t) => t.name == typeName);
    if (type.isEmpty) fail(where, '未対応の type: $typeName');

    final sourceName = reqString(j, 'source', where);
    final source = QuestionSource.values.where((s) => s.name == sourceName);
    if (source.isEmpty) {
      fail(where, '"source" は original / statute / licensed のいずれか');
    }

    final rawChoices = j['choices'];
    if (rawChoices is! List || rawChoices.any((c) => c is! String)) {
      fail(where, '"choices" は文字列の配列が必要です');
    }

    return Question(
      qid: qid,
      examId: reqString(j, 'examId', where),
      levelId: optString(j, 'levelId', where),
      subjectId: reqString(j, 'subjectId', where),
      topicId: reqString(j, 'topicId', where),
      type: type.first,
      prompt: reqString(j, 'prompt', where),
      choices: List<String>.from(rawChoices),
      answerIndex: reqInt(j, 'answerIndex', where),
      explanation: reqString(j, 'explanation', where),
      difficulty: optInt(j, 'difficulty', where, 3),
      points: optInt(j, 'points', where, 1),
      source: source.first,
      sourceRef: reqString(j, 'sourceRef', where),
      license: optString(j, 'license', where),
      lawVersion: optString(j, 'lawVersion', where),
      contentVer: reqString(j, 'contentVer', where),
      disabled: j['disabled'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'qid': qid,
        'examId': examId,
        if (levelId != null) 'levelId': levelId,
        'subjectId': subjectId,
        'topicId': topicId,
        'type': type.name,
        'prompt': prompt,
        'choices': choices,
        'answerIndex': answerIndex,
        'explanation': explanation,
        'difficulty': difficulty,
        'points': points,
        'source': source.name,
        'sourceRef': sourceRef,
        if (license != null) 'license': license,
        if (lawVersion != null) 'lawVersion': lawVersion,
        'contentVer': contentVer,
        if (disabled) 'disabled': true,
      };
}
