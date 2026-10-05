import '../question/question.dart' show QuestionSource;
import '../src/json_util.dart';

/// ニューラルネット組み立て（画期的な機能2）のデータ点1件。
class NnBuilderPoint {
  const NnBuilderPoint({
    required this.x,
    required this.y,
    required this.label,
  });

  /// 座標（0〜10の範囲を想定）。
  final double x;
  final double y;

  /// クラス（0 または 1）。
  final int label;

  factory NnBuilderPoint.fromJson(Map<String, dynamic> j, String where) {
    final label = reqInt(j, 'label', where);
    if (label != 0 && label != 1) {
      fail(where, '"label" は 0 か 1 が必要です');
    }
    return NnBuilderPoint(
      x: reqNum(j, 'x', where),
      y: reqNum(j, 'y', where),
      label: label,
    );
  }

  Map<String, dynamic> toJson() => {'x': x, 'y': y, 'label': label};
}

/// ニューラルネット組み立て（画期的な機能2、決定47の初回直後対象）の
/// 1データセット。
///
/// 体験: 層・ユニット数・活性化関数・学習率を選び、小さなデータで学習曲線
/// （訓練誤差）の変化を見る。ニューラルネットの順伝播・逆伝播（学習）自体
/// はUI層（`NnBuilderWidget`）で行い、ここはデータ点だけを持つ。
class NnBuilderDataset {
  const NnBuilderDataset({
    required this.datasetId,
    required this.examId,
    required this.title,
    required this.description,
    required this.points,
    required this.source,
    required this.sourceRef,
    required this.contentVer,
    this.subjectId,
    this.disabled = false,
  });

  final String datasetId;
  final String examId;

  /// null なら分野を問わない。
  final String? subjectId;

  final String title;
  final String description;

  /// 学習データ点。2クラス分類（label 0/1）。
  final List<NnBuilderPoint> points;

  final QuestionSource source;
  final String sourceRef;
  final String contentVer;
  final bool disabled;

  factory NnBuilderDataset.fromJson(Map<String, dynamic> j) {
    final datasetId = reqString(j, 'datasetId', 'nnBuilderDataset');
    final where = 'nnBuilderDataset[$datasetId]';

    final sourceName = reqString(j, 'source', where);
    final source = QuestionSource.values.where((s) => s.name == sourceName);
    if (source.isEmpty) {
      fail(where, '"source" は original / statute / licensed のいずれか');
    }

    final points = reqObjectList(j, 'points', where)
        .map((p) => NnBuilderPoint.fromJson(p, where))
        .toList();

    return NnBuilderDataset(
      datasetId: datasetId,
      examId: reqString(j, 'examId', where),
      subjectId: optString(j, 'subjectId', where),
      title: reqString(j, 'title', where),
      description: reqString(j, 'description', where),
      points: points,
      source: source.first,
      sourceRef: reqString(j, 'sourceRef', where),
      contentVer: reqString(j, 'contentVer', where),
      disabled: j['disabled'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'datasetId': datasetId,
        'examId': examId,
        if (subjectId != null) 'subjectId': subjectId,
        'title': title,
        'description': description,
        'points': points.map((p) => p.toJson()).toList(),
        'source': source.name,
        'sourceRef': sourceRef,
        'contentVer': contentVer,
        if (disabled) 'disabled': true,
      };
}
