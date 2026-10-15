import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ukalab_core/answer_feedback.dart';
import 'package:ukalab_core/ui.dart';
import 'package:ukalab_core/ukalab_core.dart';

Map<String, dynamic> _base(String qid, Map<String, dynamic> extra) => {
  'qid': qid,
  'examId': 'sample',
  'subjectId': 'ml',
  'topicId': 't1',
  'prompt': '問題$qid',
  'explanation': '解説テキスト',
  'source': 'original',
  'sourceRef': '自作',
  'contentVer': '1',
  ...extra,
};

Question _tf({bool answer = true}) => Question.fromJson(
  _base('tf1', {
    'type': 'trueFalse',
    'prompt': '過学習は訓練データに合いすぎる状態である。',
    'answerBool': answer,
  }),
);

Question _cloze() => Question.fromJson(
  _base('cl1', {
    'type': 'cloze',
    'prompt': '{{1}}は訓練データに合いすぎる状態で、{{2}}とは異なる。',
    'blanks': [
      {
        'id': 1,
        'answers': ['過学習', 'オーバーフィッティング'],
        'choices': ['過学習', '学習不足', '正則化'],
      },
      {
        'id': 2,
        'answers': ['未学習', 'アンダーフィッティング'],
      },
    ],
  }),
);

Question _clozeFree() => Question.fromJson(
  _base('cl2', {
    'type': 'cloze',
    'prompt': '{{1}}は訓練データに合いすぎる状態。',
    'blanks': [
      {
        'id': 1,
        'answers': ['過学習', 'オーバーフィッティング'],
      },
    ],
  }),
);

Question _reverse({bool choices = false}) => Question.fromJson(
  _base('rv1', {
    'type': 'reverseLookup',
    'prompt': '次の説明にあたる用語は何か。',
    'clue': '訓練データに合いすぎて、未知のデータで性能が落ちる状態。',
    'answers': ['過学習', 'オーバーフィッティング'],
    if (choices) 'choices': ['過学習', '正則化', '特徴量'],
  }),
);

Widget _app(Widget child, {double scale = 1.0}) => MaterialApp(
  builder: (context, c) => KitStringsScope(
    strings: KitStrings.ja,
    child: MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale)),
      child: c!,
    ),
  ),
  home: Scaffold(
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: child,
    ),
  ),
);

void main() {
  group('TrueFalseQuestionView', () {
    testWidgets('記号と文字を併記した2つのボタン。色だけに頼らない', (tester) async {
      await tester.pumpWidget(
        _app(TrueFalseQuestionView(question: _tf(), onAnswered: (_) {})),
      );
      expect(find.text('○'), findsOneWidget);
      expect(find.text('正しい'), findsOneWidget);
      expect(find.text('×'), findsOneWidget);
      expect(find.text('誤り'), findsOneWidget);
      // 読み上げは「記号 文言」
      expect(find.bySemanticsLabel(RegExp('^○.*正しい')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('^×.*誤り')), findsOneWidget);
      // タップ領域は 48dp 以上
      for (final f in [find.text('正しい'), find.text('誤り')]) {
        final tile = find.ancestor(of: f, matching: find.byType(InkWell)).first;
        expect(tester.getSize(tile).height, greaterThanOrEqualTo(48));
      }
    });

    testWidgets('正解を選ぶと onAnswered(correct)・解説・「正解です」・正解マーク', (tester) async {
      final results = <QuestionViewResult>[];
      await tester.pumpWidget(
        _app(TrueFalseQuestionView(question: _tf(), onAnswered: results.add)),
      );
      await tester.tap(find.text('正しい'));
      await tester.pump();
      expect(results.single.correct, isTrue);
      expect(results.single.boolAnswer, isTrue);
      expect(find.text('正解です'), findsOneWidget);
      expect(find.text('解説テキスト'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsWidgets);
      // 正解時は理由選択を出さない
      expect(find.byType(AnswerFeedbackPanel), findsOneWidget);
      expect(find.text('間違えた理由は？'), findsNothing);
    });

    testWidgets('不正解: 不正解マークと正解マーク、理由の選択、二重解答しない', (tester) async {
      final results = <QuestionViewResult>[];
      final causes = <WrongCause?>[];
      await tester.pumpWidget(
        _app(
          TrueFalseQuestionView(
            question: _tf(),
            onAnswered: results.add,
            onCause: causes.add,
          ),
        ),
      );
      await tester.tap(find.text('誤り'));
      await tester.pump();
      expect(results.single.correct, isFalse);
      expect(find.text('不正解です'), findsOneWidget);
      expect(find.byIcon(Icons.cancel), findsWidgets);
      expect(find.text('間違えた理由は？'), findsOneWidget);
      // 解答後は再タップしても何も起きない
      await tester.tap(find.text('正しい'));
      await tester.pump();
      expect(results.length, 1);
      await tester.tap(find.text('知識不足'));
      await tester.pump();
      expect(causes, [WrongCause.knowledge]);
    });

    testWidgets('onNext を渡すと「次へ」が解答後にだけ出る', (tester) async {
      var next = 0;
      await tester.pumpWidget(
        _app(
          TrueFalseQuestionView(
            question: _tf(),
            onAnswered: (_) {},
            onNext: () => next++,
          ),
        ),
      );
      expect(find.text('次へ'), findsNothing);
      await tester.tap(find.text('正しい'));
      await tester.pump();
      await tester.tap(find.text('次へ'));
      expect(next, 1);
    });

    testWidgets('qid が変わると状態をリセットする', (tester) async {
      Widget build(Question q) =>
          _app(TrueFalseQuestionView(question: q, onAnswered: (_) {}));
      await tester.pumpWidget(build(_tf()));
      await tester.tap(find.text('正しい'));
      await tester.pump();
      expect(find.text('正解です'), findsOneWidget);
      final other = Question.fromJson(
        _base('tf2', {
          'type': 'trueFalse',
          'prompt': '別の命題。',
          'answerBool': false,
        }),
      );
      await tester.pumpWidget(build(other));
      expect(find.text('正解です'), findsNothing);
      expect(find.text('別の命題。'), findsOneWidget);
    });

    testWidgets('型が違う問題を渡すとアサーション', (tester) async {
      expect(
        () => TrueFalseQuestionView(question: _cloze(), onAnswered: (_) {}),
        throwsA(isA<AssertionError>()),
      );
    });

    testWidgets('英語の文言（KitStrings が en）', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: KitStringsScope(
            strings: KitStrings.en,
            child: Scaffold(
              body: TrueFalseQuestionView(question: _tf(), onAnswered: (_) {}),
            ),
          ),
        ),
      );
      expect(find.text('True'), findsOneWidget);
      expect(find.text('False'), findsOneWidget);
    });
  });

  group('ClozeQuestionView', () {
    testWidgets('空欄は番号つきの枠＋Semantics「空欄n」、入力欄は空欄ごと', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(ClozeQuestionView(question: _cloze(), onAnswered: (_) {})),
      );
      expect(find.bySemanticsLabel('空欄1'), findsWidgets);
      expect(find.bySemanticsLabel('空欄2'), findsWidgets);
      expect(find.byType(TextField), findsOneWidget); // 空欄2だけ自由入力
      expect(find.text('学習不足'), findsOneWidget); // 空欄1は選択肢
      handle.dispose();
    });

    testWidgets('全空欄が埋まるまで「解答する」は押せない', (tester) async {
      await tester.pumpWidget(
        _app(ClozeQuestionView(question: _cloze(), onAnswered: (_) {})),
      );
      FilledButton button() => tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, '解答する'),
      );
      expect(button().onPressed, isNull);
      await tester.tap(find.text('過学習'));
      await tester.pump();
      expect(button().onPressed, isNull);
      await tester.enterText(find.byType(TextField), '   ');
      await tester.pump();
      expect(button().onPressed, isNull); // 空白のみは未入力扱い
      await tester.enterText(find.byType(TextField), 'ｱﾝﾀﾞｰﾌｨｯﾃｨﾝｸﾞ');
      await tester.pump();
      expect(button().onPressed, isNotNull);
    });

    testWidgets('IME の変換中は解答できず、確定すると解答できる', (tester) async {
      await tester.pumpWidget(
        _app(ClozeQuestionView(question: _clozeFree(), onAnswered: (_) {})),
      );
      final field = find.byType(TextField);
      final controller = tester.widget<TextField>(field).controller!;
      controller.value = const TextEditingValue(
        text: 'かがくしゅう',
        composing: TextRange(start: 0, end: 6),
      );
      await tester.pump();
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, '解答する'))
            .onPressed,
        isNull,
      );
      expect(find.text('変換を確定すると解答できます'), findsOneWidget);
      controller.value = const TextEditingValue(
        text: '過学習',
        selection: TextSelection.collapsed(offset: 3),
      );
      await tester.pump();
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, '解答する'))
            .onPressed,
        isNotNull,
      );
      expect(find.text('変換を確定すると解答できます'), findsNothing);
    });

    testWidgets('入力欄は自動入力・自動修正・候補表示を使わない', (tester) async {
      await tester.pumpWidget(
        _app(ClozeQuestionView(question: _clozeFree(), onAnswered: (_) {})),
      );
      final tf = tester.widget<TextField>(find.byType(TextField));
      expect(tf.autofillHints ?? const <String>[], isEmpty);
      expect(tf.autocorrect, isFalse);
      expect(tf.enableSuggestions, isFalse);
    });

    testWidgets('全問正解: 空欄ごとの正解表示、onAnswered は blankAnswers つき', (tester) async {
      final results = <QuestionViewResult>[];
      await tester.pumpWidget(
        _app(ClozeQuestionView(question: _cloze(), onAnswered: results.add)),
      );
      await tester.tap(find.text('過学習'));
      await tester.enterText(find.byType(TextField), ' アンダーフィッティング ');
      await tester.pump();
      await tester.tap(find.text('解答する'));
      await tester.pump();
      expect(results.single.correct, isTrue);
      expect(results.single.blankAnswers, {1: '過学習', 2: ' アンダーフィッティング '});
      expect(find.text('正解です'), findsOneWidget);
      expect(find.text('解説テキスト'), findsOneWidget);
      expect(find.text('解答する'), findsNothing);
    });

    testWidgets('一部だけ正解: 全体は不正解、空欄ごとの正誤と正解を示す', (tester) async {
      final results = <QuestionViewResult>[];
      await tester.pumpWidget(
        _app(ClozeQuestionView(question: _cloze(), onAnswered: results.add)),
      );
      await tester.tap(find.text('過学習'));
      await tester.enterText(find.byType(TextField), '正則化');
      await tester.pump();
      await tester.tap(find.text('解答する'));
      await tester.pump();
      expect(results.single.correct, isFalse);
      expect(find.text('不正解です'), findsOneWidget);
      expect(find.text('正解'), findsWidgets); // 空欄1のラベル（アイコンと文字を併記）
      expect(find.text('不正解'), findsOneWidget); // 空欄2のラベル
      expect(find.text('正解: 未学習'), findsOneWidget);
      // 解答後は入力欄が読み取り専用
      expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isTrue);
    });

    testWidgets('自由入力の不正解は自己申告で救済できる（選択式のみなら出ない）', (tester) async {
      var reported = 0;
      await tester.pumpWidget(
        _app(
          ClozeQuestionView(
            question: _clozeFree(),
            onAnswered: (_) {},
            onSelfReported: () => reported++,
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), '過学集');
      await tester.pump();
      await tester.tap(find.text('解答する'));
      await tester.pump();
      expect(find.text('不正解です'), findsOneWidget);
      await tester.tap(find.text('合っていた（自己申告）'));
      await tester.pump();
      expect(reported, 1);
      expect(find.text('正解です'), findsOneWidget);
      expect(find.text('自己申告で正解にしました'), findsOneWidget);
      expect(find.text('合っていた（自己申告）'), findsNothing);
    });

    testWidgets('選択式だけの cloze には自己申告ボタンを出さない', (tester) async {
      final q = Question.fromJson(
        _base('cl3', {
          'type': 'cloze',
          'prompt': '{{1}}は何か。',
          'blanks': [
            {
              'id': 1,
              'answers': ['過学習'],
              'choices': ['過学習', '正則化'],
            },
          ],
        }),
      );
      await tester.pumpWidget(
        _app(ClozeQuestionView(question: q, onAnswered: (_) {})),
      );
      await tester.tap(find.text('正則化'));
      await tester.pump();
      await tester.tap(find.text('解答する'));
      await tester.pump();
      expect(find.text('不正解です'), findsOneWidget);
      expect(find.text('合っていた（自己申告）'), findsNothing);
    });

    testWidgets('文字を200%・幅320dpにしてもはみ出さない', (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _app(
          ClozeQuestionView(question: _cloze(), onAnswered: (_) {}),
          scale: 2.0,
        ),
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('過学習'));
      await tester.enterText(find.byType(TextField), '未学習');
      await tester.pump();
      await tester.ensureVisible(find.text('解答する'));
      await tester.tap(find.text('解答する'));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('qid が変わると入力と結果をリセットする', (tester) async {
      Widget build(Question q) =>
          _app(ClozeQuestionView(question: q, onAnswered: (_) {}));
      await tester.pumpWidget(build(_clozeFree()));
      await tester.enterText(find.byType(TextField), '過学習');
      await tester.pump();
      await tester.tap(find.text('解答する'));
      await tester.pump();
      expect(find.text('正解です'), findsOneWidget);
      final other = Question.fromJson(
        _base('cl9', {
          'type': 'cloze',
          'prompt': '別の{{1}}。',
          'blanks': [
            {
              'id': 1,
              'answers': ['問題'],
            },
          ],
        }),
      );
      await tester.pumpWidget(build(other));
      expect(find.text('正解です'), findsNothing);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '',
      );
    });
  });

  group('ReverseLookupQuestionView', () {
    testWidgets('説明（clue）を示し、自由入力で答える', (tester) async {
      final results = <QuestionViewResult>[];
      await tester.pumpWidget(
        _app(
          ReverseLookupQuestionView(
            question: _reverse(),
            onAnswered: results.add,
          ),
        ),
      );
      expect(find.text('説明'), findsOneWidget);
      expect(find.textContaining('訓練データに合いすぎて'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'ｵｰﾊﾞｰﾌｨｯﾃｨﾝｸﾞ');
      await tester.pump();
      await tester.tap(find.text('解答する'));
      await tester.pump();
      expect(results.single.correct, isTrue);
      expect(results.single.text, 'ｵｰﾊﾞｰﾌｨｯﾃｨﾝｸﾞ');
      expect(find.text('正解です'), findsOneWidget);
    });

    testWidgets('不正解: 正解を示し、自己申告で救済できる', (tester) async {
      var reported = 0;
      await tester.pumpWidget(
        _app(
          ReverseLookupQuestionView(
            question: _reverse(),
            onAnswered: (_) {},
            onSelfReported: () => reported++,
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), '過学集');
      await tester.pump();
      await tester.tap(find.text('解答する'));
      await tester.pump();
      expect(find.text('不正解です'), findsOneWidget);
      expect(find.text('正解: 過学習'), findsOneWidget);
      await tester.tap(find.text('合っていた（自己申告）'));
      await tester.pump();
      expect(reported, 1);
      expect(find.text('正解です'), findsOneWidget);
      expect(find.text('正解: 過学習'), findsNothing);
    });

    testWidgets('空・空白のままでは解答できない。変換中も解答できない', (tester) async {
      await tester.pumpWidget(
        _app(
          ReverseLookupQuestionView(question: _reverse(), onAnswered: (_) {}),
        ),
      );
      FilledButton button() => tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, '解答する'),
      );
      expect(button().onPressed, isNull);
      await tester.enterText(find.byType(TextField), '　');
      await tester.pump();
      expect(button().onPressed, isNull);
      final c = tester.widget<TextField>(find.byType(TextField)).controller!;
      c.value = const TextEditingValue(
        text: 'かがく',
        composing: TextRange(start: 0, end: 3),
      );
      await tester.pump();
      expect(button().onPressed, isNull);
    });

    testWidgets('選択肢つき: 選ぶとその場で採点、正解と選んだ誤りを示す', (tester) async {
      final results = <QuestionViewResult>[];
      await tester.pumpWidget(
        _app(
          ReverseLookupQuestionView(
            question: _reverse(choices: true),
            onAnswered: results.add,
          ),
        ),
      );
      expect(find.byType(TextField), findsNothing);
      await tester.tap(find.text('正則化'));
      await tester.pump();
      expect(results.single.correct, isFalse);
      expect(results.single.text, '正則化');
      expect(find.text('不正解です'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsWidgets); // 正解の選択肢
      expect(find.byIcon(Icons.cancel), findsWidgets); // 選んだ誤り
      expect(find.text('合っていた（自己申告）'), findsNothing); // 選択式には出さない
      await tester.tap(find.text('特徴量'));
      await tester.pump();
      expect(results.length, 1);
    });

    testWidgets('選択肢つきで正解', (tester) async {
      final results = <QuestionViewResult>[];
      await tester.pumpWidget(
        _app(
          ReverseLookupQuestionView(
            question: _reverse(choices: true),
            onAnswered: results.add,
          ),
        ),
      );
      await tester.tap(find.text('過学習'));
      await tester.pump();
      expect(results.single.correct, isTrue);
      expect(find.text('正解です'), findsOneWidget);
    });

    testWidgets('文字を200%・幅320dpにしてもはみ出さない', (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _app(
          ReverseLookupQuestionView(question: _reverse(), onAnswered: (_) {}),
          scale: 2.0,
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('QuestionDetailScreen（読み取り専用）', () {
    testWidgets('新タイプの正解を要約して示す', (tester) async {
      for (final (q, expected) in [
        (_tf(), '正解: ○ 正しい'),
        (_cloze(), '空欄1: 過学習 / オーバーフィッティング\n空欄2: 未学習 / アンダーフィッティング'),
        (_reverse(), '説明: 訓練データに合いすぎて、未知のデータで性能が落ちる状態。\n正解: 過学習 / オーバーフィッティング'),
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            home: KitStringsScope(
              strings: KitStrings.ja,
              child: QuestionDetailScreen(question: q),
            ),
          ),
        );
        expect(find.text(expected), findsOneWidget, reason: q.qid);
      }
    });
  });
}
