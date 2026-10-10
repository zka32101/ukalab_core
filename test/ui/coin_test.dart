import 'package:ukalab_core/ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _shop = [
  ShopItem(id: 'hat', name: '帽子', category: ShopCategory.accessory, price: 50),
  ShopItem(id: 'glasses', name: '眼鏡', category: ShopCategory.accessory, price: 100),
  ShopItem(id: 'suit', name: 'スーツ', category: ShopCategory.outfit, price: 300),
];

class _Clock {
  DateTime now = DateTime(2026, 10, 2, 9);
  DateTime call() => now;
  void nextDay() => now = now.add(const Duration(days: 1));
}

Future<(CoinService, _Clock)> _service({CoinRules rules = CoinRules.standard}) async {
  final clock = _Clock();
  final s = CoinService(store: InMemoryCoinStore(), rules: rules, shop: _shop, clock: clock.call);
  await s.load();
  return (s, clock);
}

void main() {
  group('獲得', () {
    test('新しい問題 +1。同じ問題の再回答は対象外', () async {
      final (s, _) = await _service();
      expect((await s.grant(CoinEvent.newQuestion('q1')))?.amount, 1);
      expect(await s.grant(CoinEvent.newQuestion('q1')), isNull);
      expect(s.balance, 1);
    });

    test('新しい問題は1日30まで。翌日はまた獲得できる', () async {
      final (s, clock) = await _service();
      for (var i = 0; i < 35; i++) {
        await s.grant(CoinEvent.newQuestion('q$i'));
      }
      expect(s.balance, 30);
      clock.nextDay();
      expect((await s.grant(CoinEvent.newQuestion('q99')))?.amount, 1);
      expect(s.balance, 31);
    });

    test('網羅率は10%刻みで各段階1回だけ。10の倍数以外は対象外', () async {
      final (s, _) = await _service();
      expect((await s.grant(CoinEvent.coverageStep('t1', 10)))?.amount, 10);
      expect(await s.grant(CoinEvent.coverageStep('t1', 10)), isNull);
      expect((await s.grant(CoinEvent.coverageStep('t1', 20)))?.amount, 10);
      expect((await s.grant(CoinEvent.coverageStep('t2', 10)))?.amount, 10);
      expect(await s.grant(CoinEvent.coverageStep('t1', 15)), isNull);
      expect(s.balance, 30);
    });

    test('正答率 70／80／90% は +20／+30／+50、各段階・トピックごとに1回', () async {
      final (s, _) = await _service();
      expect((await s.grant(CoinEvent.accuracyMilestone('t1', 70)))?.amount, 20);
      expect((await s.grant(CoinEvent.accuracyMilestone('t1', 80)))?.amount, 30);
      expect((await s.grant(CoinEvent.accuracyMilestone('t1', 90)))?.amount, 50);
      expect(await s.grant(CoinEvent.accuracyMilestone('t1', 90)), isNull);
      expect(await s.grant(CoinEvent.accuracyMilestone('t1', 75)), isNull);
      expect((await s.grant(CoinEvent.accuracyMilestone('t2', 70)))?.amount, 20);
      expect(s.balance, 120);
    });

    test('自己ベスト更新 +5 は1日3回まで', () async {
      final (s, _) = await _service();
      for (final t in ['a', 'b', 'c', 'd']) {
        await s.grant(CoinEvent.accuracyBest(t));
      }
      expect(s.balance, 15);
    });

    test('復習で正解 +2 は1日20まで。同じ問題は同じ日に1回', () async {
      final (s, _) = await _service();
      expect((await s.grant(CoinEvent.reviewCorrected('q1')))?.amount, 2);
      expect(await s.grant(CoinEvent.reviewCorrected('q1')), isNull);
      for (var i = 0; i < 20; i++) {
        await s.grant(CoinEvent.reviewCorrected('r$i'));
      }
      expect(s.ledger.earnedOn('2026-10-02', kind: 'reviewCorrected'), 20);
    });

    test('今日の相談・模擬試験の実施は1日1回', () async {
      final (s, clock) = await _service();
      expect((await s.grant(CoinEvent.dailyConsult()))?.amount, 2);
      expect(await s.grant(CoinEvent.dailyConsult()), isNull);
      expect((await s.grant(CoinEvent.mockDone()))?.amount, 10);
      expect(await s.grant(CoinEvent.mockDone()), isNull);
      clock.nextDay();
      expect((await s.grant(CoinEvent.dailyConsult()))?.amount, 2);
      expect((await s.grant(CoinEvent.mockDone()))?.amount, 10);
    });

    test('模擬試験の初合格 +50 は試験ごとに1回。自己ベスト +20 は1日1回', () async {
      final (s, clock) = await _service();
      expect((await s.grant(CoinEvent.mockPass('e1')))?.amount, 50);
      expect(await s.grant(CoinEvent.mockPass('e1')), isNull);
      expect((await s.grant(CoinEvent.mockBest('e1')))?.amount, 20);
      expect(await s.grant(CoinEvent.mockBest('e1')), isNull);
      clock.nextDay();
      expect((await s.grant(CoinEvent.mockBest('e1')))?.amount, 20);
    });

    test('連続学習 7／30／100日は達成時のみ。8日などは対象外', () async {
      final (s, _) = await _service();
      expect((await s.grant(CoinEvent.streak(7)))?.amount, 30);
      expect((await s.grant(CoinEvent.streak(30)))?.amount, 100);
      expect((await s.grant(CoinEvent.streak(100)))?.amount, 300);
      expect(await s.grant(CoinEvent.streak(8)), isNull);
      expect(await s.grant(CoinEvent.streak(7)), isNull);
    });

    test('合格報告 +200 は資格ごとに1回', () async {
      final (s, _) = await _service();
      expect((await s.grant(CoinEvent.passReport('g_kentei')))?.amount, 200);
      expect(await s.grant(CoinEvent.passReport('g_kentei')), isNull);
      expect((await s.grant(CoinEvent.passReport('boki3')))?.amount, 200);
    });

    test('数値は CoinRules で調整できる', () async {
      final (s, _) = await _service(rules: const CoinRules(newQuestion: 3));
      expect((await s.grant(CoinEvent.newQuestion('q')))?.amount, 3);
    });
  });

  group('購入・装備', () {
    test('残高が足りなければ買えず、残高は変わらない（負にならない）', () async {
      final (s, _) = await _service();
      await s.grant(CoinEvent.coverageStep('t', 10)); // 10
      expect(await s.purchase('hat'), PurchaseResult.insufficient);
      expect(s.balance, 10);
      expect(s.ownedItemIds, isEmpty);
    });

    test('買うと残高から引かれ、二重購入・存在しない品目は失敗', () async {
      final (s, _) = await _service();
      for (var p = 70; p <= 90; p += 10) {
        await s.grant(CoinEvent.accuracyMilestone('t', p)); // 100
      }
      expect(s.balance, 100);
      expect(await s.purchase('hat'), PurchaseResult.purchased);
      expect(s.balance, 50);
      expect(await s.purchase('hat'), PurchaseResult.alreadyOwned);
      expect(await s.purchase('nope'), PurchaseResult.unknownItem);
      expect(s.balance, 50);
      expect(s.totalEarned, 100, reason: '累計の獲得量は購入で減らない');
    });

    test('持っている品目だけ装備でき、カテゴリごとに1つ', () async {
      final (s, _) = await _service();
      for (var p = 70; p <= 90; p += 10) {
        await s.grant(CoinEvent.accuracyMilestone('t', p));
      }
      await s.grant(CoinEvent.mockPass('e1')); // 合計 150
      expect(await s.equip('hat'), isFalse);
      await s.purchase('hat');
      await s.purchase('glasses');
      expect(await s.equip('hat'), isTrue);
      expect(await s.equip('glasses'), isTrue);
      expect(s.equipped, {'accessory': 'glasses'});
      await s.unequip(ShopCategory.accessory);
      expect(s.equipped, isEmpty);
    });

    test('価格が目安の範囲内か検査できる', () {
      expect(validateShop(_shop), isEmpty);
      expect(
        validateShop(const [ShopItem(id: 'x', name: 'x', category: ShopCategory.outfit, price: 10)]),
        hasLength(1),
      );
    });
  });

  group('保存・同期', () {
    test('保存した台帳から残高・購入・装備が復元される', () async {
      final store = InMemoryCoinStore();
      final clock = _Clock();
      final a = CoinService(store: store, shop: _shop, clock: clock.call);
      await a.load();
      for (var p = 70; p <= 90; p += 10) {
        await a.grant(CoinEvent.accuracyMilestone('t', p));
      }
      await a.purchase('hat');
      await a.equip('hat');

      final b = CoinService(store: store, shop: _shop, clock: clock.call);
      await b.load();
      expect(b.balance, 50);
      expect(b.ownedItemIds, {'hat'});
      expect(b.equipped, {'accessory': 'hat'});
      // 復元後も重複付与されない
      expect(await b.grant(CoinEvent.accuracyMilestone('t', 70)), isNull);
    });

    test('別端末の台帳を統合しても二重に数えない（何度統合しても同じ）', () async {
      final clock = _Clock();
      final a = CoinService(store: InMemoryCoinStore(), shop: _shop, clock: clock.call);
      final b = CoinService(store: InMemoryCoinStore(), shop: _shop, clock: clock.call);
      await a.load();
      await b.load();
      await a.grant(CoinEvent.passReport('g_kentei')); // 200
      await b.grant(CoinEvent.passReport('g_kentei')); // 同じ契機（別端末で重複）
      await b.grant(CoinEvent.streak(7)); // 30
      await a.mergeLedger(b.ledger);
      expect(a.balance, 230);
      await a.mergeLedger(b.ledger);
      expect(a.balance, 230);
    });

    test('壊れた保存データでも空の台帳で始まる', () async {
      SharedPreferences.setMockInitialValues({'ukalab_coin_ledger_bike': 'not json'});
      final s = CoinService(store: SharedPreferencesCoinStore('bike'), shop: _shop);
      await s.load();
      expect(s.balance, 0);
    });

    test('財布はアプリごと（appId が違えば別）', () async {
      SharedPreferences.setMockInitialValues({});
      final a = CoinService(store: SharedPreferencesCoinStore('bike'), shop: _shop);
      final b = CoinService(store: SharedPreferencesCoinStore('kanken'), shop: _shop);
      await a.load();
      await b.load();
      await a.grant(CoinEvent.passReport('x'));
      final b2 = CoinService(store: SharedPreferencesCoinStore('kanken'), shop: _shop);
      await b2.load();
      expect(b2.balance, 0);
      final a2 = CoinService(store: SharedPreferencesCoinStore('bike'), shop: _shop);
      await a2.load();
      expect(a2.balance, 200);
    });
  });

  test('Riverpod: 付与すると状態が更新され、直近の付与が分かる', () async {
    final service = CoinService(store: InMemoryCoinStore(), shop: _shop);
    final c = ProviderContainer(overrides: [coinServiceProvider.overrideWithValue(service)]);
    addTearDown(c.dispose);
    await c.read(coinProvider.notifier).load();
    expect(c.read(coinProvider).balance, 0);
    final g = await c.read(coinProvider.notifier).grant(CoinEvent.dailyConsult());
    expect(g?.amount, 2);
    expect(c.read(coinProvider).balance, 2);
    expect(c.read(coinProvider).lastGrant?.amount, 2);
    await c.read(coinProvider.notifier).grant(CoinEvent.dailyConsult());
    expect(c.read(coinProvider).lastGrant, isNull, reason: '重複は付与されない');
  });
}
