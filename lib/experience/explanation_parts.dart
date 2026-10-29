import 'chapter_reading.dart';

/// 解説文の末尾に付ける「別の場面」の目印（体験型問題で使用済み）。
const String kExplanationOtherSceneMarker = '【別の場面】';

/// 解説を「結論／理由／間違えやすい点／別の場面」に分けた入力。すべて任意。
///
/// 既存の1本文の解説は [ExplanationParts.fromPlain] で作る。本文に
/// [kExplanationOtherSceneMarker] が1つだけあり、前後とも空でなければ、
/// 前を [body]、後ろを [otherScene] に分ける。それ以外（目印なし・複数・片側が空）は
/// 全文を [body] のままにする（パースしない）。
class ExplanationParts {
  const ExplanationParts({
    this.conclusion,
    this.reason,
    this.pitfall,
    this.otherScene,
    this.body,
  });

  factory ExplanationParts.fromPlain(String text) {
    final marker = kExplanationOtherSceneMarker;
    final first = text.indexOf(marker);
    if (first >= 0 && text.indexOf(marker, first + marker.length) < 0) {
      final before = text.substring(0, first).trim();
      final after = text.substring(first + marker.length).trim();
      if (before.isNotEmpty && after.isNotEmpty) {
        return ExplanationParts(body: before, otherScene: after);
      }
    }
    return ExplanationParts(body: text);
  }

  final String? conclusion;
  final String? reason;
  final String? pitfall;
  final String? otherScene;

  /// ラベルなしで先頭に出す本文（`fromPlain` の前半、または従来の1本文）。
  final String? body;

  static bool _has(String? s) => s != null && s.trim().isNotEmpty;

  bool get hasConclusion => _has(conclusion);
  bool get hasReason => _has(reason);
  bool get hasPitfall => _has(pitfall);
  bool get hasOtherScene => _has(otherScene);
  bool get hasBody => _has(body);

  /// 出す項目が1つも無いか。
  bool get isEmpty =>
      !hasConclusion && !hasReason && !hasPitfall && !hasOtherScene && !hasBody;
}

/// 読み物のうち、[questionId] を確認問題にしているもの（`disabled` は除く）。
///
/// 誤答後に `AnswerFeedbackPanel.relatedReadings` へ渡す候補を作るために使う。
List<ChapterReading> readingsForQuestion(
  Iterable<ChapterReading> readings,
  String questionId,
) => [
  for (final r in readings)
    if (!r.disabled && r.relatedQuestionIds.contains(questionId)) r,
];
