import 'package:flutter/widgets.dart';

import 'package:app_common_kit/app_common_kit.dart' show KitStrings;

/// ラボ系ウィジェット（機械学習ラボ・ニューラルネット・畳み込み・用語カードなど）の既定文言（日本語・英語）。
///
/// 既定は日本語。[KitStringsScope] の言語が英語のときだけ英語になる
/// （[LabStrings.of]）。既存アプリの表示は変わらない。
@immutable
class LabStrings {
  const LabStrings({
    required this.wrongTryAgain,
    required this.gotIt,
    required this.class0,
    required this.class1,
    required this.mlKnn,
    required this.mlDecisionTree,
    required this.mlLinear,
    required this.mlDepth,
    required this.mlRegularization,
    required this.mlKnnSmallHint,
    required this.mlKnnLargeHint,
    required this.mlKnnMidHint,
    required this.mlTreeShallowHint,
    required this.mlTreeDeepHint,
    required this.mlTreeMidHint,
    required this.mlLinearWeakHint,
    required this.mlLinearStrongHint,
    required this.mlLinearMidHint,
    required this.nnHiddenLayers,
    required this.nnLayerCount,
    required this.nnUnits,
    required this.nnActivation,
    required this.nnSigmoid,
    required this.nnLearningRate,
    required this.nnBoundary,
    required this.nnLossCurve,
    required this.nnLossSummary,
    required this.nnFewUnitsHint,
    required this.nnManyUnitsHint,
    required this.nnHighRateHint,
    required this.nnLowRateHint,
    required this.nnMidHint,
    required this.convVerticalEdge,
    required this.convHorizontalEdge,
    required this.convBlur,
    required this.convSharpen,
    required this.convVerticalEdgeHint,
    required this.convHorizontalEdgeHint,
    required this.convBlurHint,
    required this.convSharpenHint,
    required this.convInput,
    required this.convFeatureMap,
    required this.convPooled,
    required this.convPoolingNote,
    required this.cmTp,
    required this.cmFp,
    required this.cmFn,
    required this.cmTn,
    required this.cmAccuracy,
    required this.cmPrecision,
    required this.cmRecall,
    required this.cmF1,
    required this.trainError,
    required this.validationError,
    required this.symptomPrompt,
    required this.symptomIs,
    required this.treatmentPrompt,
    required this.attentionNote,
    required this.attentionPickQuery,
    required this.attentionSummary,
    required this.boundaryDisclaimer,
    required this.boundaryUnset,
    required this.boundaryBasis,
    required this.predictButton,
    required this.predictYours,
    required this.predictCorrect,
    required this.predictAgain,
    required this.routeEmpty,
    required this.routeToday,
    required this.routeBelowCutoff,
    required this.statsTitle,
    required this.statsAverage,
    required this.statsMyScore,
    required this.statsDeviation,
    required this.storyChapterOf,
    required this.storyHowJudge,
    required this.storyGood,
    required this.storyOther,
    required this.storySeeResult,
    required this.storyNext,
    required this.storyEnd,
    required this.storyChapterLine,
    required this.termAnalogy,
    required this.termCommonMistake,
    required this.termRelatedTerms,
    required this.termRelatedQuestions,
    required this.termMapHistory,
    required this.termMapEraNote,
    required this.termMapTitle,
    required this.mascotStuck,
    required this.aiNewsTitle,
    required this.aiNewsAsOf,
    required this.aiNewsExamLikely,
    required this.readinessTitle,
    required this.readinessReady,
    required this.readinessMasteryDone,
    required this.readinessLeftWithMock,
    required this.readinessLeft,
    required this.questionNo,
    required this.questionNoOfTotal,
    required this.progressDefault,
  });

  final String wrongTryAgain;
  final String gotIt;
  final String class0;
  final String class1;
  final String mlKnn;
  final String mlDecisionTree;
  final String mlLinear;
  final String mlDepth;
  final String mlRegularization;
  final String mlKnnSmallHint;
  final String mlKnnLargeHint;
  final String mlKnnMidHint;
  final String mlTreeShallowHint;
  final String mlTreeDeepHint;
  final String mlTreeMidHint;
  final String mlLinearWeakHint;
  final String mlLinearStrongHint;
  final String mlLinearMidHint;
  final String nnHiddenLayers;
  final String Function(int) nnLayerCount;
  final String nnUnits;
  final String nnActivation;
  final String nnSigmoid;
  final String nnLearningRate;
  final String nnBoundary;
  final String nnLossCurve;
  final String Function(String, String, int) nnLossSummary;
  final String nnFewUnitsHint;
  final String nnManyUnitsHint;
  final String nnHighRateHint;
  final String nnLowRateHint;
  final String nnMidHint;
  final String convVerticalEdge;
  final String convHorizontalEdge;
  final String convBlur;
  final String convSharpen;
  final String convVerticalEdgeHint;
  final String convHorizontalEdgeHint;
  final String convBlurHint;
  final String convSharpenHint;
  final String convInput;
  final String convFeatureMap;
  final String convPooled;
  final String convPoolingNote;
  final String cmTp;
  final String cmFp;
  final String cmFn;
  final String cmTn;
  final String cmAccuracy;
  final String cmPrecision;
  final String cmRecall;
  final String cmF1;
  final String trainError;
  final String validationError;
  final String symptomPrompt;
  final String Function(String) symptomIs;
  final String treatmentPrompt;
  final String attentionNote;
  final String attentionPickQuery;
  final String Function(String, String, int) attentionSummary;
  final String boundaryDisclaimer;
  final String boundaryUnset;
  final String Function(String) boundaryBasis;
  final String predictButton;
  final String predictYours;
  final String predictCorrect;
  final String predictAgain;
  final String routeEmpty;
  final String Function(int) routeToday;
  final String routeBelowCutoff;
  final String statsTitle;
  final String Function(String, int) statsAverage;
  final String Function(int) statsMyScore;
  final String Function(String) statsDeviation;
  final String Function(int, int) storyChapterOf;
  final String storyHowJudge;
  final String storyGood;
  final String storyOther;
  final String storySeeResult;
  final String storyNext;
  final String Function(int, int) storyEnd;
  final String Function(int, String) storyChapterLine;
  final String termAnalogy;
  final String termCommonMistake;
  final String termRelatedTerms;
  final String termRelatedQuestions;
  final String termMapHistory;
  final String termMapEraNote;
  final String termMapTitle;
  final String mascotStuck;
  final String aiNewsTitle;
  final String Function(int, int) aiNewsAsOf;
  final String aiNewsExamLikely;
  final String readinessTitle;
  final String readinessReady;
  final String readinessMasteryDone;
  final String Function(int) readinessLeftWithMock;
  final String Function(int) readinessLeft;
  final String Function(int) questionNo;
  final String Function(int, int) questionNoOfTotal;
  final String progressDefault;

  /// 一部の文言だけ差し替えた複製を返す（ほかの言語の土台にも使える）。
  LabStrings copyWith({
    String? wrongTryAgain,
    String? gotIt,
    String? class0,
    String? class1,
    String? mlKnn,
    String? mlDecisionTree,
    String? mlLinear,
    String? mlDepth,
    String? mlRegularization,
    String? mlKnnSmallHint,
    String? mlKnnLargeHint,
    String? mlKnnMidHint,
    String? mlTreeShallowHint,
    String? mlTreeDeepHint,
    String? mlTreeMidHint,
    String? mlLinearWeakHint,
    String? mlLinearStrongHint,
    String? mlLinearMidHint,
    String? nnHiddenLayers,
    String Function(int)? nnLayerCount,
    String? nnUnits,
    String? nnActivation,
    String? nnSigmoid,
    String? nnLearningRate,
    String? nnBoundary,
    String? nnLossCurve,
    String Function(String, String, int)? nnLossSummary,
    String? nnFewUnitsHint,
    String? nnManyUnitsHint,
    String? nnHighRateHint,
    String? nnLowRateHint,
    String? nnMidHint,
    String? convVerticalEdge,
    String? convHorizontalEdge,
    String? convBlur,
    String? convSharpen,
    String? convVerticalEdgeHint,
    String? convHorizontalEdgeHint,
    String? convBlurHint,
    String? convSharpenHint,
    String? convInput,
    String? convFeatureMap,
    String? convPooled,
    String? convPoolingNote,
    String? cmTp,
    String? cmFp,
    String? cmFn,
    String? cmTn,
    String? cmAccuracy,
    String? cmPrecision,
    String? cmRecall,
    String? cmF1,
    String? trainError,
    String? validationError,
    String? symptomPrompt,
    String Function(String)? symptomIs,
    String? treatmentPrompt,
    String? attentionNote,
    String? attentionPickQuery,
    String Function(String, String, int)? attentionSummary,
    String? boundaryDisclaimer,
    String? boundaryUnset,
    String Function(String)? boundaryBasis,
    String? predictButton,
    String? predictYours,
    String? predictCorrect,
    String? predictAgain,
    String? routeEmpty,
    String Function(int)? routeToday,
    String? routeBelowCutoff,
    String? statsTitle,
    String Function(String, int)? statsAverage,
    String Function(int)? statsMyScore,
    String Function(String)? statsDeviation,
    String Function(int, int)? storyChapterOf,
    String? storyHowJudge,
    String? storyGood,
    String? storyOther,
    String? storySeeResult,
    String? storyNext,
    String Function(int, int)? storyEnd,
    String Function(int, String)? storyChapterLine,
    String? termAnalogy,
    String? termCommonMistake,
    String? termRelatedTerms,
    String? termRelatedQuestions,
    String? termMapHistory,
    String? termMapEraNote,
    String? termMapTitle,
    String? mascotStuck,
    String? aiNewsTitle,
    String Function(int, int)? aiNewsAsOf,
    String? aiNewsExamLikely,
    String? readinessTitle,
    String? readinessReady,
    String? readinessMasteryDone,
    String Function(int)? readinessLeftWithMock,
    String Function(int)? readinessLeft,
    String Function(int)? questionNo,
    String Function(int, int)? questionNoOfTotal,
    String? progressDefault,
  }) =>
      LabStrings(
      wrongTryAgain: wrongTryAgain ?? this.wrongTryAgain,
      gotIt: gotIt ?? this.gotIt,
      class0: class0 ?? this.class0,
      class1: class1 ?? this.class1,
      mlKnn: mlKnn ?? this.mlKnn,
      mlDecisionTree: mlDecisionTree ?? this.mlDecisionTree,
      mlLinear: mlLinear ?? this.mlLinear,
      mlDepth: mlDepth ?? this.mlDepth,
      mlRegularization: mlRegularization ?? this.mlRegularization,
      mlKnnSmallHint: mlKnnSmallHint ?? this.mlKnnSmallHint,
      mlKnnLargeHint: mlKnnLargeHint ?? this.mlKnnLargeHint,
      mlKnnMidHint: mlKnnMidHint ?? this.mlKnnMidHint,
      mlTreeShallowHint: mlTreeShallowHint ?? this.mlTreeShallowHint,
      mlTreeDeepHint: mlTreeDeepHint ?? this.mlTreeDeepHint,
      mlTreeMidHint: mlTreeMidHint ?? this.mlTreeMidHint,
      mlLinearWeakHint: mlLinearWeakHint ?? this.mlLinearWeakHint,
      mlLinearStrongHint: mlLinearStrongHint ?? this.mlLinearStrongHint,
      mlLinearMidHint: mlLinearMidHint ?? this.mlLinearMidHint,
      nnHiddenLayers: nnHiddenLayers ?? this.nnHiddenLayers,
      nnLayerCount: nnLayerCount ?? this.nnLayerCount,
      nnUnits: nnUnits ?? this.nnUnits,
      nnActivation: nnActivation ?? this.nnActivation,
      nnSigmoid: nnSigmoid ?? this.nnSigmoid,
      nnLearningRate: nnLearningRate ?? this.nnLearningRate,
      nnBoundary: nnBoundary ?? this.nnBoundary,
      nnLossCurve: nnLossCurve ?? this.nnLossCurve,
      nnLossSummary: nnLossSummary ?? this.nnLossSummary,
      nnFewUnitsHint: nnFewUnitsHint ?? this.nnFewUnitsHint,
      nnManyUnitsHint: nnManyUnitsHint ?? this.nnManyUnitsHint,
      nnHighRateHint: nnHighRateHint ?? this.nnHighRateHint,
      nnLowRateHint: nnLowRateHint ?? this.nnLowRateHint,
      nnMidHint: nnMidHint ?? this.nnMidHint,
      convVerticalEdge: convVerticalEdge ?? this.convVerticalEdge,
      convHorizontalEdge: convHorizontalEdge ?? this.convHorizontalEdge,
      convBlur: convBlur ?? this.convBlur,
      convSharpen: convSharpen ?? this.convSharpen,
      convVerticalEdgeHint: convVerticalEdgeHint ?? this.convVerticalEdgeHint,
      convHorizontalEdgeHint: convHorizontalEdgeHint ?? this.convHorizontalEdgeHint,
      convBlurHint: convBlurHint ?? this.convBlurHint,
      convSharpenHint: convSharpenHint ?? this.convSharpenHint,
      convInput: convInput ?? this.convInput,
      convFeatureMap: convFeatureMap ?? this.convFeatureMap,
      convPooled: convPooled ?? this.convPooled,
      convPoolingNote: convPoolingNote ?? this.convPoolingNote,
      cmTp: cmTp ?? this.cmTp,
      cmFp: cmFp ?? this.cmFp,
      cmFn: cmFn ?? this.cmFn,
      cmTn: cmTn ?? this.cmTn,
      cmAccuracy: cmAccuracy ?? this.cmAccuracy,
      cmPrecision: cmPrecision ?? this.cmPrecision,
      cmRecall: cmRecall ?? this.cmRecall,
      cmF1: cmF1 ?? this.cmF1,
      trainError: trainError ?? this.trainError,
      validationError: validationError ?? this.validationError,
      symptomPrompt: symptomPrompt ?? this.symptomPrompt,
      symptomIs: symptomIs ?? this.symptomIs,
      treatmentPrompt: treatmentPrompt ?? this.treatmentPrompt,
      attentionNote: attentionNote ?? this.attentionNote,
      attentionPickQuery: attentionPickQuery ?? this.attentionPickQuery,
      attentionSummary: attentionSummary ?? this.attentionSummary,
      boundaryDisclaimer: boundaryDisclaimer ?? this.boundaryDisclaimer,
      boundaryUnset: boundaryUnset ?? this.boundaryUnset,
      boundaryBasis: boundaryBasis ?? this.boundaryBasis,
      predictButton: predictButton ?? this.predictButton,
      predictYours: predictYours ?? this.predictYours,
      predictCorrect: predictCorrect ?? this.predictCorrect,
      predictAgain: predictAgain ?? this.predictAgain,
      routeEmpty: routeEmpty ?? this.routeEmpty,
      routeToday: routeToday ?? this.routeToday,
      routeBelowCutoff: routeBelowCutoff ?? this.routeBelowCutoff,
      statsTitle: statsTitle ?? this.statsTitle,
      statsAverage: statsAverage ?? this.statsAverage,
      statsMyScore: statsMyScore ?? this.statsMyScore,
      statsDeviation: statsDeviation ?? this.statsDeviation,
      storyChapterOf: storyChapterOf ?? this.storyChapterOf,
      storyHowJudge: storyHowJudge ?? this.storyHowJudge,
      storyGood: storyGood ?? this.storyGood,
      storyOther: storyOther ?? this.storyOther,
      storySeeResult: storySeeResult ?? this.storySeeResult,
      storyNext: storyNext ?? this.storyNext,
      storyEnd: storyEnd ?? this.storyEnd,
      storyChapterLine: storyChapterLine ?? this.storyChapterLine,
      termAnalogy: termAnalogy ?? this.termAnalogy,
      termCommonMistake: termCommonMistake ?? this.termCommonMistake,
      termRelatedTerms: termRelatedTerms ?? this.termRelatedTerms,
      termRelatedQuestions: termRelatedQuestions ?? this.termRelatedQuestions,
      termMapHistory: termMapHistory ?? this.termMapHistory,
      termMapEraNote: termMapEraNote ?? this.termMapEraNote,
      termMapTitle: termMapTitle ?? this.termMapTitle,
      mascotStuck: mascotStuck ?? this.mascotStuck,
      aiNewsTitle: aiNewsTitle ?? this.aiNewsTitle,
      aiNewsAsOf: aiNewsAsOf ?? this.aiNewsAsOf,
      aiNewsExamLikely: aiNewsExamLikely ?? this.aiNewsExamLikely,
      readinessTitle: readinessTitle ?? this.readinessTitle,
      readinessReady: readinessReady ?? this.readinessReady,
      readinessMasteryDone: readinessMasteryDone ?? this.readinessMasteryDone,
      readinessLeftWithMock: readinessLeftWithMock ?? this.readinessLeftWithMock,
      readinessLeft: readinessLeft ?? this.readinessLeft,
      questionNo: questionNo ?? this.questionNo,
      questionNoOfTotal: questionNoOfTotal ?? this.questionNoOfTotal,
      progressDefault: progressDefault ?? this.progressDefault,
      );

  static const ja = LabStrings(
    wrongTryAgain: 'んー、違うかも。もう一度選んでみて。',
    gotIt: 'わかった!',
    class0: 'クラス0',
    class1: 'クラス1',
    mlKnn: 'k近傍法',
    mlDecisionTree: '決定木',
    mlLinear: '線形分類',
    mlDepth: '深さ',
    mlRegularization: '正則化',
    mlKnnSmallHint: 'kが小さいと、1点の近くだけ見て判断するため境界が複雑になりすぎます（過学習）。',
    mlKnnLargeHint: 'kが大きいと、遠くの点まで見てしまい境界が単純になりすぎます（未学習）。',
    mlKnnMidHint: 'kを変えて、境界がどう変わるか見てみましょう。',
    mlTreeShallowHint: '深さが浅いと、分け方が単純すぎます（未学習）。',
    mlTreeDeepHint: '深さが深いと、データに合わせすぎて境界がギザギザになります（過学習）。',
    mlTreeMidHint: '深さを変えて、境界がどう変わるか見てみましょう。',
    mlLinearWeakHint: '正則化が弱いと、境界が訓練データに寄りすぎることがあります（過学習）。',
    mlLinearStrongHint: '正則化が強いと、境界が単純な直線に近づきすぎます（未学習）。',
    mlLinearMidHint: '正則化の強さを変えて、境界がどう変わるか見てみましょう。',
    nnHiddenLayers: '隠れ層の数',
    nnLayerCount: _jaNnLayerCount,
    nnUnits: 'ユニット数',
    nnActivation: '活性化関数',
    nnSigmoid: 'シグモイド',
    nnLearningRate: '学習率',
    nnBoundary: '決定境界',
    nnLossCurve: '学習曲線（訓練誤差）',
    nnLossSummary: _jaNnLossSummary,
    nnFewUnitsHint: 'ユニット数が少ないと、表現力が足りず複雑な境界を学習できません（未学習）。',
    nnManyUnitsHint: 'ユニット数が多いと、小さなデータに合わせすぎることがあります（過学習）。',
    nnHighRateHint: '学習率が大きすぎると、誤差が振動して学習が安定しないことがあります。',
    nnLowRateHint: '学習率が小さいと、決められたエポック数では十分に学習が進みません（未学習）。',
    nnMidHint: 'ユニット数・学習率を変えて、学習曲線と決定境界がどう変わるか見てみましょう。',
    convVerticalEdge: '縦エッジ検出',
    convHorizontalEdge: '横エッジ検出',
    convBlur: 'ぼかし',
    convSharpen: 'シャープ化',
    convVerticalEdgeHint: '縦方向の明暗の変化（左右のエッジ）を強調するフィルタです。',
    convHorizontalEdgeHint: '横方向の明暗の変化（上下のエッジ）を強調するフィルタです。',
    convBlurHint: '周囲の画素を均して滑らかにするフィルタです。',
    convSharpenHint: '中心の画素を周囲との差で強調するフィルタです。',
    convInput: '入力画像',
    convFeatureMap: '特徴マップ',
    convPooled: 'プーリング後',
    convPoolingNote: 'プーリング（2x2のmax pooling）で、特徴マップが縦横半分に縮小されます。',
    cmTp: 'TP（真陽性）',
    cmFp: 'FP（偽陽性）',
    cmFn: 'FN（偽陰性）',
    cmTn: 'TN（真陰性）',
    cmAccuracy: '正解率',
    cmPrecision: '適合率',
    cmRecall: '再現率',
    cmF1: 'F値',
    trainError: '訓練誤差',
    validationError: '検証誤差',
    symptomPrompt: 'この学習曲線の症状は?',
    symptomIs: _jaSymptomIs,
    treatmentPrompt: 'この症状への処方は?',
    attentionNote: '※ 実際のモデルの出力ではなく、教育用に用意した固定データです。',
    attentionPickQuery: '注目する単語（クエリ）を選んでください',
    attentionSummary: _jaAttentionSummary,
    boundaryDisclaimer: '※ 条件の切り替えで判定の目安がどう変わるかを体験するものです。実際の判断は必ず原文・専門家にご確認ください。',
    boundaryUnset: 'この組み合わせの判定は未設定です',
    boundaryBasis: _jaBoundaryBasis,
    predictButton: '予測する',
    predictYours: 'あなたの予測',
    predictCorrect: '正解',
    predictAgain: 'もう一度予測する',
    routeEmpty: '今はやることがありません。よくできました!',
    routeToday: _jaRouteToday,
    routeBelowCutoff: '足切りライン未達',
    statsTitle: '全国平均との比較',
    statsAverage: _jaStatsAverage,
    statsMyScore: _jaStatsMyScore,
    statsDeviation: _jaStatsDeviation,
    storyChapterOf: _jaStoryChapterOf,
    storyHowJudge: 'どう判断しますか?',
    storyGood: 'よい判断です',
    storyOther: '別の判断もありました',
    storySeeResult: '結果を見る',
    storyNext: '次の章へ',
    storyEnd: _jaStoryEnd,
    storyChapterLine: _jaStoryChapterLine,
    termAnalogy: 'たとえると',
    termCommonMistake: 'よくある間違い',
    termRelatedTerms: '関連用語',
    termRelatedQuestions: '関連問題',
    termMapHistory: 'AIの歴史（系譜図）',
    termMapEraNote: '時代区分は学習用の目安です。厳密な年代の区切りではありません。',
    termMapTitle: '用語マップ（関連でつながる用語）',
    mascotStuck: 'ここが分からない…',
    aiNewsTitle: '今月のAI動向',
    aiNewsAsOf: _jaAiNewsAsOf,
    aiNewsExamLikely: '試験に出そう',
    readinessTitle: '準備完了まで',
    readinessReady: '準備完了です。本番、応援しています',
    readinessMasteryDone: '習得度は十分です。あとは模擬試験で合格点を超えるだけ',
    readinessLeftWithMock: _jaReadinessLeftWithMock,
    readinessLeft: _jaReadinessLeft,
    questionNo: _jaQuestionNo,
    questionNoOfTotal: _jaQuestionNoOfTotal,
    progressDefault: '進捗',
  );

  static const en = LabStrings(
    wrongTryAgain: 'Hmm, not quite. Give it another try.',
    gotIt: 'Got it!',
    class0: 'Class 0',
    class1: 'Class 1',
    mlKnn: 'k-NN',
    mlDecisionTree: 'Decision tree',
    mlLinear: 'Linear classifier',
    mlDepth: 'Depth',
    mlRegularization: 'Regularization',
    mlKnnSmallHint: 'With a small k, each decision looks only at the nearest point or two, so the boundary gets too complicated (overfitting).',
    mlKnnLargeHint: 'With a large k, far-away points get included too, so the boundary gets too simple (underfitting).',
    mlKnnMidHint: 'Change k and see how the boundary changes.',
    mlTreeShallowHint: 'A shallow tree splits the data too simply (underfitting).',
    mlTreeDeepHint: 'A deep tree fits the data too closely, so the boundary gets jagged (overfitting).',
    mlTreeMidHint: 'Change the depth and see how the boundary changes.',
    mlLinearWeakHint: 'With weak regularization, the boundary can stick too closely to the training data (overfitting).',
    mlLinearStrongHint: 'With strong regularization, the boundary becomes too close to a plain straight line (underfitting).',
    mlLinearMidHint: 'Change the regularization strength and see how the boundary changes.',
    nnHiddenLayers: 'Number of hidden layers',
    nnLayerCount: _enNnLayerCount,
    nnUnits: 'Units',
    nnActivation: 'Activation function',
    nnSigmoid: 'Sigmoid',
    nnLearningRate: 'Learning rate',
    nnBoundary: 'Decision boundary',
    nnLossCurve: 'Learning curve (training error)',
    nnLossSummary: _enNnLossSummary,
    nnFewUnitsHint: 'With few units, the network cannot express a complex boundary (underfitting).',
    nnManyUnitsHint: 'With many units, the network can fit a small dataset too closely (overfitting).',
    nnHighRateHint: 'If the learning rate is too large, the error can oscillate and training may not settle.',
    nnLowRateHint: 'With a small learning rate, training does not get far enough in the fixed number of epochs (underfitting).',
    nnMidHint: 'Change the units and learning rate to see how the learning curve and decision boundary change.',
    convVerticalEdge: 'Vertical edges',
    convHorizontalEdge: 'Horizontal edges',
    convBlur: 'Blur',
    convSharpen: 'Sharpen',
    convVerticalEdgeHint: 'This filter highlights vertical brightness changes (left-right edges).',
    convHorizontalEdgeHint: 'This filter highlights horizontal brightness changes (top-bottom edges).',
    convBlurHint: 'This filter averages neighboring pixels to smooth the image.',
    convSharpenHint: 'This filter emphasizes the center pixel by its difference from its neighbors.',
    convInput: 'Input image',
    convFeatureMap: 'Feature map',
    convPooled: 'After pooling',
    convPoolingNote: 'Pooling (2x2 max pooling) shrinks the feature map to half its width and height.',
    cmTp: 'TP (true positive)',
    cmFp: 'FP (false positive)',
    cmFn: 'FN (false negative)',
    cmTn: 'TN (true negative)',
    cmAccuracy: 'Accuracy',
    cmPrecision: 'Precision',
    cmRecall: 'Recall',
    cmF1: 'F1 score',
    trainError: 'Training error',
    validationError: 'Validation error',
    symptomPrompt: 'What is the symptom of this learning curve?',
    symptomIs: _enSymptomIs,
    treatmentPrompt: 'What is the remedy for this symptom?',
    attentionNote: 'Note: this is fixed data prepared for teaching, not the output of a real model.',
    attentionPickQuery: 'Choose the word to focus on (the query)',
    attentionSummary: _enAttentionSummary,
    boundaryDisclaimer: 'Note: this lets you see how the guideline changes as conditions change. For real decisions, always check the original text or a professional.',
    boundaryUnset: 'No verdict is set for this combination',
    boundaryBasis: _enBoundaryBasis,
    predictButton: 'Predict',
    predictYours: 'Your prediction',
    predictCorrect: 'Answer',
    predictAgain: 'Predict again',
    routeEmpty: 'Nothing to do right now. Well done!',
    routeToday: _enRouteToday,
    routeBelowCutoff: 'Below the minimum cutoff',
    statsTitle: 'Comparison with the national average',
    statsAverage: _enStatsAverage,
    statsMyScore: _enStatsMyScore,
    statsDeviation: _enStatsDeviation,
    storyChapterOf: _enStoryChapterOf,
    storyHowJudge: 'What would you decide?',
    storyGood: 'Good call',
    storyOther: 'There was another way to decide',
    storySeeResult: 'See results',
    storyNext: 'Next chapter',
    storyEnd: _enStoryEnd,
    storyChapterLine: _enStoryChapterLine,
    termAnalogy: 'Think of it this way',
    termCommonMistake: 'Common mistake',
    termRelatedTerms: 'Related terms',
    termRelatedQuestions: 'Related questions',
    termMapHistory: 'History of AI (lineage)',
    termMapEraNote: 'The eras are a rough guide for learning, not strict date boundaries.',
    termMapTitle: 'Term map (terms connected by relation)',
    mascotStuck: 'I\'m stuck here...',
    aiNewsTitle: 'AI news this month',
    aiNewsAsOf: _enAiNewsAsOf,
    aiNewsExamLikely: 'Likely on the exam',
    readinessTitle: 'Until you are ready',
    readinessReady: 'You\'re ready. We\'re cheering you on',
    readinessMasteryDone: 'Your mastery is enough. Just pass a mock exam to be all set',
    readinessLeftWithMock: _enReadinessLeftWithMock,
    readinessLeft: _enReadinessLeft,
    questionNo: _enQuestionNo,
    questionNoOfTotal: _enQuestionNoOfTotal,
    progressDefault: 'Progress',
  );

  /// 最も近い [KitStringsScope] の文言。[KitStringsScope.labs] があればそれ、
  /// 無ければ言語に合わせた日本語／英語（言語が `en` 以外なら日本語）。
  static LabStrings of(BuildContext context) =>
      (KitStrings.of(context).languageCode == 'en' ? en : ja);
}

const _enMonths = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _jaNnLayerCount(int n) => '$n層';
String _enNnLayerCount(int n) =>
    '$n ${n == 1 ? 'layer' : 'layers'}';
String _jaNnLossSummary(String first, String last, int epochs) => '誤差: $first → $last（${epochs}エポック）';
String _enNnLossSummary(String first, String last, int epochs) =>
    'Error: $first → $last ($epochs epochs)';
String _jaSymptomIs(String text) => '症状: $text';
String _enSymptomIs(String text) =>
    'Symptom: $text';
String _jaAttentionSummary(String query, String top, int percent) => '「$query」は「$top」に最も強く注目しています（$percent%）。線が太く濃いほど、注意が強いことを表します。';
String _enAttentionSummary(String query, String top, int percent) =>
    '"$query" pays the most attention to "$top" ($percent%). Thicker, darker lines mean stronger attention.';
String _jaBoundaryBasis(String ref) => '根拠: $ref';
String _enBoundaryBasis(String ref) =>
    'Basis: $ref';
String _jaRouteToday(int n) => '今日やる${n}つ';
String _enRouteToday(int n) =>
    'Today\'s $n ${n == 1 ? 'task' : 'tasks'}';
String _jaStatsAverage(String avg, int n) => '全国平均点 $avg点（${n}人分）';
String _enStatsAverage(String avg, int n) =>
    'National average $avg points (${n == 1 ? '1 person' : '$n people'})';
String _jaStatsMyScore(int score) => 'あなたの点数 $score点';
String _enStatsMyScore(int score) =>
    'Your score: $score points';
String _jaStatsDeviation(String dev) => '偏差値 $dev';
String _enStatsDeviation(String dev) =>
    'Standard score $dev';
String _jaStoryChapterOf(int i, int n) => '第$i章 / 全$n章';
String _enStoryChapterOf(int i, int n) =>
    'Chapter $i of $n';
String _jaStoryEnd(int good, int total) => 'これで最後の章です。$good / ${total}章で良い判断ができました。';
String _enStoryEnd(int good, int total) =>
    'That\'s the last chapter. You made a good call in $good of $total chapters.';
String _jaStoryChapterLine(int i, String text) => '第$i章: $text';
String _enStoryChapterLine(int i, String text) =>
    'Chapter $i: $text';
String _jaAiNewsAsOf(int year, int month) => '$year年$month月時点';
String _enAiNewsAsOf(int year, int month) =>
    'As of ${_enMonths[month - 1]} $year';
String _jaReadinessLeftWithMock(int left) => '習得度があと$left%、模擬試験の合格でそろいます';
String _enReadinessLeftWithMock(int left) =>
    '$left% more mastery and a passing mock exam, and you are set';
String _jaReadinessLeft(int left) => '習得度があと$left%でそろいます';
String _enReadinessLeft(int left) =>
    '$left% more mastery and you are set';
String _jaQuestionNo(int i) => '第$i問';
String _enQuestionNo(int i) =>
    'Question $i';
String _jaQuestionNoOfTotal(int i, int total) => '第$i問 / $total問';
String _enQuestionNoOfTotal(int i, int total) =>
    'Question $i of $total';
