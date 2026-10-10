import 'package:ukalab_core/ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _CountingRemote extends InMemoryCoinRemote {
  int reads = 0;

  @override
  Future<List<dynamic>?> readLedger() {
    reads++;
    return super.readLedger();
  }
}

class _FailingRemote implements CoinRemote {
  @override
  Future<List<dynamic>?> readLedger() async => throw Exception('offline');

  @override
  Future<void> writeLedger(List<Map<String, dynamic>> json) async {}
}

ProviderContainer _container(CoinService s) =>
    ProviderContainer(overrides: [coinServiceProvider.overrideWithValue(s)]);

void main() {
  test('同期すると別端末の残高が画面の状態に反映される', () async {
    final remote = InMemoryCoinRemote();
    final other = CoinService(store: InMemoryCoinStore(), clock: () => DateTime(2026, 10, 1));
    await other.grant(CoinEvent.newQuestion('q1'));
    await CoinSync(service: other, remote: remote).sync();

    final mine = CoinService(store: InMemoryCoinStore(), clock: () => DateTime(2026, 10, 2));
    final c = _container(mine);
    addTearDown(c.dispose);
    expect(c.read(coinProvider).balance, 0);

    final r = await c.read(coinProvider.notifier).syncWith(remote);
    expect(r, CoinSyncResult.synced);
    expect(c.read(coinProvider).balance, 1);
  });

  test('minInterval 以内の再同期はスキップされる', () async {
    final remote = _CountingRemote();
    final c = _container(CoinService(store: InMemoryCoinStore()));
    addTearDown(c.dispose);
    final n = c.read(coinProvider.notifier);
    var now = DateTime(2026, 10, 1, 12);
    DateTime clock() => now;

    expect(await n.syncWith(remote, minInterval: const Duration(minutes: 5), clock: clock), CoinSyncResult.synced);
    now = now.add(const Duration(minutes: 1));
    expect(await n.syncWith(remote, minInterval: const Duration(minutes: 5), clock: clock), isNull);
    expect(remote.reads, 1);
    now = now.add(const Duration(minutes: 5));
    expect(await n.syncWith(remote, minInterval: const Duration(minutes: 5), clock: clock), CoinSyncResult.synced);
    expect(remote.reads, 2);
  });

  test('失敗は例外にならず failed。失敗では間隔の起点を進めない', () async {
    final c = _container(CoinService(store: InMemoryCoinStore()));
    addTearDown(c.dispose);
    final n = c.read(coinProvider.notifier);
    final now = DateTime(2026, 10, 1);
    expect(await n.syncWith(_FailingRemote(), minInterval: const Duration(hours: 1), clock: () => now), CoinSyncResult.failed);
    // 直後でも、失敗していたので再試行できる。
    expect(await n.syncWith(InMemoryCoinRemote(), minInterval: const Duration(hours: 1), clock: () => now), CoinSyncResult.synced);
  });

  test('Firestore の保存先パス', () {
    expect(FirebaseCoinRemote.docPath('u1', 'bike_license'), 'users/u1/exams/bike_license/coin/ledger');
  });
}
