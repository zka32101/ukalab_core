/// JSON 読み取りの共通ヘルパー。不正な入力は [FormatException] にする。
library;

Never fail(String where, String message) =>
    throw FormatException('$where: $message');

String reqString(Map<String, dynamic> j, String key, String where) {
  final v = j[key];
  if (v is! String || v.trim().isEmpty) {
    fail(where, '"$key" は空でない文字列が必要です');
  }
  return v;
}

String? optString(Map<String, dynamic> j, String key, String where) {
  final v = j[key];
  if (v == null) return null;
  if (v is! String) fail(where, '"$key" は文字列が必要です');
  return v.trim().isEmpty ? null : v;
}

int reqInt(Map<String, dynamic> j, String key, String where) {
  final v = j[key];
  if (v is! int) fail(where, '"$key" は整数が必要です');
  return v;
}

int optInt(Map<String, dynamic> j, String key, String where, int fallback) {
  final v = j[key];
  if (v == null) return fallback;
  if (v is! int) fail(where, '"$key" は整数が必要です');
  return v;
}

double reqNum(Map<String, dynamic> j, String key, String where) {
  final v = j[key];
  if (v is! num) fail(where, '"$key" は数値が必要です');
  return v.toDouble();
}

double? optNum(Map<String, dynamic> j, String key, String where) {
  final v = j[key];
  if (v == null) return null;
  if (v is! num) fail(where, '"$key" は数値が必要です');
  return v.toDouble();
}

List<Map<String, dynamic>> reqObjectList(
  Map<String, dynamic> j,
  String key,
  String where,
) {
  final v = j[key];
  if (v is! List || v.isEmpty) fail(where, '"$key" は空でない配列が必要です');
  return [
    for (final e in v)
      if (e is Map<String, dynamic>)
        e
      else
        fail(where, '"$key" の要素はオブジェクトが必要です'),
  ];
}
