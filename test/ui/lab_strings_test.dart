import 'package:app_common_kit/app_common_kit.dart';
import 'package:ukalab_core/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final _ja = RegExp(r'[぀-ヿ㐀-鿿＀-￯]');

Widget _scope(KitStrings strings, Widget child) => KitStringsScope(
      strings: strings,
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );

Widget _en(Widget child) => _scope(KitStrings.en, child);
Widget _jaApp(Widget child) => _scope(KitStrings.ja, child);

/// 画面上の全テキストに日本語が1文字も残っていないこと。
void _expectNoJapanese(WidgetTester tester) {
  for (final w in tester.widgetList<RichText>(find.byType(RichText))) {
    final t = w.text.toPlainText();
    expect(_ja.hasMatch(t), isFalse, reason: 'Japanese text remained: "$t"');
  }
}

const _enOptions = [
  FailureChoiceSpec(optionId: 'a', text: 'Wrong one', isCorrect: false),
  FailureChoiceSpec(optionId: 'b', text: 'Right one', isCorrect: true),
];

const _mlPoints = [
  MlLabPointSpec(x: 1, y: 1, label: 0),
  MlLabPointSpec(x: 2, y: 1.5, label: 0),
  MlLabPointSpec(x: 8, y: 8, label: 1),
  MlLabPointSpec(x: 7, y: 8.5, label: 1),
];

const _nnPoints = [
  NnBuilderPointSpec(x: 1, y: 1, label: 0),
  NnBuilderPointSpec(x: 2, y: 1.5, label: 0),
  NnBuilderPointSpec(x: 8, y: 8, label: 1),
  NnBuilderPointSpec(x: 7, y: 8.5, label: 1),
];

void main() {
  group('LabStrings', () {
    test('英語の文言に日本語が混じらず、複数形などが正しい', () {
      final en = LabStrings.en;
      final samples = <String>[
        en.wrongTryAgain, en.gotIt, en.class0, en.class1, en.mlKnn,
        en.mlKnnSmallHint, en.mlTreeDeepHint, en.mlLinearStrongHint,
        en.nnHiddenLayers, en.nnLayerCount(1), en.nnLayerCount(2),
        en.nnLossSummary('0.1', '0.2', 400), en.nnManyUnitsHint,
        en.convPoolingNote, en.cmTp, en.symptomIs('x'),
        en.attentionSummary('a', 'b', 50), en.boundaryDisclaimer,
        en.boundaryBasis('x'), en.routeToday(1), en.routeToday(3),
        en.statsAverage('1.0', 1), en.statsAverage('1.0', 5),
        en.statsMyScore(3), en.storyChapterOf(1, 2), en.storyEnd(1, 2),
        en.storyChapterLine(1, 'x'), en.termMapEraNote,
        en.aiNewsAsOf(2026, 12), en.readinessLeftWithMock(3),
        en.readinessLeft(3), en.questionNo(1), en.questionNoOfTotal(1, 2),
        en.progressDefault,
      ];
      for (final t in samples) {
        expect(_ja.hasMatch(t), isFalse, reason: t);
      }
      expect(en.nnLayerCount(1), '1 layer');
      expect(en.nnLayerCount(2), '2 layers');
      expect(en.aiNewsAsOf(2026, 10), 'As of Oct 2026');
      expect(LabStrings.ja.nnLayerCount(2), '2層');
      expect(LabStrings.ja.routeToday(2), '今日やる2つ');
    });

    testWidgets('of(context): scope 無しは日本語、en スコープは英語', (tester) async {
      late LabStrings plain;
      late LabStrings en;
      await tester.pumpWidget(Builder(builder: (c) {
        plain = LabStrings.of(c);
        return KitStringsScope(
          strings: KitStrings.en,
          child: Builder(builder: (c2) {
            en = LabStrings.of(c2);
            return const SizedBox();
          }),
        );
      }));
      expect(identical(plain, LabStrings.ja), isTrue);
      expect(identical(en, LabStrings.en), isTrue);
    });
  });

  group('英語表示', () {
    testWidgets('MlLabWidget', (tester) async {
      await tester.pumpWidget(_en(const MlLabWidget(
          title: 'Two clusters', description: 'Desc', points: _mlPoints)));
      expect(find.text('k-NN'), findsOneWidget);
      expect(find.text('Decision tree'), findsOneWidget);
      expect(find.text('Linear classifier'), findsOneWidget);
      expect(find.text('Class 0'), findsOneWidget);
      expect(find.text('Class 1'), findsOneWidget);
      expect(find.textContaining('Change k'), findsOneWidget);
      _expectNoJapanese(tester);

      await tester.tap(find.text('Decision tree'));
      await tester.pumpAndSettle();
      expect(find.text('Depth'), findsOneWidget);
      _expectNoJapanese(tester);

      await tester.tap(find.text('Linear classifier'));
      await tester.pumpAndSettle();
      expect(find.text('Regularization'), findsOneWidget);
      _expectNoJapanese(tester);
    });

    testWidgets('NnBuilderWidget', (tester) async {
      await tester.pumpWidget(_en(const NnBuilderWidget(
          title: 'Split', description: 'Desc', points: _nnPoints)));
      expect(find.text('Number of hidden layers'), findsOneWidget);
      expect(find.text('1 layer'), findsOneWidget);
      expect(find.text('2 layers'), findsOneWidget);
      expect(find.text('Units'), findsOneWidget);
      expect(find.text('Activation function'), findsOneWidget);
      expect(find.text('Sigmoid'), findsOneWidget);
      expect(find.text('Learning rate'), findsOneWidget);
      expect(find.text('Decision boundary'), findsOneWidget);
      expect(find.text('Learning curve (training error)'), findsOneWidget);
      expect(find.textContaining('Error: '), findsOneWidget);
      expect(find.textContaining('400 epochs'), findsOneWidget);
      _expectNoJapanese(tester);
    });

    testWidgets('ConvLabWidget', (tester) async {
      final grid = [
        for (var r = 0; r < 8; r++)
          [for (var c = 0; c < 8; c++) (r + c) % 2 == 0 ? 1.0 : 0.0],
      ];
      await tester.pumpWidget(_en(ConvLabWidget(
        image:
            ConvLabImageSpec(title: 'Digit', description: 'Desc', grid: grid),
      )));
      expect(find.text('Vertical edges'), findsOneWidget);
      expect(find.text('Horizontal edges'), findsOneWidget);
      expect(find.text('Blur'), findsOneWidget);
      expect(find.text('Sharpen'), findsOneWidget);
      expect(find.text('Input image'), findsOneWidget);
      expect(find.text('Feature map'), findsOneWidget);
      expect(find.text('After pooling'), findsOneWidget);
      expect(find.textContaining('max pooling'), findsOneWidget);
      _expectNoJapanese(tester);
      await tester.tap(find.text('Blur'));
      await tester.pumpAndSettle();
      expect(find.textContaining('averages neighboring'), findsOneWidget);
      _expectNoJapanese(tester);
    });

    testWidgets('ConfusionMatrixLabWidget', (tester) async {
      await tester.pumpWidget(_en(const ConfusionMatrixLabWidget(
        scenario: ConfusionMatrixScenarioSpec(
          title: 'Screening',
          description: 'Desc',
          initialTp: 40,
          initialFp: 10,
          initialFn: 10,
          initialTn: 40,
          options: _enOptions,
          explanation: 'Because recall.',
        ),
      )));
      expect(find.text('TP (true positive)'), findsOneWidget);
      expect(find.text('FP (false positive)'), findsOneWidget);
      expect(find.text('FN (false negative)'), findsOneWidget);
      expect(find.text('TN (true negative)'), findsOneWidget);
      expect(find.text('Accuracy 80.0%'), findsOneWidget);
      expect(find.text('Precision 80.0%'), findsOneWidget);
      expect(find.text('Recall 80.0%'), findsOneWidget);
      expect(find.text('F1 score 80.0%'), findsOneWidget);
      await tester.tap(find.text('Wrong one'));
      await tester.pump();
      expect(find.textContaining('Hmm, not quite'), findsOneWidget);
      _expectNoJapanese(tester);
      await tester.tap(find.text('Right one'));
      await tester.pumpAndSettle();
      expect(find.text('Got it!'), findsOneWidget);
      _expectNoJapanese(tester);
    });

    testWidgets('FailureGalleryWidget', (tester) async {
      await tester.pumpWidget(_en(const FailureGalleryWidget(
        title: 'Curve 1',
        curve: [
          LearningCurvePointSpec(epoch: 1, trainLoss: 0.8, valLoss: 0.9),
          LearningCurvePointSpec(epoch: 10, trainLoss: 0.05, valLoss: 0.6),
        ],
        symptomOptions: _enOptions,
        treatmentOptions: _enOptions,
        explanation: 'Overfitting.',
      )));
      expect(find.text('Training error'), findsOneWidget);
      expect(find.text('Validation error'), findsOneWidget);
      expect(find.text('What is the symptom of this learning curve?'),
          findsOneWidget);
      await tester.tap(find.widgetWithText(ChoiceChip, 'Wrong one'));
      await tester.pump();
      expect(find.textContaining('Hmm, not quite'), findsOneWidget);
      await tester.tap(find.widgetWithText(ChoiceChip, 'Right one'));
      await tester.pump();
      expect(find.text('Symptom: Right one'), findsOneWidget);
      expect(
          find.text('What is the remedy for this symptom?'), findsOneWidget);
      _expectNoJapanese(tester);
      final chip = find.widgetWithText(ChoiceChip, 'Right one');
      await tester.ensureVisible(chip);
      await tester.pumpAndSettle();
      await tester.tap(chip);
      await tester.pumpAndSettle();
      expect(find.text('Got it!'), findsOneWidget);
      _expectNoJapanese(tester);
    });

    testWidgets('AttentionVizWidget', (tester) async {
      await tester.pumpWidget(_en(const AttentionVizWidget(
        scenario: AttentionVizSpec(
          title: 'Who ate what?',
          description: 'Desc',
          tokens: ['cat', 'ate', 'fish'],
          attention: [
            [0.6, 0.2, 0.2],
            [0.5, 0.2, 0.3],
            [0.1, 0.3, 0.6],
          ],
        ),
      )));
      expect(find.textContaining('fixed data prepared for teaching'),
          findsOneWidget);
      expect(find.text('Choose the word to focus on (the query)'),
          findsOneWidget);
      expect(
          find.textContaining('"cat" pays the most attention to "cat" (60%)'),
          findsOneWidget);
      _expectNoJapanese(tester);
    });

    testWidgets('BoundarySliderWidget', (tester) async {
      const conditions = [
        BoundaryConditionSpec(
            conditionId: 'c',
            label: 'Commercial?',
            trueLabel: 'Yes',
            falseLabel: 'No'),
      ];
      await tester.pumpWidget(_en(BoundarySliderWidget(
        title: 'Data collection',
        conditions: conditions,
        evaluate: (_) =>
            const BoundaryConclusion(text: 'OK', lawReference: 'Art. 30-4'),
      )));
      expect(find.text('Basis: Art. 30-4'), findsOneWidget);
      expect(find.textContaining('always check the original text'),
          findsOneWidget);
      _expectNoJapanese(tester);

      await tester.pumpWidget(_en(BoundarySliderWidget(
        title: 'Data collection',
        conditions: conditions,
        evaluate: (_) => null,
      )));
      expect(find.text('No verdict is set for this combination'),
          findsOneWidget);
      _expectNoJapanese(tester);
    });

    testWidgets('PredictRunWidget', (tester) async {
      await tester.pumpWidget(_en(const PredictRunWidget(
        title: 'Probability',
        question: 'What is it?',
        correctAnswer: 0.15,
        explanation: 'Because.',
      )));
      expect(find.text('Predict'), findsOneWidget);
      await tester.tap(find.text('Predict'));
      await tester.pump();
      expect(find.text('Your prediction'), findsOneWidget);
      expect(find.text('Answer'), findsOneWidget);
      expect(find.text('Predict again'), findsOneWidget);
      _expectNoJapanese(tester);
    });

    testWidgets('RoutePlannerWidget', (tester) async {
      await tester.pumpWidget(_en(const RoutePlannerWidget(tasks: [
        RouteTaskSpec(
            subjectId: 'a', subjectName: 'ML basics', belowPassLine: false),
        RouteTaskSpec(subjectId: 'b', subjectName: 'Law', belowPassLine: true),
      ])));
      expect(find.text("Today's 2 tasks"), findsOneWidget);
      expect(find.text('Below the minimum cutoff'), findsOneWidget);
      _expectNoJapanese(tester);

      await tester.pumpWidget(_en(const RoutePlannerWidget(tasks: [
        RouteTaskSpec(
            subjectId: 'a', subjectName: 'ML basics', belowPassLine: false),
      ])));
      expect(find.text("Today's 1 task"), findsOneWidget);

      await tester.pumpWidget(_en(const RoutePlannerWidget(tasks: [])));
      expect(find.textContaining('Well done'), findsOneWidget);
      _expectNoJapanese(tester);
    });

    testWidgets('StatsCompareWidget', (tester) async {
      const summary =
          ExamStatsSummary(sampleCount: 120, averageScore: 100, stdDev: 10);
      await tester.pumpWidget(
          _en(const StatsCompareWidget(summary: summary, myScore: 110)));
      expect(
          find.text('Comparison with the national average'), findsOneWidget);
      expect(find.text('National average 100.0 points (120 people)'),
          findsOneWidget);
      expect(find.text('Your score: 110 points'), findsOneWidget);
      expect(find.text('Standard score 60.0'), findsOneWidget);
      _expectNoJapanese(tester);
    });

    testWidgets('StoryModeWidget', (tester) async {
      const scenario = StoryScenarioSpec(
        title: 'AI project',
        description: 'Desc',
        chapters: [
          StoryChapterSpec(situation: 'Collect data.', choices: [
            StoryChoiceSpec(
                choiceId: 'a',
                text: 'Check licenses',
                isRecommended: true,
                feedback: 'Good.'),
            StoryChoiceSpec(
                choiceId: 'b',
                text: 'Scrape',
                isRecommended: false,
                feedback: 'Risky.'),
          ]),
          StoryChapterSpec(situation: 'Evaluate.', choices: [
            StoryChoiceSpec(
                choiceId: 'c',
                text: 'Many metrics',
                isRecommended: true,
                feedback: 'Good.'),
            StoryChoiceSpec(
                choiceId: 'd',
                text: 'Accuracy only',
                isRecommended: false,
                feedback: 'Risky.'),
          ]),
        ],
      );
      await tester.pumpWidget(_en(const StoryModeWidget(scenario: scenario)));
      expect(find.text('Chapter 1 of 2'), findsOneWidget);
      expect(find.text('What would you decide?'), findsOneWidget);
      await tester.tap(find.text('Check licenses'));
      await tester.pumpAndSettle();
      expect(find.text('Good call'), findsOneWidget);
      expect(find.text('Next chapter'), findsOneWidget);
      _expectNoJapanese(tester);
      await tester.tap(find.text('Next chapter'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Accuracy only'));
      await tester.pumpAndSettle();
      expect(find.text('There was another way to decide'), findsOneWidget);
      expect(find.text('See results'), findsOneWidget);
      await tester.tap(find.text('See results'));
      await tester.pumpAndSettle();
      expect(find.textContaining("That's the last chapter"), findsOneWidget);
      expect(find.text('Chapter 2: Accuracy only'), findsOneWidget);
      _expectNoJapanese(tester);
    });

    testWidgets('TermCard', (tester) async {
      await tester.pumpWidget(_en(const TermCard(
        term: 'Overfitting',
        headline: 'Too tuned',
        definition: 'Def',
        analogy: 'Like cramming',
        commonMistake: 'Mistake',
        relatedTerms: [RelatedTermRef(termId: 't', label: 'Regularization')],
        relatedQuestions: [RelatedQuestionRef(questionId: 'q', label: 'Q1')],
      )));
      expect(find.text('Think of it this way'), findsOneWidget);
      expect(find.text('Common mistake'), findsOneWidget);
      expect(find.text('Related terms'), findsOneWidget);
      expect(find.text('Related questions'), findsOneWidget);
      _expectNoJapanese(tester);
    });

    testWidgets('TermMapWidget', (tester) async {
      await tester.pumpWidget(_en(TermMapWidget(
        nodes: const [
          TermMapNodeSpec(termId: 't1', label: 'ELIZA', era: 'boom1'),
          TermMapNodeSpec(
              termId: 't2', label: 'Overfit', relatedTermIds: ['t3']),
          TermMapNodeSpec(
              termId: 't3', label: 'Regularize', relatedTermIds: ['t2']),
        ],
        eraOrder: const {'boom1': 'First boom'},
        onNodeTap: (_) {},
      )));
      expect(find.text('History of AI (lineage)'), findsOneWidget);
      expect(find.textContaining('rough guide for learning'), findsOneWidget);
      expect(
          find.text('Term map (terms connected by relation)'), findsOneWidget);
      _expectNoJapanese(tester);
    });

    testWidgets('MethodChoiceWidget', (tester) async {
      await tester.pumpWidget(_en(const MethodChoiceWidget(
        scenario: MethodChoiceScenarioSpec(
          title: 'Churn',
          caseDescription: 'Case',
          options: _enOptions,
          explanation: 'Because.',
        ),
      )));
      await tester.tap(find.text('Wrong one'));
      await tester.pump();
      expect(find.textContaining('Hmm, not quite'), findsOneWidget);
      _expectNoJapanese(tester);
      await tester.tap(find.text('Right one'));
      await tester.pumpAndSettle();
      expect(find.text('Got it!'), findsOneWidget);
      _expectNoJapanese(tester);
    });

    testWidgets('TeachMascotWidget', (tester) async {
      await tester.pumpWidget(_en(const TeachMascotWidget(
        title: 'Collecting data',
        statementTemplate: 'This is fine because {blank}',
        options: [
          MisconceptionChoiceSpec(
              optionId: 'w', text: 'non-profit', isCorrect: false),
          MisconceptionChoiceSpec(
              optionId: 'r', text: 'no enjoyment', isCorrect: true),
        ],
        explanation: 'Because.',
      )));
      expect(find.text("I'm stuck here..."), findsOneWidget);
      await tester.tap(find.widgetWithText(ChoiceChip, 'non-profit'));
      await tester.pump();
      expect(find.textContaining('Hmm, not quite'), findsOneWidget);
      _expectNoJapanese(tester);
      await tester.tap(find.widgetWithText(ChoiceChip, 'no enjoyment'));
      await tester.pumpAndSettle();
      expect(find.text('Got it!'), findsOneWidget);
      _expectNoJapanese(tester);
    });

    testWidgets('AiNewsCard', (tester) async {
      await tester.pumpWidget(_en(AiNewsCard(items: [
        AiNewsItemSpec(
          summary: 'A new model.',
          sourceUrl: 'https://example.com/1',
          sourceDate: DateTime(2026, 9, 1),
          syllabusTag: '2 Trends',
          asOfDate: DateTime(2026, 10, 1),
          isExamRelevant: true,
        ),
      ])));
      expect(find.text('AI news this month'), findsOneWidget);
      expect(find.text('As of Oct 2026'), findsOneWidget);
      expect(find.text('Likely on the exam'), findsOneWidget);
      _expectNoJapanese(tester);
    });

    testWidgets('ReadinessProgressCard', (tester) async {
      const rule = ReadinessRule.standard;
      const half = MasteryInput(coverage: 0.7, accuracy: 0.7);
      await tester.pumpWidget(_en(ReadinessProgressCard(
          progress: rule.progress(mastery: half, mockPassed: false))));
      expect(find.text('Until you are ready'), findsOneWidget);
      expect(
          find.text('31% more mastery and a passing mock exam, and you are set'),
          findsOneWidget);
      _expectNoJapanese(tester);

      const full = MasteryInput(coverage: 1, accuracy: 1);
      await tester.pumpWidget(_en(ReadinessProgressCard(
          progress: rule.progress(mastery: full, mockPassed: true))));
      expect(find.textContaining("You're ready"), findsOneWidget);
      _expectNoJapanese(tester);
    });

    testWidgets('QuestionCard / ProgressRing', (tester) async {
      await tester.pumpWidget(_en(const Column(children: [
        QuestionCard(text: 'Q?', index: 3, total: 10),
        QuestionCard(text: 'Q?', index: 4),
        ProgressRing(value: 0.4),
      ])));
      expect(find.text('Question 3 of 10'), findsOneWidget);
      expect(find.text('Question 4'), findsOneWidget);
      expect(find.bySemanticsLabel('Progress 40%'), findsOneWidget);
      _expectNoJapanese(tester);
    });
  });

  group('日本語表示（既定）は従来どおり', () {
    testWidgets('scope 無しでも日本語', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: Column(children: [
            QuestionCard(text: 'Q', index: 3, total: 10),
            ProgressRing(value: 0.4),
          ]),
        ),
      ));
      expect(find.text('第3問 / 10問'), findsOneWidget);
      expect(find.bySemanticsLabel('進捗 40%'), findsOneWidget);
    });

    testWidgets('KitStrings.ja スコープでも日本語', (tester) async {
      await tester.pumpWidget(_jaApp(AiNewsCard(items: [
        AiNewsItemSpec(
          summary: '要約',
          sourceUrl: 'https://example.com/1',
          sourceDate: DateTime(2026, 9, 1),
          syllabusTag: '2',
          asOfDate: DateTime(2026, 10, 1),
        ),
      ])));
      expect(find.text('今月のAI動向'), findsOneWidget);
      expect(find.text('2026年10月時点'), findsOneWidget);
    });
  });
}
