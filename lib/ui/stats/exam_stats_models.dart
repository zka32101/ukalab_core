/// 模擬試験結果の匿名提出データ。
class ExamStatsSubmission {
  const ExamStatsSubmission({
    required this.certId,
    required this.examVersion,
    required this.score,
    required this.totalQuestions,
  });

  /// 資格ID（例: 'g_kentei'）。
  final String certId;

  /// 出題配分のバージョン。配分が変わると過去の集計と比較できなくなるため分ける。
  final String examVersion;

  final int score;
  final int totalQuestions;
}

/// 資格・バージョンごとの全国集計。
class ExamStatsSummary {
  const ExamStatsSummary({
    required this.sampleCount,
    required this.averageScore,
    required this.stdDev,
  });

  final int sampleCount;
  final double averageScore;
  final double stdDev;

  /// 偏差値。サンプルが少なすぎる・分散が0の場合は null。
  double? deviationScoreFor(int score) {
    if (sampleCount < 10 || stdDev <= 0) return null;
    return 50 + 10 * (score - averageScore) / stdDev;
  }
}
