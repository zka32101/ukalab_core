import 'exam_stats_models.dart';

/// 模擬試験結果の匿名集計の抽象。アプリ側はこれにだけ依存する。
abstract class ExamStatsService {
  /// 結果を匿名で送信する。失敗しても呼び出し元には影響させない（握り潰す）。
  Future<void> submitResult(ExamStatsSubmission submission);

  /// [certId]・[examVersion] の全国集計。取得できない場合は null。
  Future<ExamStatsSummary?> fetchSummary({
    required String certId,
    required String examVersion,
  });
}
