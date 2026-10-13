/// 解答後フィードバック（誤答の原因ラベル・違いの比較表示・今週の弱点）の共通部品。Flutter が要る。
///
/// アプリは解答後の画面に [AnswerFeedbackPanel] を置き、`onCause` で履歴に原因を反映する
/// （`attachCauseToLatest`）。弱点まとめは [WeakSummaryCard]（premium 判定は呼び出し側）。
/// `ui.dart` とは別の単機能エントリ。
library;

export 'experience/comparison_view.dart' show ComparisonRow, ComparisonView, buildComparison;
export 'policy/premium_features.dart' show PremiumFeature, canUsePremiumFeature;
export 'progress/history_log.dart' show attachCauseToLatest, historyRecordFor;
export 'progress/progress_record.dart' show ProgressRecord, WrongCause;
export 'progress/weak_summary.dart' show WeakSummary, buildWeakSummary;
export 'progress/weak_topics.dart' show WeakPrescription, WeakTopic, prescriptionFor;
export 'ui/answer_feedback/answer_feedback_panel.dart';
export 'ui/answer_feedback/answer_feedback_strings.dart';
export 'ui/answer_feedback/comparison_card.dart';
export 'ui/answer_feedback/weak_summary_card.dart';
export 'ui/answer_feedback/wrong_cause_selector.dart';
