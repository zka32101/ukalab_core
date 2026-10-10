# 移植した UI の使い方（app_common_kit v0.30 までの README から）

> app_common_kit v1.0.0 から、うかラボ専用の UI は ukalab_core に移りました。`import 'package:ukalab_core/ui.dart';` で使います。
> 以下は、移した当時（app_common_kit v0.30）の README の該当節です。import の `app_common_kit` は、うかラボ専用の部品については `ukalab_core/ui.dart` に読み替えてください。

## テーマ（v0.2）

分野（と資格）を渡すだけで、共通デザイン仕様 v0.4 の ThemeData が作れる。色の直書きはしない。

```dart
MaterialApp(
  theme: UkalabTheme.light(field: UkalabField.ai, cert: UkalabCert.gKentei),
  darkTheme: UkalabTheme.dark(field: UkalabField.ai, cert: UkalabCert.gKentei),
)
```

- 資格を省くと分野色になる。`cert.field` と `field` が合わないと assert で失敗する
- 色のトークンは `UkalabPalette.resolve(...)`、コントラスト比は `contrastRatio(a, b)`
- **success（ライト #1E8E3E）は背景の上で 4.0〜4.2:1 で、文字としては AA に届かない**。✓アイコンなど図形として使い、正誤は必ず✓／✕と文言を併記する


## 学習コイン（v0.2）

学習の成長でのみ獲得できる。使い道は見た目だけ。財布は**アプリごと**（`SharedPreferencesCoinStore(appId)`）。

```dart
final coin = CoinService(store: SharedPreferencesCoinStore('bike'), shop: items);
await coin.load();
final g = await coin.grant(CoinEvent.newQuestion('q123')); // 付与したら CoinGrant、重複・上限なら null
await coin.purchase('hat'); // purchased / insufficient / alreadyOwned / unknownItem
```

- 重複防止: 同じ問題・同じ段階・同じ資格は二度付与されない。1日の上限（新しい問題30コイン、復習20コイン、自己ベスト3回）あり
- 残高は台帳の合計。購入は残高以内でしか記録しないので負にならない
- 端末移行・同期: `CoinLedger.toJson()` を共通アカウントに保存し、`CoinService.mergeLedger` で統合（何度統合しても同じ）。サーバー側の保存は下の「共通アカウントで同期する」を参照
- 数値は暫定（学習コイン仕様 §2）。`CoinRules` を作り直して調整
- 網羅率や正答率の**到達判定**は呼び出し側（学習ログ）が行い、到達したらイベントを渡す

### 共通アカウントで同期する（Firestore）

端末移行・複数端末で、同じアカウントなら同じコインになる。台帳は追記専用で行ごとに ID があるため、何度同期しても二重にならない。

```dart
// 1. サインイン後（匿名でも可）に、保存先を作る。uid は Firebase Auth の uid。
final remote = FirebaseCoinRemote(uid: user.uid, examId: UkalabCert.bikeLicense.id);

// 2. 起動時と、購入の後に同期する。5分以内の再同期は自動でスキップ、失敗しても例外は出ない。
await ref.read(coinProvider.notifier).load();
await ref.read(coinProvider.notifier).syncWith(remote, minInterval: const Duration(minutes: 5));
// 購入後:  await notifier.purchase(id); await notifier.syncWith(remote);
```

- 保存先は `users/{uid}/exams/{examId}/coin/ledger`。共通ルール（`firebase/firestore.rules`）に含まれるため、**ルールの変更は不要**（本人だけが読み書きでき、examId は登録済みの資格だけ）
- 台帳は1ドキュメント（Firestore の1MB上限）。1行 約150バイトで 6,000行ほど。1日の獲得上限があるので通常は収まる
- 装備中の衣装は端末ごと（同期しない）
- 2台で同時に購入すると、統合後の残高が一時的にマイナスになりうる（購入は残高以内でしか記録しないが、オフラインの2台は互いを知らないため）。マイナスは次の獲得で戻る。必要ならアプリ側で表示を 0 に丸める
- Firestore 以外に置くなら `CoinRemote`（`readLedger`/`writeLedger`）を実装して渡す

### 学習の引き継ぎ（機種変更）

学習履歴・コイン・衣装を、共通アカウント（匿名 → Google/Apple リンクでも uid は変わらない）のサーバーへ保存し、新しい端末へ復元する。復元は**統合**で、端末内のデータを消さず、何度実行しても二重にならない。部品ごとに処理し、1つの失敗で他を止めない（例外は出さない）。

```dart
final transfer = LearningTransfer(
  remote: FirebaseTransferRemote(uid: user.uid, examId: UkalabCert.gKentei.id),
  sources: [
    CoinTransferSource(coinService),       // コイン台帳（id が同じ行は一度だけ）
    OutfitTransferSource(outfitService),   // 合格・準備完了・着ている衣装
    FunctionTransferSource(                // 学習履歴などは、アプリが中身を渡す
      partId: 'progress',
      onExport: () async => [for (final r in await store.loadRecords()) r.toJson()],
      onImport: (remote) async { /* remote(List) を端末内の記録へ統合。冪等にする */ },
    ),
  ],
);

await transfer.backup();                  // 旧端末: 起動時・学習後などに保存
final result = await transfer.restore();  // 新端末: ログイン直後に復元
// result.status: success / partial / failed。result.failed は後でやり直せる
// result.nothingToRestore: バックアップが一度も無い（新規利用者）
```

- 保存先は `users/{uid}/exams/{examId}/transfer/{partId}`（部品ごとに1ドキュメント）。共通ルールに含まれるため、**ルールの変更は不要**
- 1部品は Firestore の1MB上限まで。学習履歴が大きいアプリは、部品を分けるか、期間で切り分けて渡す
- `partId` は一意にする（英数字とアンダースコア）。Firestore 以外に置くなら `TransferRemote`（`readPart`/`writePart`）を実装して渡す
- 学習履歴（`ukalab_core` の `ProgressRecord`）の統合は、`qid` と `at` が同じ記録を重複させない形でアプリ側が実装する


## 推し（v0.2）

```dart
final model = MasteryModel.standard;
final stage = model.stageOf(MasteryInput(coverage: 0.3, accuracy: 0.8)); // Lv2
final day = MascotDayState(studiedToday: true, examDate: examDate);
MascotWidget(
  stage: stage,
  expression: day.expression,          // 学習した日はよろこび。責める表情はない
  examPhase: day.examPhase(DateTime.now()),
  line: MascotLines.gentle.pick(MascotSituation.studied, seed: dayOfYear),
);
```

- 標準キャラはコード描画で画像不要。AI 画像のパックは `CharacterPack(imageBuilder: ...)` を渡す（画像がまだ取れないときは null を返せば標準の描画に戻る）
- 習得度の式と段階の境目は暫定（網羅率×正答率、0.2／0.4／0.6／0.8）。`MasteryModel` の引数で差し替える
- セリフは `findForbiddenExpressions` で検査する。追加するときは test/mascot_test.dart の検査に通すこと
- 設定の「推しを小さく／非表示」は `MascotDisplay`、「動きを減らす」は端末設定に従う


## 衣装・資格連動（v0.2）

| 衣装 | 入手 | 呼び出し |
|---|---|---|
| 通常（資格別の小物） | コインで買う（300） | `CoinService.purchase(OutfitCatalog.idOf(cert, OutfitKind.regular))` |
| 合格記念 | 合格報告で「合格」を選んだ場合のみ（無料） | `OutfitService.reportPassed(cert)`（コインの `CoinEvent.passReport` は別に付与） |
| 試験日の装い | 試験日を設定した人だけ（無料） | `examPhase` を渡す |
| 準備完了 | 最短ルートの目標達成（無料） | `OutfitService.markReady(cert)` |

- 衣装は分野の小物と資格のシンボルだけで表す。試験団体のロゴ・制服・公式の意匠は使わない
- 共有カードは `PassShareCard(data: ShareCardData(...))`。名前・メール・IDの欄は作らない。画像化は `RepaintBoundary` に key を付けて `captureShareCard(key)`


## 評価指標ラボ（画期的な機能3）

`ConfusionMatrixLabWidget` は、混同行列（TP/FP/FN/TN）をスライダーで自由に動かすと正解率・適合率・再現率・F値が連動する様子を見せ、続けて「偽陽性と偽陰性のどちらが重いか」の場面問題につなげる。

```dart
ConfusionMatrixLabWidget(
  scenario: ConfusionMatrixScenarioSpec(
    title: 'がん検診',
    description: '見逃し(偽陰性)と誤検知(偽陽性)、どちらが重いか。',
    initialTp: 40, initialFp: 10, initialFn: 10, initialTn: 40,
    options: const [
      FailureChoiceSpec(optionId: 'recall', text: '再現率を優先する', isCorrect: true),
      FailureChoiceSpec(optionId: 'precision', text: '適合率を優先する', isCorrect: false),
    ],
    explanation: '病気を見逃す(偽陰性)方が重いため、再現率を優先する。',
  ),
)
```

- スライダーの可動範囲は初期値の合計と100の大きい方。初期値がそれを超えるデータでも壊れない
- 選択肢は `FailureChoiceSpec`（`failure_gallery.dart`）を再利用する。正解を選ぶまで `ChoiceChip` は選択状態に戻らず、再挑戦できる


## 手法の選び方（事例仕分け、画期的な機能6）

`MethodChoiceWidget` は、事例の説明を読んで適切な手法・モデル・評価指標を選び、正解すると理由を見る。

```dart
MethodChoiceWidget(
  scenario: MethodChoiceScenarioSpec(
    title: '顧客の離脱予測',
    caseDescription: '顧客の年齢・購入履歴から、将来の離脱(はい/いいえ)を予測したい。',
    options: const [
      FailureChoiceSpec(optionId: 'classification', text: '分類（教師あり学習）', isCorrect: true),
      FailureChoiceSpec(optionId: 'clustering', text: 'クラスタリング（教師なし学習）', isCorrect: false),
    ],
    explanation: '正解・不正解のラベル付きデータから学習するため、分類(教師あり学習)が適切。',
  ),
)
```

- 選択肢は `FailureChoiceSpec`（`failure_gallery.dart`）を再利用する。`ConfusionMatrixLabWidget` の選択パートと同じ構造で、混同行列の操作だけがない最小版


## 機械学習ラボ（画期的な機能1）

`MlLabWidget` は、2クラスのデータ点をk近傍法・決定木・線形分類の3手法で分類し、決定境界（背景の塗り分け）とハイパーパラメータによる過学習・未学習の変化を見せる。分類の計算（kNN・CART風の決定木・正則化付きロジスティック回帰）はこのウィジェット内で行う。

```dart
MlLabWidget(
  title: '線形分離',
  description: '2つのかたまりに分かれた点です。',
  points: const [
    MlLabPointSpec(x: 1, y: 1, label: 0),
    MlLabPointSpec(x: 8, y: 8, label: 1),
    // ...
  ],
)
```

- 座標は0〜10の範囲を想定（グリッド24×24で決定境界を塗り分ける）
- ハイパーパラメータ: k近傍法は`k`（1〜15）、決定木は`深さ`（1〜6）、線形分類は`正則化`（0〜2.0）
- クラスは色だけに頼らず形も変える（クラス0は丸、クラス1は三角）


## 今月のAI動向（画期的な機能10、決定41）

`AiNewsCard` は、ホームに3〜5件のAI動向を表示する。毎週の収集・運営者確認・月次の差分更新はアプリの外（人・定期タスク）で行い、このウィジェットは配信済みのデータを表示するだけ。

```dart
AiNewsCard(
  items: [
    AiNewsItemSpec(
      summary: '生成AIの新しい基盤モデルが発表された。',
      sourceUrl: 'https://example.com/news/1',
      sourceDate: DateTime(2026, 9, 1),
      syllabusTag: '2 人工知能をめぐる動向',
      asOfDate: DateTime(2026, 10, 1),
      isExamRelevant: true,
    ),
    // ...
  ],
)
```


## 画像認識の中身を見る（画期的な機能4）

`ConvLabWidget` は、手書き風の数字・図形（グレースケールの格子）に畳み込みフィルタ（縦/横エッジ検出・ぼかし・シャープ化）を当て、入力画像→特徴マップ→プーリング後（2x2 max pooling）の3段階を並べて表示する。畳み込み・プーリングの計算はこのウィジェット内で行う。

```dart
ConvLabWidget(
  image: ConvLabImageSpec(
    title: '手書き風の「1」',
    description: '縦棒だけの画像。',
    grid: [
      [0, 0, 1, 0, 0, 0, 0, 0],
      // ... 8x8以上のグレースケール値(0.0〜1.0)
    ],
  ),
)
```

- フィルタは`ConvFilter`（`verticalEdge` / `horizontalEdge` / `blur` / `sharpen`）の4種類で固定
- 入力画像はそのままの値をグレースケール表示、特徴マップ・プーリング後は最小〜最大を0.0〜1.0に正規化して表示（負の値も見えるようにする）

- 項目が空なら何も表示しない
- 「◯年◯月時点」はカード全体の見出しに1回だけ表示する（各項目の`asOfDate`の最大値）
- 「試験に出そう」印は色だけに頼らずアイコン（旗）とバッジ文言で示す
- 出典URLは`SelectableText`で表示するだけで、タップでの外部遷移は行わない（`url_launcher`非依存）


## Transformerの注意の可視化（画期的な機能5）

`AttentionVizWidget` は、短い文の単語（トークン）同士の注意（Attention）の強さを、線の太さ・濃さで見せる。注目する単語（クエリ）をチップで選ぶと、他の単語への注意の強さに応じて線が変化する。値は教育用に用意した固定データで、実際のモデルの出力ではないことを画面上に明記する。

```dart
AttentionVizWidget(
  scenario: AttentionVizSpec(
    title: '誰が何を食べた？',
    description: '「食べた」がどの単語に注目しているか見てみましょう。',
    tokens: ['猫', 'が', '魚', 'を', '食べた'],
    attention: [
      [0.6, 0.1, 0.1, 0.05, 0.15],
      // ... 各行の合計がおよそ1.0になる注意の強さ(0.0〜1.0)
    ],
  ),
)
```

- 色だけに頼らず、クエリ側は上向きの三角マーカー、最も注目されたキー側は星マーカーで示す
- 最も強く注目している単語とその割合(%)を文章でも表示する


## ニューラルネット組み立て（画期的な機能2）

`NnBuilderWidget` は、隠れ層の数・ユニット数・活性化関数・学習率を選び、2クラスのデータ点を分類する小さな全結合ニューラルネットを実際に学習させて、決定境界と学習曲線（訓練誤差）の変化を見せる。順伝播・誤差逆伝播法（バックプロパゲーション）による学習自体をこのウィジェット内で行う。

```dart
NnBuilderWidget(
  title: '2つのかたまりを分ける',
  description: '2つのかたまりに分かれた点です。',
  points: const [
    NnBuilderPointSpec(x: 1, y: 1, label: 0),
    NnBuilderPointSpec(x: 8, y: 8, label: 1),
    // ...
  ],
)
```

- 隠れ層は1層または2層、ユニット数は2〜8、活性化関数はシグモイド/ReLU/tanh、学習率は0.1〜3.0から選べる（出力層は常にシグモイド、二値分類）
- 座標は0〜10の範囲を想定（グリッド24×24で決定境界を塗り分ける）。クラスは色だけに頼らず形も変える（クラス0は丸、クラス1は三角）
- 学習曲線は固定400エポックのフルバッチ勾配降下法。乱数シードは固定し、同じ設定なら毎回同じ結果になる


## ストーリー型の共通エンジン（決定38）

`StoryModeWidget` は、複数資格で共用するストーリー型の体験（簿記3級の会社経営モード・乙4の現場の1日モード・G検定のAIプロジェクト経営モードなど）の章立て・選択・解説・振り返りを支える汎用エンジン。シナリオ・会社など具体的な内容は `StoryScenarioSpec` としてアプリ側が渡す。

```dart
StoryModeWidget(
  scenario: StoryScenarioSpec(
    title: 'AIプロジェクト経営モード',
    description: '架空の会社でAI導入を進めます。',
    chapters: const [
      StoryChapterSpec(
        situation: 'データ収集の段階。どちらの方法を選びますか?',
        choices: [
          StoryChoiceSpec(
            choiceId: 'license',
            text: '出典・ライセンスを確認して収集',
            isRecommended: true,
            feedback: '権利関係を確認してから使うのが基本。',
          ),
          // ...
        ],
      ),
      // ...
    ],
  ),
)
```

- 章を1つずつ進み、各章で選択肢を選ぶと、推奨の判断かどうかとその理由（解説）を表示する。最後の章まで進むと、章ごとの判断を振り返る
- 色だけに頼らず、推奨の判断には✓アイコン、そうでない判断には△アイコンを付ける
- 途中保存の仕組みは持たない（現状は短い章数の体験を想定）。長い章数のシナリオ（簿記3級の会社経営モードなど）向けの途中保存は、必要になった時点で追加する

