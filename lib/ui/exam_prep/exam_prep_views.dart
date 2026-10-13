import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../engine/exam_date.dart';
import '../../engine/exam_eve.dart';
import '../../engine/time_boxed_plan.dart';
import '../../experience/exam_day_checklist.dart';
import '../../experience/update_log.dart';
import '../../progress/history_export.dart';
import '../../progress/progress_record.dart';
import '../../question/question.dart';
import 'exam_prep_strings.dart';

/// 一般の当日チェック項目の itemId（文言は `ExamPrepStrings.defaultChecklistLabels`）。
const List<String> defaultChecklistIds = [
  'default-ticket',
  'default-id',
  'default-belongings',
  'default-allowed',
  'default-route',
  'default-margin',
  'default-net',
];

/// どの試験にも使える一般の当日チェックリスト。どの項目も `officialConfirmed: false` なので、
/// 画面には「公式で要確認」が付く。試験固有の項目を使うアプリは、`ExamDayChecklistView.items`
/// に自前のリストを渡して上書きする。
///
/// [venue] が `venue` なら会場受験の項目（通信環境を除く）、`online` なら通信環境を含み移動の項目を除く。
List<ChecklistItem> defaultExamDayChecklist({
  required String examId,
  ExamPrepStrings strings = ExamPrepStrings.ja,
  ExamVenueKind? venue = ExamVenueKind.venue,
}) {
  ChecklistItem item(String id, ChecklistCategory c, {ExamVenueKind? venue}) =>
      ChecklistItem(
        itemId: id,
        examId: examId,
        category: c,
        label: strings.defaultChecklistLabels[id] ?? id,
        venue: venue,
      );
  return checklistFor(examId, [
    item('default-ticket', ChecklistCategory.admission),
    item('default-id', ChecklistCategory.admission),
    item('default-belongings', ChecklistCategory.belongings),
    item('default-allowed', ChecklistCategory.belongings),
    item('default-route', ChecklistCategory.travel, venue: ExamVenueKind.venue),
    item(
      'default-margin',
      ChecklistCategory.travel,
      venue: ExamVenueKind.venue,
    ),
    item(
      'default-net',
      ChecklistCategory.environment,
      venue: ExamVenueKind.online,
    ),
  ], venue: venue);
}

void _showPremiumNote(BuildContext context, ExamPrepStrings s) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(s.premiumNote)));
}

/// ホームの「試験に向けて」カード。10分プラン・試験直前モード・当日チェックリストへの入口。
///
/// アプリ非依存: 問題・履歴・試験日・premium 判定・練習画面の起動は、すべて引数で受ける。
/// 試験直前モードの行は、[examDate] が試験直前の期間内のときだけ出る。
/// チェックリストの行は、[examDate] があり [onOpenChecklist] が渡されたときだけ出る。
class ExamPrepCard extends StatelessWidget {
  const ExamPrepCard({
    super.key,
    required this.questions,
    required this.records,
    required this.examDate,
    required this.onStartPractice,
    this.tenMinUnlocked = true,
    this.examEveUnlocked = true,
    this.onOpenChecklist,
    this.onLockedTap,
    this.clock = DateTime.now,
    this.strings,
  });

  /// 全問題を返す（タップ時に呼ぶ）。
  final List<Question> Function() questions;

  /// 解答履歴を返す（タップ時に呼ぶ）。
  final List<ProgressRecord> Function() records;

  /// 利用者が設定した試験日。未設定は null。
  final DateTime? examDate;

  /// 練習画面を開く。[pool] が空のときは [emptyMessage] を出す想定。
  final void Function(
    BuildContext context,
    String title,
    List<Question> pool,
    String emptyMessage,
  )
  onStartPractice;

  /// 10分プランを使えるか（premium 判定は呼び出し側）。
  final bool tenMinUnlocked;

  /// 試験直前モードを使えるか（premium 判定は呼び出し側）。
  final bool examEveUnlocked;

  /// 当日チェックリストを開く。
  final void Function(BuildContext context)? onOpenChecklist;

  /// 使えない機能をタップしたとき。null なら「プレミアムで使えます」のスナックバー。
  final void Function(BuildContext context)? onLockedTap;

  final DateTime Function() clock;
  final ExamPrepStrings? strings;

  @override
  Widget build(BuildContext context) {
    final s = strings ?? ExamPrepStrings.of(context);
    final now = clock();
    final date = examDate;
    final eve = date == null ? null : examEveStatus([date], now);
    final theme = Theme.of(context);

    void locked() => (onLockedTap ?? (c) => _showPremiumNote(c, s))(context);

    void tenMin() {
      if (!tenMinUnlocked) return locked();
      final qs = questions();
      final recs = records();
      final firstQids = (eve != null && eve.active)
          ? [
              for (final i in buildExamEveSet(qs, recs, now: now))
                i.question.qid,
            ]
          : const <String>[];
      final plan = buildTimeBoxedPlan(qs, recs, now: now, firstQids: firstQids);
      onStartPractice(context, s.tenMinTitle, plan.questions, s.emptyPlan);
    }

    void eveMode() {
      if (!examEveUnlocked) return locked();
      final items = buildExamEveSet(questions(), records(), now: now);
      onStartPractice(context, s.examEveTitle, [
        for (final i in items) i.question,
      ], s.emptyEve);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(s.sectionTitle, style: theme.textTheme.titleSmall),
            ),
            ListTile(
              key: const ValueKey('tenMinPlanTile'),
              leading: const Icon(Icons.timer_outlined),
              title: Text(s.tenMinTitle),
              subtitle: Text(tenMinUnlocked ? s.tenMinSubtitle : s.premiumNote),
              trailing: const Icon(Icons.chevron_right),
              onTap: tenMin,
            ),
            if (eve != null && eve.active)
              ListTile(
                key: const ValueKey('examEveTile'),
                leading: const Icon(Icons.event_available_outlined),
                title: Text(s.eveDays(eve.daysLeft)),
                subtitle: Text(
                  examEveUnlocked ? s.examEveSubtitle : s.premiumNote,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: eveMode,
              ),
            if (date != null && onOpenChecklist != null)
              ListTile(
                key: const ValueKey('checklistTile'),
                leading: const Icon(Icons.checklist_outlined),
                title: Text(s.checklistTitle),
                subtitle: Text(s.countdown(daysUntilExam(date, now))),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => onOpenChecklist!(context),
              ),
          ],
        ),
      ),
    );
  }
}

/// 試験当日チェックリスト。チェック状態の保存はアプリ側（[onChanged] で受けて保存し、
/// 次回は [initialProgress] に渡す）。
///
/// [items] が null なら [defaultExamDayChecklist]（一般項目。すべて「公式で要確認」）。
/// 試験固有の項目があるアプリは [items] で上書きする。
class ExamDayChecklistView extends StatefulWidget {
  const ExamDayChecklistView({
    super.key,
    required this.examId,
    this.items,
    this.venue = ExamVenueKind.venue,
    this.initialProgress = const ChecklistProgress(),
    this.onChanged,
    this.strings,
  });

  final String examId;

  /// 項目の上書き。null なら一般項目。
  final List<ChecklistItem>? items;

  /// 一般項目を使うときの受験形式。
  final ExamVenueKind venue;

  /// 保存済みのチェック状態。
  final ChecklistProgress initialProgress;

  /// チェックを付け外ししたときに、新しい状態を渡す（保存はアプリ側）。
  final ValueChanged<ChecklistProgress>? onChanged;

  final ExamPrepStrings? strings;

  @override
  State<ExamDayChecklistView> createState() => _ExamDayChecklistViewState();
}

class _ExamDayChecklistViewState extends State<ExamDayChecklistView> {
  late ChecklistProgress _progress = widget.initialProgress;

  void _toggle(String itemId) {
    setState(() => _progress = _progress.toggle(itemId));
    widget.onChanged?.call(_progress);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings ?? ExamPrepStrings.of(context);
    final theme = Theme.of(context);
    final items =
        widget.items ??
        defaultExamDayChecklist(
          examId: widget.examId,
          strings: s,
          venue: widget.venue,
        );
    final done = _progress.doneCount(items);
    ChecklistCategory? last;
    return Scaffold(
      appBar: AppBar(title: Text(s.checklistTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            s.progress(done, items.length),
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: items.isEmpty ? 0 : done / items.length,
          ),
          const SizedBox(height: 8),
          Text(s.checklistNote, style: theme.textTheme.bodySmall),
          if (_progress.isComplete(items)) ...[
            const SizedBox(height: 8),
            Text(s.checklistDone, style: theme.textTheme.bodyMedium),
          ],
          for (final item in items) ...[
            if (item.category != last)
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 4),
                child: Text(
                  s.category(last = item.category),
                  style: theme.textTheme.labelLarge,
                ),
              ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _progress.isChecked(item.itemId),
              onChanged: (_) => _toggle(item.itemId),
              title: Text(item.label),
              subtitle: item.officialConfirmed
                  ? null
                  : Text(
                      item.note == null
                          ? s.confirmNeeded
                          : '${s.confirmNeeded}: ${item.note}',
                    ),
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ],
        ],
      ),
    );
  }
}

/// 更新ログ。[entriesFuture] は新しい順に並べたもの（`recentUpdates` の結果など）。
class UpdateLogView extends StatelessWidget {
  const UpdateLogView({super.key, required this.entriesFuture, this.strings});

  final Future<List<UpdateLogEntry>> entriesFuture;
  final ExamPrepStrings? strings;

  static String _date(DateTime d) =>
      '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final s = strings ?? ExamPrepStrings.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.updateLogTitle)),
      body: FutureBuilder<List<UpdateLogEntry>>(
        future: entriesFuture,
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text(s.updateLogEmpty));
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final entries = snap.data!;
          if (entries.isEmpty) return Center(child: Text(s.updateLogEmpty));
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final e in entries)
                Card(
                  child: ListTile(
                    title: Text(e.title),
                    subtitle: Text(
                      [
                        [
                          '${_date(e.date)} ・ ${s.updateKind(e.kind)}',
                          if (e.affectedQuestions > 0)
                            s.affected(e.affectedQuestions),
                          if (e.versionRef != null) e.versionRef!,
                        ].join(' ・ '),
                        if (e.detail != null) e.detail!,
                      ].join('\n'),
                    ),
                    isThreeLine: e.detail != null,
                    titleTextStyle: theme.textTheme.titleSmall,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// 学習データのCSV書き出し。保存・共有のプラグインは足さず、表示とコピーで渡す。
/// 氏名・ID・端末情報・問題文は含まない（`historyCsvText`）。
class HistoryExportView extends StatelessWidget {
  const HistoryExportView({
    super.key,
    required this.records,
    required this.questions,
    this.strings,
  });

  final List<ProgressRecord> records;

  /// 分野の集計に使う問題データ。
  final List<Question> questions;
  final ExamPrepStrings? strings;

  @override
  Widget build(BuildContext context) {
    final s = strings ?? ExamPrepStrings.of(context);
    final csv = historyCsvText(records, questions);
    return Scaffold(
      appBar: AppBar(title: Text(s.exportTitle)),
      body: records.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(s.exportEmpty),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  s.exportNote,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  key: const ValueKey('copyCsv'),
                  icon: const Icon(Icons.copy),
                  label: Text(s.exportCopy),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: csv));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(s.exportCopied)));
                  },
                ),
                const SizedBox(height: 12),
                SelectableText(
                  csv,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ],
            ),
    );
  }
}

/// 設定タブに置く、更新ログ・学習データ書き出しの入口。画面の起動はアプリ側。
class ExamPrepSettingsTiles extends StatelessWidget {
  const ExamPrepSettingsTiles({
    super.key,
    required this.onOpenUpdateLog,
    required this.onOpenExport,
    this.exportUnlocked = true,
    this.onLockedTap,
    this.strings,
  });

  final void Function(BuildContext context) onOpenUpdateLog;
  final void Function(BuildContext context) onOpenExport;

  /// 書き出しを使えるか（premium 判定は呼び出し側）。
  final bool exportUnlocked;

  /// 使えない機能をタップしたとき。null なら「プレミアムで使えます」のスナックバー。
  final void Function(BuildContext context)? onLockedTap;
  final ExamPrepStrings? strings;

  @override
  Widget build(BuildContext context) {
    final s = strings ?? ExamPrepStrings.of(context);
    return Card(
      child: Column(
        children: [
          ListTile(
            key: const ValueKey('updateLogTile'),
            leading: const Icon(Icons.history_toggle_off_outlined),
            title: Text(s.updateLogTitle),
            subtitle: Text(s.updateLogSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => onOpenUpdateLog(context),
          ),
          ListTile(
            key: const ValueKey('exportTile'),
            leading: const Icon(Icons.file_download_outlined),
            title: Text(s.exportTitle),
            subtitle: Text(exportUnlocked ? s.exportSubtitle : s.premiumNote),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => exportUnlocked
                ? onOpenExport(context)
                : (onLockedTap ?? (c) => _showPremiumNote(c, s))(context),
          ),
        ],
      ),
    );
  }
}
