/// 模擬試験の結果分析の文言（「今日はここを少しだけ」調。点数で責めない）。
///
/// 「ダメ」「弱い」「足りない」「失敗」「急いで」「〜しないと」など、責める・煽る語は使わない
/// （全文言をテストで機械検証する）。ja・en は推敲済み。運営での文言確認は別途必要。
class MockExamAnalysisStrings {
  const MockExamAnalysisStrings({
    required this.title,
    required this.summaryLabel,
    required this.byTopicLabel,
    required this.growLabel,
    required this.nextLabel,
    required this.nextLead,
    required this.allGoodBody,
    required this.questionsUnit,
    required this.correctUnit,
    required this.emptyTitle,
    required this.emptyBody,
  });

  final String title;
  final String summaryLabel;
  final String byTopicLabel;

  /// 弱点分野の見出し（「伸びしろのある分野」調）。
  final String growLabel;
  final String nextLabel;
  final String nextLead;

  /// 次にやる分野が無いとき（どの分野も安定している）の本文。
  final String allGoodBody;

  /// 数値のあとの単位（無ければ空文字）。
  final String questionsUnit;
  final String correctUnit;
  final String emptyTitle;
  final String emptyBody;

  List<String> get allTexts => [
        title, summaryLabel, byTopicLabel, growLabel, nextLabel, nextLead, allGoodBody,
        questionsUnit, correctUnit, emptyTitle, emptyBody,
      ];

  static const ja = MockExamAnalysisStrings(
    title: '模擬試験のふりかえり',
    summaryLabel: '解いた問題',
    byTopicLabel: '分野ごとの様子',
    growLabel: '伸びしろのある分野',
    nextLabel: '今日はここを少しだけ',
    nextLead: '次はこの分野を、1問からのんびりどうぞ。',
    allGoodBody: 'どの分野も落ち着いています。好きな分野から続けよう。',
    questionsUnit: '問',
    correctUnit: '問正解',
    emptyTitle: 'まだ結果がありません',
    emptyBody: '模擬試験を解くと、ここに分野ごとの様子が出ます。',
  );

  static const en = MockExamAnalysisStrings(
    title: 'Mock exam review',
    summaryLabel: 'Questions solved',
    byTopicLabel: 'Topic by topic',
    growLabel: 'Room to grow',
    nextLabel: 'A little of this today',
    nextLead: 'Next time, try one question from these at your own pace.',
    allGoodBody: 'Every topic looks steady. Pick whatever you like.',
    questionsUnit: '',
    correctUnit: ' right',
    emptyTitle: 'No results yet',
    emptyBody: 'Once you take a mock exam, your topics will show up here.',
  );

  static MockExamAnalysisStrings forLanguageCode(String code) => switch (code) {
        'en' => en,
        _ => ja,
      };
}
