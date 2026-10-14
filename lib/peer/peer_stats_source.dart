import 'peer_stats.dart';

/// 匿名集計の取得元。Firestore 実装は `lib/ui/peer_stats/firestore_peer_stats_source.dart`。
///
/// 失敗（オフライン等）や未集計は null を返す（例外で画面を壊さない）。
abstract interface class PeerStatsSource {
  Future<PeerStatsSnapshot?> fetch({required String examId});
}

/// 端末が送る1日1回の匿名の値。個人を特定する値（名前・メール・uid・端末ID）は含めない。
class PeerContribution {
  const PeerContribution({
    required this.examId,
    required this.dateKey,
    required this.streakDays,
    required this.totalQuestions,
    this.examDate,
  });

  final String examId;

  /// 送信日（`yyyy-MM-dd`、端末のローカル日付）。
  final String dateKey;
  final int streakDays;
  final int totalQuestions;

  /// 試験日（`yyyy-MM-dd`）。未設定は null。
  final String? examDate;
}

/// 匿名の値の送り先（実装は別 PR）。端末ごと・日次 1 回まで。
abstract interface class PeerStatsSink {
  Future<void> submit(PeerContribution contribution);
}

/// 送信のオン/オフ。ユーザーが明示的にオフにできる。既定値の提案は `docs/peer_stats.md`。
abstract interface class PeerStatsSettings {
  Future<bool> isSharingEnabled();
  Future<void> setSharingEnabled(bool enabled);
}
