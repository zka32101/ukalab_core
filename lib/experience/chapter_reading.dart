import '../question/question.dart' show QuestionSource;
import '../src/json_util.dart';

/// 節の種類の許容値。省略は [kReadingSectionText]。
const String kReadingSectionText = 'text';
const String kReadingSectionTable = 'table';
const String kReadingSectionSteps = 'steps';
const String kReadingSectionFigure = 'figure';
const List<String> kReadingSectionKinds = [
  kReadingSectionText,
  kReadingSectionTable,
  kReadingSectionSteps,
  kReadingSectionFigure,
];

/// 表の上限（配信前検証 `validateChapterReadings` で検査する）。
const int kReadingTableMaxColumns = 6;
const int kReadingTableMaxRows = 20;

/// 図の代替テキスト `alt` の最大文字数。
const int kReadingFigureAltMaxLength = 200;

/// 読み物の表（列見出し＋行）。セルは文字列のみ。
class ReadingTable {
  const ReadingTable({required this.columns, required this.rows});

  final List<String> columns;
  final List<List<String>> rows;

  factory ReadingTable.fromJson(Map<String, dynamic> j, String where) {
    final cols = j['columns'];
    final rows = j['rows'];
    if (cols is! List || cols.any((e) => e is! String)) {
      fail(where, '"table.columns" は文字列の配列が必要です');
    }
    if (rows is! List ||
        rows.any((r) => r is! List || r.any((e) => e is! String))) {
      fail(where, '"table.rows" は文字列の配列の配列が必要です');
    }
    return ReadingTable(
      columns: cols.cast<String>(),
      rows: [for (final r in rows) (r as List).cast<String>()],
    );
  }

  Map<String, dynamic> toJson() => {'columns': columns, 'rows': rows};
}

/// 読み物の図。画像は assets 参照の相対パス。[alt] は必須（読み上げに使う）。
class ReadingFigure {
  const ReadingFigure({required this.asset, required this.alt, this.caption});

  /// 例: `assets/readings/ch1_flow.png`。先頭に `/` や `..`、URL は使えない。
  final String asset;
  final String alt;
  final String? caption;

  factory ReadingFigure.fromJson(Map<String, dynamic> j, String where) {
    return ReadingFigure(
      asset: reqString(j, 'asset', where),
      alt: reqString(j, 'alt', where),
      caption: optString(j, 'caption', where),
    );
  }

  Map<String, dynamic> toJson() => {
    'asset': asset,
    'alt': alt,
    if (caption != null) 'caption': caption,
  };
}

/// 章ごとの解説読み物の1節。
///
/// 従来は見出し＋本文のみ。任意で [kind]（`text`｜`table`｜`steps`｜`figure`、
/// 省略は `text`）と、kind に応じた [table]・[steps]・[figure] を持てる。
/// 追加フィールドは未指定なら JSON に出力せず、従来の JSON と往復で一致する。
/// [body] は kind が `text` のときだけ必須（検証で検査）で、それ以外では補足として任意。
class ReadingSection {
  const ReadingSection({
    required this.heading,
    this.body = '',
    this.kind = kReadingSectionText,
    this.table,
    this.steps,
    this.figure,
  });

  final String heading;
  final String body;

  /// 節の種類。許容値は [kReadingSectionKinds]（未知の値は検証で指摘され、描画は本文にフォールバック）。
  final String kind;
  final ReadingTable? table;
  final List<String>? steps;
  final ReadingFigure? figure;

  factory ReadingSection.fromJson(Map<String, dynamic> j, String where) {
    final kindRaw = j['kind'];
    if (kindRaw != null && kindRaw is! String) {
      fail(where, '"kind" は文字列が必要です');
    }
    final kind = (kindRaw as String?) ?? kReadingSectionText;

    final tableJson = j['table'];
    if (tableJson != null && tableJson is! Map<String, dynamic>) {
      fail(where, '"table" はオブジェクトが必要です');
    }
    final figureJson = j['figure'];
    if (figureJson != null && figureJson is! Map<String, dynamic>) {
      fail(where, '"figure" はオブジェクトが必要です');
    }
    final stepsJson = j['steps'];
    if (stepsJson != null &&
        (stepsJson is! List || stepsJson.any((e) => e is! String))) {
      fail(where, '"steps" は文字列の配列が必要です');
    }

    // 従来形式（kind 省略/text）は body 必須のまま。それ以外は任意。
    final String body;
    if (kind == kReadingSectionText) {
      body = reqString(j, 'body', where);
    } else {
      body = optString(j, 'body', where) ?? '';
    }
    return ReadingSection(
      heading: reqString(j, 'heading', where),
      body: body,
      kind: kind,
      table: tableJson == null
          ? null
          : ReadingTable.fromJson(tableJson as Map<String, dynamic>, where),
      steps: (stepsJson as List?)?.cast<String>(),
      figure: figureJson == null
          ? null
          : ReadingFigure.fromJson(figureJson as Map<String, dynamic>, where),
    );
  }

  Map<String, dynamic> toJson() => {
    'heading': heading,
    if (kind != kReadingSectionText) 'kind': kind,
    if (kind == kReadingSectionText || body.isNotEmpty) 'body': body,
    if (table != null) 'table': table!.toJson(),
    if (steps != null) 'steps': steps,
    if (figure != null) 'figure': figure!.toJson(),
  };
}

/// 章ごとの解説読み物（教科書的なまとめページ）。
///
/// 用語の暗記だけでなく、章の学習項目を体系的に読める記事を提供する。
/// 問題・解説文中の用語と同じく [relatedTermIds]・[relatedQuestionIds] で
/// 用語カード・関連問題に繋げる。
class ChapterReading {
  const ChapterReading({
    required this.readingId,
    required this.examId,
    required this.subjectId,
    required this.title,
    required this.sections,
    required this.source,
    required this.sourceRef,
    required this.contentVer,
    this.relatedTermIds = const [],
    this.relatedQuestionIds = const [],
    this.disabled = false,
  });

  final String readingId;
  final String examId;

  /// 対象の章（ExamConfig の subjectId）。
  final String subjectId;

  /// 章の見出し（例: 「3 機械学習の概要」）。
  final String title;

  /// 節（見出し＋本文）の並び。
  final List<ReadingSection> sections;

  final List<String> relatedTermIds;
  final List<String> relatedQuestionIds;

  final QuestionSource source;
  final String sourceRef;
  final String contentVer;
  final bool disabled;

  factory ChapterReading.fromJson(Map<String, dynamic> j) {
    final readingId = reqString(j, 'readingId', 'chapterReading');
    final where = 'chapterReading[$readingId]';

    final sourceName = reqString(j, 'source', where);
    final source = QuestionSource.values.where((s) => s.name == sourceName);
    if (source.isEmpty) {
      fail(where, '"source" は original / statute / licensed のいずれか');
    }

    final sectionsJson = j['sections'];
    if (sectionsJson is! List || sectionsJson.isEmpty) {
      fail(where, '"sections" は1件以上の配列が必要です');
    }
    final sections = sectionsJson
        .map((s) => ReadingSection.fromJson(s as Map<String, dynamic>, where))
        .toList();

    return ChapterReading(
      readingId: readingId,
      examId: reqString(j, 'examId', where),
      subjectId: reqString(j, 'subjectId', where),
      title: reqString(j, 'title', where),
      sections: sections,
      relatedTermIds: _stringList(j, 'relatedTermIds', where),
      relatedQuestionIds: _stringList(j, 'relatedQuestionIds', where),
      source: source.first,
      sourceRef: reqString(j, 'sourceRef', where),
      contentVer: reqString(j, 'contentVer', where),
      disabled: j['disabled'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'readingId': readingId,
    'examId': examId,
    'subjectId': subjectId,
    'title': title,
    'sections': sections.map((s) => s.toJson()).toList(),
    if (relatedTermIds.isNotEmpty) 'relatedTermIds': relatedTermIds,
    if (relatedQuestionIds.isNotEmpty) 'relatedQuestionIds': relatedQuestionIds,
    'source': source.name,
    'sourceRef': sourceRef,
    'contentVer': contentVer,
    if (disabled) 'disabled': true,
  };

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
    return v.cast<String>();
  }
}
