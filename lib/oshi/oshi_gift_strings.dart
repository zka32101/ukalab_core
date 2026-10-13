import 'oshi_gift_engine.dart';

/// 衣装・背景プレゼントの文言（祝う調子だけ。未達を理由にした催促はしない）。
///
/// `UkalabStrings` とは別にして、既存アプリを壊さない。`{name}`（プレゼント名）と
/// `{n}`（連続日数）を含められる。ja・en は推敲済み。運営での文言確認は別途必要。
class OshiGiftStrings {
  const OshiGiftStrings({
    required this.titleOutfit,
    required this.titleBackground,
    required this.bodyOutfit,
    required this.bodyBackground,
    required this.reasonStreak,
    required this.reasonMedal,
    required this.reasonMockPass,
    required this.placeholderNote,
    required this.close,
  });

  final String titleOutfit;
  final String titleBackground;
  final String bodyOutfit;
  final String bodyBackground;
  final String reasonStreak;
  final String reasonMedal;
  final String reasonMockPass;

  /// 画像が未用意のときの補足。
  final String placeholderNote;
  final String close;

  String titleOf(OshiGiftKind k) => k == OshiGiftKind.outfit ? titleOutfit : titleBackground;

  String bodyOf(OshiGiftSpec g) =>
      (g.kind == OshiGiftKind.outfit ? bodyOutfit : bodyBackground).replaceAll('{name}', g.name);

  String reasonOf(OshiGiftSpec g) => switch (g.condition.type) {
    OshiGiftConditionType.streakDays => reasonStreak.replaceAll('{n}', '${g.condition.days ?? 0}'),
    OshiGiftConditionType.medalId => reasonMedal,
    OshiGiftConditionType.mockPass => reasonMockPass,
  };

  OshiGiftStrings copyWith({
    String? titleOutfit,
    String? titleBackground,
    String? bodyOutfit,
    String? bodyBackground,
    String? reasonStreak,
    String? reasonMedal,
    String? reasonMockPass,
    String? placeholderNote,
    String? close,
  }) => OshiGiftStrings(
    titleOutfit: titleOutfit ?? this.titleOutfit,
    titleBackground: titleBackground ?? this.titleBackground,
    bodyOutfit: bodyOutfit ?? this.bodyOutfit,
    bodyBackground: bodyBackground ?? this.bodyBackground,
    reasonStreak: reasonStreak ?? this.reasonStreak,
    reasonMedal: reasonMedal ?? this.reasonMedal,
    reasonMockPass: reasonMockPass ?? this.reasonMockPass,
    placeholderNote: placeholderNote ?? this.placeholderNote,
    close: close ?? this.close,
  );

  /// 検査用: 全文言。
  List<String> get allTexts => [
    titleOutfit, titleBackground, bodyOutfit, bodyBackground,
    reasonStreak, reasonMedal, reasonMockPass, placeholderNote, close,
  ];

  static const ja = OshiGiftStrings(
    titleOutfit: '衣装のプレゼント',
    titleBackground: '背景のプレゼント',
    bodyOutfit: '「{name}」が届いたよ。着せ替えでいつでも使えるよ。',
    bodyBackground: '「{name}」が届いたよ。いつでも使えるよ。',
    reasonStreak: '{n}日つづけたお祝いだよ。',
    reasonMedal: 'メダル獲得のお祝いだよ。',
    reasonMockPass: '模試の合格、おめでとう。',
    placeholderNote: '仮の表示です',
    close: 'ありがとう',
  );

  static const en = OshiGiftStrings(
    titleOutfit: 'A gift: new outfit',
    titleBackground: 'A gift: new background',
    bodyOutfit: '"{name}" has arrived. You can use it anytime in the wardrobe.',
    bodyBackground: '"{name}" has arrived. You can use it anytime.',
    reasonStreak: 'A little celebration for {n} days in a row.',
    reasonMedal: 'A little celebration for your new medal.',
    reasonMockPass: 'Congratulations on passing the mock exam.',
    placeholderNote: 'Temporary preview',
    close: 'Thank you',
  );

  static OshiGiftStrings forLanguageCode(String code) => switch (code) {
    'en' => en,
    _ => ja,
  };
}
