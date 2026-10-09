import 'package:test/test.dart';
import 'package:ukalab_core/ukalab_core.dart';

Question _q(String qid) => Question.fromJson({
      'qid': qid,
      'examId': 'sample',
      'subjectId': 'math',
      'topicId': 'ch1',
      'prompt': '問題',
      'choices': ['a', 'b'],
      'answerIndex': 0,
      'explanation': '解説',
      'source': 'original',
      'sourceRef': '自作',
      'contentVer': '1',
    });

void main() {
  final at = DateTime(2026, 10, 9, 12);

  test('historyRecordFor は問題の科目・章を写す', () {
    final r = historyRecordFor(_q('q1'), correct: false, ms: 1200, at: at);
    expect(r.qid, 'q1');
    expect(r.subjectId, 'math');
    expect(r.topicId, 'ch1');
    expect(r.correct, isFalse);
    expect(r.ms, 1200);
    expect(r.at, at);
  });

  test('appendHistory は末尾に足し、上限を超えた分は古いものから捨てる', () {
    var log = <ProgressRecord>[];
    for (var i = 0; i < 5; i++) {
      log = appendHistory(log, historyRecordFor(_q('q$i'), correct: true, at: at), max: 3);
    }
    expect([for (final r in log) r.qid], ['q2', 'q3', 'q4']);
  });

  test('appendHistory は元のリストを変えない', () {
    final base = [historyRecordFor(_q('q1'), correct: true, at: at)];
    appendHistory(base, historyRecordFor(_q('q2'), correct: true, at: at));
    expect(base, hasLength(1));
  });

  test('encodeHistory と decodeHistory は往復できる', () {
    final log = [
      historyRecordFor(_q('q1'), correct: true, at: at),
      historyRecordFor(_q('q2'), correct: false, ms: 900, at: at),
    ];
    final back = decodeHistory(encodeHistory(log));
    expect([for (final r in back) r.qid], ['q1', 'q2']);
    expect(back[1].correct, isFalse);
    expect(back[1].ms, 900);
  });

  test('decodeHistory は null・壊れたデータで空を返す', () {
    expect(decodeHistory(null), isEmpty);
    expect(decodeHistory('{壊れた'), isEmpty);
    expect(decodeHistory('{"a":1}'), isEmpty);
  });

  test('historyCsv は日ごと・分野ごとを連結する', () {
    final csv = historyCsv([historyRecordFor(_q('q1'), correct: true, at: at)], [_q('q1')]);
    expect(csv, contains('\n'));
    expect(csv, contains('2026-10-09'));
  });

  test('effectiveExamDates は利用者の日付を優先し、日付のみにする', () {
    final defined = [DateTime(2026, 12, 1)];
    expect(effectiveExamDates(null, defined), defined);
    expect(effectiveExamDates(DateTime(2026, 11, 22, 15, 30), defined), [DateTime(2026, 11, 22)]);
  });

  test('受験日の保存形式は往復でき、壊れた値は null', () {
    expect(decodeExamDate(encodeExamDate(DateTime(2026, 11, 22, 9))), DateTime(2026, 11, 22));
    expect(decodeExamDate(null), isNull);
    expect(decodeExamDate('x'), isNull);
  });
}
