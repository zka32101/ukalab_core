/// 週間ふりかえりカードの文言（できたことだけを見せる）。`UkalabStrings` とは別にして、既存アプリを壊さない。
///
/// 「サボ」「遅れ」「〜しないと」「ダメ」「焦」「少なかった」「減った」「先週より」など、
/// 責める・煽る・前週と比べる語は使わない（全文言をテストで機械検証する）。
/// ja・en は推敲済み。運営での文言確認は別途必要。
class WeeklyRecapStrings {
  const WeeklyRecapStrings({
    required this.title,
    required this.answeredLabel,
    required this.studyDaysLabel,
    required this.streakLabel,
    required this.medalsLabel,
    required this.topTopicsLabel,
    required this.improvedLabel,
    required this.questionsUnit,
    required this.daysUnit,
    required this.medalsUnit,
    required this.emptyTitle,
    required this.emptyBody,
  });

  final String title;
  final String answeredLabel;
  final String studyDaysLabel;
  final String streakLabel;
  final String medalsLabel;
  final String topTopicsLabel;
  final String improvedLabel;

  /// 数値のあとに付く単位（無ければ空文字）。
  final String questionsUnit;
  final String daysUnit;
  final String medalsUnit;

  /// 解いていない週の穏やかな表示。
  final String emptyTitle;
  final String emptyBody;

  WeeklyRecapStrings copyWith({
    String? title,
    String? answeredLabel,
    String? studyDaysLabel,
    String? streakLabel,
    String? medalsLabel,
    String? topTopicsLabel,
    String? improvedLabel,
    String? questionsUnit,
    String? daysUnit,
    String? medalsUnit,
    String? emptyTitle,
    String? emptyBody,
  }) =>
      WeeklyRecapStrings(
        title: title ?? this.title,
        answeredLabel: answeredLabel ?? this.answeredLabel,
        studyDaysLabel: studyDaysLabel ?? this.studyDaysLabel,
        streakLabel: streakLabel ?? this.streakLabel,
        medalsLabel: medalsLabel ?? this.medalsLabel,
        topTopicsLabel: topTopicsLabel ?? this.topTopicsLabel,
        improvedLabel: improvedLabel ?? this.improvedLabel,
        questionsUnit: questionsUnit ?? this.questionsUnit,
        daysUnit: daysUnit ?? this.daysUnit,
        medalsUnit: medalsUnit ?? this.medalsUnit,
        emptyTitle: emptyTitle ?? this.emptyTitle,
        emptyBody: emptyBody ?? this.emptyBody,
      );

  /// 検査用: 全文言。
  List<String> get allTexts => [
        title, answeredLabel, studyDaysLabel, streakLabel, medalsLabel, topTopicsLabel,
        improvedLabel, questionsUnit, daysUnit, medalsUnit, emptyTitle, emptyBody,
      ];

  static const ja = WeeklyRecapStrings(
    title: '今週のふりかえり',
    answeredLabel: '解いた問題',
    studyDaysLabel: '学習した日',
    streakLabel: '続いた日',
    medalsLabel: '集めたメダル',
    topTopicsLabel: 'よく解いた分野',
    improvedLabel: '伸びた分野',
    questionsUnit: '問',
    daysUnit: '日',
    medalsUnit: '個',
    emptyTitle: '今週はひと休み',
    emptyBody: 'また気が向いたら、1問からいっしょにやろう。',
  );

  static const en = WeeklyRecapStrings(
    title: 'Your week in review',
    answeredLabel: 'Questions solved',
    studyDaysLabel: 'Days you studied',
    streakLabel: 'Days in a row',
    medalsLabel: 'Medals collected',
    topTopicsLabel: 'Topics you worked on',
    improvedLabel: 'Topics that grew',
    questionsUnit: '',
    daysUnit: '',
    medalsUnit: '',
    emptyTitle: 'A quiet week',
    emptyBody: 'Come back whenever you feel like it. One question is plenty.',
  );

  static WeeklyRecapStrings forLanguageCode(String code) => switch (code) {
        'en' => en,
        _ => ja,
      };
}
