import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ukalab_core/ui.dart';
import 'package:ukalab_core/ukalab_core.dart';

Question _q(String qid) => Question(
  qid: qid,
  examId: 'sample',
  subjectId: 'law',
  topicId: 'ch1',
  prompt: '問題$qid',
  choices: const ['A', 'B'],
  answerIndex: 0,
  explanation: '解説',
  source: QuestionSource.original,
  sourceRef: '自作',
  contentVer: '1',
);

Widget _app(Widget child, {KitStrings? kit}) {
  final body = MaterialApp(home: Scaffold(body: child));
  return kit == null ? body : KitStringsScope(strings: kit, child: body);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const ja = ExamPrepStrings.ja;

  test('更新ログの例データが読めて、検証を通り、新しい順に並ぶ', () {
    final text = File(
      'test/fixtures/exam_prep_update_log.jsonl',
    ).readAsStringSync();
    final parsed = parseUpdateLogJsonl(text);
    expect(parsed.issues, isEmpty);
    final log = recentUpdates(parsed.entries, DateTime(2026, 10, 13));
    expect(log, isNotEmpty);
    for (var i = 1; i < log.length; i++) {
      expect(log[i - 1].date.isBefore(log[i].date), isFalse);
    }
  });

  test('一般チェックリスト: 公式で要確認のまま。形式で項目が変わる', () {
    final venue = defaultExamDayChecklist(examId: 'x');
    expect(venue.length, greaterThanOrEqualTo(5));
    expect(unconfirmedItems(venue), hasLength(venue.length));
    expect(venue.any((i) => i.itemId == 'default-net'), isFalse);
    final online = defaultExamDayChecklist(
      examId: 'x',
      venue: ExamVenueKind.online,
    );
    expect(online.any((i) => i.itemId == 'default-net'), isTrue);
    expect(online.any((i) => i.itemId == 'default-route'), isFalse);
    for (final s in [
      ExamPrepStrings.ja,
      ExamPrepStrings.en,
      ExamPrepStrings.zhHans,
      ExamPrepStrings.zhHant,
      ExamPrepStrings.ko,
    ]) {
      expect(
        s.defaultChecklistLabels.keys.toSet(),
        defaultChecklistIds.toSet(),
      );
    }
  });

  test('履歴CSVに個人情報・問題IDを含めず、日別と分野別が並ぶ', () {
    final q = _q('sample-secret-id');
    final csv = historyCsvText(
      [
        ProgressRecord(
          qid: q.qid,
          subjectId: 'law',
          topicId: 'ch1',
          at: DateTime(2026, 10, 12, 9),
          correct: true,
          ms: 30000,
        ),
        ProgressRecord(
          qid: q.qid,
          subjectId: 'law',
          topicId: 'ch1',
          at: DateTime(2026, 10, 12, 10),
          correct: false,
        ),
      ],
      [q],
    );
    expect(csv, contains('日付,解答数,正答数,正答率(%),学習時間(分)'));
    expect(csv, contains('2026-10-12,2,1,50.0,0.5'));
    expect(csv, contains('分野,解答数,正答数,正答率(%)'));
    expect(csv, contains('ch1,2,1,50.0'));
    expect(csv, isNot(contains('secret')));
  });

  test('試験直前は3日前から、10分プランは時間内に収まる', () {
    final now = DateTime(2026, 10, 13);
    expect(examEveStatus([DateTime(2026, 10, 15)], now)!.active, isTrue);
    expect(examEveStatus([DateTime(2026, 11, 15)], now)!.active, isFalse);
    final qs = [for (var i = 0; i < 40; i++) _q('q$i')];
    final plan = buildTimeBoxedPlan(qs, const [], now: now);
    expect(plan.estimatedSeconds, lessThanOrEqualTo(600));
    expect(plan.questions, isNotEmpty);
  });

  testWidgets('チェックリスト: 一般項目が出て、チェックが進捗に反映され、保存先に渡る', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final saved = <ChecklistProgress>[];
    await tester.pumpWidget(
      _app(ExamDayChecklistView(examId: 'x', onChanged: saved.add)),
    );
    final total = defaultExamDayChecklist(examId: 'x').length;
    expect(find.text('0 / $total 完了'), findsOneWidget);
    expect(find.text(ja.confirmNeeded), findsNWidgets(total));
    await tester.tap(find.byType(CheckboxListTile).first);
    await tester.pump();
    expect(find.text('1 / $total 完了'), findsOneWidget);
    expect(saved, hasLength(1));
    expect(saved.single.checkedIds, hasLength(1));
  });

  testWidgets('チェックリスト: 項目を上書きでき、保存済みの状態から始まり、全完了で励ます', (tester) async {
    final items = [
      for (final id in ['a', 'b'])
        ChecklistItem(
          itemId: id,
          examId: 'x',
          category: ChecklistCategory.belongings,
          label: '項目$id',
          officialConfirmed: id == 'a',
          note: id == 'b' ? '案内を見る' : null,
        ),
    ];
    await tester.pumpWidget(
      _app(
        ExamDayChecklistView(
          examId: 'x',
          items: items,
          initialProgress: const ChecklistProgress({'a'}),
        ),
      ),
    );
    expect(find.text('項目a'), findsOneWidget);
    expect(find.text('1 / 2 完了'), findsOneWidget);
    expect(find.text('${ja.confirmNeeded}: 案内を見る'), findsOneWidget);
    expect(find.text(ja.checklistDone), findsNothing);
    await tester.tap(find.text('項目b'));
    await tester.pump();
    expect(find.text(ja.checklistDone), findsOneWidget);
  });

  testWidgets('更新ログ: 新しい順に表示、空なら穏やかな文言', (tester) async {
    await tester.pumpWidget(
      _app(
        UpdateLogView(
          entriesFuture: Future.value([
            UpdateLogEntry(
              entryId: 'a',
              examId: 'x',
              date: DateTime(2026, 10, 10),
              kind: UpdateKind.correction,
              title: '訂正しました',
              affectedQuestions: 2,
            ),
          ]),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('訂正しました'), findsOneWidget);
    expect(find.text('2026/10/10 ・ 訂正 ・ 2問'), findsOneWidget);
    await tester.pumpWidget(
      _app(UpdateLogView(entriesFuture: Future.value([]))),
    );
    await tester.pump();
    expect(find.text(ja.updateLogEmpty), findsOneWidget);
  });

  testWidgets('書き出し: 空なら案内、あればCSVを表示しファイルとして保存できる', (tester) async {
    Uint8List? savedBytes;
    String? savedName;
    String? savedMime;
    Future<bool> saver({
      required Uint8List bytes,
      required String fileName,
      required String mimeType,
      Rect? sharePositionOrigin,
    }) async {
      savedBytes = bytes;
      savedName = fileName;
      savedMime = mimeType;
      return true;
    }

    await tester.pumpWidget(
      _app(const HistoryExportView(records: [], questions: [])),
    );
    expect(find.text(ja.exportEmpty), findsOneWidget);
    expect(find.byKey(const ValueKey('downloadCsv')), findsNothing);

    await tester.pumpWidget(
      _app(
        HistoryExportView(
          records: [
            ProgressRecord(
              qid: 'q1',
              subjectId: 'law',
              topicId: 'ch1',
              at: DateTime(2026, 10, 12, 9),
              correct: true,
            ),
          ],
          questions: [_q('q1')],
          saver: saver,
          now: () => DateTime(2026, 10, 20, 8),
        ),
      ),
    );
    expect(find.textContaining('2026-10-12,1,1,100.0'), findsOneWidget);
    expect(find.byKey(const ValueKey('copyCsv')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('downloadCsv')));
    await tester.pump();
    expect(savedName, 'ukalab_history_20261020.csv');
    expect(savedMime, 'text/csv');
    expect(savedBytes!.sublist(0, 3), [0xEF, 0xBB, 0xBF]);
    expect(utf8.decode(savedBytes!.sublist(3)), contains('2026-10-12,1,1,100.0'));
    expect(find.text(ja.exportSaved), findsOneWidget);
  });

  testWidgets('書き出し: 保存に失敗したら案内を出す', (tester) async {
    await tester.pumpWidget(
      _app(
        HistoryExportView(
          records: [
            ProgressRecord(
              qid: 'q1',
              subjectId: 'law',
              topicId: 'ch1',
              at: DateTime(2026, 10, 12, 9),
              correct: true,
            ),
          ],
          questions: [_q('q1')],
          saver:
              ({
                required Uint8List bytes,
                required String fileName,
                required String mimeType,
                Rect? sharePositionOrigin,
              }) async => throw Exception('x'),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('downloadCsv')));
    await tester.pump();
    expect(find.text(ja.exportSaveFailed), findsOneWidget);
  });

  group('ExamPrepCard', () {
    final now = DateTime(2026, 10, 13);
    final qs = [for (var i = 0; i < 10; i++) _q('q$i')];

    Widget card({
      DateTime? exam,
      bool tenMin = true,
      bool eve = true,
      void Function(BuildContext, String, List<Question>, String)? start,
      bool withChecklist = true,
      void Function(BuildContext)? onLocked,
    }) => _app(
      ExamPrepCard(
        questions: () => qs,
        records: () => const [],
        examDate: exam,
        clock: () => now,
        tenMinUnlocked: tenMin,
        examEveUnlocked: eve,
        onStartPractice: start ?? (c, t, p, e) {},
        onOpenChecklist: withChecklist ? (c) {} : null,
        onLockedTap: onLocked,
      ),
    );

    testWidgets('試験日が遠いと直前モードは出ず、近いと出る', (tester) async {
      await tester.pumpWidget(card());
      expect(find.byKey(const ValueKey('tenMinPlanTile')), findsOneWidget);
      expect(find.byKey(const ValueKey('examEveTile')), findsNothing);
      expect(find.byKey(const ValueKey('checklistTile')), findsNothing);

      await tester.pumpWidget(card(exam: DateTime(2026, 11, 20)));
      expect(find.byKey(const ValueKey('examEveTile')), findsNothing);
      expect(find.byKey(const ValueKey('checklistTile')), findsOneWidget);

      await tester.pumpWidget(card(exam: DateTime(2026, 10, 15)));
      expect(find.byKey(const ValueKey('examEveTile')), findsOneWidget);
      expect(find.text(ja.eveDays(2)), findsOneWidget);
      expect(find.text(ja.countdown(2)), findsOneWidget);
    });

    testWidgets('チェックリスト行はコールバックが無ければ出ない', (tester) async {
      await tester.pumpWidget(
        card(exam: DateTime(2026, 10, 15), withChecklist: false),
      );
      expect(find.byKey(const ValueKey('checklistTile')), findsNothing);
    });

    testWidgets('解放済みなら練習を起動し、10分に収まる問題を渡す', (tester) async {
      String? title;
      List<Question>? pool;
      await tester.pumpWidget(
        card(
          start: (c, t, p, e) {
            title = t;
            pool = p;
          },
        ),
      );
      await tester.tap(find.byKey(const ValueKey('tenMinPlanTile')));
      expect(title, ja.tenMinTitle);
      expect(pool, isNotEmpty);
    });

    testWidgets('未解放なら練習を起動せず、既定は案内のスナックバー', (tester) async {
      var started = false;
      await tester.pumpWidget(
        card(tenMin: false, start: (c, t, p, e) => started = true),
      );
      expect(find.text(ja.premiumNote), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('tenMinPlanTile')));
      await tester.pump();
      expect(started, isFalse);
      expect(find.text(ja.premiumNote), findsNWidgets(2)); // 副題とスナックバー
    });

    testWidgets('onLockedTap があればそちらを呼ぶ', (tester) async {
      var locked = 0;
      await tester.pumpWidget(card(tenMin: false, onLocked: (c) => locked++));
      await tester.tap(find.byKey(const ValueKey('tenMinPlanTile')));
      expect(locked, 1);
    });
  });

  testWidgets('設定タイル: 書き出しが未解放なら起動せず案内、解放なら起動', (tester) async {
    var log = 0, export = 0;
    Widget tiles(bool unlocked) => _app(
      ExamPrepSettingsTiles(
        onOpenUpdateLog: (c) => log++,
        onOpenExport: (c) => export++,
        exportUnlocked: unlocked,
      ),
    );
    await tester.pumpWidget(tiles(false));
    await tester.tap(find.byKey(const ValueKey('updateLogTile')));
    await tester.tap(find.byKey(const ValueKey('exportTile')));
    await tester.pump();
    expect((log, export), (1, 0));
    expect(find.text(ja.premiumNote), findsNWidgets(2));
    await tester.pumpWidget(tiles(true));
    await tester.tap(find.byKey(const ValueKey('exportTile')));
    expect(export, 1);
  });

  testWidgets('言語: KitStringsScope に従い、未対応は日本語', (tester) async {
    await tester.pumpWidget(
      _app(ExamDayChecklistView(examId: 'x'), kit: KitStrings.en),
    );
    expect(find.text(ExamPrepStrings.en.checklistTitle), findsOneWidget);
    expect(ExamPrepStrings.forLanguageCode('fr'), same(ExamPrepStrings.ja));
    expect(
      ExamPrepStrings.forLanguageCode('zh-Hant'),
      same(ExamPrepStrings.zhHant),
    );
  });

  test('文言に責める表現・他人比較を含めない（全言語）', () {
    const banned = {
      'ja': ['遅れ', 'サボ', 'ダメ', '他の人', '平均', 'ランキング', '順位', 'なぜ'],
      'en': [
        'behind',
        'lazy',
        'slacker',
        'other people',
        'average',
        'ranking',
        'rank ',
      ],
      'zh': ['落后', '偷懒', '别人', '平均', '排名'],
      'zh-Hant': ['落後', '偷懶', '別人', '平均', '排名'],
      'ko': ['뒤처', '게으', '다른 사람', '평균', '순위'],
    };
    for (final code in banned.keys) {
      final s = ExamPrepStrings.forLanguageCode(code);
      final texts = s.allTexts.join('\n').toLowerCase();
      for (final w in banned[code]!) {
        expect(texts.contains(w.toLowerCase()), isFalse, reason: '$code: $w');
      }
      expect(
        s.allTexts.every((t) => t.trim().isNotEmpty),
        isTrue,
        reason: code,
      );
    }
  });
}
