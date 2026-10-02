import 'usage_quota.dart';

/// 無料版の制限（うかラボ共通の線引き。決定ログ追補・企画設計書 §11-3）。
///
/// 問題・解説そのものは絞らない。プレミアム(premium)の価値は「合格に近づく機能」
/// に置く。値は暫定で、公開後の実測で見直す。
/// premium でない人（noads のみを含む）が対象。
class FreeTierLimits {
  const FreeTierLimits({
    this.mockExamsPerMonth = 1,
    this.weakTopicsShown = 3,
    this.reviewQuestionsPerDay = 10,
    this.generatedQuestionsPerDay = 10,
  });

  static const standard = FreeTierLimits();

  /// 模擬試験を始められる回数（月）。
  final int mockExamsPerMonth;

  /// 苦手分析で表示する分野の数（苦手な順）。
  final int weakTopicsShown;

  /// 間隔反復で出題される復習の数（日）。
  final int reviewQuestionsPerDay;

  /// 自動生成問題（簿記など）の演習数（日）。
  final int generatedQuestionsPerDay;

  /// 模擬試験の回数制限。プレミアムなら無制限。
  UsageQuota mockExamQuota({
    required bool isPremium,
    required KeyValueStore store,
    DateTime Function()? clock,
  }) =>
      UsageQuota(
        id: 'mock_exam',
        period: QuotaPeriod.monthly,
        limit: isPremium ? null : mockExamsPerMonth,
        store: store,
        clock: clock,
      );

  /// 復習の回数制限。プレミアムなら無制限。
  UsageQuota reviewQuota({
    required bool isPremium,
    required KeyValueStore store,
    DateTime Function()? clock,
  }) =>
      UsageQuota(
        id: 'review',
        period: QuotaPeriod.daily,
        limit: isPremium ? null : reviewQuestionsPerDay,
        store: store,
        clock: clock,
      );

  /// 苦手分析で表示する分野数。プレミアムなら全分野(null)。
  int? weakTopicLimit({required bool isPremium}) =>
      isPremium ? null : weakTopicsShown;
}
