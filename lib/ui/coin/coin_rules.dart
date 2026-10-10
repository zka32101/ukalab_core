/// 学習コインの獲得イベントとルール（ukalab_学習コイン仕様 v0.1 §2）。
///
/// コインは**学習の成長でのみ**獲得する。課金・広告視聴での付与は実装しない。
/// 数値は暫定で、`CoinRules` を差し替えて調整できる（Remote Config から作る想定）。
library;

enum CoinEventType {
  /// 新しい問題を初めて解く
  newQuestion,

  /// トピックの網羅率が10%刻みで上昇
  coverageStep,

  /// トピック別正答率が 70／80／90% に初到達
  accuracyMilestone,

  /// トピック別正答率の自己ベスト更新
  accuracyBest,

  /// 間違えた問題を、間隔を空けた復習で正解
  reviewCorrected,

  /// 推しの「今日の相談」に答える
  dailyConsult,

  /// 模擬試験の実施
  mockDone,

  /// 模擬試験で合格点を初めて超える
  mockPass,

  /// 模擬試験の自己ベスト更新
  mockBest,

  /// 連続学習 7／30／100 日
  streak,

  /// 合格報告で「合格」を選んだ場合
  passReport,
}

/// 獲得イベント。同じ [dedupeKey] は（上限の範囲で）二重に付与されない。
class CoinEvent {
  const CoinEvent._(this.type, this.key, {this.level = 0});

  final CoinEventType type;

  /// 重複判定に使う識別子（問題ID、トピックID など）。
  final String key;

  /// 段階（網羅率の%、正答率の%、連続日数など）。
  final int level;

  factory CoinEvent.newQuestion(String questionId) =>
      CoinEvent._(CoinEventType.newQuestion, questionId);

  /// [percent] は 10, 20, … 100。
  factory CoinEvent.coverageStep(String topicId, int percent) =>
      CoinEvent._(CoinEventType.coverageStep, '$topicId@$percent', level: percent);

  /// [percent] は 70, 80, 90。直近20問以上の実績で判定するのは呼び出し側。
  factory CoinEvent.accuracyMilestone(String topicId, int percent) =>
      CoinEvent._(CoinEventType.accuracyMilestone, '$topicId@$percent', level: percent);

  factory CoinEvent.accuracyBest(String topicId) =>
      CoinEvent._(CoinEventType.accuracyBest, topicId);

  factory CoinEvent.reviewCorrected(String questionId) =>
      CoinEvent._(CoinEventType.reviewCorrected, questionId);

  factory CoinEvent.dailyConsult() => const CoinEvent._(CoinEventType.dailyConsult, 'consult');

  factory CoinEvent.mockDone() => const CoinEvent._(CoinEventType.mockDone, 'mock');

  factory CoinEvent.mockPass(String examId) => CoinEvent._(CoinEventType.mockPass, examId);

  factory CoinEvent.mockBest(String examId) => CoinEvent._(CoinEventType.mockBest, examId);

  /// [days] は 7, 30, 100。
  factory CoinEvent.streak(int days) => CoinEvent._(CoinEventType.streak, '$days', level: days);

  factory CoinEvent.passReport(String certId) => CoinEvent._(CoinEventType.passReport, certId);
}

/// 付与の可否と量を決める数値。
class CoinRules {
  const CoinRules({
    this.newQuestion = 1,
    this.newQuestionDailyCap = 30,
    this.coverageStep = 10,
    this.accuracy70 = 20,
    this.accuracy80 = 30,
    this.accuracy90 = 50,
    this.accuracyBest = 5,
    this.accuracyBestDailyCount = 3,
    this.reviewCorrected = 2,
    this.reviewCorrectedDailyCap = 20,
    this.dailyConsult = 2,
    this.mockDone = 10,
    this.mockPass = 50,
    this.mockBest = 20,
    this.streak7 = 30,
    this.streak30 = 100,
    this.streak100 = 300,
    this.passReport = 200,
  });

  final int newQuestion;
  final int newQuestionDailyCap;
  final int coverageStep;
  final int accuracy70;
  final int accuracy80;
  final int accuracy90;
  final int accuracyBest;
  final int accuracyBestDailyCount;
  final int reviewCorrected;
  final int reviewCorrectedDailyCap;
  final int dailyConsult;
  final int mockDone;
  final int mockPass;
  final int mockBest;
  final int streak7;
  final int streak30;
  final int streak100;
  final int passReport;

  /// 既定値（仕様の暫定値）。
  static const CoinRules standard = CoinRules();

  /// イベントの獲得量。段階が仕様にないイベント（例: 正答率 75%）は 0。
  int amountFor(CoinEvent e) {
    switch (e.type) {
      case CoinEventType.newQuestion:
        return newQuestion;
      case CoinEventType.coverageStep:
        return (e.level >= 10 && e.level <= 100 && e.level % 10 == 0) ? coverageStep : 0;
      case CoinEventType.accuracyMilestone:
        return switch (e.level) { 70 => accuracy70, 80 => accuracy80, 90 => accuracy90, _ => 0 };
      case CoinEventType.accuracyBest:
        return accuracyBest;
      case CoinEventType.reviewCorrected:
        return reviewCorrected;
      case CoinEventType.dailyConsult:
        return dailyConsult;
      case CoinEventType.mockDone:
        return mockDone;
      case CoinEventType.mockPass:
        return mockPass;
      case CoinEventType.mockBest:
        return mockBest;
      case CoinEventType.streak:
        return switch (e.level) { 7 => streak7, 30 => streak30, 100 => streak100, _ => 0 };
      case CoinEventType.passReport:
        return passReport;
    }
  }
}
