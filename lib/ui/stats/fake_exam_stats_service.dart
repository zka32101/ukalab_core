import 'exam_stats_models.dart';
import 'exam_stats_service.dart';

/// テスト・プレビュー用のモック実装。固定の集計値を返す。
class FakeExamStatsService implements ExamStatsService {
  FakeExamStatsService({this.summary});

  /// 返す集計値。null なら「集計なし」。
  ExamStatsSummary? summary;

  final submitted = <ExamStatsSubmission>[];

  @override
  Future<void> submitResult(ExamStatsSubmission submission) async {
    submitted.add(submission);
  }

  @override
  Future<ExamStatsSummary?> fetchSummary({
    required String certId,
    required String examVersion,
  }) async =>
      summary;
}
