import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:yourwish_kentei/yourwish_kentei.dart';

final exam = ExamConfig.fromJson(
  jsonDecode(File('example/sample_exam.json').readAsStringSync())
      as Map<String, dynamic>,
);

void main() {
  final level = exam.level('basic')!;
  const planner = RoutePlanner();

  test('未着手(進捗なし)の科目は正答率0として伸びしろ最大になる', () {
    final tasks = planner.plan(exam: exam, level: level, progress: const []);
    expect(tasks, hasLength(2)); // sample_exam.json は2科目
    expect(tasks.every((t) => t.score > 0), isTrue);
  });

  test('正答率が低い科目のスコアが高い(優先度が高い)', () {
    final tasks = planner.plan(exam: exam, level: level, progress: const [
      SubjectProgress(subjectId: 'math', accuracy: 0.9),
      SubjectProgress(subjectId: 'word', accuracy: 0.2),
    ]);
    expect(tasks.first.subjectId, 'word');
  });

  test('科目別出題数配分がなければ均等重みで計算する', () {
    final tasks = planner.plan(exam: exam, level: level, progress: const [
      SubjectProgress(subjectId: 'math', accuracy: 0.5),
      SubjectProgress(subjectId: 'word', accuracy: 0.5),
    ]);
    expect(tasks[0].score, closeTo(tasks[1].score, 0.0001));
  });

  test('足切り(subjectMinPct)を下回る科目は、スコアが低くても最優先になる', () {
    // math: 正答率50%(伸びしろ小さめ) だが足切り60%未満 → 最優先
    // word: 正答率20%(伸びしろ大きい) だが足切り60%は超えている
    final tasks = planner.plan(exam: exam, level: level, progress: const [
      SubjectProgress(subjectId: 'math', accuracy: 0.5),
      SubjectProgress(subjectId: 'word', accuracy: 0.8),
    ]);
    expect(tasks.first.subjectId, 'math');
    expect(tasks.first.belowPassLine, isTrue);
  });

  test('taskCount で件数を絞れる', () {
    final tasks = planner.plan(
      exam: exam,
      level: level,
      progress: const [],
      taskCount: 1,
    );
    expect(tasks, hasLength(1));
  });

  test('科目別出題数配分がある場合、配点の重みが反映される', () {
    final weighted = ExamConfig.fromJson({
      'examId': 'w',
      'name': 'w',
      'audience': 'adult',
      'subjects': [
        {'subjectId': 'a', 'name': 'A'},
        {'subjectId': 'b', 'name': 'B'},
      ],
      'levels': [
        {
          'levelId': 'l',
          'name': 'L',
          'questionCount': 10,
          'passRule': {'totalPct': 60},
          'subjectQuestionCounts': {'a': 8, 'b': 2},
        },
      ],
    });
    final tasks = planner.plan(
      exam: weighted,
      level: weighted.level('l')!,
      progress: const [
        SubjectProgress(subjectId: 'a', accuracy: 0.5),
        SubjectProgress(subjectId: 'b', accuracy: 0.5),
      ],
    );
    // 伸びしろは同じ(0.5)だが、配点が大きい a が優先される
    expect(tasks.first.subjectId, 'a');
  });
}
