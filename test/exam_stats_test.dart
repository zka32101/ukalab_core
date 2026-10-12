import 'package:ukalab_core/ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('deviationScoreFor は平均と同点なら50', () {
    const summary = ExamStatsSummary(sampleCount: 100, averageScore: 100, stdDev: 10);
    expect(summary.deviationScoreFor(100), 50);
    expect(summary.deviationScoreFor(110), 60);
    expect(summary.deviationScoreFor(90), 40);
  });

  test('サンプルが少ない・分散0なら null', () {
    const tooFew = ExamStatsSummary(sampleCount: 3, averageScore: 100, stdDev: 10);
    expect(tooFew.deviationScoreFor(100), isNull);
    const noVariance = ExamStatsSummary(sampleCount: 100, averageScore: 100, stdDev: 0);
    expect(noVariance.deviationScoreFor(100), isNull);
  });

  test('FakeExamStatsService は submitResult を記録し summary を返す', () async {
    const summary = ExamStatsSummary(sampleCount: 50, averageScore: 90, stdDev: 12);
    final service = FakeExamStatsService(summary: summary);
    const submission = ExamStatsSubmission(
      certId: 'g_kentei',
      examVersion: 'v1',
      score: 100,
      totalQuestions: 145,
    );

    await service.submitResult(submission);

    expect(service.submitted, [submission]);
    expect(
      await service.fetchSummary(certId: 'g_kentei', examVersion: 'v1'),
      summary,
    );
  });

  test('FakeExamStatsService は summary 未設定なら null を返す', () async {
    final service = FakeExamStatsService();
    expect(
      await service.fetchSummary(certId: 'g_kentei', examVersion: 'v1'),
      isNull,
    );
  });
}
