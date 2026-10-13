import 'package:app_common_kit/app_common_kit.dart' show KitStrings;
import 'package:flutter/widgets.dart';

import '../../progress/progress_record.dart';
import '../../progress/weak_topics.dart';

/// 解答後フィードバック（原因ラベル・違いの比較・今週の弱点）の文言。
///
/// 言語は [KitStrings.languageCode]（`KitStringsScope`）に従う。内蔵は ja・en・zh（簡体）・
/// zh-Hant（繁体）・ko。それ以外は日本語。ja・en 以外は機械翻訳の下書きで、公開前に母語話者の確認が要る。
/// 引数で [AnswerFeedbackStrings] を渡せば、そちらが優先される。
@immutable
class AnswerFeedbackStrings {
  const AnswerFeedbackStrings({
    required this.causeKnowledge,
    required this.causeTrap,
    required this.causeCalculation,
    required this.causeMisread,
    required this.selectorTitle,
    required this.selectorHint,
    required this.prescriptionTitle,
    required this.prescriptionStudy,
    required this.prescriptionCompare,
    required this.prescriptionCalculation,
    required this.prescriptionMisread,
    required this.comparisonTitle,
    required this.comparisonAnswer,
    required this.comparisonOther,
    required this.weakTitle,
    required this.weakTopTitle,
    required this.weakEmpty,
    required this.weakCauseTitle,
    required this.weakCauseEmpty,
    required this.weakTrendTitle,
    required this.weakTrendNote,
    required this.trendBetter,
    required this.trendWorse,
    required this.trendSame,
    required this.weakAttempts,
  });

  final String causeKnowledge;
  final String causeTrap;
  final String causeCalculation;
  final String causeMisread;
  final String selectorTitle;
  final String selectorHint;
  final String prescriptionTitle;
  final String prescriptionStudy;
  final String prescriptionCompare;
  final String prescriptionCalculation;
  final String prescriptionMisread;
  final String comparisonTitle;
  final String comparisonAnswer;
  final String comparisonOther;
  final String weakTitle;

  /// 「今週の弱点トップN」。
  final String Function(int n) weakTopTitle;
  final String weakEmpty;
  final String weakCauseTitle;
  final String weakCauseEmpty;
  final String weakTrendTitle;
  final String weakTrendNote;
  final String trendBetter;
  final String trendWorse;
  final String trendSame;

  /// 「N問中M問ミス」。
  final String Function(int attempts, int misses) weakAttempts;

  String causeLabel(WrongCause cause) => switch (cause) {
        WrongCause.knowledge => causeKnowledge,
        WrongCause.trap => causeTrap,
        WrongCause.calculation => causeCalculation,
        WrongCause.misread => causeMisread,
      };

  String prescriptionText(WeakPrescription p) => switch (p) {
        WeakPrescription.studyExplanation => prescriptionStudy,
        WeakPrescription.compareFirst => prescriptionCompare,
        WeakPrescription.calculationSteps => prescriptionCalculation,
        WeakPrescription.markKeyPoints => prescriptionMisread,
      };

  static const ja = AnswerFeedbackStrings(
    causeKnowledge: '知識不足',
    causeTrap: 'ひっかけ',
    causeCalculation: '計算ミス',
    causeMisread: '読み違い',
    selectorTitle: '間違えた理由は？',
    selectorHint: '選ばなくても大丈夫です。もう一度押すと取り消せます。',
    prescriptionTitle: 'おすすめの対策',
    prescriptionStudy: '解説と用語カードで、まず意味を押さえましょう。',
    prescriptionCompare: '似た用語の違いを比べてから、もう一度解きましょう。',
    prescriptionCalculation: '計算を1ステップずつ書き出して確認しましょう。',
    prescriptionMisread: '問題文のポイントに印をつけてから選びましょう。',
    comparisonTitle: '違いを比べてみよう',
    comparisonAnswer: '答え',
    comparisonOther: '紛らわしい用語',
    weakTitle: '今週の弱点',
    weakTopTitle: _jaTop,
    weakEmpty: '今週は目立った弱点がありません。',
    weakCauseTitle: '間違えた理由の内訳',
    weakCauseEmpty: '理由を選んだ誤答はまだありません。',
    weakTrendTitle: '自分の先週との比較',
    weakTrendNote: 'ほかの人とは比べません。',
    trendBetter: '先週より改善',
    trendWorse: '先週より悪化',
    trendSame: '先週と同程度',
    weakAttempts: _jaAttempts,
  );

  static const en = AnswerFeedbackStrings(
    causeKnowledge: 'Missing knowledge',
    causeTrap: 'Tricked',
    causeCalculation: 'Calculation slip',
    causeMisread: 'Misread',
    selectorTitle: 'Why did you miss it?',
    selectorHint: 'Optional. Tap again to undo.',
    prescriptionTitle: 'Suggested next step',
    prescriptionStudy: 'Read the explanation and term card to get the meaning down first.',
    prescriptionCompare: 'Compare the look-alike terms, then try again.',
    prescriptionCalculation: 'Write out the calculation one step at a time.',
    prescriptionMisread: 'Mark the key points in the question before choosing.',
    comparisonTitle: 'Compare the differences',
    comparisonAnswer: 'Answer',
    comparisonOther: 'Look-alike',
    weakTitle: 'This week\'s weak spots',
    weakTopTitle: _enTop,
    weakEmpty: 'No standout weak spots this week.',
    weakCauseTitle: 'Why you missed',
    weakCauseEmpty: 'No misses with a reason yet.',
    weakTrendTitle: 'Compared with your last week',
    weakTrendNote: 'Never compared with other people.',
    trendBetter: 'Better than last week',
    trendWorse: 'Worse than last week',
    trendSame: 'About the same as last week',
    weakAttempts: _enAttempts,
  );

  // 簡体字・繁体字・韓国語は機械翻訳の下書き。公開前に母語話者の確認が要る。
  static const zhHans = AnswerFeedbackStrings(
    causeKnowledge: '知识不足',
    causeTrap: '被陷阱迷惑',
    causeCalculation: '计算失误',
    causeMisread: '看错题意',
    selectorTitle: '答错的原因是？',
    selectorHint: '可以不选。再点一次即可取消。',
    prescriptionTitle: '建议的对策',
    prescriptionStudy: '先通过解析和术语卡片弄清含义。',
    prescriptionCompare: '先比较相似术语的区别，再做一次。',
    prescriptionCalculation: '把计算一步一步写出来确认。',
    prescriptionMisread: '先在题目要点上做标记再作答。',
    comparisonTitle: '比较一下区别',
    comparisonAnswer: '答案',
    comparisonOther: '易混淆的术语',
    weakTitle: '本周的薄弱点',
    weakTopTitle: _zhTop,
    weakEmpty: '本周没有明显的薄弱点。',
    weakCauseTitle: '答错原因的分布',
    weakCauseEmpty: '还没有选择过原因的错题。',
    weakTrendTitle: '与自己上周的对比',
    weakTrendNote: '不会与其他人比较。',
    trendBetter: '比上周进步',
    trendWorse: '比上周退步',
    trendSame: '与上周持平',
    weakAttempts: _zhAttempts,
  );

  static const zhHant = AnswerFeedbackStrings(
    causeKnowledge: '知識不足',
    causeTrap: '被陷阱迷惑',
    causeCalculation: '計算失誤',
    causeMisread: '看錯題意',
    selectorTitle: '答錯的原因是？',
    selectorHint: '可以不選。再點一次即可取消。',
    prescriptionTitle: '建議的對策',
    prescriptionStudy: '先透過解析和術語卡片弄清含義。',
    prescriptionCompare: '先比較相似術語的差異，再做一次。',
    prescriptionCalculation: '把計算一步一步寫出來確認。',
    prescriptionMisread: '先在題目重點上做記號再作答。',
    comparisonTitle: '比較一下差異',
    comparisonAnswer: '答案',
    comparisonOther: '易混淆的術語',
    weakTitle: '本週的弱點',
    weakTopTitle: _zhHantTop,
    weakEmpty: '本週沒有明顯的弱點。',
    weakCauseTitle: '答錯原因的分布',
    weakCauseEmpty: '還沒有選擇過原因的錯題。',
    weakTrendTitle: '與自己上週的比較',
    weakTrendNote: '不會與其他人比較。',
    trendBetter: '比上週進步',
    trendWorse: '比上週退步',
    trendSame: '與上週持平',
    weakAttempts: _zhHantAttempts,
  );

  static const ko = AnswerFeedbackStrings(
    causeKnowledge: '지식 부족',
    causeTrap: '함정에 걸림',
    causeCalculation: '계산 실수',
    causeMisread: '문제를 잘못 읽음',
    selectorTitle: '틀린 이유는?',
    selectorHint: '선택하지 않아도 됩니다. 다시 누르면 취소돼요.',
    prescriptionTitle: '추천 대책',
    prescriptionStudy: '해설과 용어 카드로 먼저 의미를 확인해요.',
    prescriptionCompare: '비슷한 용어의 차이를 비교한 뒤 다시 풀어 봐요.',
    prescriptionCalculation: '계산을 한 단계씩 적어서 확인해요.',
    prescriptionMisread: '문제의 핵심에 표시를 한 뒤 고르세요.',
    comparisonTitle: '차이를 비교해 봐요',
    comparisonAnswer: '정답',
    comparisonOther: '헷갈리는 용어',
    weakTitle: '이번 주의 약점',
    weakTopTitle: _koTop,
    weakEmpty: '이번 주에는 눈에 띄는 약점이 없어요.',
    weakCauseTitle: '틀린 이유의 내역',
    weakCauseEmpty: '이유를 선택한 오답이 아직 없어요.',
    weakTrendTitle: '지난주 나와의 비교',
    weakTrendNote: '다른 사람과는 비교하지 않아요.',
    trendBetter: '지난주보다 좋아짐',
    trendWorse: '지난주보다 나빠짐',
    trendSame: '지난주와 비슷함',
    weakAttempts: _koAttempts,
  );

  /// [KitStrings.languageCode] に対応する文言。無い言語は日本語。
  static AnswerFeedbackStrings forLanguageCode(String code) => switch (code) {
        'en' => en,
        'ko' => ko,
        'zh' => zhHans,
        'zh-Hant' => zhHant,
        _ => ja,
      };

  /// 最も近い `KitStringsScope` の言語に合う文言。無ければ日本語。
  static AnswerFeedbackStrings of(BuildContext context) =>
      forLanguageCode(KitStrings.of(context).languageCode);
}

String _jaTop(int n) => '今週の弱点トップ$n';
String _enTop(int n) => 'Top $n weak spots this week';
String _zhTop(int n) => '本周薄弱点前$n名';
String _zhHantTop(int n) => '本週弱點前$n名';
String _koTop(int n) => '이번 주 약점 TOP $n';
String _jaAttempts(int a, int m) => '$a問中$m問ミス';
String _enAttempts(int a, int m) => '$m of $a missed';
String _zhAttempts(int a, int m) => '$a题中错$m题';
String _zhHantAttempts(int a, int m) => '$a題中錯$m題';
String _koAttempts(int a, int m) => '$a문제 중 $m문제 오답';
