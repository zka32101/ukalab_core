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
