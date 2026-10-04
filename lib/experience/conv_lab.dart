import '../question/question.dart' show QuestionSource;
import '../src/json_util.dart';

/// 画像認識の中身を見る（画期的な機能4）の1画像。
///
/// 体験: 畳み込みフィルタ（エッジ検出など）を手書き風の数字・図形に当て、
/// 特徴マップの変化を見る。プーリングでの縮小も段階表示する。フィルタの
/// 適用・プーリングの計算自体はUI層（`ConvLabWidget`）で行い、ここは
/// 入力画像のグレースケール格子だけを持つ。
class ConvLabImage {
  const ConvLabImage({
    required this.imageId,
    required this.examId,
    required this.title,
    required this.description,
    required this.grid,
    required this.source,
    required this.sourceRef,
    required this.contentVer,
    this.subjectId,
    this.disabled = false,
  });

  final String imageId;
  final String examId;

  /// null なら分野を問わない。
  final String? subjectId;

  final String title;
  final String description;

  /// 手書き風の数字・図形を表すグレースケールの格子（0.0〜1.0）。
  /// すべての行は同じ長さ（正方形である必要はない）。
  final List<List<double>> grid;

  final QuestionSource source;
  final String sourceRef;
  final String contentVer;
  final bool disabled;

  factory ConvLabImage.fromJson(Map<String, dynamic> j) {
    final imageId = reqString(j, 'imageId', 'convLabImage');
    final where = 'convLabImage[$imageId]';

    final sourceName = reqString(j, 'source', where);
    final source = QuestionSource.values.where((s) => s.name == sourceName);
    if (source.isEmpty) {
      fail(where, '"source" は original / statute / licensed のいずれか');
    }

    final rawGrid = j['grid'];
    if (rawGrid is! List || rawGrid.isEmpty) {
      fail(where, '"grid" は空でない配列が必要です');
    }
    final grid = <List<double>>[
      for (final row in rawGrid)
        if (row is List && row.isNotEmpty)
          [
            for (final v in row)
              if (v is num) v.toDouble() else fail(where, '"grid" の値は数値が必要です'),
          ]
        else
          fail(where, '"grid" の各行は空でない配列が必要です'),
    ];

    return ConvLabImage(
      imageId: imageId,
      examId: reqString(j, 'examId', where),
      subjectId: optString(j, 'subjectId', where),
      title: reqString(j, 'title', where),
      description: reqString(j, 'description', where),
      grid: grid,
      source: source.first,
      sourceRef: reqString(j, 'sourceRef', where),
      contentVer: reqString(j, 'contentVer', where),
      disabled: j['disabled'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'imageId': imageId,
        'examId': examId,
        if (subjectId != null) 'subjectId': subjectId,
        'title': title,
        'description': description,
        'grid': grid,
        'source': source.name,
        'sourceRef': sourceRef,
        'contentVer': contentVer,
        if (disabled) 'disabled': true,
      };
}
