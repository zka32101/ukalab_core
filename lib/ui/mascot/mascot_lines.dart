import 'mascot_models.dart';

/// セリフの場面。
enum MascotSituation {
  greeting,
  studied,
  streak,
  welcomeBack,
  examApproaching,
  examClose,
  examEve,
  examToday,
  passed,
  tap,
}

/// 推しの口調に合わせたセリフ集。文言はデータとして管理し、月次更新で差し替えられる。
///
/// ルール: 責めない・落ち込まない・いなくなる表現を使わない。恋愛・依存を煽らない。
/// 全文を [findForbiddenExpressions] で検査する（test/mascot_test.dart）。
class MascotLines {
  const MascotLines(this._lines);

  final Map<MascotSituation, List<String>> _lines;

  List<String> of(MascotSituation s) => _lines[s] ?? const [];

  Iterable<String> get all => _lines.values.expand((e) => e);

  /// [seed] で決まる1行（同じ seed なら同じセリフ。テストしやすい）。
  String pick(MascotSituation s, {int seed = 0}) {
    final l = of(s);
    if (l.isEmpty) return '';
    return l[seed.abs() % l.length];
  }

  /// 口調に合ったセリフ。用意のない口調は標準（やさしい）に戻す。
  ///
  /// [lang] は `'en'` で英語、それ以外は日本語。
  /// [custom]（アプリが用意した言語のセリフ）に口調があれば、それを優先する。
  static MascotLines forTone(
    MascotTone tone, {
    String lang = 'ja',
    Map<MascotTone, MascotLines>? custom,
  }) =>
      custom?[tone] ??
      (lang == 'en' ? (_byToneEn[tone] ?? gentleEn) : (_byTone[tone] ?? gentle));

  static const gentle = MascotLines({
    MascotSituation.greeting: ['こんにちは。今日も少しずつ進めましょう', 'ようこそ。ゆっくりで大丈夫です'],
    MascotSituation.studied: ['今日の学習、おつかれさまでした', 'よくできました。着実に進んでいます'],
    MascotSituation.streak: ['続けているのがすばらしいです', '毎日の積み重ねが力になっています'],
    MascotSituation.welcomeBack: ['おかえりなさい。また一緒に進めましょう', 'おかえりなさい。今日は1問からでも大丈夫です'],
    MascotSituation.examApproaching: ['試験日まであと少し。弱点を確認しておきましょう'],
    MascotSituation.examClose: ['もうすぐ試験です。新しいことより、復習を大切に'],
    MascotSituation.examEve: ['明日は試験ですね。持ち物を確認して、早めに休みましょう'],
    MascotSituation.examToday: ['今日は試験です。落ち着いて、いつもどおりに'],
    MascotSituation.passed: ['合格おめでとうございます。これまでの努力の成果です'],
    MascotSituation.tap: ['用語でわからないところは、解説を開いてみましょう', '間違えた問題は、復習で力になります'],
  });

  static const gentleEn = MascotLines({
    MascotSituation.greeting: [
      "Hello! Let's make a little progress today.",
      'Welcome. Taking it slow is perfectly fine.',
    ],
    MascotSituation.studied: [
      "Nice work on today's study session.",
      "Well done. You're moving forward steadily.",
    ],
    MascotSituation.streak: [
      'Keeping at it is wonderful.',
      'Your daily effort is building real strength.',
    ],
    MascotSituation.welcomeBack: [
      "Welcome back! Let's go on together.",
      'Welcome back. Even one question today is great.',
    ],
    MascotSituation.examApproaching: [
      "The exam is getting close. Let's check your weak spots.",
    ],
    MascotSituation.examClose: [
      'The exam is almost here. Focus on review rather than new material.',
    ],
    MascotSituation.examEve: [
      'The exam is tomorrow. Check your things and rest early.',
    ],
    MascotSituation.examToday: [
      'Exam day. Stay calm and do it like you always do.',
    ],
    MascotSituation.passed: [
      "Congratulations on passing! It's the result of your hard work.",
    ],
    MascotSituation.tap: [
      'If a term is unclear, open its explanation.',
      'Questions you missed become strength through review.',
    ],
  });

  static const _byTone = <MascotTone, MascotLines>{MascotTone.gentle: gentle};
  static const _byToneEn = <MascotTone, MascotLines>{MascotTone.gentle: gentleEn};
}

/// 禁止表現（責める・消える・恋愛依存）。推しは応援と成長の関係に限る。
const List<(String, String)> kForbiddenExpressions = [
  // 責める
  ('なんで', '責める'),
  ('どうして', '責める'),
  ('サボ', '責める'),
  ('怠', '責める'),
  ('だめ', '責める'),
  ('ダメ', '責める'),
  ('やる気がない', '責める'),
  ('失望', '責める'),
  ('がっかり', '責める'),
  // 消える・いなくなる・落ち込む
  ('いなくなる', '消える'),
  ('消える', '消える'),
  ('さよなら', '消える'),
  ('もう会えない', '消える'),
  ('お別れ', '消える'),
  ('見捨て', '消える'),
  ('悲しい', '落ち込む'),
  ('泣いて', '落ち込む'),
  // 恋愛・依存
  ('ずっと一緒', '恋愛依存'),
  ('大好き', '恋愛依存'),
  ('愛して', '恋愛依存'),
  ('寂しい', '恋愛依存'),
  ('さみしい', '恋愛依存'),
  ('会いたい', '恋愛依存'),
  ('離れない', '恋愛依存'),
  ('あなただけ', '恋愛依存'),
];

/// 英語の禁止表現（小文字で照合する）。
const List<(String, String)> kForbiddenExpressionsEn = [
  ('why didn', 'blame'),
  ('lazy', 'blame'),
  ('disappoint', 'blame'),
  ('you should have', 'blame'),
  ('slacking', 'blame'),
  ('goodbye', 'disappear'),
  ('farewell', 'disappear'),
  ('leave you', 'disappear'),
  ('never see you', 'disappear'),
  ('so sad', 'down'),
  ('crying', 'down'),
  ('forever together', 'romance/dependence'),
  ('love you', 'romance/dependence'),
  ('miss you', 'romance/dependence'),
  ('lonely', 'romance/dependence'),
  ('only you', 'romance/dependence'),
];

/// 文に含まれる禁止表現を返す（なければ空）。日本語・英語の両方を検査する。
List<String> findForbiddenExpressions(String text) {
  final lower = text.toLowerCase();
  return [
    for (final (word, kind) in kForbiddenExpressions)
      if (text.contains(word)) '$word（$kind）',
    for (final (word, kind) in kForbiddenExpressionsEn)
      if (lower.contains(word)) '$word ($kind)',
  ];
}
