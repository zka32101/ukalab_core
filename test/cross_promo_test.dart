import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ukalab_core/cross_promo.dart';
import 'package:ukalab_core/src/cross_promo_test_support.dart';

const _list = '''
[
  {"id":"com.yourwish.ukalab.g_kentei","name":"G検定コレ","tagline":"AIを学ぶ","iconUrl":"","storeUrl":"https://play.google.com/store/apps/details?id=com.example.gkentei","category":"うかラボ"},
  {"id":"com.yourwish.ukalab.boki3","name":"簿記コレ","tagline":"簿記を学ぶ","iconUrl":"","storeUrl":"https://play.google.com/store/apps/details?id=com.example.boki","category":"うかラボ"},
  {"id":"com.example.sansu","name":"算数コレ","tagline":"小学生向け","iconUrl":"","storeUrl":"https://play.google.com/store/apps/details?id=com.example.sansu","category":"小学コレ"}
]
''';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('kUkalabAppIds に無い currentAppId は debug で assert', (tester) async {
    await tester.pumpWidget(_host(const UkalabCrossPromoSection(currentAppId: 'com.example.unknown')));
    expect(tester.takeException(), isA<AssertionError>());
  });

  test('カテゴリ定数', () {
    expect(kUkalabCrossPromoCategory, 'うかラボ');
  });

  testWidgets('掲載0件では何も描画せず例外も出ない', (tester) async {
    await tester.pumpWidget(
      _host(const UkalabCrossPromoSection(currentAppId: 'com.yourwish.ukalab.g_kentei')),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('他のアプリもチェック！'), findsNothing);
    expect(find.byType(Card), findsNothing);
  });

  testWidgets('自アプリを除外し、うかラボだけを表示する', (tester) async {
    await tester.pumpWidget(_host(ukalabCrossPromoSectionForTest(
      currentAppId: 'com.yourwish.ukalab.g_kentei',
      rawJson: _list,
    )));
    expect(tester.takeException(), isNull);
    expect(find.text('他のアプリもチェック！'), findsOneWidget);
    expect(find.text('簿記コレ'), findsOneWidget);
    expect(find.text('G検定コレ'), findsNothing); // 自アプリ
    expect(find.text('算数コレ'), findsNothing); // 別カテゴリ
  });

  testWidgets('自アプリ以外にうかラボが無ければ何も出さない', (tester) async {
    await tester.pumpWidget(_host(ukalabCrossPromoSectionForTest(
      currentAppId: 'com.yourwish.ukalab.boki3',
      rawJson: _list.replaceFirst('"id":"com.yourwish.ukalab.g_kentei"', '"id":"com.example.other"').replaceFirst(
          '"category":"うかラボ"', '"category":"小学コレ"'),
    )));
    expect(tester.takeException(), isNull);
    expect(find.byType(Card), findsNothing);
  });

  testWidgets('beforeOpenStore が false を返すとストアを開かない', (tester) async {
    var gateCalls = 0;
    var opened = 0;
    await tester.pumpWidget(_host(ukalabCrossPromoSectionForTest(
      currentAppId: 'com.yourwish.ukalab.g_kentei',
      rawJson: _list,
      isChildDirected: true,
      beforeOpenStore: (_) async {
        gateCalls++;
        return false;
      },
      onOpenStore: (_) => opened++,
    )));
    await tester.tap(find.text('簿記コレ'));
    await tester.pump();
    expect(gateCalls, 1);
    expect(opened, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('isChildDirected: true でゲート未指定なら assert', (tester) async {
    // const だとコンパイル時に評価されて analyze が落ちるので、実行時に作る。
    final childDirected = true;
    expect(
      () => UkalabCrossPromoSection(
        currentAppId: 'com.yourwish.ukalab.g_kentei',
        isChildDirected: childDirected,
      ),
      throwsAssertionError,
    );
  });

  test('init() は Firebase 未設定のテスト環境でも例外なく完了し、二重呼び出しも安全', () async {
    await UkalabCrossPromo.init();
    await UkalabCrossPromo.init();
    final a = UkalabCrossPromo.init();
    final b = UkalabCrossPromo.init();
    expect(identical(a, b), isTrue);
    await a;
  });
}
