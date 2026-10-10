/// 追記専用の台帳。残高は台帳の合計で決まる（保存した残高と食い違わない）。
///
/// 端末移行・共通アカウントでの同期は、台帳を JSON にして [merge] で統合する。
/// 各行の [id] が決まっているので、同じ行は何度統合しても二重にならない。
library;

class CoinEntry {
  const CoinEntry({
    required this.id,
    required this.kind,
    required this.amount,
    required this.day,
    required this.at,
    this.ref,
  });

  /// 獲得は `type|key|(日付)`、購入は `spend|itemId`。
  final String id;

  /// イベント種別の名前、または `spend`。
  final String kind;

  /// 獲得は正、購入は負。
  final int amount;

  /// `yyyy-MM-dd`（端末のローカル日付）。
  final String day;
  final DateTime at;

  /// 購入した品目ID（購入のみ）。
  final String? ref;

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind,
        'amount': amount,
        'day': day,
        'at': at.toIso8601String(),
        if (ref != null) 'ref': ref,
      };

  factory CoinEntry.fromJson(Map<String, dynamic> j) => CoinEntry(
        id: j['id'] as String,
        kind: j['kind'] as String,
        amount: j['amount'] as int,
        day: j['day'] as String,
        at: DateTime.parse(j['at'] as String),
        ref: j['ref'] as String?,
      );
}

class CoinLedger {
  CoinLedger([Iterable<CoinEntry> entries = const []]) {
    for (final e in entries) {
      _byId[e.id] = e;
    }
  }

  final Map<String, CoinEntry> _byId = {};

  List<CoinEntry> get entries {
    final l = _byId.values.toList()..sort((a, b) => a.at.compareTo(b.at));
    return List.unmodifiable(l);
  }

  bool contains(String id) => _byId.containsKey(id);

  /// 残高（購入分を引いた合計）。購入は残高以内でしか記録しないので負にならない。
  int get balance => _byId.values.fold(0, (s, e) => s + e.amount);

  /// 累計の獲得量（購入で減らない）。
  int get totalEarned => _byId.values.where((e) => e.amount > 0).fold(0, (s, e) => s + e.amount);

  Set<String> get ownedItemIds =>
      {for (final e in _byId.values) if (e.kind == 'spend' && e.ref != null) e.ref!};

  int earnedOn(String day, {String? kind}) => _byId.values
      .where((e) => e.amount > 0 && e.day == day && (kind == null || e.kind == kind))
      .fold(0, (s, e) => s + e.amount);

  int countOn(String day, String kind) =>
      _byId.values.where((e) => e.amount > 0 && e.day == day && e.kind == kind).length;

  /// 行を追加する。同じ id があれば何もしない（false）。
  bool add(CoinEntry e) {
    if (_byId.containsKey(e.id)) return false;
    _byId[e.id] = e;
    return true;
  }

  /// 別の台帳（別端末・サーバー）を統合する。id が同じ行は一度だけ数える。
  CoinLedger merge(CoinLedger other) => CoinLedger([...entries, ...other.entries]);

  List<Map<String, dynamic>> toJson() => [for (final e in entries) e.toJson()];

  factory CoinLedger.fromJson(List<dynamic> json) => CoinLedger([
        for (final j in json) CoinEntry.fromJson(Map<String, dynamic>.from(j as Map)),
      ]);
}
