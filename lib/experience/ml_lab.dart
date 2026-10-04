import '../question/question.dart' show QuestionSource;
import '../src/json_util.dart';

/// 機械学習ラボ（画期的な機能1）のデータ点1件。
class MlLabPoint {
  const MlLabPoint({
    required this.x,
    required this.y,
    required this.label,
  });

  /// 座標（0〜10の範囲を想定）。
  final double x;
  final double y;

  /// クラス（0 または 1）。
  final int label;

  factory MlLabPoint.fromJson(Map<String, dynamic> j, String where) {
    final label = reqInt(j, 'label', where);
    if (label != 0 && label != 1) {
      fail(where, '"label" は 0 か 1 が必要です');
    }
    return MlLabPoint(
      x: reqNum(j, 'x', where),
      y: reqNum(j, 'y', where),
      label: label,
    );
  }

  Map<String, dynamic> toJson() => {'x': x, 'y': y, 'label': label};
}

/// 機械学習ラボ（画期的な機能1、決定29の章「機械学習の概要」に対応）の
/// 1データセット。
///
/// 体験: 点を置いてk近傍法・決定木・線形分類の境界を見る。ハイパーパラメータ
/// （k、深さ、正則化）のスライダーで過学習・未学習を体験する。分類の計算
/// 自体はUI層（`MlLabWidget`）で行い、ここはデータセットだけを持つ。
class MlLabDataset {
  const MlLabDataset({
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
  final List<MlLabPoint> points;

  final QuestionSource source;
  final String sourceRef;
  final String contentVer;
  final bool disabled;

  factory MlLabDataset.fromJson(Map<String, dynamic> j) {
    final datasetId = reqString(j, 'datasetId', 'mlLabDataset');
    final where = 'mlLabDataset[$datasetId]';

    final sourceName = reqString(j, 'source', where);
    final source = QuestionSource.values.where((s) => s.name == sourceName);
    if (source.isEmpty) {
      fail(where, '"source" は original / statute / licensed のいずれか');
    }

    final points = reqObjectList(j, 'points', where)
        .map((p) => MlLabPoint.fromJson(p, where))
        .toList();

    return MlLabDataset(
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
