import 'package:ukalab_core/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _chapters = [
  StoryChapterSpec(
    situation: 'データ収集の段階。どちらの方法を選びますか?',
    choices: [
      StoryChoiceSpec(
        choiceId: 'license',
        text: '出典・ライセンスを確認して収集',
        isRecommended: true,
        feedback: '権利関係を確認してから使うのが基本。',
      ),
      StoryChoiceSpec(
        choiceId: 'scrape',
        text: '手早くスクレイピングで収集',
        isRecommended: false,
        feedback: '権利関係の確認を怠ると、後で使えなくなるリスクがある。',
      ),
    ],
  ),
  StoryChapterSpec(
    situation: '評価の段階。どちらの方法を選びますか?',
    choices: [
      StoryChoiceSpec(
        choiceId: 'multi',
        text: '複数の指標で評価',
        isRecommended: true,
        feedback: '正解率だけでは不均衡データを見落とす。',
      ),
      StoryChoiceSpec(
        choiceId: 'accuracy',
        text: '正解率だけで評価',
        isRecommended: false,
        feedback: '不均衡データでは正解率が高く出ても性能が悪いことがある。',
      ),
    ],
  ),
];

const _scenario = StoryScenarioSpec(
  title: 'AIプロジェクト経営モード',
  description: '架空の会社でAI導入を進めます。',
  chapters: _chapters,
);

Widget _app(Widget child) => MaterialApp(
      home: Scaffold(body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: child)),
    );

void main() {
  testWidgets('タイトル・説明・1章目の状況と選択肢を表示する', (tester) async {
    await tester.pumpWidget(_app(const StoryModeWidget(scenario: _scenario)));

    expect(find.text('AIプロジェクト経営モード'), findsOneWidget);
    expect(find.text('架空の会社でAI導入を進めます。'), findsOneWidget);
    expect(find.text('第1章 / 全2章'), findsOneWidget);
    expect(find.text('データ収集の段階。どちらの方法を選びますか?'), findsOneWidget);
    expect(find.text('出典・ライセンスを確認して収集'), findsOneWidget);
  });

  testWidgets('推奨の選択肢を選ぶとよい判断と出て、次の章へ進める', (tester) async {
    await tester.pumpWidget(_app(const StoryModeWidget(scenario: _scenario)));

    await tester.tap(find.text('出典・ライセンスを確認して収集'));
    await tester.pumpAndSettle();
    expect(find.text('よい判断です'), findsOneWidget);
    expect(find.text('権利関係を確認してから使うのが基本。'), findsOneWidget);

    await tester.tap(find.text('次の章へ'));
    await tester.pumpAndSettle();
    expect(find.text('第2章 / 全2章'), findsOneWidget);
  });

  testWidgets('推奨でない選択肢を選ぶと別の判断もあったと出る', (tester) async {
    await tester.pumpWidget(_app(const StoryModeWidget(scenario: _scenario)));

    await tester.tap(find.text('手早くスクレイピングで収集'));
    await tester.pumpAndSettle();
    expect(find.text('別の判断もありました'), findsOneWidget);
  });

  testWidgets('最後の章まで進むと振り返りが出る', (tester) async {
    await tester.pumpWidget(_app(const StoryModeWidget(scenario: _scenario)));

    await tester.tap(find.text('出典・ライセンスを確認して収集'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('次の章へ'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('複数の指標で評価'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('結果を見る'));
    await tester.pumpAndSettle();

    expect(find.textContaining('2 / 2章で良い判断ができました。'), findsOneWidget);
    expect(find.text('第1章: 出典・ライセンスを確認して収集'), findsOneWidget);
    expect(find.text('第2章: 複数の指標で評価'), findsOneWidget);
  });
}
