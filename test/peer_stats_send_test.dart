import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ukalab_core/ui.dart';
import 'package:ukalab_core/ukalab_core.dart';

class _Settings implements PeerStatsSettings {
  _Settings(this.on);
  bool on;
  @override
  Future<bool> isSharingEnabled() async => on;
  @override
  Future<void> setSharingEnabled(bool enabled) async => on = enabled;
}

class _Gate implements PeerStatsGate {
  _Gate(this.allowed);
  bool allowed;
  @override
  Future<bool> isAllowed() async => allowed;
  @override
  Future<bool> request() async => allowed;
  @override
  Future<void> revoke() async => allowed = false;
}

class _Sink implements PeerStatsSink {
  final sent = <PeerContribution>[];
  bool fail = false;
  @override
  Future<void> submit(PeerContribution c) async {
    if (fail) throw StateError('offline');
    sent.add(c);
  }
}

class _Dates implements PeerSentDateStore {
  final m = <String, String>{};
  @override
  Future<String?> read(String examId) async => m[examId];
  @override
  Future<void> write(String examId, String dateKey) async => m[examId] = dateKey;
}

class _Writer implements PeerDeviceWriter {
  final writes = <String, Map<String, Object?>>{};
  @override
  Future<void> set(String path, Map<String, Object?> data) async => writes[path] = data;
}

void main() {
  late _Settings settings;
  late _Gate gate;
  late _Sink sink;
  late _Dates dates;
  var now = DateTime.utc(2026, 10, 15, 3); // JST 12:00
  late PeerStatsSender sender;

  setUp(() {
    settings = _Settings(true);
    gate = _Gate(true);
    sink = _Sink();
    dates = _Dates();
    now = DateTime.utc(2026, 10, 15, 3);
    sender = PeerStatsSender(settings: settings, gate: gate, sink: sink, sentDates: dates, clock: () => now);
  });

  Future<PeerSendResult> send() => sender.maybeSend(
      examId: 'fe', streakDays: 5, totalQuestions: 300, examDate: DateTime(2026, 12, 6));

  test('オプトインOFF（既定）では送らない', () async {
    settings.on = false;
    expect(await send(), PeerSendResult.disabled);
    expect(sink.sent, isEmpty);
  });

  test('ゲート未通過では送らない', () async {
    gate.allowed = false;
    expect(await send(), PeerSendResult.gateBlocked);
    expect(sink.sent, isEmpty);
  });

  test('ON かつ ゲート通過で送る。日本時間の暦日で、同日2回目は送らない', () async {
    expect(await send(), PeerSendResult.sent);
    expect(sink.sent.single.dateKey, '2026-10-15');
    expect(sink.sent.single.examDate, '2026-12-06');
    expect(await send(), PeerSendResult.alreadySentToday);
    expect(sink.sent, hasLength(1));
    now = DateTime.utc(2026, 10, 15, 14, 59); // JST 23:59 まだ同日
    expect(await send(), PeerSendResult.alreadySentToday);
    now = DateTime.utc(2026, 10, 15, 15, 0); // JST 翌日 00:00
    expect(await send(), PeerSendResult.sent);
    expect(sink.sent.last.dateKey, '2026-10-16');
  });

  test('失敗は握りつぶし、記録しないので次回また送る', () async {
    sink.fail = true;
    expect(await send(), PeerSendResult.failed);
    expect(dates.m, isEmpty);
    sink.fail = false;
    expect(await send(), PeerSendResult.sent);
  });

  test('設定・ゲートの読み取りが例外でも投げない', () async {
    final s = PeerStatsSender(
        settings: _ThrowingSettings(), gate: gate, sink: sink, sentDates: dates, clock: () => now);
    expect(await s.maybeSend(examId: 'fe', streakDays: 1, totalQuestions: 1), PeerSendResult.failed);
  });

  test('試験ごとに日次1回を数える', () async {
    await send();
    expect(await sender.maybeSend(examId: 'boki3', streakDays: 1, totalQuestions: 1), PeerSendResult.sent);
  });

  test('NoPeerStatsGate は常に許可（成人向け）', () async {
    expect(await const NoPeerStatsGate().isAllowed(), isTrue);
  });

  group('書き込みデータ', () {
    test('最小限のキーだけ（個人・端末の情報なし）', () async {
      SharedPreferences.setMockInitialValues({});
      final w = _Writer();
      final store = SharedPrefsInstallIdStore();
      final s = FirestorePeerStatsSink(installIdStore: store, writer: w, timestamp: () => 'TS');
      await s.submit(const PeerContribution(
          examId: 'fe', dateKey: '2026-10-15', streakDays: 5, totalQuestions: 300, examDate: '2026-12-06'));
      final id = await store.getOrCreate();
      expect(w.writes.keys.single, 'peer_devices/fe/devices/$id');
      expect(w.writes.values.single, {
        'day': '2026-10-15',
        'streakDays': 5,
        'totalQuestions': 300,
        'examDate': '2026-12-06',
        'updatedAt': 'TS',
      });
    });

    test('試験日なしは examDate を含めない。値域外は丸める', () {
      final m = PeerDevicePayload.build(
          const PeerContribution(examId: 'fe', dateKey: '2026-10-15', streakDays: -3, totalQuestions: 99999999),
          updatedAt: 'TS');
      expect(m.containsKey('examDate'), isFalse);
      expect(m['streakDays'], 0);
      expect(m['totalQuestions'], 1000000);
      expect(m.keys.toSet(), {'day', 'streakDays', 'totalQuestions', 'updatedAt'});
    });

    test('不正な形式の試験日は書かない', () {
      final m = PeerDevicePayload.build(
          const PeerContribution(
              examId: 'fe', dateKey: '2026-10-15', streakDays: 1, totalQuestions: 1, examDate: 'abc'),
          updatedAt: 'TS');
      expect(m.containsKey('examDate'), isFalse);
    });
  });

  group('installId', () {
    test('UUID v4 形式でルールの正規表現を満たす', () {
      final id = InstallId.generate(Random(1));
      expect(InstallId.isValid(id), isTrue);
      expect(RegExp(r'^[0-9a-f-]{36}$').hasMatch(id), isTrue);
      expect(InstallId.generate(Random(2)), isNot(id));
    });

    test('保存して再取得しても同じ。clear で別IDになる。壊れた値は作り直す', () async {
      SharedPreferences.setMockInitialValues({});
      final store = SharedPrefsInstallIdStore();
      final a = await store.getOrCreate();
      expect(await SharedPrefsInstallIdStore().getOrCreate(), a);
      await store.clear();
      expect(await store.getOrCreate(), isNot(a));
      SharedPreferences.setMockInitialValues({'ukalab_peer_install_id': 'broken'});
      expect(InstallId.isValid(await SharedPrefsInstallIdStore().getOrCreate()), isTrue);
    });

    test('送信日の保存', () async {
      SharedPreferences.setMockInitialValues({});
      final s = SharedPrefsPeerSentDateStore();
      expect(await s.read('fe'), isNull);
      await s.write('fe', '2026-10-15');
      expect(await s.read('fe'), '2026-10-15');
    });
  });

  test('日本時間の暦日', () {
    expect(peerJstDateKey(DateTime.utc(2026, 10, 14, 14, 59)), '2026-10-14');
    expect(peerJstDateKey(DateTime.utc(2026, 10, 14, 15)), '2026-10-15');
  });
}

class _ThrowingSettings implements PeerStatsSettings {
  @override
  Future<bool> isSharingEnabled() async => throw StateError('x');
  @override
  Future<void> setSharingEnabled(bool enabled) async {}
}
