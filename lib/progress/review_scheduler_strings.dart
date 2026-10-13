/// 「今日の復習」の文言（煽らない・責めない。たまっても大丈夫、という調子）。`UkalabStrings` とは別にして既存アプリを壊さない。
///
/// 「遅れ」「サボ」「〜しないと」「残り」「期限」「溜」など、急かす・圧をかける語は使わない
/// （全文言をテストで機械検証する）。ja・en は推敲済み。運営での文言確認は別途必要。
class ReviewSchedulerStrings {
  const ReviewSchedulerStrings({
    required this.title,
    required this.dueTemplate,
    required this.dueHint,
    required this.reassure,
    required this.start,
    required this.startHint,
    required this.emptyTitle,
    required this.emptyBody,
  });

  final String title;

  /// 件数の文。`{n}` が件数に置き換わる。
  final String dueTemplate;
  final String dueHint;

  /// 「たまっても大丈夫」の一言。
  final String reassure;

  /// 「やってみる」ボタン。
  final String start;
  final String startHint;
  final String emptyTitle;
  final String emptyBody;

  String dueText(int n) => dueTemplate.replaceAll('{n}', '$n');

  ReviewSchedulerStrings copyWith({
    String? title,
    String? dueTemplate,
    String? dueHint,
    String? reassure,
    String? start,
    String? startHint,
    String? emptyTitle,
    String? emptyBody,
  }) =>
      ReviewSchedulerStrings(
        title: title ?? this.title,
        dueTemplate: dueTemplate ?? this.dueTemplate,
        dueHint: dueHint ?? this.dueHint,
        reassure: reassure ?? this.reassure,
        start: start ?? this.start,
        startHint: startHint ?? this.startHint,
        emptyTitle: emptyTitle ?? this.emptyTitle,
        emptyBody: emptyBody ?? this.emptyBody,
      );

  /// 検査用: 全文言（件数入りの文は 3 件で展開）。
  List<String> get allTexts =>
      [title, dueText(3), dueHint, reassure, start, startHint, emptyTitle, emptyBody];

  static const ja = ReviewSchedulerStrings(
    title: '今日の復習',
    dueTemplate: '{n}問、見返せるよ',
    dueHint: '忘れかけた頃に見ると、しっかり残るよ。',
    reassure: 'たまっても大丈夫。できるときに、できた分だけで。',
    start: 'やってみる',
    startHint: '今日の復習を始める',
    emptyTitle: '今日の復習はおやすみ',
    emptyBody: '見返す時期になったら、ここでそっと知らせるよ。',
  );

  static const en = ReviewSchedulerStrings(
    title: "Today's review",
    dueTemplate: '{n} to revisit',
    dueHint: 'Looking again just as it starts to fade helps it stick.',
    reassure: 'It is fine if they pile up. Do what you can, when you can.',
    start: 'Give it a try',
    startHint: "Start today's review",
    emptyTitle: 'No review today',
    emptyBody: 'We will let you know here when it is time to revisit.',
  );

  static ReviewSchedulerStrings forLanguageCode(String code) => switch (code) {
        'en' => en,
        _ => ja,
      };
}
