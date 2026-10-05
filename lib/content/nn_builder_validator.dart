import 'dart:convert';

import '../config/exam_config.dart';
import '../experience/nn_builder.dart';
import 'question_validator.dart' show ContentIssue;

class ParsedNnBuilderDatasets {
  const ParsedNnBuilderDatasets(this.datasets, this.issues);

  final List<NnBuilderDataset> datasets;

  /// 読み込み（JSON 構文・必須項目）で見つかった問題。
  final List<ContentIssue> issues;
}

/// JSON Lines（1行1データセット）を読む。読めない行は
/// [ParsedNnBuilderDatasets.issues] に入れて続行する。
ParsedNnBuilderDatasets parseNnBuilderDatasetsJsonl(String text) {
  final datasets = <NnBuilderDataset>[];
  final issues = <ContentIssue>[];
  final lines = const LineSplitter().convert(text);
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i].trim();
    if (line.isEmpty || line.startsWith('//')) continue;
    try {
      final decoded = jsonDecode(line);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('1行は JSON オブジェクトが必要です');
      }
      datasets.add(NnBuilderDataset.fromJson(decoded));
    } on FormatException catch (e) {
      issues.add(ContentIssue('line:${i + 1}', 'parse', e.message));
    }
  }
  return ParsedNnBuilderDatasets(datasets, issues);
}

/// 配信前の品質ゲート。データ点が十分あるか、両クラスを含むか、座標が範囲内
/// かなどを検査する。
///
/// [exam] を渡すと、examId・subjectId が試験定義と整合するかも検査する。
List<ContentIssue> validateNnBuilderDatasets(
  List<NnBuilderDataset> datasets, {
  ExamConfig? exam,
}) {
  final issues = <ContentIssue>[];
  void add(NnBuilderDataset d, String code, String message) =>
      issues.add(ContentIssue(d.datasetId, code, message));

  final seenIds = <String>{};
  for (final d in datasets) {
    if (!seenIds.add(d.datasetId)) {
      add(d, 'duplicate-id', 'datasetId が重複しています');
    }

    if (d.description.trim().isEmpty) add(d, 'empty-description', '説明(description)が空です');
    if (d.sourceRef.trim().isEmpty) add(d, 'no-source', '出典の説明がありません');
    if (d.contentVer.trim().isEmpty) add(d, 'no-content-ver', 'contentVer がありません');

    if (d.points.length < 6) {
      add(d, 'too-few-points', 'データ点(points)は6点以上必要です');
    }
    final labels = d.points.map((p) => p.label).toSet();
    if (!labels.contains(0) || !labels.contains(1)) {
      add(d, 'single-class', 'points は両方のクラス(0と1)を含む必要があります');
    }
    for (final p in d.points) {
      if (p.x < 0 || p.x > 10 || p.y < 0 || p.y > 10) {
        add(d, 'out-of-range', '座標は0〜10の範囲が必要です: (${p.x}, ${p.y})');
      }
    }

    if (exam != null) {
      if (d.examId != exam.examId) {
        add(d, 'exam-mismatch', 'examId(${d.examId}) が試験(${exam.examId})と一致しません');
      }
      final subjectId = d.subjectId;
      if (subjectId != null && exam.subject(subjectId) == null) {
        add(d, 'unknown-subject', '未定義の subjectId: $subjectId');
      }
    }
  }
  return issues;
}
