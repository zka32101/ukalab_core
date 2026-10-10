import 'package:ukalab_core/ui.dart';
import 'package:flutter_test/flutter_test.dart';

class _FailingRemote implements CoinRemote {
  @override
  Future<List<dynamic>?> readLedger() async => throw Exception('offline');

  @override
  Future<void> writeLedger(List<Map<String, dynamic>> json) async {}
}

CoinService _service(DateTime t) =>
    CoinService(store: InMemoryCoinStore(), clock: () => t);

void main() {
  test('2台の端末の台帳が統合され、何度同期しても二重にならない', () async {
    final remote = InMemoryCoinRemote();
    final a = _service(DateTime(2026, 10, 1));
    final b = _service(DateTime(2026, 10, 2));
    await a.grant(CoinEvent.newQuestion('q1'));
    await b.grant(CoinEvent.newQuestion('q2'));

    expect(await CoinSync(service: a, remote: remote).sync(), CoinSyncResult.synced);
    expect(await CoinSync(service: b, remote: remote).sync(), CoinSyncResult.synced);
    await CoinSync(service: a, remote: remote).sync();
    await CoinSync(service: a, remote: remote).sync();

    expect(a.balance, b.balance);
    expect(a.ledger.entries.length, 2);
  });

  test('失敗しても端末内の台帳は変わらない', () async {
    final a = _service(DateTime(2026, 10, 1));
    await a.grant(CoinEvent.newQuestion('q1'));
    final before = a.balance;
    final r = await CoinSync(service: a, remote: _FailingRemote()).sync();
    expect(r, CoinSyncResult.failed);
    expect(a.balance, before);
  });
}
