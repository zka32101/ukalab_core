import '../question/question.dart' show QuestionSource;
import '../src/json_util.dart';

/// 専門用語の解説カード（決定50「専門用語の解説（全アプリ共通）」）。
///
/// 問題・解説文中の専門用語は [termId] で参照する。1か所を直せば、
/// その用語を参照する全ての問題・解説に反映される。
class Term {
  const Term({
    required this.termId,
    required this.examId,
    required this.term,
    required this.headline,
    required this.definition,
    required this.source,
    required this.sourceRef,
    required this.contentVer,
    this.subjectId,
    this.analogy,
    this.commonMistake,
    this.relatedTermIds = const [],
    this.relatedQuestionIds = const [],
    this.diagramId,
    this.era,
    this.license,
    this.lawVersion,
    this.disabled = false,
  });

  final String termId;
  final String examId;

  /// null なら分野を問わず全体の用語集に表示する。
  final String? subjectId;

  /// 見出し語（表記）。
  final String term;

  /// ①ひとことで言うと（中学生にもわかる1文）。
  final String headline;

  /// ②正確な意味（試験で問われる定義）。
  final String definition;

  /// ③たとえ話または身近な例。
  final String? analogy;

  /// ④よくある間違い・紛らわしい用語との違い。
  final String? commonMistake;

  /// ⑤関連用語（タップで移動）。
  final List<String> relatedTermIds;

  /// ⑥関連問題（タップで出題）。
  final List<String> relatedQuestionIds;

  /// 図が役立つ用語に添えるコード描画（SVG）図のID。null なら図なし。
  final String? diagramId;

  /// 用語マップ・AI系譜図（決定41・画期的な機能9）向けの時代区分。
  /// null なら系譜図には出さず用語マップ側のみに表示する。表示順はアプリ側が
  /// 時代区分の一覧で決める（このIDだけでは順序を持たない）。
  final String? era;

  final QuestionSource source;

  /// 出典の説明（条文番号・公式資料名・自作の根拠など）。必須。
  final String sourceRef;

  /// source が licensed のときの許諾の記録。
  final String? license;

  /// source が statute のときの法令の版。
  final String? lawVersion;
  final String contentVer;
  final bool disabled;

  factory Term.fromJson(Map<String, dynamic> j) {
    final termId = reqString(j, 'termId', 'term');
    final where = 'term[$termId]';

    final sourceName = reqString(j, 'source', where);
    final source = QuestionSource.values.where((s) => s.name == sourceName);
    if (source.isEmpty) {
      fail(where, '"source" は original / statute / licensed のいずれか');
    }

    return Term(
      termId: termId,
      examId: reqString(j, 'examId', where),
      subjectId: optString(j, 'subjectId', where),
      term: reqString(j, 'term', where),
      headline: reqString(j, 'headline', where),
      definition: reqString(j, 'definition', where),
      analogy: optString(j, 'analogy', where),
      commonMistake: optString(j, 'commonMistake', where),
      relatedTermIds: _stringList(j, 'relatedTermIds', where),
      relatedQuestionIds: _stringList(j, 'relatedQuestionIds', where),
      diagramId: optString(j, 'diagramId', where),
      era: optString(j, 'era', where),
      source: source.first,
      sourceRef: reqString(j, 'sourceRef', where),
      license: optString(j, 'license', where),
      lawVersion: optString(j, 'lawVersion', where),
      contentVer: reqString(j, 'contentVer', where),
      disabled: j['disabled'] == true,
    );
  }

  static List<String> _stringList(
    Map<String, dynamic> j,
    String key,
    String where,
  ) {
    final v = j[key];
    if (v == null) return const [];
    if (v is! List || v.any((e) => e is! String)) {
      fail(where, '"$key" は文字列の配列が必要です');
    }
    return List<String>.from(v);
  }

  Map<String, dynamic> toJson() => {
        'termId': termId,
        'examId': examId,
        if (subjectId != null) 'subjectId': subjectId,
        'term': term,
        'headline': headline,
        'definition': definition,
        if (analogy != null) 'analogy': analogy,
        if (commonMistake != null) 'commonMistake': commonMistake,
        if (relatedTermIds.isNotEmpty) 'relatedTermIds': relatedTermIds,
        if (relatedQuestionIds.isNotEmpty)
          'relatedQuestionIds': relatedQuestionIds,
        if (diagramId != null) 'diagramId': diagramId,
        if (era != null) 'era': era,
        'source': source.name,
        'sourceRef': sourceRef,
        if (license != null) 'license': license,
        if (lawVersion != null) 'lawVersion': lawVersion,
        'contentVer': contentVer,
        if (disabled) 'disabled': true,
      };
}
