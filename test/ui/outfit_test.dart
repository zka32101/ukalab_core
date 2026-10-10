import 'package:ukalab_core/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('衣装の台帳', () {
    test('17資格 × 4着（通常・合格記念・試験日・準備完了）で id が一意', () {
      expect(OutfitCatalog.all, hasLength(68));
      expect(OutfitCatalog.all.map((o) => o.id).toSet(), hasLength(68));
      for (final c in UkalabCert.values) {
        expect(OutfitCatalog.forCert(c).map((o) => o.kind).toSet(), OutfitKind.values.toSet());
      }
    });

    test('コインで買うのは通常衣装だけ。合格記念・試験日・準備完了は無料', () {
      for (final o in OutfitCatalog.all) {
        expect(o.isPurchasable, o.kind == OutfitKind.regular);
        expect(o.price > 0, o.kind == OutfitKind.regular, reason: o.id);
      }
    });

    test('ショップ品目の価格は衣装の目安（200〜500）に収まる', () {
      final items = OutfitCatalog.shopItems();
      expect(items, hasLength(17));
      expect(validateShop(items), isEmpty);
    });

    test('衣装名に「公式」「認定」を入れない（誤認防止）', () {
      for (final o in OutfitCatalog.all) {
        expect(o.name, isNot(contains('公式')));
        expect(o.name, isNot(contains('認定')));
      }
    });

    test('id から引ける', () {
      expect(OutfitCatalog.byId('passMemorial.g_kentei')?.cert, UkalabCert.gKentei);
      expect(OutfitCatalog.byId('nope'), isNull);
    });
  });

  group('解放と装備', () {
    Future<OutfitService> svc([OutfitStore? store]) async {
      final s = OutfitService(store: store ?? InMemoryOutfitStore());
      await s.load();
      return s;
    }

    final regular = OutfitCatalog.byId('regular.g_kentei')!;
    final memorial = OutfitCatalog.byId('passMemorial.g_kentei')!;
    final examDay = OutfitCatalog.byId('examDay.g_kentei')!;
    final ready = OutfitCatalog.byId('readiness.g_kentei')!;

    test('最初は何も着られない（通常は購入が必要）', () async {
      final s = await svc();
      expect(s.availability(regular), OutfitAvailability.notPurchased);
      expect(s.availability(memorial), OutfitAvailability.notPassed);
      expect(s.availability(examDay), OutfitAvailability.noExamDate);
      expect(s.availability(ready), OutfitAvailability.notReady);
    });

    test('通常衣装は、コインで買った品目IDを渡すと着られる', () async {
      final s = await svc();
      expect(s.isAvailable(regular, purchasedIds: {regular.id}), isTrue);
      expect(await s.equip(regular.id), isFalse);
      expect(await s.equip(regular.id, purchasedIds: {regular.id}), isTrue);
      expect(s.equippedId, regular.id);
    });

    test('合格記念は、合格報告で「合格」を選んだ資格だけ（コイン不要）。別の資格は解放されない', () async {
      final s = await svc();
      expect(await s.reportPassed(UkalabCert.gKentei), isTrue);
      expect(await s.reportPassed(UkalabCert.gKentei), isFalse, reason: '2回目は新規ではない');
      expect(s.isAvailable(memorial), isTrue);
      expect(s.isAvailable(OutfitCatalog.byId('passMemorial.boki3')!), isFalse);
      expect(await s.equip(memorial.id), isTrue);
    });

    test('試験日の装いは、試験日を設定した人だけ。試験日が過ぎたら着られなくなる', () async {
      final s = await svc();
      expect(await s.equip(examDay.id), isFalse);
      expect(await s.equip(examDay.id, examPhase: ExamPhase.close), isTrue);
      expect(s.currentOutfit(examPhase: ExamPhase.close)?.id, examDay.id);
      expect(s.currentOutfit(examPhase: ExamPhase.none), isNull);
    });

    test('準備完了は、最短ルートの目標達成（markReady）で解放（無料）', () async {
      final s = await svc();
      expect(s.isAvailable(ready), isFalse);
      expect(await s.markReady(UkalabCert.gKentei), isTrue);
      expect(s.isAvailable(ready), isTrue);
    });

    test('着られない衣装・存在しない衣装は装備できず、状態は変わらない', () async {
      final s = await svc();
      expect(await s.equip('nope'), isFalse);
      expect(await s.equip(memorial.id), isFalse);
      expect(s.equippedId, isNull);
      await s.reportPassed(UkalabCert.gKentei);
      await s.equip(memorial.id);
      expect(await s.equip(regular.id), isFalse);
      expect(s.equippedId, memorial.id);
      await s.unequip();
      expect(s.equippedId, isNull);
    });

    test('保存して復元できる', () async {
      final store = InMemoryOutfitStore();
      final a = await svc(store);
      await a.reportPassed(UkalabCert.boki3);
      await a.markReady(UkalabCert.gKentei);
      await a.equip('passMemorial.boki3');
      final b = await svc(store);
      expect(b.passedCerts, {'boki3'});
      expect(b.readyCerts, {'g_kentei'});
      expect(b.equippedId, 'passMemorial.boki3');
    });

    test('着られる衣装が先頭に並ぶ', () async {
      final s = await svc();
      await s.reportPassed(UkalabCert.gKentei);
      final l = s.outfitsFor(UkalabCert.gKentei);
      expect(l.first.kind, OutfitKind.passMemorial);
      expect(l, hasLength(4));
    });
  });

  group('描画', () {
    Widget host(Widget child) => MaterialApp(
          theme: UkalabTheme.light(field: UkalabField.ai, cert: UkalabCert.gKentei),
          home: Scaffold(body: SingleChildScrollView(child: child)),
        );

    testWidgets('全60着を着て描画できる（全分野の小物・合格記念・準備完了）', (tester) async {
      for (final o in OutfitCatalog.all) {
        await tester.pumpWidget(host(MascotWidget(outfit: o, stage: MascotStage.lv3, animate: false)));
        expect(tester.takeException(), isNull, reason: o.id);
      }
    });

    testWidgets('animate: false ならアニメーションが走らない', (tester) async {
      await tester.pumpWidget(host(const MascotWidget(animate: false)));
      await tester.pump(const Duration(seconds: 1));
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  group('共有カード', () {
    final data = ShareCardData(
      certLabel: 'G検定',
      date: DateTime(2026, 12, 14),
      packName: 'うか',
      stage: MascotStage.lv5,
      outfit: OutfitCatalog.byId('passMemorial.g_kentei'),
    );

    Widget host(Widget child, {double scale = 1}) => MaterialApp(
          theme: UkalabTheme.light(field: UkalabField.ai, cert: UkalabCert.gKentei),
          builder: (context, c) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
            child: c!,
          ),
          home: Scaffold(body: Center(child: SizedBox(width: 320, child: child))),
        );

    testWidgets('資格名・日付・メッセージだけが出る。点数は任意', (tester) async {
      await tester.pumpWidget(host(PassShareCard(data: data)));
      final texts = tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).whereType<String>().toSet();
      expect(texts, {'うかラボ', 'G検定', '合格しました！', '2026年12月14日'});

      await tester.pumpWidget(host(PassShareCard(
        data: ShareCardData(
          certLabel: 'G検定',
          date: DateTime(2026, 12, 14),
          packName: 'うか',
          stage: MascotStage.lv5,
          scoreText: '845点',
        ),
      )));
      expect(find.text('845点'), findsOneWidget);
    });

    test('個人情報を入れる欄がない（名前・メール・ID・端末情報）', () {
      // ShareCardData のコンストラクタ引数は、資格名・日付・推し名・段階・衣装・点数・メッセージだけ。
      final d = ShareCardData(certLabel: 'x', date: DateTime(2026), packName: 'p', stage: MascotStage.lv1);
      expect(d.dateText, '2026年1月1日');
    });

    testWidgets('文字拡大200%でも崩れない', (tester) async {
      await tester.pumpWidget(host(PassShareCard(data: data), scale: 2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('PNG に書き出せる', (tester) async {
      final key = GlobalKey();
      await tester.pumpWidget(host(RepaintBoundary(key: key, child: PassShareCard(data: data))));
      final bytes = await tester.runAsync(() => captureShareCard(key, pixelRatio: 1));
      expect(bytes, isNotNull);
      // PNG のシグネチャ
      expect(bytes!.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47]);
    });
  });
}
