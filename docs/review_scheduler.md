# 今日の復習（`ReviewSchedulerEngine` / `TodayReviewCard`、v0.68.0）

間違いノートの問題を、忘れる頃に「今日の復習」として出す。たまっても大丈夫という調子で、件数や期限超過で圧をかけない（赤字・警告色なし）。出題画面は持たず、各アプリの既存クイズにコールバックで接続する。

### 既存の復習との関係（重複しない使い分け）

- `Srs`（`lib/engine/srs.dart`）: 全問題の履歴向けの Leitner 方式。不正解は箱0（すぐ再出題）。`PracticeSession.priorityQids` に渡す用途
- `ReviewSchedulerEngine`（本節）: 間違いノートの「これから」だけが対象。間隔は 1/3/7/14/30 日、不正解は1段戻る（すぐ再出題しない）。入力は `MistakeNoteEntry`
- 漢検など、アプリ側にすでに「復習（間隔反復）」がある場合は無理に置き換えない。そのアプリでは `TodayReviewCard` を件数表示の入口として使い、`onStart` で既存の復習画面を開く（件数はアプリ側の `dueCount` を渡してよい）。`ReviewSchedulerEngine` を使わなくても `TodayReviewCard` 単体で使える

### 使い方

```dart
const engine = ReviewSchedulerEngine(); // intervals: [1, 3, 7, 14, 30]（暫定。引数で変えられる）
final noteStore = SharedPreferencesMistakeNoteStore('myapp');
final reviewStore = SharedPreferencesReviewSchedulerStore('myapp'); // キー ukalab_myapp_review_schedule

// ホームを開くとき: 間違いノートから復習予定を同期（冪等）
final items = engine.sync(await reviewStore.read(), await noteStore.read());
await reviewStore.write(items);
final now = DateTime.now();

TodayReviewCard(
  dueCount: engine.dueCount(items, now),
  onStart: () {
    final todays = engine.due(items, now, max: 5); // 今日の期限分を最大5問
    openQuiz(qids: [for (final i in todays) i.qid]); // 各アプリの既存クイズへ
  },
)

// 復習の1問ごとの結果を反映
final updated = engine.applyResult(items, qid, correct: ok, now: DateTime.now());
await reviewStore.write(updated);
// 同じ解答は通常の履歴にも記録し、MistakeNoteEngine.update で「克服」も更新する
```

- 新しく載った問題は、間違えた翌日の 0 時から出る。正解で 3 → 7 → 14 → 30 日と進み、最後の段の正解で卒業（以後は出ない）。不正解は1段戻る
- 間違いノートで「克服」になった問題・ノートから消えた問題は `sync` で外れる。復習より後にまた間違えたら段 0 からやり直す（卒業後も同様）
- 期限を過ぎても罰や重みづけはなく、`due` は期限の古い順→段の低い順→qid 順で最大 N 問を返すだけ
- 日付は暦日（時刻・夏時間で 1 日ずれない）。`now` を渡すのでテストで固定できる。復習の解答は履歴にも記録するので、`applyResult` の `now` には履歴の `ProgressRecord.at` と同じ時刻を渡す（復習より後の間違いと見なされて段 0 からやり直しになるのを避ける）
- 文言は `ReviewSchedulerStrings`（ja・en。`copyWith` で上書き可。`UkalabStrings` は変えない）。禁止語リストでテスト。運営での文言確認は別途必要
- バックアップ・リセットは `reviewSchedulerDataPart(store)`（キー `reviewSchedule`、いったん決めたら変えない）を `DataManagementSection(parts: ...)` に並べる
- premium で出し分けたいときは、アプリ側で `TodayReviewCard` を包む。core は制限しない
