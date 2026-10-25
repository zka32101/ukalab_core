import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ukalab_core/ui.dart';

Widget _app(Widget child, {Brightness b = Brightness.light}) => MaterialApp(
      theme: ThemeData(brightness: b),
      home: child,
    );

void main() {
  testWidgets('背景色・アイコンサイズ既定160・角丸クリップなし・進行表示', (tester) async {
    await tester.pumpWidget(_app(const UkalabStartupSplash(
      backgroundColor: Color(0xFF123456),
      iconAsset: 'assets/none.png',
      footer: SizedBox.shrink(),
    )));
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, const Color(0xFF123456));
    final img = tester.widget<Image>(find.byType(Image));
    expect(img.width, 160);
    expect(img.height, 160);
    expect(find.byType(ClipRRect), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('iconSize と showProgress を反映', (tester) async {
    await tester.pumpWidget(_app(const UkalabStartupSplash(
      backgroundColor: Colors.white,
      iconAsset: 'assets/none.png',
      iconSize: 96,
      showProgress: false,
      footer: SizedBox.shrink(),
    )));
    expect(tester.widget<Image>(find.byType(Image)).width, 96);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('cert から背景色を導出（ライト/ダーク）', (tester) async {
    await tester.pumpWidget(_app(const UkalabStartupSplash.cert(
      cert: UkalabCert.boki3,
      iconAsset: 'assets/none.png',
      footer: SizedBox.shrink(),
    )));
    expect(tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor, UkalabCert.boki3.light);

    await tester.pumpWidget(_app(
      const UkalabStartupSplash.cert(
        cert: UkalabCert.boki3,
        iconAsset: 'assets/none.png',
        footer: SizedBox.shrink(),
      ),
      b: Brightness.dark,
    ));
    await tester.pump(const Duration(seconds: 1)); // テーマ切替のアニメーションを終える
    expect(tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor, UkalabCert.boki3.dark);
  });

  testWidgets('footer を渡せる', (tester) async {
    await tester.pumpWidget(_app(const UkalabStartupSplash(
      backgroundColor: Colors.white,
      iconAsset: 'assets/none.png',
      footer: Text('ORG'),
    )));
    expect(find.text('ORG'), findsOneWidget);
  });
}
