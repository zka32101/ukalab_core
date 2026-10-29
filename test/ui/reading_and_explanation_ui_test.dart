import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ukalab_core/answer_feedback.dart';
import 'package:ukalab_core/ui.dart';
import 'package:ukalab_core/ukalab_core.dart';

Widget _app(Widget child, {ThemeData? theme, double scale = 1}) => MaterialApp(
  theme: theme,
  home: MediaQuery(
    data: MediaQueryData(textScaler: TextScaler.linear(scale)),
    child: Scaffold(body: SingleChildScrollView(child: child)),
  ),
);

Future<void> _settle(WidgetTester tester) =>
    tester.pump(const Duration(seconds: 1));

Question _question() => Question.fromJson({
  'qid': 'q1',
  'examId': 'sample',
  'subjectId': 'math',
  'topicId': 'ch1',
  'prompt': '問題',
  'choices': ['a', 'b', 'c'],
  'answerIndex': 1,
  'explanation': '解説',
  'source': 'original',
  'sourceRef': '自作',
  'contentVer': '1',
});

ChapterReading _reading(String id, {bool disabled = false}) => ChapterReading(
  readingId: id,
  examId: 'sample',
  subjectId: 'math',
  title: '読み物$id',
  sections: const [ReadingSection(heading: 'h', body: 'b')],
  relatedQuestionIds: const ['q1', 'q2'],
  source: QuestionSource.original,
  sourceRef: '自作',
  contentVer: '1',
  disabled: disabled,
);

void main() {
  group('ReadingSectionContent', () {
    testWidgets('text: 見出しと本文', (tester) async {
      await tester.pumpWidget(
        _app(
          const ReadingSectionContent(
            section: ReadingSection(heading: '見出し', body: '本文です'),
          ),
        ),
      );
      await _settle(tester);
      expect(find.text('見出し'), findsOneWidget);
      expect(find.text('本文です'), findsOneWidget);
    });

    testWidgets('table: 列見出しとセル', (tester) async {
      await tester.pumpWidget(
        _app(
          const ReadingSectionContent(
            section: ReadingSection(
              heading: '比較',
              kind: 'table',
              table: ReadingTable(
                columns: ['用語', '意味'],
                rows: [
                  ['A', '説明A'],
                  ['B', '説明B'],
                ],
              ),
              body: '補足です',
            ),
          ),
        ),
      );
      await _settle(tester);
      expect(find.byType(Table), findsOneWidget);
      for (final t in ['用語', '意味', 'A', '説明B', '補足です']) {
        expect(find.text(t), findsOneWidget);
      }
    });

    testWidgets('steps: 番号付きで、読み上げは「番号. 内容」', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(
          const ReadingSectionContent(
            section: ReadingSection(
              heading: '手順',
              kind: 'steps',
              steps: ['まず混ぜる', '次に焼く'],
            ),
          ),
        ),
      );
      await _settle(tester);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.bySemanticsLabel('1. まず混ぜる'), findsOneWidget);
      expect(find.bySemanticsLabel('2. 次に焼く'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('figure: alt を読み上げ、画像が読めなければ alt の文字を出す', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(
          const ReadingSectionContent(
            section: ReadingSection(
              heading: '図',
              kind: 'figure',
              figure: ReadingFigure(
                asset: 'assets/none.png',
                alt: '処理の流れ図',
                caption: '図1',
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.bySemanticsLabel('処理の流れ図'), findsOneWidget);
      expect(find.text('図1'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('未知の kind は本文にフォールバック', (tester) async {
      await tester.pumpWidget(
        _app(
          const ReadingSectionContent(
            section: ReadingSection(
              heading: 'h',
              body: '代わりの本文',
              kind: 'video',
            ),
          ),
        ),
      );
      await _settle(tester);
      expect(find.text('代わりの本文'), findsOneWidget);
    });

    for (final dark in [false, true]) {
      testWidgets('文字3倍・狭幅・${dark ? "ダーク" : "ライト"}でもはみ出さない', (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          _app(
            const Column(
              children: [
                ReadingSectionContent(
                  section: ReadingSection(
                    heading: '長い見出しのサンプルです',
                    kind: 'table',
                    table: ReadingTable(
                      columns: ['ながい列見出しその一', 'ながい列見出しその二', 'ながい列見出しその三'],
                      rows: [
                        ['ながいセルの内容です', 'ながいセルの内容です', 'ながいセルの内容です'],
                      ],
                    ),
                  ),
                ),
                ReadingSectionContent(
                  section: ReadingSection(
                    heading: '手順',
                    kind: 'steps',
                    steps: ['とても長い手順の文章です。とても長い手順の文章です。とても長い手順の文章です。'],
                  ),
                ),
              ],
            ),
            theme: dark ? ThemeData.dark() : ThemeData.light(),
            scale: 3,
          ),
        );
        await _settle(tester);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('ExplanationCard', () {
    testWidgets('4項目を出し、無い項目は出さない', (tester) async {
      await tester.pumpWidget(
        _app(
          const ExplanationCard(
            conclusion: 'Aが答え',
            pitfall: 'Bと混同しやすい',
            strings: AnswerFeedbackStrings.ja,
          ),
        ),
      );
      await _settle(tester);
      expect(find.text('結論'), findsOneWidget);
      expect(find.text('Aが答え'), findsOneWidget);
      expect(find.text('間違えやすい点'), findsOneWidget);
      expect(find.text('理由'), findsNothing);
      expect(find.text('別の場面'), findsNothing);
    });

    testWidgets('fromPlain: 目印なしは従来どおり全文', (tester) async {
      await tester.pumpWidget(_app(ExplanationCard.fromPlain('ふつうの解説です。')));
      await _settle(tester);
      expect(find.text('ふつうの解説です。'), findsOneWidget);
      expect(find.text('別の場面'), findsNothing);
    });

    testWidgets('fromPlain: 【別の場面】を欄に分ける', (tester) async {
      await tester.pumpWidget(
        _app(ExplanationCard.fromPlain('本文。\n【別の場面】別の例。')),
      );
      await _settle(tester);
      expect(find.text('本文。'), findsOneWidget);
      expect(find.text('別の場面'), findsOneWidget);
      expect(find.text('別の例。'), findsOneWidget);
    });

    testWidgets('fromPlain: パース不能は全文をそのまま', (tester) async {
      const t = '【別の場面】だけ';
      await tester.pumpWidget(_app(ExplanationCard.fromPlain(t)));
      await _settle(tester);
      expect(find.text(t), findsOneWidget);
      expect(find.text('別の場面'), findsNothing);
    });

    testWidgets('en の文言', (tester) async {
      await tester.pumpWidget(
        _app(
          const ExplanationCard(
            reason: 'because',
            strings: AnswerFeedbackStrings.en,
          ),
        ),
      );
      await _settle(tester);
      expect(find.text('Why'), findsOneWidget);
    });
  });

  group('AnswerFeedbackPanel 読み物導線', () {
    Widget panel({
      List<ChapterReading> readings = const [],
      ValueChanged<ChapterReading>? onOpen,
      int selected = 0,
    }) => _app(
      AnswerFeedbackPanel(
        question: _question(),
        selectedIndex: selected,
        onCause: (_) {},
        strings: AnswerFeedbackStrings.ja,
        relatedReadings: readings,
        onOpenReading: onOpen,
      ),
    );

    testWidgets('引数未指定なら読み物の欄は出ない（従来どおり）', (tester) async {
      await tester.pumpWidget(panel());
      await _settle(tester);
      expect(find.text('間違えた理由は？'), findsOneWidget);
      expect(find.text('読み物でおさらい'), findsNothing);
    });

    testWidgets('誤答で読み物リンクを出し、タップで onOpenReading', (tester) async {
      final opened = <String>[];
      await tester.pumpWidget(
        panel(
          readings: [_reading('a'), _reading('b', disabled: true)],
          onOpen: (r) => opened.add(r.readingId),
        ),
      );
      await _settle(tester);
      expect(find.text('読み物でおさらい'), findsOneWidget);
      expect(find.text('読み物b'), findsNothing);
      await tester.tap(find.text('読み物a'));
      expect(opened, ['a']);
    });

    testWidgets('正解なら何も出ない／onOpenReading が無ければ欄も出ない', (tester) async {
      await tester.pumpWidget(
        panel(readings: [_reading('a')], onOpen: (_) {}, selected: 1),
      );
      await _settle(tester);
      expect(find.text('読み物でおさらい'), findsNothing);
      await tester.pumpWidget(panel(readings: [_reading('a')]));
      await _settle(tester);
      expect(find.text('読み物でおさらい'), findsNothing);
    });
  });

  group('ReadingQuestionLinks', () {
    testWidgets('relatedQuestionIds ごとにボタンを出しタップで qid を返す', (tester) async {
      final opened = <String>[];
      await tester.pumpWidget(
        _app(
          ReadingQuestionLinks.forReading(
            reading: _reading('a'),
            onOpenQuestion: opened.add,
            labels: const {'q2': '二つ目の問題'},
            strings: AnswerFeedbackStrings.ja,
          ),
        ),
      );
      await _settle(tester);
      expect(find.text('確認問題にもどる'), findsOneWidget);
      expect(find.text('確認問題 1'), findsOneWidget);
      await tester.tap(find.text('二つ目の問題'));
      expect(opened, ['q2']);
    });

    testWidgets('問題が無ければ何も出さない', (tester) async {
      await tester.pumpWidget(
        _app(
          ReadingQuestionLinks(questionIds: const [], onOpenQuestion: (_) {}),
        ),
      );
      await _settle(tester);
      expect(find.byType(OutlinedButton), findsNothing);
    });
  });
}
