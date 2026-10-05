import '../question/question.dart' show QuestionSource;
import '../src/json_util.dart';

/// ストーリー型の体験（決定38）の1章での選択肢1つ。
class StoryChoice {
  const StoryChoice({
    required this.choiceId,
    required this.text,
    required this.isRecommended,
    required this.feedback,
  });

  final String choiceId;
  final String text;

  /// この章で最も適切な選択かどうか。ちょうど1つが true。
  final bool isRecommended;

  /// この選択肢をタップしたあとに見せる解説。
  final String feedback;

  factory StoryChoice.fromJson(Map<String, dynamic> j, String where) {
    return StoryChoice(
      choiceId: reqString(j, 'choiceId', where),
      text: reqString(j, 'text', where),
      isRecommended: j['isRecommended'] == true,
      feedback: reqString(j, 'feedback', where),
    );
  }

  Map<String, dynamic> toJson() => {
        'choiceId': choiceId,
        'text': text,
        'isRecommended': isRecommended,
        'feedback': feedback,
      };
}

/// ストーリー型の体験（決定38）の1章。
class StoryChapter {
  const StoryChapter({
    required this.chapterId,
    required this.situation,
    required this.choices,
  });

  final String chapterId;

  /// この章の状況説明。
  final String situation;

  /// 判断の選択肢。ちょうど1つが [StoryChoice.isRecommended]。
  final List<StoryChoice> choices;

  StoryChoice get recommendedChoice =>
      choices.firstWhere((c) => c.isRecommended);

  factory StoryChapter.fromJson(Map<String, dynamic> j, String where) {
    final chapterId = reqString(j, 'chapterId', where);
    final choices = reqObjectList(j, 'choices', where)
        .map((c) => StoryChoice.fromJson(c, '$where.chapter[$chapterId]'))
        .toList();
    return StoryChapter(
      chapterId: chapterId,
      situation: reqString(j, 'situation', where),
      choices: choices,
    );
  }

  Map<String, dynamic> toJson() => {
        'chapterId': chapterId,
        'situation': situation,
        'choices': choices.map((c) => c.toJson()).toList(),
      };
}

/// ストーリー型の体験（決定38。簿記3級の会社経営モード・乙4の現場の1日
/// モード・G検定のAIプロジェクト経営モードなど複数資格で共用する汎用の
/// 仕組み）の1シナリオ。
///
/// 体験: [chapters] を順に進み、各章の [StoryChapter.situation] に対して
/// [StoryChapter.choices] から判断を選ぶ→選んだ選択肢の [StoryChoice.feedback]
/// で理由を見る→次の章へ。最後の章まで進むと結果を振り返る。
/// シナリオ・会社など具体的な内容はアプリ側のデータ（本クラス）で持ち、
/// 章立て・途中保存・振り返りの仕組みはエンジン（本パッケージ・UIウィ
/// ジェット）側で共通化する。
class StoryScenario {
  const StoryScenario({
    required this.scenarioId,
    required this.examId,
    required this.title,
    required this.description,
    required this.chapters,
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

  /// シナリオの見出し。
  final String title;

  /// シナリオ全体の説明。
  final String description;

  /// 章のリスト。進める順。
  final List<StoryChapter> chapters;

  final QuestionSource source;
  final String sourceRef;
  final String contentVer;
  final bool disabled;

  factory StoryScenario.fromJson(Map<String, dynamic> j) {
    final scenarioId = reqString(j, 'scenarioId', 'storyScenario');
    final where = 'storyScenario[$scenarioId]';

    final sourceName = reqString(j, 'source', where);
    final source = QuestionSource.values.where((s) => s.name == sourceName);
    if (source.isEmpty) {
      fail(where, '"source" は original / statute / licensed のいずれか');
    }

    final chapters = reqObjectList(j, 'chapters', where)
        .map((c) => StoryChapter.fromJson(c, where))
        .toList();

    return StoryScenario(
      scenarioId: scenarioId,
      examId: reqString(j, 'examId', where),
      subjectId: optString(j, 'subjectId', where),
      title: reqString(j, 'title', where),
      description: reqString(j, 'description', where),
      chapters: chapters,
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
        'chapters': chapters.map((c) => c.toJson()).toList(),
        'source': source.name,
        'sourceRef': sourceRef,
        'contentVer': contentVer,
        if (disabled) 'disabled': true,
      };
}
