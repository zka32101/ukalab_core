DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// 試験直前モードなどに使う受験日の候補。利用者が入力した日付があればそれだけ、
/// 無ければ試験定義の日付。
List<DateTime> effectiveExamDates(DateTime? userDate, List<DateTime> defined) =>
    userDate != null ? [_dateOnly(userDate)] : defined;

/// 受験日を保存用の文字列（日付のみ）にする。
String encodeExamDate(DateTime date) => _dateOnly(date).toIso8601String();

/// 保存された文字列から受験日を復元する。null・壊れた値は null。
DateTime? decodeExamDate(String? raw) {
  if (raw == null) return null;
  final parsed = DateTime.tryParse(raw);
  return parsed == null ? null : _dateOnly(parsed);
}
