import 'package:ukalab_core/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _app(Widget child, {List<Override> overrides = const []}) => ProviderScope(
      overrides: overrides,
      child: MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child))),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('標準キャラのとき「あなたの推し」とLvを表示し、メニューが開く', (tester) async {
    await tester.pumpWidget(_app(const UkalabOshiCard(
      cert: UkalabCert.boki3,
      stage: MascotStage.lv3,
      appId: 'test',
      streakDays: 2,
    )));
    await tester.pump();
    expect(find.text('あなたの推し  Lv3'), findsOneWidget);

    await tester.tap(find.byTooltip('推しのメニュー'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('推しを選ぶ'), findsOneWidget);
    expect(find.text('着替え・ショップ'), findsOneWidget);
    expect(find.text('試験の結果を報告'), findsOneWidget);
  });

  testWidgets('画像の推しを選ぶと名前が出る', (tester) async {
    SharedPreferences.setMockInitialValues({'ukalab.mascot.selected': 'mio'});
    await tester.pumpWidget(_app(const UkalabOshiCard(
      cert: UkalabCert.hazmat4,
      stage: MascotStage.lv1,
      appId: 'test',
    )));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('ミオ  Lv1'), findsOneWidget);
  });

  testWidgets('保存された「非表示」設定を読み込み、非表示のカードを出す', (tester) async {
    SharedPreferences.setMockInitialValues({'ukalab.oshi.display.hidetest': 'hidden'});
    await tester.pumpWidget(_app(const UkalabOshiCard(
      cert: UkalabCert.gKentei,
      stage: MascotStage.lv2,
      appId: 'hidetest',
    )));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('推しは非表示です'), findsOneWidget);
    expect(find.byTooltip('推しのメニュー'), findsOneWidget);
  });

  testWidgets('試験前日は前日のひとこと、久しぶりはおかえりのひとこと', (tester) async {
    final now = DateTime(2026, 10, 10, 9);
    await tester.pumpWidget(_app(UkalabOshiCard(
      cert: UkalabCert.boki3,
      stage: MascotStage.lv1,
      appId: 'eve',
      examDate: DateTime(2026, 10, 11),
      now: now,
    )));
    await tester.pump();
    final eve = MascotLines.gentle.of(MascotSituation.examEve);
    expect(eve.any((l) => find.text(l).evaluate().isNotEmpty), true);

    await tester.pumpWidget(_app(UkalabOshiCard(
      cert: UkalabCert.boki3,
      stage: MascotStage.lv1,
      appId: 'back',
      daysSinceLastStudy: 5,
      now: now,
    )));
    await tester.pump();
    final back = MascotLines.gentle.of(MascotSituation.welcomeBack);
    expect(back.any((l) => find.text(l).evaluate().isNotEmpty), true);
  });

  testWidgets('画像の推しは、前日・おかえり・連続のとき（Lv問わず）場面別ポーズの画像になる', (tester) async {
    SharedPreferences.setMockInitialValues({'ukalab.mascot.selected': 'kai'});
    final now = DateTime(2026, 10, 10, 9);
    Future<ImageProvider?> imageFor(UkalabOshiCard card) async {
      await tester.pumpWidget(_app(card));
      await tester.pump(const Duration(milliseconds: 100));
      final img = tester.widget<Image>(find.descendant(of: find.byType(MascotWidget), matching: find.byType(Image)));
      return img.image;
    }

    final eve = await imageFor(UkalabOshiCard(
      cert: UkalabCert.boki3, stage: MascotStage.lv1, appId: 's1', examDate: DateTime(2026, 10, 11), now: now));
    expect((eve as AssetImage).assetName, contains('kai_lv1_eve.webp'));

    final back = await imageFor(UkalabOshiCard(
      cert: UkalabCert.boki3, stage: MascotStage.lv1, appId: 's2', daysSinceLastStudy: 5, now: now));
    expect((back as AssetImage).assetName, contains('kai_lv1_back.webp'));

    final streak = await imageFor(UkalabOshiCard(
      cert: UkalabCert.boki3, stage: MascotStage.lv1, appId: 's3', streakDays: 4, now: now));
    expect((streak as AssetImage).assetName, contains('kai_lv1_streak.webp'));

    final plain = await imageFor(UkalabOshiCard(
      cert: UkalabCert.boki3, stage: MascotStage.lv1, appId: 's4', now: now));
    expect((plain as AssetImage).assetName, contains('kai_lv1_normal.webp'));

    // Lv2 以上でもそのレベルの姿の場面画像になる
    final lv2 = await imageFor(UkalabOshiCard(
      cert: UkalabCert.boki3, stage: MascotStage.lv2, appId: 's5', daysSinceLastStudy: 5, now: now));
    expect((lv2 as AssetImage).assetName, contains('kai_lv2_back.webp'));
    final lv5 = await imageFor(UkalabOshiCard(
      cert: UkalabCert.boki3, stage: MascotStage.lv5, appId: 's6', streakDays: 5, now: now));
    expect((lv5 as AssetImage).assetName, contains('kai_lv5_streak.webp'));
  });
}
