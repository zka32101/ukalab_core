/// 学習アプリ向けの部品（問題カード・解説・結果・連続学習・模試の推移・回答フィードバック）。
///
/// 以前は app_common_kit にあったもの。キットは学習に依存しない共通基盤に絞り、学習固有の部品はコアが持つ。
/// `package:ukalab_core/ui.dart` とは別の入口にして、名前の衝突を避ける。
library;

export 'learning/answer_feedback.dart';
export 'learning/explanation_panel.dart';
export 'learning/mock_exam_trend_chart.dart';
export 'learning/question_card.dart';
export 'learning/result_summary.dart';
export 'learning/streak_badge.dart';
export 'learning/streak_store.dart';
