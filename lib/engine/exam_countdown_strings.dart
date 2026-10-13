import 'exam_countdown_engine.dart';

/// 試験日カウントダウンの文言。`UkalabStrings` とは別にして、既存アプリを壊さない。
///
/// 日数を押し付けず「自分のペースで」「今日できること」を添える。final 期でも
/// 「いつもどおりで大丈夫」の調子。煽る・責める語は使わない（全文言をテストで機械検証する）。
/// ja・en は推敲済み。運営での文言確認は別途必要。
class ExamCountdownStrings {
  const ExamCountdownStrings({
    required this.chipDays,
    required this.chipToday,
    required this.chipDone,
    required this.titleDays,
    required this.titleToday,
    required this.titleDone,
    required this.paceFarAway,
    required this.paceApproaching,
    required this.paceClose,
    required this.paceFinal,
    required this.paceToday,
    required this.paceDone,
    required this.todayFarAway,
    required this.todayApproaching,
    required this.todayClose,
    required this.todayFinal,
    required this.todayToday,
    required this.tapHint,
  });

  /// チップの文言（日数入り）。
  final String Function(int days) chipDays;
  final String chipToday;
  final String chipDone;

  /// カードの見出し。
  final String Function(int days) titleDays;
  final String titleToday;
  final String titleDone;

  /// 気持ちの向け方（段階ごと）。
  final String paceFarAway;
  final String paceApproaching;
  final String paceClose;
  final String paceFinal;
  final String paceToday;
  final String paceDone;

  /// 「今日できること」の短い提案（段階ごと。終了後は出さない）。
  final String todayFarAway;
  final String todayApproaching;
  final String todayClose;
  final String todayFinal;
  final String todayToday;

  /// タップで試験日設定を開くときの読み上げ補足。
  final String tapHint;

  String chip(ExamCountdown c) => switch (c.phase) {
        ExamCountdownPhase.none => '',
        ExamCountdownPhase.today => chipToday,
        ExamCountdownPhase.done => chipDone,
        _ => chipDays(c.daysLeft!),
      };

  String title(ExamCountdown c) => switch (c.phase) {
        ExamCountdownPhase.none => '',
        ExamCountdownPhase.today => titleToday,
        ExamCountdownPhase.done => titleDone,
        _ => titleDays(c.daysLeft!),
      };

  String pace(ExamCountdownPhase p) => switch (p) {
        ExamCountdownPhase.none => '',
        ExamCountdownPhase.farAway => paceFarAway,
        ExamCountdownPhase.approaching => paceApproaching,
        ExamCountdownPhase.close => paceClose,
        ExamCountdownPhase.finalDays => paceFinal,
        ExamCountdownPhase.today => paceToday,
        ExamCountdownPhase.done => paceDone,
      };

  /// 今日できること。無い段階（未設定・終了後）は null。
  String? todaySuggestion(ExamCountdownPhase p) => switch (p) {
        ExamCountdownPhase.farAway => todayFarAway,
        ExamCountdownPhase.approaching => todayApproaching,
        ExamCountdownPhase.close => todayClose,
        ExamCountdownPhase.finalDays => todayFinal,
        ExamCountdownPhase.today => todayToday,
        _ => null,
      };

  ExamCountdownStrings copyWith({
    String Function(int days)? chipDays,
    String? chipToday,
    String? chipDone,
    String Function(int days)? titleDays,
    String? titleToday,
    String? titleDone,
    String? paceFarAway,
    String? paceApproaching,
    String? paceClose,
    String? paceFinal,
    String? paceToday,
    String? paceDone,
    String? todayFarAway,
    String? todayApproaching,
    String? todayClose,
    String? todayFinal,
    String? todayToday,
    String? tapHint,
  }) =>
      ExamCountdownStrings(
        chipDays: chipDays ?? this.chipDays,
        chipToday: chipToday ?? this.chipToday,
        chipDone: chipDone ?? this.chipDone,
        titleDays: titleDays ?? this.titleDays,
        titleToday: titleToday ?? this.titleToday,
        titleDone: titleDone ?? this.titleDone,
        paceFarAway: paceFarAway ?? this.paceFarAway,
        paceApproaching: paceApproaching ?? this.paceApproaching,
        paceClose: paceClose ?? this.paceClose,
        paceFinal: paceFinal ?? this.paceFinal,
        paceToday: paceToday ?? this.paceToday,
        paceDone: paceDone ?? this.paceDone,
        todayFarAway: todayFarAway ?? this.todayFarAway,
        todayApproaching: todayApproaching ?? this.todayApproaching,
        todayClose: todayClose ?? this.todayClose,
        todayFinal: todayFinal ?? this.todayFinal,
        todayToday: todayToday ?? this.todayToday,
        tapHint: tapHint ?? this.tapHint,
      );

  /// 検査用: 全文言（関数は代表値で展開する）。
  List<String> get allTexts => [
        chipDays(1), chipDays(7), chipDays(30), chipDays(100), chipDays(200),
        chipToday, chipDone,
        titleDays(1), titleDays(7), titleDays(30), titleDays(100), titleDays(200),
        titleToday, titleDone,
        paceFarAway, paceApproaching, paceClose, paceFinal, paceToday, paceDone,
        todayFarAway, todayApproaching, todayClose, todayFinal, todayToday,
        tapHint,
      ];

  static const ja = ExamCountdownStrings(
    chipDays: _jaChipDays,
    chipToday: '今日が試験日',
    chipDone: 'おつかれさまでした',
    titleDays: _jaTitleDays,
    titleToday: '今日は試験日です',
    titleDone: 'おつかれさまでした',
    paceFarAway: 'まだ時間はたっぷり。自分のペースで。',
    paceApproaching: '自分のペースで続けていけば大丈夫。',
    paceClose: 'いつものペースで、ひとつずつ。',
    paceFinal: 'いつもどおりで大丈夫。',
    paceToday: 'ここまで続けてきた自分を信じて、いつもどおりに。',
    paceDone: 'ゆっくり休んでね。',
    todayFarAway: '今日できること: 1問だけ解いてみる',
    todayApproaching: '今日できること: 気になる分野をひとつ見直す',
    todayClose: '今日できること: 気になった問題を1問見直す',
    todayFinal: '今日できること: 得意な問題を解いて、ゆっくり休む',
    todayToday: '今日できること: 深呼吸して、持ち物をもう一度見る',
    tapHint: 'タップして試験日を設定',
  );

  static const en = ExamCountdownStrings(
    chipDays: _enChipDays,
    chipToday: 'Exam day is today',
    chipDone: 'Well done',
    titleDays: _enTitleDays,
    titleToday: 'Today is exam day',
    titleDone: 'Well done',
    paceFarAway: 'Plenty of time. Go at your own pace.',
    paceApproaching: 'Keep going at your own pace and you\'ll be fine.',
    paceClose: 'Your usual pace, one step at a time.',
    paceFinal: 'Just like usual is perfectly fine.',
    paceToday: 'Trust how far you\'ve come. Just like usual.',
    paceDone: 'Take a good rest.',
    todayFarAway: 'Something to try today: solve one question',
    todayApproaching: 'Something to try today: look again at one topic on your mind',
    todayClose: 'Something to try today: look again at one tricky question',
    todayFinal: 'Something to try today: solve a favorite topic, then rest well',
    todayToday: 'Something to try today: take a deep breath and check your things once more',
    tapHint: 'Tap to set the exam date',
  );

  static ExamCountdownStrings forLanguageCode(String code) => switch (code) {
        'en' => en,
        _ => ja,
      };
}

String _jaChipDays(int n) => 'あと$n日';
String _jaTitleDays(int n) => '試験まで$n日';
String _enChipDays(int n) => n == 1 ? '1 day to go' : '$n days to go';
String _enTitleDays(int n) => n == 1 ? 'The exam is in 1 day' : 'The exam is in $n days';
