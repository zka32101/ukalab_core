# 観点を変えた出題（multi-angle）設計書

状態: 設計案（コード変更なし。決定はオーナーの承認後に `DECISIONS.md` へ追記）
対象: ukalab_core v0.74.0 の次の minor（v0.75.0 想定）以降

## 0. 目的と現状

広告コンセプト（`docs/marketing_concept.md`、PR #110）の「同じ用語・概念を、別の角度で繰り返し解く」を**事実にする**ための設計。現状は次のとおりで、広告に使える根拠がない。

- `QuestionType` は `choice / journal / worksheet / ledger`。README「まだ入っていないもの」に ○×・数値などが未実装とある。
- `Question` に「どの用語・概念の問題か」を表す項目がない。近いのは `topicId`（章）・`subtopicId`（細目）・`compareWith`（比較相手の `termId`）だけ。
- `Term.relatedQuestionIds` による用語→問題の逆リンクはあるが任意で、G検定は 399 用語中 370 が問題 1 本、ITパスは `relatedQuestionIds` が空。
- `Srs`（qid 単位の Leitner）と `ReviewSchedulerEngine`（間違いノート対象）はどちらも同じ問題を同じ形で再出題する。

方針: 既存データを壊さず、**任意項目の追加＋新しい問題タイプ＋検証＋SRS の出題形式ローテーション**で段階的に実現する。広告の文言は、計測値が基準を満たすまで使わない（§6）。

## 1. データモデル（後方互換）

### 1.1 追加項目（すべて任意）

| 項目 | 型 | 意味 |
|---|---|---|
| `conceptId` | `String?` | 用語・概念の安定ID。**用語データの `termId` と同じ値を使う**（用語カードがある概念）。用語カードを持たない概念（計算手順など）は `c-` 接頭辞の独自ID。不変（改名しない。廃止は `disabled`） |
| `angle` | `QuestionAngle?` | 出題の観点（下記） |

```dart
enum QuestionAngle { definition, scenario, comparison, reverse, cloze, trueFalse }
```

- `definition`: 定義・性質を問う（用語→意味）。
- `scenario`: 事例・場面に当てはめる。
- `comparison`: 紛らわしい相手との違い（`compareWith` と併用可）。
- `reverse`: 説明文から用語を当てる（意味→用語）。
- `cloze`: 文章の空欄補充。
- `trueFalse`: 命題の正誤判断。
- `angle` は**問題の形式（`QuestionType`）とは別軸**。例: `choice` で `scenario`、`trueFalse` で `definition` もあり得る。

### 1.2 JSON とシリアライズ

- JSON キーは `conceptId` / `angle`（文字列は enum 名）。未指定なら `toJson` に出力しない（現行の `subtopicId` と同じ作法）。
- `fromJson` は未知の `angle` を `fail`（`type` と同様）。`conceptId` は空文字不可。
- 既存の問題 JSONL は無変更で読める。`conceptId` 未設定の問題は「観点カウントの対象外」と扱い、出題・採点・SRS は従来どおり。
- `conceptId` が無い問題の暫定扱い: 検証・集計では `compareWith` 空かつ `Term.relatedQuestionIds` に載っている場合に限り、**逆リンクから推定した概念ID**を補助的に表示する（保存はしない）。移行の足場であり、広告判定には使わない。

### 1.3 アプリの段階的移行

1. core を更新（`ref` を新タグへ）。何も変えなくても動く。
2. 用語を持つ問題から `conceptId` を付与（`Term.relatedQuestionIds` を機械的に流用できるものは補助スクリプトで提案 → 人が確認）。
3. 観点の足りない概念へ新しい問題（§2）を追加。
4. 検証の警告 → 閾値達成 → エラー化（§3）。アプリごとに独立して進められる。

## 2. 新しい問題タイプ

`QuestionType` に `trueFalse`, `cloze`, `reverseLookup` を追加する（既存値の順序・名前は変えない）。`fromJson` は型ごとの必須項目を `switch` で検査する現行方式を踏襲。

### 2.1 データ形

```jsonc
// trueFalse
{"type":"trueFalse","prompt":"…という説明は正しい。","answerBool":true, ...共通項目}
// cloze（空欄は prompt 中の {{1}} {{2}}。選択肢つきと自由入力の両対応）
{"type":"cloze","prompt":"…は{{1}}であり、{{2}}とは異なる。",
 "blanks":[{"id":1,"answers":["過学習","オーバーフィッティング"],"choices":["過学習","学習不足","正則化"]},
           {"id":2,"answers":["…"]}], ...}
// reverseLookup（説明→用語）
{"type":"reverseLookup","prompt":"次の説明にあたる用語は何か。","clue":"…",
 "answers":["…"],"choices":["…","…","…","…"] /* 省略時は自由入力 */, ...}
```

- 共通項目（`qid / examId / subjectId / topicId / explanation / source / sourceRef / contentVer` など）は現行どおり必須。
- 別の `Question` サブクラスは作らず、現行どおり型ごとのフィールドを持つ（`journalAnswer` 等と同じ流儀。`trueFalseAnswer` 等のまとまりにしてもよい。実装時に決定）。

### 2.2 採点

- `trueFalse`: `answerBool` との一致。
- `cloze` / `reverseLookup`（自由入力）: 正規化（NFKC・前後空白除去・全半角/大小文字・長音/中黒の揺れ・ひらがな/カタカナ同一視はしない＝用語の綴りを問うため）後に `answers` のいずれかと完全一致。部分点なし（`cloze` は空欄ごと正誤、問題全体は全空欄正解で正解。`points` は問題単位のまま）。
- 選択肢つき（`choices` あり）は選択式と同様に番号で判定。
- 採点関数は純Dart（`lib/engine/answer_check.dart` 案）に置き、`journal_judge.dart` と同じ位置づけ。
- 自由入力は**打ち間違いを不正解にしすぎない**ため、初期は選択肢つきを既定とし、自由入力は「入力後に『合っていた』と自己申告できる」補助を UI に用意する（§2.3、オーナー確認事項）。

### 2.3 アクセシビリティ・UI

- ウィジェット案: `TrueFalseQuestionView` / `ClozeQuestionView` / `ReverseLookupQuestionView`。既存の選択式ビューと同じ「解答→解説→`AnswerFeedbackPanel`」の流れにそろえる。
- ○×は色だけで判別させない（「○ 正しい」「× 誤り」と文字・アイコン併記）。ボタンの最小タップ領域 48dp、`Semantics` で「正しい／誤り」を読み上げる。
- 空欄は `{{n}}` を視覚的な枠と `Semantics(label: '空欄n')` で示す。自由入力は `TextField` に `autofillHints` を付けず、IME 変換確定後に判定（変換中は判定しない）。
- 文字サイズ（OS 設定の拡大）で空欄が崩れないよう折り返し可能なレイアウトにする。
- 選択式との共存: `PracticeSession` / `pickMockExamQuestions` は `type` を意識せず `Question` を扱う。模擬試験は実試験の形式に合わせ、**`QuestionType` ごとの出題比率は ExamConfig で指定可能**にする（既定は選択式のみ。新タイプは学習モード優先で、模擬試験には既定で入れない）。
- 解答記録（`ProgressRecord`）は `qid` と正誤を持つ現行形のまま。選んだ値が必要な型は追加項目を任意で足す（後方互換）。

## 3. 検証 CLI と集計

### 3.1 `validate_content` の新ルール

| ルール | 内容 | 初期 | 最終 |
|---|---|---|---|
| `angle-without-concept` | `angle` があるのに `conceptId` が無い | 警告 | エラー |
| `concept-unknown` | `conceptId` が用語データにも独自ID一覧にも無い | 警告 | エラー |
| `concept-single-angle` | 概念あたり**異なる `angle` が 2 未満**（`disabled` は除外） | 警告 | エラー（対象は「観点必須」指定の概念のみ） |
| `angle-duplicate` | 同一概念・同一 `angle` の問題が同文面（正規化後） | 警告 | エラー |
| `type-fields` | 新タイプの必須項目・空欄番号の整合・`answers` 空 | エラー | エラー |

- 警告は終了コードに影響しない。`--strict-angles` で警告をエラー扱いにする（アプリ側 CI が任意に有効化）。既存の「問題が 1 件でもあれば終了コード 1」は維持。
- 概念ごとに必須の観点数を変えたい場合のため、用語データに任意項目 `minAngles`（既定 2）を設ける案。数が少ない概念（固有名詞など）は 1 を許容。

### 3.2 カバレッジレポート

`dart run ukalab_core:validate_content ... --angle-report=json|md` で出力（`tools/question_quality/` の Python 側には `angle_coverage.py` として同じ集計を置き、`run_checks.py` から呼べる形に）。

- アプリ別・観点別・概念別の表: 概念数、`conceptId` 付与率、2 観点以上の概念数と率（**分母は有効な用語/概念の総数**、分子は有効問題で 2 観点以上を持つ概念）、観点別の問題数、観点が 0/1 の概念のリスト。
- 機械可読な JSON を出し、広告ゲート（§6）がそのまま読む。出力は決定的（ソート済み）にして CI で差分が見えるようにする。
- 品質チェック（長さ・断定語）は新タイプにも流用するが、選択肢のない型は対象外とする。

## 4. SRS との連携

現状の `Srs` は `qid` 単位。変更は**追加のみ**とする。

- 新しい状態 `ConceptSrsItem(conceptId, box, dueAt, lastAngle, angleHistory)` を別クラスで用意（`SrsItem` は無変更）。`conceptId` を持つ問題を持つ概念だけ概念単位で管理し、持たない問題は従来の `qid` 単位のまま併存。
- 復習の期限が来た概念に対し、**直近に出していない観点の問題**を選ぶ（`angleHistory` の古い順 → 未出題の観点を優先 → 無ければ同一観点の別問題）。不正解のときは同じ観点を一度だけ再提示せず、より易しい観点（`definition` / `trueFalse`）へ寄せる。
- 正誤は概念の箱に反映（観点間で正解が積み上がるほど箱が上がる）。同じ観点の連続正解では箱を上げすぎない（上限は箱 3 までなど、暫定。オーナー確認）。
- `ReviewSchedulerEngine`（間違いノート対象）も同様に、`MistakeNoteEntry` に `conceptId` があれば出題時に観点をローテーションする。入力は後方互換。
- 保存形式は JSON に往復でき、`SharedPreferences` のキーは新規（`ukalab_<app>_concept_srs`）。バックアップ対象に追加する。

## 5. アプリ別ロールアウトとコンテンツ品質

### 5.1 順序

1. **G検定（先行）**: 399 用語、うち 370 が問題 1 本。まず `conceptId = termId` を付与し、概念ごとに `reverse` と `trueFalse`（量産しやすく誤り検出もしやすい）を追加して 2 観点を確保。優先は出題頻度の高い章。目標は §6 の基準まで。
2. **ITパス**: `relatedQuestionIds` が空のため、先に用語↔問題のリンクを補う（`compareWith` と `relatedQuestionIds` の整備）。その後 G検定と同様。
3. その他のアプリ: 用語カードの有無で着手順を決める。漢検は意味の下書きが AI 生成で未確認のため、確認が済むまで対象外（`marketing_concept.md` の注意に従う）。

### 5.2 コンテンツ品質ルール

- **すべて自作の問題**にする。過去問・市販問題集・他社アプリの文面を転記・微修正しない（`source: original`）。公式の用語定義を使う場合は出典を `sourceRef` に残し、言い回しは自分の言葉にする。
- AI 下書きの問題は `tags` に `ai-draft` を付けて識別し、**人が事実確認した後に外す**。`ai-draft` が残る問題は広告判定の分子に数えない（§6）。ストアの AI 利用申告と整合させる。
- 専門確認（資格の内容に詳しい人のレビュー）を、各アプリの最初の量産バッチ（概念 20 件程度）で必ず通す。新しい事実を作らない（`DECISIONS.md` のレビュー運用に従う）。
- ○×は「ひっかけ」ではなく理解を確かめる命題にする。誤りの命題は**もっともらしい典型的な誤解**に基づかせ、解説で正しい記述を示す。
- 既存の観点（重複・答え漏れ・断定語など。`docs/question_quality_viewpoints.md`）に、「同一概念内で同じ答えの言い換えだけになっていないか（観点の水増し）」を追加する案。

## 6. 広告表現のゲート

- 「同じ用語を別の角度で」を打ち出してよい条件（アプリ単位）:
  - カバレッジレポートで、**有効概念のうち 2 観点以上を持つ概念の割合が X% 以上**。提案: **X = 60**（最初のストア公開表現）。「全用語で」「すべての問題で」の表現は X = 95 かつ `ai-draft` なしの場合のみ。
  - 分子に数える問題は `ai-draft` が付いておらず、専門確認済み（レビュー記録あり）のもの。
  - `conceptId` 付与率が 90% 以上（付与されていない問題が多いと分母が小さく見えるため）。
- 条件を満たさないアプリは、観点訴求の文言を出さず「シラバスに沿って」等の別の訴求だけにする。
- 判定は**レポートの JSON を根拠として残す**（日付・コミット・数値）。数値が基準を下回ったら表現を取り下げる。
- 効果の断定（「身につく」「点数が上がる」）はしない。非公式であることの併記を維持（`marketing_concept.md`）。ゲートは CI のエラーにはせず、リリースチェックリストの項目とする。

## 7. バージョニング・テスト・未決事項

### 7.1 semver

- 追加のみ（任意項目、enum 値の追加、新規クラス、検証は既定で警告）なので **minor（v0.75.0）**。
- 注意点: `QuestionType` に値を足すと、アプリ側で `switch (type)` を網羅しているコードが非網羅警告になる。CHANGELOG の移行欄に明記し、既存アプリが新型を含むデータを読まない限り動作は変わらない。
- `--strict-angles` や必須化（エラー化）を既定にする時点は別の minor で告知してから行う。

### 7.2 テスト計画

- モデル: `Question.fromJson/toJson` の往復（新旧データ）、未知 `angle`/`type` のエラー、`conceptId` 空文字。
- 採点: 正規化の境界（全半角・空白・長音・複数正解）、`cloze` の部分正解。
- 検証: 各ルールの正例/負例、`disabled` 除外、警告と終了コード、`--strict-angles`。
- レポート: 固定の小さな JSONL からの期待 JSON（スナップショット）、空データ、分母 0。
- SRS: 観点ローテーション（直近観点を避ける、全観点出題済み時）、不正解時の観点、`conceptId` 無し問題との併存、日付固定。
- ウィジェット: 各ビューの表示・Semantics・文字拡大 2.0 倍・色に依存しない表示。
- 例データ: `example/` に架空の概念で 3 観点以上のサンプルを追加（実在の試験の問題は使わない）。

### 7.3 オーナーに決めてほしいこと

1. `conceptId` を `termId` と同一にする方針でよいか（用語カードが無い概念の独自ID規則も含む）。
2. §6 の X（60% / 95%）と `conceptId` 付与率 90% の基準値。
3. 自由入力（`cloze` / `reverseLookup`）を初期から出すか、選択肢つきのみで始めるか。
4. 模擬試験に新タイプを入れるか（既定は入れない案）。
5. 概念SRSで観点間の箱の上がり方（同一観点連続正解の上限）。
6. `ai-draft` タグ運用と、専門確認の担当・記録の置き場所。
7. 先行アプリを G検定でよいか、実装の担当順（モデル → 検証/レポート → UI → SRS の 4 PR 程度に分割する想定）。
