import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';

import 'exam_stats_models.dart';
import 'exam_stats_service.dart';

/// Firestore 実装。`exam_stats/{certId}_{examVersion}` に件数・合計・平方和だけを
/// 持ち、個々の提出は匿名のまま保存しない（Cloud Functions 不要で平均・標準偏差
/// を導出できる）。Firestore ルールで書き込みはこの3フィールドの増分のみに限定し、
/// App Check で正規のアプリからのみ書き込めるようにする（決定32）。
class FirebaseExamStatsService implements ExamStatsService {
  FirebaseExamStatsService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  String _docId(String certId, String examVersion) => '${certId}_$examVersion';

  @override
  Future<void> submitResult(ExamStatsSubmission submission) async {
    try {
      final ref = _firestore
          .collection('exam_stats')
          .doc(_docId(submission.certId, submission.examVersion));
      await ref.set({
        'certId': submission.certId,
        'examVersion': submission.examVersion,
        'count': FieldValue.increment(1),
        'sum': FieldValue.increment(submission.score),
        'sumOfSquares': FieldValue.increment(submission.score * submission.score),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // オフライン等。集計は参考情報のため失敗は握り潰す。
    }
  }

  @override
  Future<ExamStatsSummary?> fetchSummary({
    required String certId,
    required String examVersion,
  }) async {
    try {
      final doc = await _firestore
          .collection('exam_stats')
          .doc(_docId(certId, examVersion))
          .get();
      final data = doc.data();
      if (data == null) return null;
      final count = (data['count'] as num?)?.toInt() ?? 0;
      if (count <= 0) return null;
      final sum = (data['sum'] as num?)?.toDouble() ?? 0;
      final sumOfSquares = (data['sumOfSquares'] as num?)?.toDouble() ?? 0;
      final average = sum / count;
      final variance = sumOfSquares / count - average * average;
      return ExamStatsSummary(
        sampleCount: count,
        averageScore: average,
        stdDev: math.sqrt(variance < 0 ? 0 : variance),
      );
    } catch (_) {
      return null;
    }
  }
}
