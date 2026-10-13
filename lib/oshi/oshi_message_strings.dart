/// 推しの一言が使う状況。[OshiMessageEngine] が選び、文言は [OshiMessageStrings] が持つ。
enum OshiSituation { welcomeBack, struggling, streak, praise, examPace, weakTopic, greeting }

/// 推しの一言の文言（責めない励ましだけ）。`UkalabStrings` とは別にして、既存アプリを壊さない。
///
/// 各状況に 3 件以上の言い回しを持ち、日付の seed で日替わりに選ぶ。
/// [OshiSituation.examPace] の文言は `{n}`（試験までの日数）を含められる。
/// 「サボった」「遅れている」「〜しないと」「ダメ」などの語、残り日数での脅しは使わない
/// （全文言をテストで機械検証する）。ja・en は推敲済み。運営での文言確認は別途必要。
class OshiMessageStrings {
  const OshiMessageStrings({required this.messages, required this.tapHint});

  final Map<OshiSituation, List<String>> messages;

  /// ウィジェットのタップで別の一言が出ることを伝える読み上げ用ヒント。
  final String tapHint;

  /// 状況の言い回し一覧。無い状況は greeting、それも無ければ空。
  List<String> variants(OshiSituation s) =>
      messages[s] ?? messages[OshiSituation.greeting] ?? const [];

  /// 一部の状況だけ差し替える。
  OshiMessageStrings copyWith({Map<OshiSituation, List<String>>? messages, String? tapHint}) =>
      OshiMessageStrings(
        messages: messages == null ? this.messages : {...this.messages, ...messages},
        tapHint: tapHint ?? this.tapHint,
      );

  /// 検査用: 全文言。
  List<String> get allTexts => [for (final l in messages.values) ...l, tapHint];

  static const ja = OshiMessageStrings(
    tapHint: 'タップすると別の一言が出ます',
    messages: {
      OshiSituation.welcomeBack: [
        'おかえり。今日は1問からでいいよ。',
        'また会えてうれしい。ひとつ解くだけでも十分だよ。',
        'おかえりなさい。気が向いたときに、少しだけ始めよう。',
      ],
      OshiSituation.struggling: [
        '間違えた所が伸びしろだよ。',
        '今日は難しい日もあるよね。見直せた分だけ前に進んでいるよ。',
        '間違いは覚えるチャンス。ゆっくりいこう。',
      ],
      OshiSituation.streak: [
        'いい調子。無理せず続けよう。',
        '続いているね。今日もほどほどにいこう。',
        'コツコツが、ちゃんと積み重なっているよ。',
      ],
      OshiSituation.praise: [
        'いいね、今日の分はばっちり。ゆっくり休んでね。',
        '今日もおつかれさま。よくできました。',
        'その調子。ここまでで十分えらいよ。',
      ],
      OshiSituation.examPace: [
        'あと{n}日。自分のペースで大丈夫だよ。',
        '本番まであと{n}日。今日のひと息も力になるよ。',
        'あと{n}日、一緒に少しずつ進もう。',
      ],
      OshiSituation.weakTopic: [
        '苦手な所は、ゆっくり見直せば大丈夫。',
        '気になる分野から、1問だけ触れてみよう。',
        '苦手は伸びしろ。のんびりでいいよ。',
      ],
      OshiSituation.greeting: [
        'こんにちは。今日も一緒にやろう。',
        '気楽に1問、どう？',
        'できる範囲で大丈夫だよ。',
      ],
    },
  );

  static const en = OshiMessageStrings(
    tapHint: 'Tap for another message',
    messages: {
      OshiSituation.welcomeBack: [
        'Welcome back. One question today is plenty.',
        'So glad to see you. Even a single question counts.',
        'Welcome back. Start with a little whenever you feel like it.',
      ],
      OshiSituation.struggling: [
        'The ones you missed are where you can grow.',
        'Some days are tricky. Every review moves you forward.',
        'Mistakes are a chance to remember. Take it slowly.',
      ],
      OshiSituation.streak: [
        'Nice rhythm. Keep going at an easy pace.',
        'You are on a roll. Take it easy today too.',
        'Your steady effort is really adding up.',
      ],
      OshiSituation.praise: [
        'Nicely done. Today\'s study is in good shape. Get some rest.',
        'Good work today. Well done.',
        'Keep it up. What you did today is already plenty.',
      ],
      OshiSituation.examPace: [
        '{n} days to go. Your own pace is just fine.',
        '{n} days until the exam. A short break today helps too.',
        '{n} days left. Let\'s move forward together, bit by bit.',
      ],
      OshiSituation.weakTopic: [
        'Tricky topics are fine. A gentle review will do.',
        'Pick a topic that caught your eye and try just one question.',
        'Weak spots are room to grow. Take your time.',
      ],
      OshiSituation.greeting: [
        'Hi. Let\'s study together today.',
        'How about one easy question?',
        'Whatever you can do is enough.',
      ],
    },
  );

  static OshiMessageStrings forLanguageCode(String code) => switch (code) {
    'en' => en,
    _ => ja,
  };
}
