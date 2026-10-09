import '../question/question.dart';
import 'progress_record.dart';

// 学習履歴の書き出し（CSV）。個人情報は含めない。
//
// 含める項目: 日付ごとの学習時間（回答時間の合計）・解答数・正答率、
// 分野（章）ごとの解答数・正答率。氏名・ユーザーID・端末情報・問題文は含めない。
// ファイルへの保存・共有の画面はアプリ側が持つ。

/// 日付ごとの学習のまとめ。
class DailyStudySummary {
  const DailyStudySummary({
    required this.date,
    required this.answered,
    required this.correct,
    required this.seconds,
  });

  /// 日付（時刻は 0 時）。
  final DateTime date;
  final int answered;
  final int correct;

  /// 回答時間の合計（秒）。回答時間が無い記録は 0 秒として数える。
  final int seconds;

  double get accuracy => answered == 0 ? 0 : correct / answered;
}

/// 分野（章）ごとの正答のまとめ。
class TopicAccuracy {
  const TopicAccuracy({
    required this.topicId,
    required this.answered,
    required this.correct,
  });

  final String topicId;
  final int answered;
  final int correct;

  double get accuracy => answered == 0 ? 0 : correct / answered;
}

/// 解答記録を日付ごとにまとめる。古い日付から順。
List<DailyStudySummary> summarizeByDay(List<ProgressRecord> records) {
  final answered = <DateTime, int>{};
  final correct = <DateTime, int>{};
  final ms = <DateTime, int>{};
  for (final r in records) {
    final day = DateTime(r.at.year, r.at.month, r.at.day);
    answered[day] = (answered[day] ?? 0) + 1;
    if (r.correct) correct[day] = (correct[day] ?? 0) + 1;
    ms[day] = (ms[day] ?? 0) + (r.ms ?? 0);
  }
  final days = answered.keys.toList()..sort();
  return [
    for (final day in days)
      DailyStudySummary(
        date: day,
        answered: answered[day]!,
        correct: correct[day] ?? 0,
        seconds: ((ms[day] ?? 0) / 1000).round(),
      ),
  ];
}

/// 解答記録を分野（章）ごとにまとめる。解答数の多い順（同数は章ID順）。
/// 記録に章が無い旧データは [questions] から補い、補えなければ数えない。
List<TopicAccuracy> summarizeByTopic(
  List<ProgressRecord> records, {
  List<Question> questions = const [],
}) {
  final topicOf = {for (final q in questions) q.qid: q.topicId};
  final answered = <String, int>{};
  final correct = <String, int>{};
  for (final r in records) {
    final topic = r.topicId ?? topicOf[r.qid];
    if (topic == null) continue;
    answered[topic] = (answered[topic] ?? 0) + 1;
    if (r.correct) correct[topic] = (correct[topic] ?? 0) + 1;
  }
  final topics = answered.keys.toList()
    ..sort((a, b) {
      final byCount = answered[b]!.compareTo(answered[a]!);
      return byCount != 0 ? byCount : a.compareTo(b);
    });
  return [
    for (final t in topics)
      TopicAccuracy(topicId: t, answered: answered[t]!, correct: correct[t] ?? 0),
  ];
}

String _csvField(String value) {
  if (value.contains(',') || value.contains('"') || value.contains('\n') || value.contains('\r')) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}

String _percent(double ratio) => (ratio * 100).toStringAsFixed(1);

String _twoDigits(int n) => n.toString().padLeft(2, '0');

/// 日付ごとの学習のまとめを CSV にする（ヘッダー付き、改行は `\n`）。
/// 列: 日付(YYYY-MM-DD)・解答数・正答数・正答率(%)・学習時間(分)。
String dailySummaryCsv(List<DailyStudySummary> days) {
  final lines = ['日付,解答数,正答数,正答率(%),学習時間(分)'];
  for (final d in days) {
    final date = '${d.date.year}-${_twoDigits(d.date.month)}-${_twoDigits(d.date.day)}';
    lines.add([
      date,
      '${d.answered}',
      '${d.correct}',
      _percent(d.accuracy),
      (d.seconds / 60).toStringAsFixed(1),
    ].map(_csvField).join(','));
  }
  return '${lines.join('\n')}\n';
}

/// 分野（章）ごとの正答のまとめを CSV にする（ヘッダー付き）。
/// 列: 分野(章ID)・解答数・正答数・正答率(%)。
String topicAccuracyCsv(List<TopicAccuracy> topics) {
  final lines = ['分野,解答数,正答数,正答率(%)'];
  for (final t in topics) {
    lines.add([
      t.topicId,
      '${t.answered}',
      '${t.correct}',
      _percent(t.accuracy),
    ].map(_csvField).join(','));
  }
  return '${lines.join('\n')}\n';
}
