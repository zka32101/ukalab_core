# 移植した UI の使い方（app_common_kit v0.30 までの README から）

> app_common_kit v1.0.0 から、うかラボ専用の UI は ukalab_core に移りました。`import 'package:ukalab_core/ui.dart';` で使います。
> 以下は、移した当時（app_common_kit v0.30）の README の該当節です。import の `app_common_kit` は、うかラボ専用の部品については `ukalab_core/ui.dart` に読み替えてください。

> ながらセッション（`NagaraSessionController` / `NagaraSessionView` / `AwaitableSpeechBackend` / `HandsFreeSettings` の `thinkSeconds`・`betweenSeconds`・`autoAdvance` / `KitStrings.nagara`）は app_common_kit v3.1.0 から。core は再エクスポートのみで、`package:app_common_kit/app_common_kit.dart` から import する（`NagaraSessionView` など flutter_tts 依存のものは `package:app_common_kit/hands_free_tts.dart`。core の `ui.dart` と名前の衝突はないので hide/show は不要）。

> kit v3.5.0 追従（core v0.66.0）: ながらセッションの `NagaraSessionController(onAnswered:)` / `NagaraSessionView(onAnswered:)` が使える。`onAnswered(question, chosen, correct)` は正答を含む全てのタップ回答を返す（呼び出し順は解答確定 → `onAnswered` → 誤答なら `onWrongAnswer`。1 問につき最大 1 回。未回答 `onUnanswered`・スキップでは呼ばない）。通常の解答と同じ記録経路（履歴・間隔反復・デイリーミッション）に載せると、間違いノートの「克服」や週間ふりかえりに正答も反映される。
> 同時に取り込んだ kit の追加: v3.2.0 同意管理 `ConsentController`、v3.3.0 保護者ゲート `ParentalGateDialog`（`package:app_common_kit/parental_gate.dart`）、v3.4.0 診断情報つき不具合報告 `DiagnosticsCollector`。

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
| 通常（資格別の小物） | コインで買う（200） | `CoinService.purchase(OutfitCatalog.idOf(cert, OutfitKind.regular))` |
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


## 衣装・背景のプレゼント（`OshiGiftEngine` / `showOshiGiftDialog`）

学習の節目（連続日数・メダル獲得・模試合格）で、推しの衣装や背景を解放して祝う。未達を理由にした催促はしない（解放された分だけを知らせる）。

```dart
const gifts = [
  OshiGift(id: 'bg_streak7', kind: OshiGiftKind.background,
      condition: OshiGiftCondition.streakDays(7), name: '夕焼けの背景'),
  OshiGift(id: 'outfit_medal', kind: OshiGiftKind.outfit,
      condition: OshiGiftCondition.medal('streak7'), name: 'お祝いの衣装',
      image: AssetImage('assets/gift/outfit_medal.png')), // image は任意
  OshiGift(id: 'outfit_mock', kind: OshiGiftKind.outfit,
      condition: OshiGiftCondition.mockPass(), name: '合格の衣装'),
];

final svc = OshiGiftService(store: SharedPreferencesOshiGiftStore('myapp'));
await svc.load();
final fresh = await svc.check(
  OshiGiftProgress(streakDays: 7, earnedMedalIds: {'streak7'}, mockPassed: false), // 個人情報は入れない
  gifts,
);
for (final g in fresh) {
  await showOshiGiftDialog(context, gift: g, pack: pack, stage: stage);
}
```

- 判定だけなら純 Dart の `OshiGiftEngine().newlyUnlocked(progress:, gifts:, alreadyUnlocked:)`（既解放は除外・冪等）
- 解放済みIDは `OshiGiftStore` に保存（`SharedPreferencesOshiGiftStore(appId)`、キー `ukalab_oshi_gift_<appId>`）。衣装の着用そのものは既存の `OutfitService` / 着せ替えとアプリ側で結びつける
- `image` が無ければ、衣装は仮アイコン、背景はコード描画のグラデーション。画像ができたら `image` を渡すだけで差し替わる（読み込み失敗時は描画に戻る）
- 文言は `OshiGiftStrings`（ja・en。`copyWith` で上書き可。`UkalabStrings` は変えない）。禁止語リストでテスト。運営での文言確認は別途必要

## 推しの成長演出（`OshiGrowthEngine` / `OshiGrowthBubble` / `showOshiGrowthDialog`）

アプリが渡す累計の学習量（回答数・学習日数）で、推しの反応（表情の絵文字・ラベル・一言）が段階的に変わる。10/50/100/300/1000 問・7/30/100 日などの節目に到達したら、一度だけ祝う。次の節目までの残りを数えて促さず、休んでも責めない（学習日数は連続ではなく合計。累計は減らないので段階も下がらない）。

```dart
final progress = OshiGrowthProgress(totalAnswered: 120, studyDays: 12); // 個人情報は入れない

// 常時表示: 推しの今の反応（OshiMessageBubble と同じ吹き出し。タップで別の一言）
OshiGrowthBubble(progress: progress, avatar: MascotWidget(/* ... */)) // avatar 省略時は絵文字

// 節目の祝福: 起動時・学習後などに 1 回
final svc = OshiGrowthService(store: SharedPreferencesOshiGrowthStore('myapp'));
await svc.load();
final m = await svc.checkHeadline(progress); // 新しく到達した節目のうち見せる 1 件（無ければ null）
if (m != null && context.mounted) {
  await showOshiGrowthDialog(context, milestone: m);
}
```

- 段階（`OshiGrowthStage`）: newcomer → budding（10問/7日）→ growing（100問/30日）→ blooming（300問/100日）→ radiant（1000問）。回答数と学習日数の進んでいる方で決まる
- 節目の既定: 回答 10/50/100/300/1000 問、学習 7/30/100 日（ID は `answered_10` / `days_7`。保存に使うので変えない）。`OshiGrowthEngine(milestones: [...])` で差し替え可
- 久しぶりに開いて複数の節目を一度に迎えても、記録は全て済ませ、祝福は最も大きい 1 件だけ（`headlineOf`）。`svc.check(progress)` なら到達した全件を返す
- 既出判定は注入式の `OshiGrowthStore`（`InMemoryOshiGrowthStore` / `SharedPreferencesOshiGrowthStore(appId)`、キー `ukalab_oshi_growth_<appId>`）。保存に失敗したときは記録せず例外を伝え、次回また祝える
- 判定だけなら純 Dart の `OshiGrowthEngine().newlyReached(progress, alreadyCelebrated:)`（冪等）、反応だけなら `reaction(progress, seed: OshiGrowthEngine.seedFromDate(DateTime.now()))`
- 文言は `OshiGrowthStrings`（ja・en。`copyWith` で上書き可。`UkalabStrings` は変えない）。禁止語リストでテスト。運営での文言確認は別途必要
- 推しの一言（`OshiMessageEngine`）は「今日の状況」への声かけ、こちらは「これまでの積み重ね」への反応。両方を並べてもよいが、同時に出すと賑やかなので、ホームではどちらか一方か、成長演出は祝福ダイアログ中心にするのがおすすめ

## 推しの一言（`OshiMessageEngine` / `OshiMessageBubble`）

学習状況に応じて推しが短い一言を出す。責めない・煽らない・罪悪感を与えない（久しぶり→「おかえり。今日は1問からでいいよ」、連続→「いい調子。無理せず続けよう」、間違いが多い日→「間違えた所が伸びしろだよ」）。

```dart
const ctx = OshiMessageContext(
  daysSinceLastStudy: 5, streakDays: 0, todayAnswered: 0,
  todayCorrectRate: null, examDaysLeft: 40, hasWeakTopics: true, // 個人情報は入れない
);
final msg = const OshiMessageEngine().pick(ctx, seed: OshiMessageEngine.seedFromDate(DateTime.now()));
// msg.id / msg.text / msg.mood

OshiMessageBubble(situation: ctx, avatar: MascotWidget(/* ... */)) // avatar 省略時は絵文字
```

- 状況の優先順: 久しぶり（3日以上空き・今日未学習）> 間違いが多い（5問以上で正答率50%未満）> 連続3日以上 > 今日の達成 > 試験が近い（1〜120日。「あと◯日、自分のペースで大丈夫」と軽く触れるだけ）> 苦手あり > あいさつ
- 同じ入力でも seed（日付）で言い回しが変わる。`salt` を変える（ウィジェットはタップ）と別の一言
- 文言は `OshiMessageStrings`（ja・en。`copyWith` で上書き可。`UkalabStrings` とは別なので既存アプリは変更不要）。責める語・脅しは禁止語リストでテスト
- 試験日カウントダウンは別機能（`ExamCountdownChip` / `ExamCountdownCard`）。`examDaysLeft` は励ましの言及にしか使わない

## 週間ふりかえり（`WeeklyRecapEngine` / `WeeklyRecapCard`）

週に一度、「できたこと」だけを見せる。解いた問題数・学習した日・続いた日・メダル・よく解いた分野/伸びた分野。前週との比較や「少なかった」の表現は出さない。解いていない週は「今週はひと休み」と穏やかに表示する。

```dart
final days = weeklyRecapDaysFromRecords(history); // ProgressRecord から（問題IDは引き継がない）
final recap = const WeeklyRecapEngine(weekStartsOn: DateTime.monday) // 日曜始まりなら DateTime.sunday
    .build(days, weekOf: DateTime.now(), medalsEarned: 2);

WeeklyRecapCard(
  recap: recap,
  topicLabel: (id) => chapterNames[id] ?? id,
  message: OshiMessageBubble(situation: ctx), // 任意。推しのひとこと
)
```

- 連続日数は「週の中で続いた最長の日数」（1日のときは行を出さない）。伸びた分野は、今週・前週とも3問以上で正答率が上がった分野（差は見せない）
- 文言は `WeeklyRecapStrings`（ja・en。`copyWith` で上書き可。`UkalabStrings` は変えない）。禁止語リストでテスト。運営での文言確認は別途必要
- 共有カード（`WeeklyRecapShareCard`）は今回は含まない。同じ `WeeklyRecap` を受け取る別ウィジェットとして追加し、`OshiMedalShareCard` と同様に `RepaintBoundary` + `captureShareCard` で画像化する想定（個人情報の欄は作らない）

## 模擬試験の結果分析（`MockExamAnalysisEngine` / `MockExamAnalysisCard`）

模擬試験（または任意の回答履歴）から、分野別の様子・伸びしろのある分野・「今日はここを少しだけ」（次にやる分野、最大3件）を見せる。点数で責めず、赤などの警告色・順位は使わない。アプリは分野名と回答リストを渡すだけ。

```dart
final analysis = const MockExamAnalysisEngine().analyze([
  for (final q in answered) MockExamAnswer(topicId: q.chapterId, correct: q.isCorrect),
]);

MockExamAnalysisCard(analysis: analysis, topicLabel: (id) => chapterNames[id] ?? id);
// 画面ごと: MockExamAnalysisScreen(answers: [...], topicLabel: ...)
```

- `MockExamAnalysisEngine({minSamples = 2, weakThreshold = 0.7, masteredThreshold = 0.9, nextCount = 3})`。弱点は `minSamples` 問以上解いて正答率が `weakThreshold` 未満の分野。次にやる分野は正答率の低い順（同率は解答数の多い順→ID順）で、`masteredThreshold` 以上の分野は入れない（全部安定なら空→カードは穏やかな文言）
- エンジンは何も保存しない純粋ロジック。履歴を残したいアプリは、自分で保存した回答リストを渡す（`DataPart` への登録は不要）
- 文言は `MockExamAnalysisStrings`（ja・en。`UkalabStrings` は変えない）。禁止語リストでテスト。運営での文言確認は別途必要

## 試験日カウントダウン（`ExamCountdownEngine` / `ExamCountdownChip` / `ExamCountdownCard`）

試験日までの日数を、煽らず前向きに見せる。「あと◯日」を押し付けず、「自分のペースで」「今日できること」を添える。試験日を過ぎたら日数を消し、静かに「おつかれさまでした」を出す。

```dart
final date = ref.watch(examDateProvider); // 受験日の保存は exam_date.dart（変更なし）

// ホームの AppBar 付近や ExamPrepCard の近くに
ExamCountdownChip(examDate: date, onTap: () => openExamDateSettings(context))

// 今日できることの提案つき
ExamCountdownCard(examDate: date, onTap: () => openExamDateSettings(context))

// 純 Dart（ukalab_core.dart）
final c = const ExamCountdownEngine().compute(date, today: DateTime.now());
c.daysLeft; c.phase; // ExamCountdownPhase
```

- 段階: none（未設定）/ farAway（100日超）/ approaching（31〜100日）/ close（8〜30日）/ finalDays（1〜7日）/ today / done（過去）
- 日数は年月日だけの暦日差（既存 `daysUntilExam`）。時刻・タイムゾーン・夏時間で 1 日ずれない。`today` を渡すとテストで基準日を固定できる
- 未設定は Chip / Card とも何も描かない。done は日数を出さず「おつかれさまでした」のみ（いつまで出すかはアプリ側。不要なら `examDate` に null を渡す）
- 文言は `ExamCountdownStrings`（ja・en。`copyWith` で上書き可。`UkalabStrings` は変えない）。禁止語リストでテスト。final 期でも「いつもどおりで大丈夫」。運営での文言確認は別途必要
- `OshiMessageEngine` の `examDaysLeft`（推しのひとこと）とは独立。併用してよい

## 新しい問題タイプの画面（`TrueFalseQuestionView` / `ClozeQuestionView` / `ReverseLookupQuestionView`）

○×・空欄補充・説明から用語の3タイプ（設計は `docs/multi_angle_questions_design.md`）。解答後は「結果（アイコン＋文字）→ 正解 → 解説 → `AnswerFeedbackPanel`（間違えた理由）→ 次へ」の順に出る。

```dart
switch (q.type) {
  case QuestionType.trueFalse:
    return TrueFalseQuestionView(
      key: ValueKey(q.qid), question: q, index: i + 1, total: n,
      onAnswered: (r) => session.answerTrueFalse(r.boolAnswer!),
      onNext: next,
    );
  case QuestionType.cloze:
    return ClozeQuestionView(
      key: ValueKey(q.qid), question: q,
      onAnswered: (r) => session.answerCloze(r.blankAnswers!),
      onSelfReported: session.markLastSelfReportedCorrect, // 自由入力の打ち間違い救済
      onNext: next,
    );
  case QuestionType.reverseLookup:
    return ReverseLookupQuestionView(
      key: ValueKey(q.qid), question: q,
      onAnswered: (r) => session.answerReverseLookup(r.text!),
      onSelfReported: session.markLastSelfReportedCorrect,
      onNext: next,
    );
  // choice / journal / worksheet / ledger は従来どおり
}
```

- アクセシビリティ: ○×は「○ 正しい」「× 誤り」と記号・文字・アイコンを併記し、高さ 48dp 以上。空欄は枠つきの番号と `Semantics(label: '空欄n')`。結果の帯は `liveRegion`。文字を 200% にしても折り返して崩れない
- 自由入力: 入力の候補表示・自動修正・自動入力は使わない。IME の変換中は「解答する」を押せない（確定してから判定）。判定は `normalizeAnswerText`（全角/半角・空白・長音・中黒の揺れを吸収。ひらがな/カタカナは区別）後の完全一致で、`answers` のどれかに一致すれば正解
- 選択肢つき（`choices` あり）は選ぶとその場で採点（○×・説明から用語）、空欄補充は選んでから「解答する」
- 文言は `QuestionTypeStrings`（ja・en。他の言語は日本語）。引数 `strings` で差し替え可
- 模擬試験には既定で出ない（`pickMockExamQuestions` の `allowedTypes`）

## 間違いノート（`MistakeNoteEngine` / `MistakeNoteView`）

間違えた問題をあとから見返して解き直せるノート。間違いは「伸びしろ」として扱い、解き直して連続で正解したら「克服」と祝う。件数の多い順などのランキング表示や、件数で圧をかける文言は出さない。

```dart
const engine = MistakeNoteEngine(); // overcomeStreak: 2（暫定。引数で変えられる）
final store = SharedPreferencesMistakeNoteStore('myapp'); // キー ukalab_myapp_mistake_notes

// 解答のたびに（または画面を開くときに）履歴から取り込む。同じ履歴を何度渡しても結果は同じ
final before = await store.read();
final after = engine.update(before, history); // history は ProgressRecord（cause・topicId は既存のもの）
await store.write(after);
final justOvercome = engine.newlyOvercome(before, after).toSet(); // 祝う対象

MistakeNoteView(
  entries: after,
  questionBuilder: (context, entry) => Text(questionTextOf(entry.qid)), // 問題文はアプリ側（core は持たない）
  onRetry: (entry) => openQuestionScreen(entry.qid),                    // 出題画面を開く
  celebrateQids: justOvercome,
  topicLabel: (id) => chapterNames[id] ?? id,
)
```

- 克服 = 間違えたあとに連続 N 回（既定 2）正解。克服後にまた間違えたら「これから」に戻る。履歴が上限で切り捨てられても、保存済みのノートは残る
- 項目は `MistakeNoteEntry{qid, firstMissedAt, lastMissedAt, missCount, overcome, lastCause?, topicId?}`。`lastCause` は既存の `WrongCause`（`WrongCauseSelector` / `attachCauseToLatest` で付いたもの）を再利用。保存するのは問題ID・日時・原因コード・分野ID・回数だけ
- 並びは直近の間違い順。フィルタは「これから」「克服」。`missCount` は判定用で、画面には出さない
- premium で出し分けたいときは、アプリ側で `MistakeNoteView` を包む（`canUsePremiumFeature` など）。core は制限しない
- 文言は `MistakeNoteStrings`（ja・en。`copyWith` で上書き可。`UkalabStrings` は変えない）。禁止語リストでテスト。運営での文言確認は別途必要
- Semantics 付き。「動きを減らす」設定では祝う表示の出現の動きなし

### バックアップ・リセットへの登録

```dart
final parts = <DataPart>[
  // ...既存の部品
  mistakeNoteDataPart(store, onChanged: () => ref.invalidate(mistakeNotesProvider)), // 画面を開いたままでも反映したいとき
];
DataManagementSection(parts: parts)
```

バックアップ内のキーは `mistakeNotes`（いったん決めたら変えない）。壊れた値を読み込んだ場合は空になる。

## 推しメダルカード（`OshiMedalShareCard` / `showOshiMedalDialog`）

推しの画像の隅にメダル（実績・連続学習・模擬合格）を置いた 4:5 の共有カード。名前・メール・ID の欄は作らない（日付・「うかラボ」・「自己記録・非公式」の注記のみ）。

```dart
await showOshiMedalDialog(
  context,
  medal: const OshiMedal(id: 'streak7', label: '7日連続', tier: 2, kind: OshiMedalKind.streak),
  pack: pack, stage: stage, outfit: outfit,
  corner: OshiMedalCorner.bottomRight, // 既定。左上/右上/左下/右下
  onShare: (png) async { /* アプリ側の共有処理 */ },
  onSave: (png) async { /* アプリ側の保存処理 */ },
);
```

- `OshiMedal.image` が無ければコード描画（リボン+円+アイコン）。画像アセットができたら `image: AssetImage(...)` を渡すだけで差し替わる（読み込み失敗時はコード描画に戻る）
- PNG 化は `captureShareCard`（pixelRatio 3）。画像化の前に medal 画像を precache する
- `onShare` / `onSave` が null のボタンは出ない。共有・保存の実処理（`share_plus` や ギャラリー保存など）はアプリ側。core にネイティブプラグインは足さない
- カードだけ使う場合は `OshiMedalShareCard` を `RepaintBoundary` に入れ、`captureShareCard(key)` で画像化する


## 試験に向けて（10分プラン・試験直前・チェックリスト・更新ログ・書き出し）

otsu4 の「追加差別化機能」画面を共通化したもの。アプリ非依存で、データの取得・保存・premium 判定・画面遷移は引数とコールバックで渡す。文言は `ExamPrepStrings`（`KitStringsScope` の言語に従う。ja・en 以外は機械翻訳の下書き）。励ます表現のみで、責める表現・他人との比較は使わない。

```dart
// ホーム: 入口カード（試験直前の行は、試験日が3日以内のときだけ出る）
ExamPrepCard(
  questions: () => allQuestions,
  records: () => history,
  examDate: examDate,                       // 未設定は null
  tenMinUnlocked: isPremium,                // premium 判定は呼び出し側
  examEveUnlocked: isPremium,
  onStartPractice: (context, title, pool, emptyMessage) => Navigator.of(context).push(/* 自前の練習画面 */),
  onOpenChecklist: (context) => Navigator.of(context).push(MaterialPageRoute<void>(
    builder: (_) => ExamDayChecklistView(
      examId: 'myexam',
      items: myChecklist,                   // 省略すると一般項目（すべて「公式で要確認」）
      initialProgress: ChecklistProgress(savedIds),
      onChanged: (p) => save(p.checkedIds), // 保存先はアプリ側
    ),
  )),
)

// 設定: 更新ログ・書き出しの入口
ExamPrepSettingsTiles(
  exportUnlocked: isPremium,
  onOpenUpdateLog: (c) => Navigator.of(c).push(MaterialPageRoute<void>(
    builder: (_) => UpdateLogView(entriesFuture: loadMyUpdateLog()))), // recentUpdates(parseUpdateLogJsonl(text).entries, now, examId: ...)
  onOpenExport: (c) => Navigator.of(c).push(MaterialPageRoute<void>(
    builder: (_) => HistoryExportView(records: history, questions: allQuestions))),
)
```

- `ExamPrepCard`: 10分プランは `buildTimeBoxedPlan`、試験直前は `buildExamEveSet` / `examEveStatus`。試験直前の期間なら10分プランの先頭に直前セットを入れる。未解放の行をタップしたときは `onLockedTap`（省略時は「プレミアムで使えます」のスナックバー）
- `ExamDayChecklistView`: 項目は `ChecklistItem`。`officialConfirmed: false` の項目には「公式で要確認」（`note` があれば併記）を出す。`defaultExamDayChecklist(examId:, venue:)` で一般項目だけを取り出して、足し引きしてから `items` に渡してもよい
- `HistoryExportView`: CSV は `historyCsvText`（氏名・ID・端末情報・問題文を含めない）。保存・共有のプラグインは足さず、表示とコピーのみ
- 次の一手（`next_step`）の画面は含まない

## ホーム画面の分類（`HomeSection` / `HomeMenuTile` / `HomeMenuGrid`）

見出しの無い縦一列を、分類ごとに見出し付きでまとめるための部品（`ui.dart`）。文言は持たない（見出し・ラベルはアプリが渡す）。色・角丸は `ColorScheme` から取るのでアプリのテーマに馴染み、ダーク対応。

### 標準の並び（全アプリ共通）

① 今日やること ② 記録 ③ 試験に向けて ④ 道具 ⑤ 体験ラボ（G検定・生成AIのみ）⑥ 設定・その他。推しカードと推しの一言は画面最上部にそのまま置く。

```dart
ListView(children: [
  const OshiHomeCard(/* 推しカード・一言は最上部 */),
  HomeSection(
    title: '今日やること',
    leading: const Icon(Icons.today),
    child: Column(children: [
      HomeMenuTile(icon: Icons.play_arrow, title: '今日の一問', badge: const HomeMenuBadge.dot(), onTap: openDaily),
    ]),
  ),
  HomeSection(
    title: '記録',
    child: HomeMenuGrid(items: [
      HomeMenuItem(icon: Icons.bar_chart, title: '成績', onTap: openStats),
      HomeMenuItem(icon: Icons.book, title: '間違いノート', badge: HomeMenuBadge.count(3), onTap: openNotes),
    ]),
  ),
  // 数が多いグループは畳む。開閉の保存はアプリ側（core は永続化しない）
  HomeSection(
    title: '体験ラボ',
    collapsible: true,
    initiallyExpanded: false,
    expandedListenable: labExpanded, // 任意。ValueNotifier<bool>
    onExpandedChanged: (v) => prefs.setBool('lab_expanded', v), // 任意
    child: HomeMenuGrid(items: labItems),
  ),
]);
```

- `HomeMenuTile`: 1 列、最小高さ 48dp。バッジは `HomeMenuBadge.dot()` / `.count(n)`（99+、0 以下は非表示）/ `.label('NEW')` / `.premium()`
- `HomeMenuGrid`: 2 列。幅 360 未満・文字倍率 1.3 超で 1 列に自動フォールバック（`minWidthForTwoColumns` / `maxTextScaleForTwoColumns` で調整可）
- `HomeSection`: `collapsible: false`（既定）なら常に表示。折りたたみは「動きを減らす」設定でアニメーションなし
- 実機での見た目の確認と各アプリへの適用は別途
