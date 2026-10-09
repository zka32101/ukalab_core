/// premium（期間パス・買い切り）でだけ使える機能（うかラボ共通の線引き。
/// 決定事項ログ追補3）。問題・解説・模擬試験・基本の苦手特訓、および原因ラベルの記録・
/// 比較表示・更新ログ・引き継ぎなどは無料で、ここには含めない。
/// 合格報告の特典（premium 7日間）の間は、すべて使える。
enum PremiumFeature {
  /// 弱点集中ドリルと、原因別の集計・推移。
  weakDrill,

  /// 試験直前モード（試験日の3日前から）。
  examEveMode,

  /// 今日の10分プラン。
  tenMinutePlan,

  /// 学習履歴の書き出し（CSV / PDF）。
  historyExport,
}

/// [feature] を使えるか。premium でなければ使えない。
bool canUsePremiumFeature(PremiumFeature feature, {required bool isPremium}) =>
    isPremium;
