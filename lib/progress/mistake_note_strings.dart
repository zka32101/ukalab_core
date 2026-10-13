/// 間違いノートの文言（「伸びしろ」として扱い、責めない・煽らない）。`UkalabStrings` とは別にして、既存アプリを壊さない。
///
/// 「サボ」「遅れ」「〜しないと」「ダメ」「焦」「急が」「少な」「減」「ワースト」「苦手ばかり」
/// 「また間違」など、責める・煽る・件数で圧をかける語は使わない（全文言をテストで機械検証する）。
/// ja・en は推敲済み。運営での文言確認は別途必要。
class MistakeNoteStrings {
  const MistakeNoteStrings({
    required this.title,
    required this.intro,
    required this.filterUpcoming,
    required this.filterOvercome,
    required this.retry,
    required this.retryHint,
    required this.overcomeBadge,
    required this.foundOnLabel,
    required this.celebrateTitle,
    required this.celebrateBody,
    required this.emptyUpcomingTitle,
    required this.emptyUpcomingBody,
    required this.emptyOvercomeTitle,
    required this.emptyOvercomeBody,
  });

  final String title;
  final String intro;
  final String filterUpcoming;
  final String filterOvercome;

  /// 「解き直す」ボタン。
  final String retry;

  /// ボタンの読み上げ補足。
  final String retryHint;
  final String overcomeBadge;

  /// 見つけた日（直近の間違いの日付）の見出し。
  final String foundOnLabel;
  final String celebrateTitle;
  final String celebrateBody;
  final String emptyUpcomingTitle;
  final String emptyUpcomingBody;
  final String emptyOvercomeTitle;
  final String emptyOvercomeBody;

  MistakeNoteStrings copyWith({
    String? title,
    String? intro,
    String? filterUpcoming,
    String? filterOvercome,
    String? retry,
    String? retryHint,
    String? overcomeBadge,
    String? foundOnLabel,
    String? celebrateTitle,
    String? celebrateBody,
    String? emptyUpcomingTitle,
    String? emptyUpcomingBody,
    String? emptyOvercomeTitle,
    String? emptyOvercomeBody,
  }) =>
      MistakeNoteStrings(
        title: title ?? this.title,
        intro: intro ?? this.intro,
        filterUpcoming: filterUpcoming ?? this.filterUpcoming,
        filterOvercome: filterOvercome ?? this.filterOvercome,
        retry: retry ?? this.retry,
        retryHint: retryHint ?? this.retryHint,
        overcomeBadge: overcomeBadge ?? this.overcomeBadge,
        foundOnLabel: foundOnLabel ?? this.foundOnLabel,
        celebrateTitle: celebrateTitle ?? this.celebrateTitle,
        celebrateBody: celebrateBody ?? this.celebrateBody,
        emptyUpcomingTitle: emptyUpcomingTitle ?? this.emptyUpcomingTitle,
        emptyUpcomingBody: emptyUpcomingBody ?? this.emptyUpcomingBody,
        emptyOvercomeTitle: emptyOvercomeTitle ?? this.emptyOvercomeTitle,
        emptyOvercomeBody: emptyOvercomeBody ?? this.emptyOvercomeBody,
      );

  /// 検査用: 全文言。
  List<String> get allTexts => [
        title, intro, filterUpcoming, filterOvercome, retry, retryHint, overcomeBadge,
        foundOnLabel, celebrateTitle, celebrateBody, emptyUpcomingTitle, emptyUpcomingBody,
        emptyOvercomeTitle, emptyOvercomeBody,
      ];

  static const ja = MistakeNoteStrings(
    title: '間違いノート',
    intro: '伸びしろをためておく場所。気が向いたときに、ゆっくり見返そう。',
    filterUpcoming: 'これから',
    filterOvercome: '克服',
    retry: '解き直す',
    retryHint: 'この問題をもう一度解く',
    overcomeBadge: '克服',
    foundOnLabel: '見つけた日',
    celebrateTitle: '克服したよ！',
    celebrateBody: '解き直して、自分のものにできたね。すてき！',
    emptyUpcomingTitle: 'いまは見返すものはありません',
    emptyUpcomingBody: '気づきが生まれたら、ここにためておくよ。',
    emptyOvercomeTitle: '克服した問題がここに並びます',
    emptyOvercomeBody: '解き直して続けて正解できたら、ここでお祝いするよ。',
  );

  static const en = MistakeNoteStrings(
    title: 'Mistake notebook',
    intro: 'A place to keep your room to grow. Look back whenever you like.',
    filterUpcoming: 'Up next',
    filterOvercome: 'Overcome',
    retry: 'Try again',
    retryHint: 'Solve this question once more',
    overcomeBadge: 'Overcome',
    foundOnLabel: 'Found on',
    celebrateTitle: 'You did it!',
    celebrateBody: 'You tried it again and made it your own. Nice work!',
    emptyUpcomingTitle: 'Nothing to revisit right now',
    emptyUpcomingBody: 'New discoveries will be kept here for you.',
    emptyOvercomeTitle: 'Overcome questions will show up here',
    emptyOvercomeBody: 'Get one right a couple of times in a row and we will celebrate here.',
  );

  static MistakeNoteStrings forLanguageCode(String code) => switch (code) {
        'en' => en,
        _ => ja,
      };
}
