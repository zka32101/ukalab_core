import 'oshi_growth_engine.dart';

/// 成長段階 1 つ分の見た目と一言。
class OshiGrowthStageText {
  const OshiGrowthStageText({required this.emoji, required this.label, required this.messages});

  /// 表情の絵文字。
  final String emoji;

  /// 表情・様子のラベル（「めばえ」など）。
  final String label;

  /// 一言の言い回し（3 件以上）。日付の seed で日替わりに選ぶ。
  final List<String> messages;
}

/// 推しの成長演出の文言（煽らない・休んでも責めない）。`UkalabStrings` とは別にして、既存アプリを壊さない。
///
/// 「サボ」「遅れ」「〜しないと」「ダメ」「焦」「もっと」「まだ」「途切れ」「リセット」「あと◯問」など、
/// 責める・煽る・催促する語は使わない（全文言をテストで機械検証する）。
/// 学習日数は「連続」ではなく「学習した日の合計」なので、休んでも減らない。
/// ja・en は推敲済み。運営での文言確認は別途必要。
class OshiGrowthStrings {
  const OshiGrowthStrings({
    required this.stages,
    required this.answeredTitle,
    required this.daysTitle,
    required this.answeredEmoji,
    required this.daysEmoji,
    required this.milestoneBodies,
    required this.answeredFallbackBody,
    required this.daysFallbackBody,
    required this.tapHint,
    required this.close,
  });

  final Map<OshiGrowthStage, OshiGrowthStageText> stages;

  /// 節目の見出し。`{n}` に節目の値が入る。
  final String answeredTitle;
  final String daysTitle;
  final String answeredEmoji;
  final String daysEmoji;

  /// 節目 ID（`answered_10` など）ごとのひとこと。
  final Map<String, String> milestoneBodies;

  /// 節目 ID に専用文言が無いときの本文。`{n}` に節目の値が入る。
  final String answeredFallbackBody;
  final String daysFallbackBody;

  /// タップで別の一言が出ることを伝える読み上げ用ヒント。
  final String tapHint;
  final String close;

  OshiGrowthStageText stageText(OshiGrowthStage s) =>
      stages[s] ?? stages[OshiGrowthStage.newcomer]!;

  OshiGrowthStrings copyWith({
    Map<OshiGrowthStage, OshiGrowthStageText>? stages,
    String? answeredTitle,
    String? daysTitle,
    String? answeredEmoji,
    String? daysEmoji,
    Map<String, String>? milestoneBodies,
    String? answeredFallbackBody,
    String? daysFallbackBody,
    String? tapHint,
    String? close,
  }) =>
      OshiGrowthStrings(
        stages: stages == null ? this.stages : {...this.stages, ...stages},
        answeredTitle: answeredTitle ?? this.answeredTitle,
        daysTitle: daysTitle ?? this.daysTitle,
        answeredEmoji: answeredEmoji ?? this.answeredEmoji,
        daysEmoji: daysEmoji ?? this.daysEmoji,
        milestoneBodies:
            milestoneBodies == null ? this.milestoneBodies : {...this.milestoneBodies, ...milestoneBodies},
        answeredFallbackBody: answeredFallbackBody ?? this.answeredFallbackBody,
        daysFallbackBody: daysFallbackBody ?? this.daysFallbackBody,
        tapHint: tapHint ?? this.tapHint,
        close: close ?? this.close,
      );

  /// 検査用: 全文言（`{n}` は置換前のまま）。
  List<String> get allTexts => [
        for (final s in stages.values) ...[s.label, ...s.messages],
        answeredTitle,
        daysTitle,
        ...milestoneBodies.values,
        answeredFallbackBody,
        daysFallbackBody,
        tapHint,
        close,
      ];

  static const ja = OshiGrowthStrings(
    tapHint: 'タップすると別の一言が出ます',
    close: 'とじる',
    answeredTitle: '{n}問に到達',
    daysTitle: '学習した日が{n}日に',
    answeredEmoji: '🎉',
    daysEmoji: '🌟',
    answeredFallbackBody: '{n}問ここまで来たね。おつかれさま。',
    daysFallbackBody: '{n}日、一緒に過ごせたね。ありがとう。',
    milestoneBodies: {
      'answered_10': '最初の10問、おつかれさま。ここからも自分のペースでね。',
      'answered_50': '50問をこえたね。少しずつ、ちゃんと力になっているよ。',
      'answered_100': '100問。たくさん向き合ってきたね。いつでも応援しているよ。',
      'answered_300': '300問。積み重ねてきた時間が、あなたの力になっているよ。',
      'answered_1000': '1000問。本当にすごいね。ここまで来たことを、一緒に喜ばせてね。',
      'days_7': '学習した日が7日になったよ。連続でなくて大丈夫。1日1日が宝物だよ。',
      'days_30': '30日分の積み重ね。お休みの日があっても、これまでの分はずっと残っているよ。',
      'days_100': '100日。長い時間を一緒に過ごせてうれしい。これからも、あなたの好きなペースでね。',
    },
    stages: {
      OshiGrowthStage.newcomer: OshiGrowthStageText(
        emoji: '🌱',
        label: 'はじめの一歩',
        messages: ['ここから一緒に始めよう。', '1問ずつで大丈夫だよ。', 'ゆっくり慣れていこうね。'],
      ),
      OshiGrowthStage.budding: OshiGrowthStageText(
        emoji: '🌿',
        label: 'めばえ',
        messages: ['だんだん慣れてきたね。', '少しずつ形になってきているよ。', 'これまでの分が、ちゃんと力になっているよ。'],
      ),
      OshiGrowthStage.growing: OshiGrowthStageText(
        emoji: '🌳',
        label: 'すくすく',
        messages: ['しっかり育ってきたね。自分のペースでいこう。', 'ここまで来たこと、自分で誇っていいよ。', 'お休みしても、積み重ねは消えないよ。'],
      ),
      OshiGrowthStage.blooming: OshiGrowthStageText(
        emoji: '🌸',
        label: 'ひらく',
        messages: ['きれいな花がひらいてきたよ。', 'たくさん積み重ねたね。いつでも戻っておいでね。', '力がついてきたね。のんびりいこう。'],
      ),
      OshiGrowthStage.radiant: OshiGrowthStageText(
        emoji: '✨',
        label: 'かがやき',
        messages: ['すごい積み重ね。いつも一緒だよ。', 'ここまで来たあなたが、いちばんの自慢だよ。', 'これからも、気が向いたときに一緒にやろう。'],
      ),
    },
  );

  static const en = OshiGrowthStrings(
    tapHint: 'Tap for another message',
    close: 'Close',
    answeredTitle: '{n} questions answered',
    daysTitle: '{n} days of study',
    answeredEmoji: '🎉',
    daysEmoji: '🌟',
    answeredFallbackBody: 'You have answered {n} questions. Well done.',
    daysFallbackBody: 'We have spent {n} days together. Thank you.',
    milestoneBodies: {
      'answered_10': 'Your first 10 questions. Nice work. Keep your own pace from here.',
      'answered_50': 'Past 50 questions. Little by little, it is really adding up.',
      'answered_100': '100 questions. You have given them so much time. I am always cheering for you.',
      'answered_300': '300 questions. All the time you put in is becoming your strength.',
      'answered_1000': '1000 questions. That is truly something. Let us celebrate how far you have come.',
      'days_7': '7 days of study. They do not need to be in a row. Every single day counts.',
      'days_30': '30 days of effort. Even with days off, everything you did so far stays with you.',
      'days_100': '100 days. I am happy we spent this long together. Keep going at whatever pace you like.',
    },
    stages: {
      OshiGrowthStage.newcomer: OshiGrowthStageText(
        emoji: '🌱',
        label: 'First steps',
        messages: ['Let us begin together.', 'One question at a time is fine.', 'We can ease into it slowly.'],
      ),
      OshiGrowthStage.budding: OshiGrowthStageText(
        emoji: '🌿',
        label: 'Sprouting',
        messages: ['You are getting used to it.', 'It is taking shape little by little.', 'What you did so far is really helping.'],
      ),
      OshiGrowthStage.growing: OshiGrowthStageText(
        emoji: '🌳',
        label: 'Growing',
        messages: ['You are growing strong. Your own pace is just fine.', 'You can be proud of how far you have come.', 'Taking a break does not erase what you built.'],
      ),
      OshiGrowthStage.blooming: OshiGrowthStageText(
        emoji: '🌸',
        label: 'Blooming',
        messages: ['Beautiful flowers are opening.', 'You have built so much. Come back anytime.', 'You are getting stronger. Take it easy.'],
      ),
      OshiGrowthStage.radiant: OshiGrowthStageText(
        emoji: '✨',
        label: 'Shining',
        messages: ['What a wonderful journey. I am always with you.', 'I am proud of how far you have come.', 'Let us keep going whenever you feel like it.'],
      ),
    },
  );

  static OshiGrowthStrings forLanguageCode(String code) => switch (code) {
        'en' => en,
        _ => ja,
      };
}
