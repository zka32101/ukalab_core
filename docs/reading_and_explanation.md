# 読み物の表現拡張・解説カード・誤答→読み物導線

すべて追加のみ。引数・JSON キーを指定しなければ、従来と同じ表示・同じ JSON になる。

## 1. 読み物の節（ReadingSection）

`kind`（`text`｜`table`｜`steps`｜`figure`、省略は `text`）と、kind に応じた項目を任意で足せる。

```jsonl
{"readingId":"r1","examId":"x","subjectId":"s1","title":"章のまとめ","sections":[
  {"heading":"導入","body":"従来どおりの本文"},
  {"heading":"用語の比べ方","kind":"table","table":{"columns":["用語","意味"],"rows":[["A","説明A"],["B","説明B"]]},"body":"補足（任意）"},
  {"heading":"進め方","kind":"steps","steps":["まず確認する","次に比べる"]},
  {"heading":"全体の流れ","kind":"figure","figure":{"asset":"assets/readings/flow.png","alt":"処理の流れを表す図","caption":"図1"}}
],"source":"original","sourceRef":"自作","contentVer":"1"}
```

- `body` は kind が `text` のときだけ必須。それ以外では補足として任意。
- 表は列 6 まで・行 20 まで（`kReadingTableMaxColumns` / `kReadingTableMaxRows`）。各行のセル数は列数と同じ。
- 図の `asset` は assets 配下の相対パス（先頭 `/`・`..`・URL は不可）、`alt` は必須で 200 文字まで。画像ファイルはアプリの `pubspec.yaml` の assets に登録する。
- 未指定のキーは `toJson` に出さない。`validateChapterReadings` が上の条件を検査する（`validate_content` の既存の動きは変わらない）。

## 2. 描画: ReadingSectionContent

```dart
import 'package:ukalab_core/ui.dart';

Column(children: [
  for (final s in reading.sections) ...[
    ReadingSectionContent(section: s),
    const SizedBox(height: 20),
  ],
  ReadingQuestionLinks.forReading(
    reading: reading,
    onOpenQuestion: (qid) => openQuestion(qid), // 確認問題へ戻る
  ),
])
```

色・文字はテーマに従い（ダークモード対応）、文字拡大で折り返す。図は `alt` を読み上げ、手順は「1. …」と読み上げる。画像が読めないときは `alt` の文字を出す。

### 表の列幅・横スクロール

- 2・3列の表は従来どおり均等幅。
- 4列以上の表は、内容に合わせて列幅を決める。従来の均等幅で各列が収まるなら見た目は従来と同じ。
  短い語（8文字以下）は1行で収まる幅、長い文は全角6文字分（数字・英字の長い語があればその幅）を各列の下限にする。
  下限を満たせないが合計が画面幅に収まるときは、全幅のまま列幅を配分する。合計が画面幅を超えるときは表全体が横スクロールになる（スクロールバーを表示。読み上げ・キーボードの順序は行→列のまま）。横スクロールのときは右端にフェード＋シェブロンの手がかりを出し、右端に達したら消える（装飾で、読み上げ対象外）。
- 列数の上限は 6 のまま。

### 数字・金額の折り返し

- `300,000円` `¥1,350,000` のように数字・カンマ・通貨記号・単位が続く語（4文字以上）は、文字の間に WORD JOINER（U+2060、幅ゼロで見えない）を入れて描画し、数字の途中や数字と単位の間では折らない。折り返すのは語の前後だけ。
- 読み上げは元の文字列。JSON のデータは変更しない。表のセルと `ReadingQuestionLinks` のラベルに適用される。
- 画面に出す `Text.data` には U+2060 が入るので、ウィジェットテストで完全一致検索をするときは `replaceAll('\u2060', '')` してから比べる。
- `ReadingQuestionLinks` のラベルは最大3行まで折り返し、3行を超えるときだけ末尾を「…」で省略する。省略は `Text` の `maxLines` + `ellipsis` が行い、ラベル文字列自体は切り詰めない。
既存の `ChapterReadingWidget` / `ReadingSectionView`（見出し＋本文のデータ型）はそのまま。

## 3. 解説カード: ExplanationCard

```dart
import 'package:ukalab_core/answer_feedback.dart'; // または ui.dart

// 型で出す（無い項目は出さない）
const ExplanationCard(conclusion: '…', reason: '…', pitfall: '…', otherScene: '…');

// 既存の1本文の解説（末尾の【別の場面】があれば別の欄に分ける）
ExplanationCard.fromPlain(question.explanation);
```

`【別の場面】` が1つだけあり前後とも空でないときだけ分ける。それ以外は全文をそのまま出す。純 Dart の `ExplanationParts.fromPlain` でも同じ分け方が使える。

## 4. 誤答→読み物導線

```dart
AnswerFeedbackPanel(
  question: q,
  selectedIndex: i,
  onCause: onCause,
  relatedReadings: readingsForQuestion(allReadings, q.qid), // 省略すれば従来と同じ
  onOpenReading: (r) => openReading(r),
)
```

不正解のときだけ「読み物でおさらい」を出す。`disabled` の読み物は出さない。`onOpenReading` が null なら欄ごと出さない。
文言は `AnswerFeedbackStrings` の `explConclusion` `explReason` `explPitfall` `explOtherScene` `relatedReadingsTitle` `readingBackToQuestion` `readingQuestionLabel`（ja / en。zh / ko は機械翻訳の下書きで、公開前に母語話者の確認が要る）。独自の `AnswerFeedbackStrings` を作っているアプリは、追加項目を省略すれば日本語になる。

## 5. 出題範囲の絞り込み（levelId）

`ChapterReading` に任意の `levelId` を持てる（例: 簿記の `level3_from_2027_04`）。省略した読み物は全範囲向け。

```json
{"readingId":"r1","examId":"boki","subjectId":"s1","title":"仕訳の基本","levelId":"level3_from_2027_04","sections":[{"heading":"導入","body":"..."}],"source":"original","sourceRef":"自作","contentVer":"1"}
```

```dart
// 簿記: 今の出題範囲の読み物だけを一覧・誤答導線に使う
final visible = readingsForLevel(allReadings, currentLevelId);
```

`levelId` が null の読み物は常に含まれ、指定のある読み物は一致するものだけ。`currentLevelId` が null なら全件。`validateChapterReadings` は空文字の `levelId` を `empty-level-id` で指摘する。

## 6. 他コンテンツへの参照（relatedLinks）

```json
"relatedLinks":[{"kind":"hazard","id":"h12"},{"kind":"story","id":"s3"}]
```

`kind` は文字列（例: `hazard` / `story` / `term` / `question`）で、コアは意味を解釈しない。遷移先の解決はアプリ側。

```dart
for (final l in linksOfKind(reading, 'hazard')) {
  openHazard(l.id); // バイク: 危険予測へ
}
```

validator は `kind` / `id` が空なら `empty-link-kind` / `empty-link-id`。`relatedTermIds` / `relatedQuestionIds` は従来どおり。

## 7. 誤答導線だけ出す: RelatedReadingsCard

`AnswerFeedbackPanel` は原因選択欄とセットなので、独自の結果表示を持つアプリはこのカードだけを置く。

```dart
// バイク: AnswerResultOverlay の中
RelatedReadingsCard(
  readings: readingsForQuestion(allReadings, q.qid),
  isCorrect: correct,           // 正解なら何も出ない
  onOpenReading: (r) => openReading(r),
)
```

読み物が空・全て `disabled`・`onOpenReading` が null のときも何も出さない。文言は `AnswerFeedbackStrings.relatedReadingsTitle`（`strings:` で差し替え可）。

## 8. import の入口: reading.dart

```dart
import 'package:ukalab_core/reading.dart';
```

読み物/説明ページ関連（`ChapterReading` `ContentLink` `ReadingSection` `ReadingTable` `ReadingFigure` `ReadingSectionContent` `ExplanationCard` `ExplanationParts` `RelatedReadingsCard` `ReadingQuestionLinks` `readingsForQuestion` `readingsForLevel` `linksOfKind` `validateChapterReadings`、`kReadingSection*` 定数）をまとめて使える。Flutter が要る。純Dartだけで使うなら従来どおり `ukalab_core.dart`。既存の入口の公開名は変わらず、同じ宣言を再エクスポートするだけなので併用しても曖昧にならない（別名の型をアプリが持つ場合は `show` / `as` で選ぶ）。

## 9. 設計メモ: 問題の変換アダプタ（今回は実装しない）

アプリ側の `Question`（独自スキーマ）を core の `Question` に変換するアダプタの実現可能性:

- 可能。core 側に変換関数を置くとアプリ固有の型に依存してしまうため、**アプリ側に `Question toCoreQuestion(AppQuestion q)` を置く**のを推奨（core は変更しない）。
- 必須の対応: `qid`・`prompt`・`choices`・`answerIndex`・`explanation`・`examId`・`subjectId`・`topicId`・`source`・`sourceRef`・`contentVer`。選択肢を並べ替えて表示するアプリは、`AnswerFeedbackPanel.selectedIndex` に元の番号を渡す。
- 変換結果は表示用に毎回作らず、一覧読み込み時に1度作ってキャッシュする。変換できない問題（記述式など）は `isCorrect` を渡して `selectedIndex: null` で使う。
- 将来共通化するなら、core に `abstract interface class` ではなく変換用の関数型 typedef だけを足す案を先に検討する（既存アプリへの影響が最小）。
