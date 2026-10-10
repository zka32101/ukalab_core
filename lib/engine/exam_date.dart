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

/// [examDate] までの残り日数（日付のみで計算。当日なら0、過去なら負の値）。
int daysUntilExam(DateTime examDate, DateTime now) {
  final today = DateTime.utc(now.year, now.month, now.day);
  final target = DateTime.utc(examDate.year, examDate.month, examDate.day);
  return target.difference(today).inDays;
}

/// 残り日数からホームに表示する文言を組み立てる。
String examCountdownText(int daysLeft) {
  if (daysLeft > 0) return '本番まであと$daysLeft日';
  if (daysLeft == 0) return '本番は今日です';
  return '本番から${-daysLeft}日経過しました';
}

/// 試験までの残り日数から、1日あたりの目安解答数を逆算する。
/// [daysLeft] が0以下（当日・試験日未設定・過去）なら null（計画を示せない）。
/// [remainingQuestions] が0以下なら0（すべて解答済み）。
int? studyPlanQuestionsPerDay({required int daysLeft, required int remainingQuestions}) {
  if (daysLeft <= 0) return null;
  if (remainingQuestions <= 0) return 0;
  return (remainingQuestions / daysLeft).ceil();
}
