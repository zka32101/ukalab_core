import 'package:flutter_test/flutter_test.dart';
import 'package:ukalab_core/ukalab_core.dart';

UpdateLogEntry entry(
  String id, {
  String examId = 'otsu4',
  DateTime? date,
  UpdateKind kind = UpdateKind.correction,
  String title = '訂正',
  int affected = 1,
  String? versionRef,
}) =>
    UpdateLogEntry(
      entryId: id,
      examId: examId,
      date: date ?? DateTime(2026, 10, 1),
      kind: kind,
      title: title,
      affectedQuestions: affected,
      versionRef: versionRef,
    );

void main() {
  final now = DateTime(2026, 10, 9);

  group('更新ログ', () {
    test('JSON を読み書きできる', () {
      final e = entry('u1', kind: UpdateKind.lawChange, versionRef: '政令2026-04', affected: 5);

      expect(UpdateLogEntry.fromJson(e.toJson()).kind, UpdateKind.lawChange);
      expect(UpdateLogEntry.fromJson(e.toJson()).affectedQuestions, 5);
      expect(UpdateLogEntry.fromJson(e.toJson()).versionRef, '政令2026-04');
    });

    test('recentUpdates: 新しい順。未来の予定と古い更新は含めない', () {
      final list = recentUpdates(
        [
          entry('old', date: DateTime(2026, 1, 1)),
          entry('a', date: DateTime(2026, 9, 1)),
          entry('b', date: DateTime(2026, 10, 5)),
          entry('future', date: DateTime(2026, 11, 1)),
        ],
        now,
      );

      expect(list.map((e) => e.entryId), ['b', 'a']);
    });

    test('recentUpdates: examId で絞る', () {
      final list = recentUpdates(
        [entry('a', examId: 'otsu4'), entry('b', examId: 'boki')],
        now,
        examId: 'boki',
      );

      expect(list.map((e) => e.entryId), ['b']);
    });

    test('読み込み: 不正な行は issues に入れて続行する', () {
      final parsed = parseUpdateLogJsonl(
        '{"entryId":"u1","examId":"otsu4","date":"2026-10-01","kind":"correction","title":"訂正"}\n'
        '{"entryId":"u2","examId":"otsu4","date":"2026-10-01","kind":"unknown","title":"x"}\n'
        'not json\n',
      );

      expect(parsed.entries.map((e) => e.entryId), ['u1']);
      expect(parsed.issues.length, 2);
    });

    test('検証: 重複・空の見出し・負の件数・法改正の版の欠落', () {
      final issues = validateUpdateLog([
        entry('u1'),
        entry('u1'),
        entry('u2', title: ' '),
        entry('u3', affected: -1),
        entry('u4', kind: UpdateKind.lawChange),
        entry('u5', kind: UpdateKind.syllabusChange, versionRef: ' '),
        entry('u6', kind: UpdateKind.lawChange, versionRef: '政令2026-04'),
      ]);

      expect(
        issues.map((i) => '${i.qid}:${i.code}'),
        ['u1:duplicate-id', 'u2:empty-title', 'u3:negative-count', 'u4:no-version-ref', 'u5:no-version-ref'],
      );
    });
  });

  group('合格後の次の一手', () {
    const rules = [
      NextStepRule(fromExamId: 'boki3', toExamId: 'boki2', reason: '2級へ'),
      NextStepRule(fromExamId: 'boki3', toExamId: 'fp3', reason: 'FPへ'),
      NextStepRule(fromExamId: 'boki3', toExamId: 'boki2', reason: '重複'),
      NextStepRule(fromExamId: 'otsu4', toExamId: 'fire', reason: '消防設備士へ'),
    ];

    test('公開済みの資格だけを、対応表の順に提案する', () {
      final steps = suggestNextSteps('boki3', rules, {'boki2', 'otsu4'});

      expect(steps.map((r) => r.toExamId), ['boki2']);
    });

    test('提案先は1回だけ。自分自身は提案しない', () {
      final steps = suggestNextSteps(
        'boki3',
        [...rules, const NextStepRule(fromExamId: 'boki3', toExamId: 'boki3', reason: '自分')],
        {'boki2', 'fp3', 'boki3'},
      );

      expect(steps.map((r) => r.toExamId), ['boki2', 'fp3']);
    });

    test('公開済みの資格が無ければ空', () {
      expect(suggestNextSteps('boki3', rules, const {}), isEmpty);
    });

    test('検証: 自分自身・重複・空の理由・未定義の試験ID', () {
      final issues = validateNextSteps(
        [
          const NextStepRule(fromExamId: 'a', toExamId: 'a', reason: 'x'),
          const NextStepRule(fromExamId: 'a', toExamId: 'b', reason: 'x'),
          const NextStepRule(fromExamId: 'a', toExamId: 'b', reason: 'x'),
          const NextStepRule(fromExamId: 'a', toExamId: 'c', reason: ' '),
          const NextStepRule(fromExamId: 'a', toExamId: 'zz', reason: 'x'),
        ],
        knownExamIds: {'a', 'b', 'c'},
      );

      expect(
        issues.map((i) => i.code),
        ['self-reference', 'duplicate-rule', 'empty-reason', 'unknown-exam'],
      );
    });

    test('読み込み: JSON Lines', () {
      final parsed = parseNextStepsJsonl(
        '{"fromExamId":"boki3","toExamId":"boki2","reason":"2級へ"}\n{"fromExamId":"x"}\n',
      );

      expect(parsed.rules.length, 1);
      expect(parsed.issues.length, 1);
    });
  });

  group('試験当日チェックリスト', () {
    ChecklistItem item(
      String id, {
      ChecklistCategory category = ChecklistCategory.belongings,
      ExamVenueKind? venue,
      bool confirmed = false,
      String examId = 'otsu4',
    }) =>
        ChecklistItem(
          itemId: id,
          examId: examId,
          category: category,
          label: id,
          venue: venue,
          officialConfirmed: confirmed,
        );

    test('JSON を読み書きできる', () {
      final i = ChecklistItem(
        itemId: 'c1',
        examId: 'otsu4',
        category: ChecklistCategory.admission,
        label: '受験票',
        venue: ExamVenueKind.venue,
        officialConfirmed: true,
        note: '印刷しておく',
      );

      final restored = ChecklistItem.fromJson(i.toJson());

      expect(restored.category, ChecklistCategory.admission);
      expect(restored.venue, ExamVenueKind.venue);
      expect(restored.officialConfirmed, isTrue);
      expect(restored.note, '印刷しておく');
    });

    test('checklistFor: 試験と受験形式で絞り、分類の順 → 登録順に並べる', () {
      final items = [
        item('env', category: ChecklistCategory.environment, venue: ExamVenueKind.online),
        item('pen'),
        item('ticket', category: ChecklistCategory.admission),
        item('route', category: ChecklistCategory.travel, venue: ExamVenueKind.venue),
        item('other-exam', examId: 'boki'),
        item('pencil'),
      ];

      expect(
        checklistFor('otsu4', items, venue: ExamVenueKind.venue).map((i) => i.itemId),
        ['pen', 'pencil', 'route', 'ticket'],
      );
      expect(
        checklistFor('otsu4', items, venue: ExamVenueKind.online).map((i) => i.itemId),
        ['pen', 'pencil', 'ticket', 'env'],
      );
      expect(checklistFor('otsu4', items).length, 5);
    });

    test('unconfirmedItems: 公式で未確認の項目', () {
      final items = [item('a', confirmed: true), item('b')];

      expect(unconfirmedItems(items).map((i) => i.itemId), ['b']);
    });

    test('ChecklistProgress: チェックの付け外しと完了判定', () {
      final items = [item('a'), item('b')];
      var progress = const ChecklistProgress();

      expect(progress.isComplete(items), isFalse);
      progress = progress.toggle('a');
      expect(progress.isChecked('a'), isTrue);
      expect(progress.doneCount(items), 1);
      progress = progress.toggle('b');
      expect(progress.isComplete(items), isTrue);
      progress = progress.toggle('a');
      expect(progress.isChecked('a'), isFalse);
      expect(const ChecklistProgress().isComplete(const []), isFalse);
    });

    test('検証: 重複・空のラベル・試験の不一致。未確認はエラーにしない', () {
      final issues = validateChecklistItems([
        item('a'),
        item('a'),
        const ChecklistItem(
          itemId: 'b',
          examId: 'otsu4',
          category: ChecklistCategory.travel,
          label: ' ',
        ),
        item('c', confirmed: false),
      ]);

      expect(issues.map((i) => '${i.qid}:${i.code}'), ['a:duplicate-id', 'b:empty-label']);
    });

    test('読み込み: JSON Lines', () {
      final parsed = parseChecklistItemsJsonl(
        '{"itemId":"c1","examId":"otsu4","category":"belongings","label":"筆記用具"}\n'
        '{"itemId":"c2","examId":"otsu4","category":"bad","label":"x"}\n',
      );

      expect(parsed.items.map((i) => i.itemId), ['c1']);
      expect(parsed.issues.length, 1);
    });
  });
}
