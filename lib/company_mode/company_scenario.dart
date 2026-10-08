import '../question/question.dart' show JournalAnswer, QuestionSource;
import '../src/json_util.dart';

/// 会社経営モード（決定: 2026-10-08、ukalab-boki3の企画ドラフト
/// `docs/company_mode_v1_design.md`）の1ターン分の取引イベント。
///
/// 仕訳の入力・採点は既存の [JournalAnswer]・`judgeJournal` をそのまま使う
/// （ロールプレイの文脈を [eventText] で添えるだけで、新しい採点ロジックは
/// 要らない）。
class CompanyTurn {
  const CompanyTurn({
    required this.turnId,
    required this.eventText,
    required this.answer,
    required this.explanation,
  });

  final String turnId;

  /// 取引イベント文（例:「商品10万円を仕入れ、代金は掛けとした」）。
  final String eventText;

  final JournalAnswer answer;
  final String explanation;

  factory CompanyTurn.fromJson(Map<String, dynamic> j, String where) {
    final turnId = reqString(j, 'turnId', where);
    final turnWhere = '$where.turn[$turnId]';
    final answerRaw = j['answer'];
    if (answerRaw is! List) fail(turnWhere, '"answer" は配列が必要です');
    return CompanyTurn(
      turnId: turnId,
      eventText: reqString(j, 'eventText', turnWhere),
      answer: JournalAnswer.fromJson(answerRaw, '$turnWhere.answer'),
      explanation: reqString(j, 'explanation', turnWhere),
    );
  }

  Map<String, dynamic> toJson() => {
        'turnId': turnId,
        'eventText': eventText,
        'answer': answer.toJson(),
        'explanation': explanation,
      };
}

/// 会社経営モードの1シナリオ（業種・初期状態・ターンの流れ）。
///
/// 1シナリオ＝固定ターン数の取引を順番に処理し、最終的に累積の財務諸表を
/// 完成させるロールプレイ。財務諸表の集計（勘定科目グループの判定が要る）は
/// 科目マスタを持つアプリ側の責務とし、ここではデータモデルのみを持つ。
class CompanyScenario {
  const CompanyScenario({
    required this.scenarioId,
    required this.examId,
    required this.companyName,
    required this.industry,
    required this.introText,
    required this.initialCapital,
    required this.turns,
    required this.source,
    required this.sourceRef,
    required this.contentVer,
    this.disabled = false,
  });

  final String scenarioId;
  final String examId;

  /// 会社名（例:「カフェどんぐり」）。
  final String companyName;

  /// 表示用の業種ラベル（例:「飲食業」）。
  final String industry;

  /// シナリオ開始時の導入文。
  final String introText;

  /// 初期資本金（円）。0より大きい必要がある。
  final int initialCapital;

  /// 取引ターン（最終集計ターンは含まない。`turns.length` がターン数）。
  final List<CompanyTurn> turns;

  final QuestionSource source;
  final String sourceRef;
  final String contentVer;
  final bool disabled;

  factory CompanyScenario.fromJson(Map<String, dynamic> j) {
    final scenarioId = reqString(j, 'scenarioId', 'companyScenario');
    final where = 'companyScenario[$scenarioId]';

    final sourceName = reqString(j, 'source', where);
    final source = QuestionSource.values.where((s) => s.name == sourceName);
    if (source.isEmpty) {
      fail(where, '"source" は original / statute / licensed のいずれか');
    }

    final turnsRaw = reqObjectList(j, 'turns', where);
    final turns = [
      for (var i = 0; i < turnsRaw.length; i++) CompanyTurn.fromJson(turnsRaw[i], '$where[$i]'),
    ];

    return CompanyScenario(
      scenarioId: scenarioId,
      examId: reqString(j, 'examId', where),
      companyName: reqString(j, 'companyName', where),
      industry: reqString(j, 'industry', where),
      introText: reqString(j, 'introText', where),
      initialCapital: reqInt(j, 'initialCapital', where),
      turns: turns,
      source: source.first,
      sourceRef: reqString(j, 'sourceRef', where),
      contentVer: reqString(j, 'contentVer', where),
      disabled: j['disabled'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'scenarioId': scenarioId,
        'examId': examId,
        'companyName': companyName,
        'industry': industry,
        'introText': introText,
        'initialCapital': initialCapital,
        'turns': [for (final t in turns) t.toJson()],
        'source': source.name,
        'sourceRef': sourceRef,
        'contentVer': contentVer,
        if (disabled) 'disabled': true,
      };
}
