import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ukalab_core/ui.dart';

Future<void> _pump(
  WidgetTester t, {
  String? appId,
  bool premium = false,
  VoidCallback? onLockedTap,
  double scale = 1.0,
  Size size = const Size(400, 900),
  ProviderContainer? container,
}) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1.0;
  addTearDown(t.view.reset);
  final overrides = [
    characterAppIdProvider.overrideWithValue(appId),
    characterPremiumProvider.overrideWithValue(premium),
  ];
  final app = MaterialApp(
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    home: KitStringsScope(strings: KitStrings.ja, child: CharacterSelectScreen(onLockedTap: onLockedTap)),
  );
  await t.pumpWidget(
    container == null
        ? ProviderScope(overrides: overrides, child: app)
        : UncontrolledProviderScope(container: container, child: app),
  );
  await t.pump();
  // 保存済みの選択の読み込み(実際の非同期)を待つ。
  await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
  await t.pump(const Duration(milliseconds: 50));
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('resolveCharacterPack / isCharacterUnlocked', () {
    test('共通キャラは常に使える', () {
      for (final p in UkalabCharacters.all) {
        expect(isCharacterUnlocked(p, appId: null, isPremium: false), true, reason: p.id);
      }
    });

    test('資格専用キャラ: 自アプリ かつ プレミアムのときだけ使える', () {
      const sala = UkalabCharacters.sala;
      expect(isCharacterUnlocked(sala, appId: 'hazmat4', isPremium: true), true);
      expect(isCharacterUnlocked(sala, appId: 'hazmat4', isPremium: false), false);
      expect(isCharacterUnlocked(sala, appId: 'boki3', isPremium: true), false);
      expect(isCharacterUnlocked(sala, appId: null, isPremium: true), false);
    });

    test('失効したら直前の共通キャラに戻る。権利が戻れば資格キャラのまま', () {
      const sala = UkalabCharacters.sala;
      expect(
        resolveCharacterPack(selected: sala, lastCommon: UkalabCharacters.mio, appId: 'hazmat4', isPremium: false).id,
        'mio',
      );
      expect(
        resolveCharacterPack(selected: sala, lastCommon: UkalabCharacters.mio, appId: 'hazmat4', isPremium: true).id,
        'sala',
      );
      // 直前の共通キャラが無ければ標準キャラ
      expect(
        resolveCharacterPack(selected: sala, lastCommon: CharacterPack.standard, appId: 'hazmat4', isPremium: false).id,
        'standard',
      );
      // 共通キャラの選択はそのまま
      expect(
        resolveCharacterPack(selected: UkalabCharacters.kai, lastCommon: UkalabCharacters.mio, appId: null, isPremium: false).id,
        'kai',
      );
    });
  });

  group('保存と失効時のフォールバック', () {
    test('資格キャラを選んでも直前の共通キャラを覚え、失効で戻る。保存値は消さない', () async {
      final c = ProviderContainer(overrides: [
        characterAppIdProvider.overrideWithValue('hazmat4'),
        characterPremiumProvider.overrideWithValue(false),
      ]);
      addTearDown(c.dispose);
      c.read(selectedCharacterPackProvider);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final n = c.read(selectedCharacterPackProvider.notifier);
      await n.select(UkalabCharacters.moka);
      await n.select(UkalabCharacters.sala); // (プレミアム判定は画面側。保存は通す)
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('ukalab.mascot.selected'), 'sala');
      expect(prefs.getString('ukalab.mascot.lastCommon'), 'moka');
      expect(c.read(selectedCharacterPackProvider).id, 'sala');
      // プレミアムなし(失効)なので、表示は直前の共通キャラ
      expect(c.read(effectiveCharacterPackProvider).id, 'moka');
    });

    test('再起動後も、失効中は共通キャラ・保存値は資格キャラのまま', () async {
      SharedPreferences.setMockInitialValues({
        'ukalab.mascot.selected': 'sala',
        'ukalab.mascot.lastCommon': 'mike',
      });
      final c = ProviderContainer(overrides: [
        characterAppIdProvider.overrideWithValue('hazmat4'),
        characterPremiumProvider.overrideWithValue(false),
      ]);
      addTearDown(c.dispose);
      c.listen(effectiveCharacterPackProvider, (_, __) {});
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(c.read(selectedCharacterPackProvider).id, 'sala');
      expect(c.read(effectiveCharacterPackProvider).id, 'mike');
    });

    test('プレミアムありなら資格キャラがそのまま表示される', () async {
      SharedPreferences.setMockInitialValues({'ukalab.mascot.selected': 'sala'});
      final c = ProviderContainer(overrides: [
        characterAppIdProvider.overrideWithValue('hazmat4'),
        characterPremiumProvider.overrideWithValue(true),
      ]);
      addTearDown(c.dispose);
      c.listen(effectiveCharacterPackProvider, (_, __) {});
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(c.read(effectiveCharacterPackProvider).id, 'sala');
    });

    test('appId 未設定のアプリでは従来どおり(資格キャラを選んでいても標準キャラ)', () async {
      SharedPreferences.setMockInitialValues({'ukalab.mascot.selected': 'circa'});
      final c = ProviderContainer();
      addTearDown(c.dispose);
      c.listen(effectiveCharacterPackProvider, (_, __) {});
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(c.read(effectiveCharacterPackProvider).id, 'standard');
    });
  });

  group('選択画面', () {
    testWidgets('appId 未設定: 共通キャラ5体だけ(従来どおり)。資格キャラは出ない', (t) async {
      await _pump(t);
      expect(find.text('カイ'), findsOneWidget);
      expect(find.text('資格専用キャラ'), findsNothing);
      expect(find.byIcon(Icons.lock_outline), findsNothing);
      expect(find.text('サーキ'), findsNothing);
    });

    testWidgets('appId で絞る: 自アプリの資格キャラだけが出る', (t) async {
      await _pump(t, appId: 'g_kentei', premium: true);
      expect(find.text('資格専用キャラ'), findsOneWidget);
      expect(find.text('ノーダ'), findsOneWidget);
      expect(find.text('サーキ'), findsNothing);
      expect(find.text('タツ'), findsNothing);
      expect(find.byIcon(Icons.lock_outline), findsNothing);
    });

    testWidgets('無料ユーザー: ロック表示。タップはプレビューで選択されない', (t) async {
      await _pump(t, appId: 'it_passport');
      expect(find.text('サーキ'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
      expect(find.text('プレミアムで使えます'), findsOneWidget);

      await t.ensureVisible(find.text('サーキ'));
      await t.tap(find.text('サーキ'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('プレビュー中です。選ぶにはプレミアムが必要です'), findsOneWidget);
      expect(find.text('プレミアムを見る'), findsNothing); // onLockedTap なし
      await t.tap(find.text('閉じる'));
      await t.pump(const Duration(milliseconds: 300));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('ukalab.mascot.selected'), isNull);
    });

    testWidgets('プレビューの購入導線: onLockedTap が呼ばれる', (t) async {
      var called = 0;
      await _pump(t, appId: 'it_passport', onLockedTap: () => called++);
      await t.ensureVisible(find.text('サーキ'));
      await t.tap(find.text('サーキ'));
      await t.pump(const Duration(milliseconds: 300));
      await t.tap(find.text('プレミアムを見る'));
      await t.pump(const Duration(milliseconds: 300));
      expect(called, 1);
    });

    testWidgets('プレミアム: ロックが外れ、タップで選択・保存される', (t) async {
      final c = ProviderContainer(overrides: [
        characterAppIdProvider.overrideWithValue('hazmat4'),
        characterPremiumProvider.overrideWithValue(true),
      ]);
      addTearDown(c.dispose);
      await _pump(t, appId: 'hazmat4', premium: true, container: c);
      expect(find.byIcon(Icons.lock_outline), findsNothing);
      await t.ensureVisible(find.text('サラ'));
      await t.tap(find.text('サラ'));
      await t.pump();
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await t.pump();
      expect(c.read(selectedCharacterPackProvider).id, 'sala');
      expect(c.read(effectiveCharacterPackProvider).id, 'sala');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('ukalab.mascot.selected'), 'sala');
    });

    testWidgets('失効: 選択中が資格キャラでも、チェックは共通キャラ側に付く', (t) async {
      SharedPreferences.setMockInitialValues({
        'ukalab.mascot.selected': 'sala',
        'ukalab.mascot.lastCommon': 'kai',
      });
      await _pump(t, appId: 'hazmat4', premium: false);
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await t.pump();
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
      // チェックが付くのはカイ(1つだけ)
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      final kaiCard = find.ancestor(of: find.text('カイ'), matching: find.byType(Card));
      expect(find.descendant(of: kaiCard, matching: find.byIcon(Icons.check_circle)), findsOneWidget);
    });

    testWidgets('画像が無くても例外にならない(アイコン・プレビュー)', (t) async {
      await _pump(t, appId: 'kanji_kentei');
      await t.ensureVisible(find.text('タツ'));
      await t.tap(find.text('タツ'));
      await t.pump(const Duration(milliseconds: 300));
      expect(tester(t), isNull);
    });

    for (final size in const [Size(320, 568), Size(280, 480)]) {
      for (final scale in const [1.0, 2.0, 3.0]) {
        testWidgets('オーバーフローしない: ${size.width.toInt()}dp x 文字${scale}倍(ロック+プレビュー)', (t) async {
          await _pump(t, appId: 'info_security', size: size, scale: scale);
          expect(tester(t), isNull);
          await t.ensureVisible(find.text('シェル'));
          await t.tap(find.text('シェル'));
          await t.pump(const Duration(milliseconds: 300));
          expect(find.text('プレビュー中です。選ぶにはプレミアムが必要です'), findsOneWidget);
          expect(tester(t), isNull);
        });
      }
    }
  });

  group('B 画像が無い画面の代替表示', () {
    testWidgets('MascotWidget: 資格キャラに scene を渡しても例外にならない(Lv 画像で代用)', (t) async {
      for (final p in UkalabCharacters.qualificationPacks) {
        for (final sc in MascotScene.values) {
          await t.pumpWidget(MaterialApp(
            home: Scaffold(body: MascotWidget(pack: p, scene: sc, stage: MascotStage.lv3, animate: false)),
          ));
          await t.pump();
          expect(tester(t), isNull, reason: '${p.id} $sc');
          final img = t.widget<Image>(find.byType(Image));
          // 場面別(scenes/guide/states)ではなく、Lv 画像を指す
          expect((img.image as AssetImage).assetName, contains('${p.id}_lv3_normal'), reason: '${p.id} $sc');
        }
      }
    });

    testWidgets('MascotPoseImage / MascotStateView: 資格キャラは Lv 画像で代用し、例外にならない', (t) async {
      for (final p in UkalabCharacters.qualificationPacks) {
        await t.pumpWidget(MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(children: [
                MascotPoseImage(pack: p, pose: MascotPose.cheer),
                MascotStateView(pack: p, state: MascotState.empty, message: 'まだありません'),
              ]),
            ),
          ),
        ));
        await t.pump();
        await t.pump(const Duration(milliseconds: 50));
        expect(tester(t), isNull, reason: p.id);
        for (final img in t.widgetList<Image>(find.byType(Image))) {
          final name = (img.image as AssetImage).assetName;
          expect(name.contains('/poses/') || name.contains('/states/') || name.contains('/scenes/'), false, reason: name);
        }
      }
    });

    testWidgets('画像ファイルが無い(読み込めない)ときも、標準キャラの描画に戻って例外にならない', (t) async {
      await t.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MascotWidget(pack: UkalabCharacters.noda, stage: MascotStage.lv1, animate: false),
        ),
      ));
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));
      expect(tester(t), isNull);
    });
  });

  test('共通キャラは従来どおり all.length==5 で、資格キャラを含まない', () {
    expect(UkalabCharacters.all.length, 5);
    expect(UkalabCharacters.imagePacks.length, 4);
    for (final p in UkalabCharacters.all) {
      expect(UkalabCharacters.isQualification(p), false, reason: p.id);
    }
  });
}

/// 直近の描画で出た例外(オーバーフローなど)を取り出す。無ければ null。
Object? tester(WidgetTester t) => t.takeException();
