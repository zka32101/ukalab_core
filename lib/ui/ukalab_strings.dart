import 'package:app_common_kit/app_common_kit.dart' show KitStrings;
import 'package:flutter/widgets.dart';

import 'ukalab_strings_ko.dart';
import 'ukalab_strings_zh_hans.dart';
import 'ukalab_strings_zh_hant.dart';

/// うかラボ専用画面（推し・着せ替え・コイン・合格報告・共有カード・下部タブ）の文言。
///
/// 言語は [KitStrings.languageCode]（`app_common_kit` の `KitStringsScope`）に従う。内蔵は ja・en・
/// 簡体字(zh)・繁体字(zh-Hant)・ko。それ以外は日本語。個別の引数で文言を渡した場合は、そちらが優先される。
@immutable
class UkalabStrings {
  const UkalabStrings({
    required this.coinTotal,
    required this.coinBreakdownTitle,
    required this.coinEventLabels,
    required this.passAskBody,
    required this.passNotYet,
    required this.passNotPassed,
    required this.passPassed,
    required this.passEncourageTitle,
    required this.passEncourageBody,
    required this.passCongrats,
    required this.passPrivacy,
    required this.passShare,
    required this.wardrobeTitle,
    required this.wardrobeNote,
    required this.wardrobeInsufficient,
    required this.wardrobeAlreadyOwned,
    required this.wardrobeUnknown,
    required this.wardrobeCannotWear,
    required this.wardrobeWear,
    required this.wardrobeWearing,
    required this.wardrobeCanWear,
    required this.lockedNotPassed,
    required this.lockedNoExamDate,
    required this.lockedNotReady,
    required this.oshiMenuTooltip,
    required this.oshiChoose,
    required this.oshiPassReport,
    required this.oshiDisplayNormal,
    required this.oshiDisplaySmall,
    required this.oshiDisplayHidden,
    required this.oshiName,
    required this.oshiHiddenNote,
    required this.oshiYours,
    required this.oshiTapHint,
    required this.coinBalance,
    required this.wardrobePurchased,
    required this.wardrobePrice,
    required this.lockedNotPurchased,
    required this.passAskTitle,
    required this.passCoin,
    required this.passOutfit,
    required this.characterNames,
    required this.characterRoles,
    required this.tabLabels,
    required this.mockRecordTitle,
    required this.mockRecordNote,
    required this.mockRecordMessage,
    required this.mockRecordCert,
    required this.shareCardBrand,
    required this.shareCardPassed,
    required this.shareDate,
  });
  final String coinTotal;
  final String coinBreakdownTitle;

  /// `CoinEventType.name` → 表示名。
  final Map<String, String> coinEventLabels;
  final String passAskBody;
  final String passNotYet;
  final String passNotPassed;
  final String passPassed;
  final String passEncourageTitle;
  final String passEncourageBody;
  final String passCongrats;
  final String passPrivacy;
  final String passShare;
  final String wardrobeTitle;
  final String wardrobeNote;
  final String wardrobeInsufficient;
  final String wardrobeAlreadyOwned;
  final String wardrobeUnknown;
  final String wardrobeCannotWear;
  final String wardrobeWear;
  final String wardrobeWearing;
  final String wardrobeCanWear;
  final String lockedNotPassed;
  final String lockedNoExamDate;
  final String lockedNotReady;
  final String oshiMenuTooltip;
  final String oshiChoose;
  final String oshiPassReport;
  final String oshiDisplayNormal;
  final String oshiDisplaySmall;
  final String oshiDisplayHidden;
  final String oshiName;
  final String oshiHiddenNote;
  final String oshiYours;
  final String oshiTapHint;
  final String Function(int balance) coinBalance;
  final String Function(String name) wardrobePurchased;
  final String Function(int price) wardrobePrice;
  final String Function(int price) lockedNotPurchased;
  final String Function(String cert) passAskTitle;
  final String Function(int amount) passCoin;
  final String Function(String name) passOutfit;

  /// `CharacterPack.id` → 表示名。無い id はパックの name を使う。
  final Map<String, String> characterNames;

  /// `CharacterPack.id` → 役割の説明。
  final Map<String, String> characterRoles;
  final List<String> tabLabels;
  final String mockRecordTitle;
  final String mockRecordNote;
  final String mockRecordMessage;
  final String Function(String cert) mockRecordCert;
  final String shareCardBrand;
  final String shareCardPassed;
  final String Function(DateTime date) shareDate;

  UkalabStrings copyWith({
    String? coinTotal,
    String? coinBreakdownTitle,
    Map<String, String>? coinEventLabels,
    String? passAskBody,
    String? passNotYet,
    String? passNotPassed,
    String? passPassed,
    String? passEncourageTitle,
    String? passEncourageBody,
    String? passCongrats,
    String? passPrivacy,
    String? passShare,
    String? wardrobeTitle,
    String? wardrobeNote,
    String? wardrobeInsufficient,
    String? wardrobeAlreadyOwned,
    String? wardrobeUnknown,
    String? wardrobeCannotWear,
    String? wardrobeWear,
    String? wardrobeWearing,
    String? wardrobeCanWear,
    String? lockedNotPassed,
    String? lockedNoExamDate,
    String? lockedNotReady,
    String? oshiMenuTooltip,
    String? oshiChoose,
    String? oshiPassReport,
    String? oshiDisplayNormal,
    String? oshiDisplaySmall,
    String? oshiDisplayHidden,
    String? oshiName,
    String? oshiHiddenNote,
    String? oshiYours,
    String? oshiTapHint,
    String Function(int balance)? coinBalance,
    String Function(String name)? wardrobePurchased,
    String Function(int price)? wardrobePrice,
    String Function(int price)? lockedNotPurchased,
    String Function(String cert)? passAskTitle,
    String Function(int amount)? passCoin,
    String Function(String name)? passOutfit,
    Map<String, String>? characterNames,
    Map<String, String>? characterRoles,
    List<String>? tabLabels,
    String? mockRecordTitle,
    String? mockRecordNote,
    String? mockRecordMessage,
    String Function(String cert)? mockRecordCert,
    String? shareCardBrand,
    String? shareCardPassed,
    String Function(DateTime date)? shareDate,
  }) => UkalabStrings(
    coinTotal: coinTotal ?? this.coinTotal,
    coinBreakdownTitle: coinBreakdownTitle ?? this.coinBreakdownTitle,
    coinEventLabels: coinEventLabels ?? this.coinEventLabels,
    passAskBody: passAskBody ?? this.passAskBody,
    passNotYet: passNotYet ?? this.passNotYet,
    passNotPassed: passNotPassed ?? this.passNotPassed,
    passPassed: passPassed ?? this.passPassed,
    passEncourageTitle: passEncourageTitle ?? this.passEncourageTitle,
    passEncourageBody: passEncourageBody ?? this.passEncourageBody,
    passCongrats: passCongrats ?? this.passCongrats,
    passPrivacy: passPrivacy ?? this.passPrivacy,
    passShare: passShare ?? this.passShare,
    wardrobeTitle: wardrobeTitle ?? this.wardrobeTitle,
    wardrobeNote: wardrobeNote ?? this.wardrobeNote,
    wardrobeInsufficient: wardrobeInsufficient ?? this.wardrobeInsufficient,
    wardrobeAlreadyOwned: wardrobeAlreadyOwned ?? this.wardrobeAlreadyOwned,
    wardrobeUnknown: wardrobeUnknown ?? this.wardrobeUnknown,
    wardrobeCannotWear: wardrobeCannotWear ?? this.wardrobeCannotWear,
    wardrobeWear: wardrobeWear ?? this.wardrobeWear,
    wardrobeWearing: wardrobeWearing ?? this.wardrobeWearing,
    wardrobeCanWear: wardrobeCanWear ?? this.wardrobeCanWear,
    lockedNotPassed: lockedNotPassed ?? this.lockedNotPassed,
    lockedNoExamDate: lockedNoExamDate ?? this.lockedNoExamDate,
    lockedNotReady: lockedNotReady ?? this.lockedNotReady,
    oshiMenuTooltip: oshiMenuTooltip ?? this.oshiMenuTooltip,
    oshiChoose: oshiChoose ?? this.oshiChoose,
    oshiPassReport: oshiPassReport ?? this.oshiPassReport,
    oshiDisplayNormal: oshiDisplayNormal ?? this.oshiDisplayNormal,
    oshiDisplaySmall: oshiDisplaySmall ?? this.oshiDisplaySmall,
    oshiDisplayHidden: oshiDisplayHidden ?? this.oshiDisplayHidden,
    oshiName: oshiName ?? this.oshiName,
    oshiHiddenNote: oshiHiddenNote ?? this.oshiHiddenNote,
    oshiYours: oshiYours ?? this.oshiYours,
    oshiTapHint: oshiTapHint ?? this.oshiTapHint,
    coinBalance: coinBalance ?? this.coinBalance,
    wardrobePurchased: wardrobePurchased ?? this.wardrobePurchased,
    wardrobePrice: wardrobePrice ?? this.wardrobePrice,
    lockedNotPurchased: lockedNotPurchased ?? this.lockedNotPurchased,
    passAskTitle: passAskTitle ?? this.passAskTitle,
    passCoin: passCoin ?? this.passCoin,
    passOutfit: passOutfit ?? this.passOutfit,
    characterNames: characterNames ?? this.characterNames,
    characterRoles: characterRoles ?? this.characterRoles,
    tabLabels: tabLabels ?? this.tabLabels,
    mockRecordTitle: mockRecordTitle ?? this.mockRecordTitle,
    mockRecordNote: mockRecordNote ?? this.mockRecordNote,
    mockRecordMessage: mockRecordMessage ?? this.mockRecordMessage,
    mockRecordCert: mockRecordCert ?? this.mockRecordCert,
    shareCardBrand: shareCardBrand ?? this.shareCardBrand,
    shareCardPassed: shareCardPassed ?? this.shareCardPassed,
    shareDate: shareDate ?? this.shareDate,
  );

  static const ja = UkalabStrings(
    coinTotal: '合計',
    coinBreakdownTitle: '今回貯まった学習コイン',
    coinEventLabels: {
      'newQuestion': '新しい問題',
      'coverageStep': '網羅率アップ',
      'accuracyMilestone': '正答率の達成',
      'accuracyBest': '自己ベスト更新',
      'reviewCorrected': '復習で克服',
      'dailyConsult': '今日の相談',
      'mockDone': '模擬試験の実施',
      'mockPass': '模擬試験で合格点',
      'mockBest': '模擬試験の自己ベスト',
      'streak': '連続学習',
      'passReport': '合格報告',
    },
    passAskBody: 'お知らせいただいた内容は、この端末の中だけで使います。',
    passNotYet: 'まだ・結果待ち',
    passNotPassed: '今回は合格できなかった',
    passPassed: '合格しました',
    passEncourageTitle: 'おつかれさまでした',
    passEncourageBody: '弱点を復習して、また挑戦しましょう。コインや衣装はそのままです。',
    passCongrats: '合格おめでとうございます',
    passPrivacy: '共有するカードに、名前などの個人情報は入りません。',
    passShare: '共有する',
    wardrobeTitle: '着替え・ショップ',
    wardrobeNote: 'コインは学習で貯まります。衣装は見た目だけで、学習の内容には影響しません。',
    wardrobeInsufficient: 'コインが足りません。学習すると貯まります',
    wardrobeAlreadyOwned: 'すでに持っています',
    wardrobeUnknown: '購入できません',
    wardrobeCannotWear: 'この衣装は今は着られません',
    wardrobeWear: '着る',
    wardrobeWearing: '着ています',
    wardrobeCanWear: '着られます',
    lockedNotPassed: '合格したときに解放されます',
    lockedNoExamDate: '試験日を設定すると着られます',
    lockedNotReady: '準備完了の目標を達成すると解放されます',
    oshiMenuTooltip: '推しのメニュー',
    oshiChoose: '推しを選ぶ',
    oshiPassReport: '試験の結果を報告',
    oshiDisplayNormal: '通常',
    oshiDisplaySmall: '小さく表示',
    oshiDisplayHidden: '表示しない',
    oshiName: '推し',
    oshiHiddenNote: '推しは非表示です',
    oshiYours: 'あなたの推し',
    oshiTapHint: '推しをタップすると、ひとこと話します',
    coinBalance: _jaCoinBalance,
    wardrobePurchased: _jaWardrobePurchased,
    wardrobePrice: _jaWardrobePrice,
    lockedNotPurchased: _jaLockedNotPurchased,
    passAskTitle: _jaPassAskTitle,
    passCoin: _jaPassCoin,
    passOutfit: _jaPassOutfit,
    characterNames: {},
    characterRoles: {
      'standard': 'フラスコの助手',
      'kai': '頼れる先輩',
      'mio': '明るい後輩',
      'moka': 'ゆるい相棒（犬）',
      'mike': 'ていねいな解説役（猫）',
    },
    tabLabels: ['ホーム', '学ぶ', '模擬', '記録', '設定'],
    mockRecordTitle: '学習の記録カード',
    mockRecordNote: '模擬試験の記録です。本番の合格ではありません。名前などの個人情報は入りません。',
    mockRecordMessage: '合格点を超えました！',
    mockRecordCert: _jaMockRecordCert,
    shareCardBrand: 'うかラボ',
    shareCardPassed: '合格しました！',
    shareDate: _jaShareDate,
  );

  static const en = UkalabStrings(
    coinTotal: 'Total',
    coinBreakdownTitle: 'Study coins earned this time',
    coinEventLabels: {
      'newQuestion': 'New questions',
      'coverageStep': 'Coverage up',
      'accuracyMilestone': 'Accuracy milestone',
      'accuracyBest': 'New personal best',
      'reviewCorrected': 'Mastered in review',
      'dailyConsult': "Today's consult",
      'mockDone': 'Mock exam taken',
      'mockPass': 'Mock exam passed',
      'mockBest': 'Mock exam personal best',
      'streak': 'Study streak',
      'passReport': 'Pass report',
    },
    passAskBody: 'What you tell us is used only on this device.',
    passNotYet: 'Not yet / waiting for results',
    passNotPassed: "I didn't pass this time",
    passPassed: 'I passed',
    passEncourageTitle: 'Good work',
    passEncourageBody:
        'Review your weak spots and try again. Your coins and outfits stay as they are.',
    passCongrats: 'Congratulations on passing!',
    passPrivacy:
        'The shared card contains no personal information such as your name.',
    passShare: 'Share',
    wardrobeTitle: 'Outfits & shop',
    wardrobeNote:
        'Coins are earned by studying. Outfits are cosmetic only and do not affect your study content.',
    wardrobeInsufficient: 'Not enough coins. You earn them by studying',
    wardrobeAlreadyOwned: 'You already own this',
    wardrobeUnknown: 'This cannot be purchased',
    wardrobeCannotWear: 'You cannot wear this outfit right now',
    wardrobeWear: 'Wear',
    wardrobeWearing: 'Wearing',
    wardrobeCanWear: 'Available to wear',
    lockedNotPassed: 'Unlocked when you pass',
    lockedNoExamDate: 'Set your exam date to wear this',
    lockedNotReady: 'Unlocked when you reach your readiness goal',
    oshiMenuTooltip: 'Companion menu',
    oshiChoose: 'Choose companion',
    oshiPassReport: 'Report exam result',
    oshiDisplayNormal: 'Normal',
    oshiDisplaySmall: 'Show small',
    oshiDisplayHidden: 'Hide',
    oshiName: 'Companion',
    oshiHiddenNote: 'Your companion is hidden',
    oshiYours: 'Your companion',
    oshiTapHint: 'Tap your companion to hear a word',
    coinBalance: _enCoinBalance,
    wardrobePurchased: _enWardrobePurchased,
    wardrobePrice: _enWardrobePrice,
    lockedNotPurchased: _enLockedNotPurchased,
    passAskTitle: _enPassAskTitle,
    passCoin: _enPassCoin,
    passOutfit: _enPassOutfit,
    characterNames: {
      'standard': 'Uka',
      'kai': 'Kai',
      'mio': 'Mio',
      'moka': 'Moka',
      'mike': 'Mike',
    },
    characterRoles: {
      'standard': 'Flask assistant',
      'kai': 'Reliable senior',
      'mio': 'Cheerful junior',
      'moka': 'Easygoing buddy (dog)',
      'mike': 'Careful explainer (cat)',
    },
    tabLabels: ['Home', 'Learn', 'Mock', 'Records', 'Settings'],
    mockRecordTitle: 'Study record card',
    mockRecordNote:
        'This is a mock exam record, not an actual pass. It contains no personal information such as your name.',
    mockRecordMessage: 'You beat the passing score!',
    mockRecordCert: _enMockRecordCert,
    shareCardBrand: 'Qualab',
    shareCardPassed: 'I passed!',
    shareDate: _enShareDate,
  );

  /// 簡体字中国語（`zh`）。機械翻訳の下書き。公開前に母語話者の確認が要る。
  static const zhHans = ukalabStringsZhHans;

  /// 繁体字中国語（`zh-Hant`）。機械翻訳の下書き。公開前に母語話者の確認が要る。
  static const zhHant = ukalabStringsZhHant;

  /// 韓国語（`ko`）。機械翻訳の下書き。公開前に母語話者の確認が要る。
  static const ko = ukalabStringsKo;

  /// [KitStrings.languageCode] に対応する文言。無い言語は日本語。
  static UkalabStrings forLanguageCode(String code) => switch (code) {
    'en' => en,
    'ko' => ko,
    'zh' => zhHans,
    'zh-Hant' => zhHant,
    _ => ja,
  };

  /// 最も近い `KitStringsScope` の言語に合う文言。無ければ日本語。
  static UkalabStrings of(BuildContext context) =>
      forLanguageCode(KitStrings.of(context).languageCode);
}

String _jaPassAskTitle(String c) => '${c}の結果を教えてください';
String _enPassAskTitle(String c) => 'Tell us your $c result';
String _jaPassCoin(int a) => '学習コイン +$a';
String _enPassCoin(int a) => 'Study coins +$a';
String _jaPassOutfit(String n) => '「$n」を着られるようになりました';
String _enPassOutfit(String n) => 'You can now wear "$n"';
String _jaCoinBalance(int b) => '学習コイン $b';
String _enCoinBalance(int b) => 'Study coins $b';
String _jaWardrobePurchased(String n) => '${n}を購入しました';
String _enWardrobePurchased(String n) => 'Purchased $n';
String _jaWardrobePrice(int p) => '${p}コイン';
String _enWardrobePrice(int p) => '$p coins';
String _jaLockedNotPurchased(int p) => '${p}コインで購入できます';
String _enLockedNotPurchased(int p) => 'Buy for $p coins';
String _jaMockRecordCert(String c) => '$c 模擬試験';
String _enMockRecordCert(String c) => '$c mock exam';
String _jaShareDate(DateTime d) => '${d.year}年${d.month}月${d.day}日';
const _enShortMonths = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];
String _enShareDate(DateTime d) =>
    '${_enShortMonths[d.month - 1]} ${d.day}, ${d.year}';
