import 'dart:convert';

import '../config/exam_config.dart';
import '../experience/conv_lab.dart';
import 'question_validator.dart' show ContentIssue;

class ParsedConvLabImages {
  const ParsedConvLabImages(this.images, this.issues);

  final List<ConvLabImage> images;

  /// 読み込み（JSON 構文・必須項目）で見つかった問題。
  final List<ContentIssue> issues;
}

/// JSON Lines（1行1画像）を読む。読めない行は [ParsedConvLabImages.issues]
/// に入れて続行する。
ParsedConvLabImages parseConvLabImagesJsonl(String text) {
  final images = <ConvLabImage>[];
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
      images.add(ConvLabImage.fromJson(decoded));
    } on FormatException catch (e) {
      issues.add(ContentIssue('line:${i + 1}', 'parse', e.message));
    }
  }
  return ParsedConvLabImages(images, issues);
}

/// 配信前の品質ゲート。格子が長方形か、畳み込み・プーリングに十分な大きさ
/// か、値が0.0〜1.0の範囲かなどを検査する。
///
/// [exam] を渡すと、examId・subjectId が試験定義と整合するかも検査する。
List<ContentIssue> validateConvLabImages(
  List<ConvLabImage> images, {
  ExamConfig? exam,
}) {
  final issues = <ContentIssue>[];
  void add(ConvLabImage im, String code, String message) =>
      issues.add(ContentIssue(im.imageId, code, message));

  final seenIds = <String>{};
  for (final im in images) {
    if (!seenIds.add(im.imageId)) {
      add(im, 'duplicate-id', 'imageId が重複しています');
    }

    if (im.description.trim().isEmpty) add(im, 'empty-description', '説明(description)が空です');
    if (im.sourceRef.trim().isEmpty) add(im, 'no-source', '出典の説明がありません');
    if (im.contentVer.trim().isEmpty) add(im, 'no-content-ver', 'contentVer がありません');

    final rowLength = im.grid.first.length;
    final isRectangular = im.grid.every((row) => row.length == rowLength);
    if (!isRectangular) {
      add(im, 'not-rectangular', 'grid の各行の長さが揃っていません');
    }
    if (im.grid.length < 6 || rowLength < 6) {
      add(im, 'too-small', 'grid は畳み込み・プーリングのため6x6以上が必要です');
    }
    for (final row in im.grid) {
      for (final v in row) {
        if (v < 0 || v > 1) {
          add(im, 'out-of-range', 'grid の値は0.0〜1.0の範囲が必要です: $v');
        }
      }
    }

    if (exam != null) {
      if (im.examId != exam.examId) {
        add(im, 'exam-mismatch', 'examId(${im.examId}) が試験(${exam.examId})と一致しません');
      }
      final subjectId = im.subjectId;
      if (subjectId != null && exam.subject(subjectId) == null) {
        add(im, 'unknown-subject', '未定義の subjectId: $subjectId');
      }
    }
  }
  return issues;
}
