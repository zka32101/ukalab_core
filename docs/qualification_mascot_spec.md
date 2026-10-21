# 資格専用キャラ 仕様書

対象: ukalab_core v0.78.0 時点。最初の対象は ITパスポート（`ukalab_it_passport`）。
状態: 画像担当へ引継ぎ可（ITパスポート用「サーキ」、キャラid `circa`。§8 の引継ぎ文を使える）。
この文書は仕様書のみで、コード・画像は変更しない。画像は別セッション（画像担当）が作り、コード取り込みは本セッション側が担当する。

決定事項（依頼元からの指定）:

- 1資格に1体
- 既存4体（kai, mio, moka, mike）とは別の新規キャラ
- 成長段階（Lv1〜5）まで作る
- 画像はAI生成
- 最初の対象は ITパスポート
- ITパスポート用は案1「サーキ」（キャラid `circa`）で確定。画像は A+B+C の全39枚、scenes は 460x700 に統一


---

## 決定事項（案B）（2026-10-20）

`docs/qualification_mascot_candidates.md` §2 の選択肢のうち **案B** を採用する。ユーザー決定は「資格ごとにキャラを作る」。

### 決定内容

- サーキ（`circa`）は **ITパスポート専用**。`appIds` は `{'it_passport'}` のみに絞る。
- 他の資格は、資格ごとに専用キャラを1体ずつ作る（1資格に1体）。
- モチーフは candidates.md §6 の推奨案を採用する（簿記3級=ソロ、危険物乙4=サラ、漢検=タツ を含む）。
- 画像制作は、アプリがある7資格を先に行う（詳細は `docs/qualification_mascot_image_briefs.md`）。アプリが無い9資格と生成AI導入実務者検定は将来（同ドキュメントの「将来」節）。

### appIds 割当（予定）

| キャラ | id | appIds | 備考 |
|---|---|---|---|
| サーキ | `circa` | `{'it_passport'}` | 現行コードの `{'g_kentei','it_passport','info_security','gen_ai_passport'}` から絞る（PR-D） |
| ノーダ | `noda` | `{'g_kentei'}` | |
| ヒラリ | `hirari` | `{'gen_ai_passport'}` | |
| シェル | `sheru` | `{'info_security'}` | |
| ソロ | `soro` | `{'boki3'}` | 資格id（`UkalabCert`）の綴り。アプリ側の識別子と一致するかは PR-D で確認 |
| サラ | `sala` | `{'hazmat4'}` | 同上 |
| タツ | `tatsu` | `{'kanji_kentei'}` | 同上。漢検は独自 `PurchasesService` のため配線は別扱い（§6.4 の8） |

`appIds` の値は、既存の `circa` と同じく資格id（`UkalabCert`）の綴りに合わせる。

### 後続 PR 計画（更新版）

| PR | 内容 | 状態 |
|---|---|---|
| PR-A | キャラ別の画像制作と取り込み（`assets/mascot/<id>/`、pubspec 登録、画像存在テスト）。サーキ（39枚）と、7資格の新規6体（各 A+B=36枚） | 画像制作は別セッション。取り込みはキャラ単位で分割可 |
| PR-B | サーキのモデル・定義・文言（UI未配線） | 済み（#134） |
| PR-C | 選択UI（プレミアム限定のロック表示、購入導線、失効時のフォールバック。§6.4） | 実装済み（0.81.0。末尾「実装状況（PR-C）」） |
| PR-D | アプリ別配線。`circa.appIds` を `{'it_passport'}` に絞る1行を含む。各キャラの `appIds` 設定と、各アプリでの権利判定の渡し方。漢検は統一作業の後に別扱い | 未着手 |

各 PR は minor バージョン扱い。本ドキュメント PR にはタグを付けない。空ディレクトリはビルドを壊すため、画像を伴わないキャラの assets 登録は先行させない。

### 追記（2026-10-20）: 画像の納品範囲の変更

変更: 画像は A（必須13枚）+ C（小物 2〜3枚）を作り、**B（推奨23枚: scenes 10 + states 5 + guide 3 + poses 5）は作らない**。対象は新規6体（ノーダ・シェル・ヒラリ・ソロ・サラ・タツ）とサーキ（`circa`）の全員。サーキの B も作らない。

- 変更: PR-A（画像）の枚数。旧: サーキ39枚（A+B+C）、新規6体は各36枚（A+B）。新: サーキ16枚（A13 + C3）、新規6体は各15〜16枚（A13 + C2〜3）。合計は 106〜112枚（詳細は image_briefs.md 冒頭）。上の PR-A 行と §2.1・§7 U2 の旧記述（39枚、A+B+C）は残してあり、この追記が優先する。
- 影響: B 画像が必要な画面（場面別 `scenes`、状態 `states`、ガイド `guide`、ポーズ `poses`）では、資格専用キャラの画像が存在しない。PR-C で、他キャラの画像または汎用表示へフォールバックする実装が必要（§6.3 の確認事項を必須とする）。フォールバックが無いまま表示コードを通すと画像の欠落になる。
- テストの影響: 既存の画像存在テスト（場面別・全 `MascotScene` x 全Lv）を、資格キャラでは B を要求しない形にする必要がある。
- 「画像を伴わないキャラの assets 登録は先行させない」「pubspec は B のディレクトリ（`scenes/` `states/` `guide/` `poses/`）を登録しない」点に注意（空ディレクトリはビルドを壊す）。

### 旧案（案A前提）との関係

以下は案A（情報系4資格でサーキ共用）を前提にした記述で、案B の決定により置き換わる。削除せず「旧案」として残す。

- 旧案: 現行コードの `circa.appIds = {'g_kentei', 'it_passport', 'info_security', 'gen_ai_passport'}`（情報系4）。案Bでは `{'it_passport'}` のみ。
- 旧案: candidates.md §2 の「サーキの扱いの食い違い」の選択肢A。案Bの採用で解消。
- 旧案: 後続PRの内訳がサーキ1体のみを前提にしていた点（上の PR 計画が最新）。
- 本文 §3 の「他資格に広げるときのモチーフ設計方針」は引き続き有効。§7 の U6 は candidates.md §6 の推奨案で埋まる。

---

## 1. 現状の構成と取り込みの仕組み

読んだ事実のみ。推測は「推測」と明記する。

### 1.1 フォルダ構成（`assets/mascot/`）

- キャラ別フォルダ: `kai/` `mio/` `moka/` `mike/`（各90ファイル、kai の合計は約3.8MB。`assets/mascot/` 全体は約18MB）
- 共通フォルダ: `rooms/`（部屋背景）、`props/`（小物）、`medals/`（資格ごとの合格メダル `<certId>_medal.webp`）
- 1体あたりの構成（kai で確認。mike も同じファイル名構成）

| 置き場所 | ファイル名 | 枚数 | 実サイズ（px、幅x高さ） |
|---|---|---|---|
| 直下 | `<id>_icon_256.webp` | 1 | 256x256 |
| 直下 | `<id>_lv<1-5>_<normal\|joy>.webp` | 10 | 336x512（ほぼ共通） |
| 直下 | `<id>_special_pass.webp` / `<id>_special_bow.webp` | 2 | 336x512 / 341x512 |
| `scenes/` | `<id>_lv<1-5>_<eve\|back>.webp` | 10 | 460x700 が8枚、736x1120 が2枚（不揃い） |
| `states/` | `<id>_<empty\|error\|loading\|welcome\|streak>.webp` | 5 | 高さ512、幅209〜244 |
| `guide/` | `<id>_guide_<point\|think\|teach>.webp` | 3 | 736x1120 |
| `poses/` | `<id>_<thinking\|cheer\|hint\|rest\|fight>.webp` | 5 | 高さ512、幅177〜328 |
| `items/` | `<id>_<小物名>.webp` | 3 | 高さ512、幅164〜261。小物名はキャラごとに違う（kai: drone/hachimaki/helmet） |
| `outfits/` | `<certId>_<normal\|pass\|exam>.webp` | 51（17資格x3） | 736x1120。バイク免許のみ `bike_license_lv5` が加わり exam なし |

- 形式はすべて webp、色モードは RGBA。確認した画像の左上ピクセルのアルファは0で、背景は透過（確認したのは一部の画像。全数確認はしていない）。
- 容量: kai のルート直下の webp は 1枚あたり約13KB〜33KB（icon 約13KB、Lv 画像 約19〜31KB）。衣装フォルダ（51枚）で約2.7MB（1枚あたり約50KB強）。
- 命名規則: 小文字・英数字・アンダースコア。`<キャラid>_<要素>.webp`。キャラid（`kai` など）がファイル名の先頭に付く。
- 色モードRGB（透過なし）の画像は `rooms/` の背景のみ（`room_it.webp` 1120x736 を確認）。

### 1.2 コード側の仕組み

- キャラ定義: `lib/ui/mascot/ukalab_characters.dart` の `UkalabCharacters`。
  - 各キャラは `CharacterPack`（`id`, `name`, `tone`, `imageBuilder`, `outfitImageBuilder`, `sceneImageBuilder`）として `static const` で定義される。
  - 一覧は `all`（標準キャラ「うか」＋画像4体）と `imagePacks`（画像4体）。`byId(id)` は不明な id を標準キャラに戻す。
  - 画像パスは `assets/mascot/<id>/...` を文字列で組み立て、`AssetImage(..., package: 'ukalab_core')` で返す。ファイルが存在するかの実行時チェックはない（存在はテストで保証している）。
  - `_kaiImage` `_kaiOutfit` `_kaiScene` のような、キャラごとの薄いラッパー関数が1体につき3つ手書きされている。
- 型・列挙: `lib/ui/mascot/mascot_models.dart`。`MascotStage`（Lv1〜5）、`MascotExpression`（normal/joy）、`MascotScene`、`MascotPose`（thinking/cheer/hint/rest/fight）、`MascotState`（empty/error/loading/welcome/streak）、`MascotTone`（gentle/cool/cheerful/relaxed）、`CharacterPack`。
- 表示: `mascot_widget.dart`（`MascotWidget`）、`mascot_state_view.dart`、`oshi_home_card.dart`、`teach_mascot.dart`、`outfit/wardrobe_screen.dart` など。いずれも `CharacterPack` のビルダー経由で画像を取る。
- 選択: `lib/ui/mascot/character_selection.dart`。`CharacterSelectScreen` は `UkalabCharacters.all` を並べて表示し、選んだ `id` を `SharedPreferences` のキー `ukalab.mascot.selected` に保存する。キーはうかラボ共通。
- 表示名・役割文: `lib/ui/ukalab_strings.dart` の `characterNames` / `characterRoles`（`CharacterPack.id` をキーにした Map。日本語と英語がある）。
- 衣装: `UkalabCharacters.costumedCerts`（17資格）と `outfitFile()`。資格ごとの衣装画像（通常/合格記念/試験日）が各キャラの `outfits/` にある。
- 登録: `pubspec.yaml` の `flutter: assets:` に、キャラごとに7ディレクトリ（`<id>/`, `outfits/`, `scenes/`, `guide/`, `poses/`, `states/`, `items/`）を列挙している。ディレクトリ登録なので、既存ディレクトリ内にファイルを足すだけなら pubspec の変更は不要。新キャラのフォルダは登録の追加が必要。
- テスト: `test/ui/ukalab_characters_test.dart` ほか。`imagePacks` の全キャラについて、icon・Lv x 表情・場面別（全 `MascotScene` x 全Lv）・衣装（全17資格）の画像ファイルが存在することを検査している。`all.length` が 5 であることも検査している。
- 既存キャラ設計資料: `docs/` には画像キャラの設計資料は見当たらなかった。関連する記述は `README.md`「キャラ・メダル画像」節（webp・長辺512、AI生成は Leonardo.Ai Phoenix / Nano Banana、規約版・プランは公開前に確認）、`docs/DECISIONS.md`（衣装画像はユーザーが別セッションで作成）、`docs/ui.md`（`CharacterPack(imageBuilder: ...)` でAI画像パックを渡せる）、`docs/store_listing_drafts.md`（AI画像の記載）。

### 1.3 推測（未確認）

- 長辺512は「ゲーム内表示で十分、容量を抑える」ための値と推測する。
- Lv画像 336x512 の比率は約 0.66。立ち絵の縦長比率にそろえたものと推測する。
- 既存4体の見た目（人型か動物型か、色、モチーフ）は、この調査では画像を目視していない。画像担当は必ず既存4体の全身 Lv1〜5 を見てから作業すること。
- 既存キャラの「サイズ不揃い」（scenes、states、poses）は、生成後に余白を切り詰めた結果と推測する。

---

## 2. 資格キャラの必須画像セット

フォルダ配置: `assets/mascot/<キャラid>/`（サブフォルダは既存と同じ）。
`<キャラid>` は英小文字・数字・アンダースコアのみ。既存4体と衝突しない短い名前にする。ITパスポート用は `circa`（確定）。以下 `<id>` と書く。

### 2.1 優先度

| 区分 | 内容 | 枚数 |
|---|---|---|
| A 必須（最初の納品） | icon 1 + Lv1〜5 x normal/joy 10 + special_pass 1 + special_bow 1 | 13 |
| B 推奨（既存4体と同等の表示を満たす） | scenes 10 + states 5 + guide 3 + poses 5 | 23 |
| C 任意 | items（小物。キャラ固有に2〜3枚） | 2〜3 |
| 不要（提案） | 衣装 `outfits/`（17資格x3）。資格専用キャラはその資格の姿が基本なので作らない案 | 0 |

A だけで 13枚、A+B で 36枚、C まで含めて 39枚（サーキは C を3枚作る。決定済み）。
B を作らない場合、現行の表示コードは場面別・ポーズ・状態の画像を要求するため、コード側でフォールバック（Lv画像で代用）を用意する必要がある（§6）。

### 2.2 ファイル名一覧（A+B）

```
assets/mascot/<id>/
  <id>_icon_256.webp
  <id>_lv1_normal.webp  <id>_lv1_joy.webp
  <id>_lv2_normal.webp  <id>_lv2_joy.webp
  <id>_lv3_normal.webp  <id>_lv3_joy.webp
  <id>_lv4_normal.webp  <id>_lv4_joy.webp
  <id>_lv5_normal.webp  <id>_lv5_joy.webp
  <id>_special_pass.webp
  <id>_special_bow.webp
  scenes/<id>_lv1_eve.webp  <id>_lv1_back.webp   （Lv2〜5も同様、計10）
  states/<id>_empty.webp  <id>_error.webp  <id>_loading.webp  <id>_welcome.webp  <id>_streak.webp
  guide/<id>_guide_point.webp  <id>_guide_think.webp  <id>_guide_teach.webp
  poses/<id>_thinking.webp  <id>_cheer.webp  <id>_hint.webp  <id>_rest.webp  <id>_fight.webp
  items/<id>_<小物名>.webp  （任意）
```

### 2.3 サイズ・形式・透過

| 区分 | サイズ（px） | 備考 |
|---|---|---|
| icon | 256x256 | 顔アップ。丸く切り抜かれても顔が欠けない配置 |
| Lv画像・special | 336x512（幅x高さ）を基準 | 全身。5段階で足元の位置（下端）をそろえる |
| scenes | 460x700 に統一（確定） | 同一キャラ内で全10枚を同サイズにそろえる |
| guide | 736x1120 | |
| states・poses | 高さ512、幅は内容に合わせる（約170〜330） | 高さ512に統一 |
| items | 高さ512、幅は内容に合わせる | |

- 形式: webp（RGBA）。png や jpg での納品は不可。
- 背景: 透明（アルファ）。背景色・影の四角・白フチの残りがないこと。半透明のふちは可（拡大時に白い輪郭が出ないこと）。
- 左右: キャラが画像の端で切れない。余白は上下左右とも数px〜20px程度。
- 容量の目安: Lv・special・icon は 1枚 40KB 以下、scenes・guide は 1枚 150KB 以下、states・poses・items は 1枚 60KB 以下。フォルダ全体で 1.5MB 以下（A+B）。目安であり、既存（kai は約3.8MB で衣装込み）を超えない範囲。

### 2.4 納品チェックリスト

- [ ] フォルダ名・ファイル名が §2.2 と完全一致（小文字、拡張子 `.webp`）
- [ ] 枚数: A 13枚（必須）、B 23枚（推奨）
- [ ] 全ファイルが webp、RGBA、背景が透明
- [ ] サイズが §2.3 の範囲（icon は正方形 256x256）
- [ ] 容量が目安以内
- [ ] Lv1〜5 で同一キャラと分かる（顔・配色・特徴が共通）。Lv が上がるごとに成長が分かる
- [ ] normal と joy で表情だけが変わり、体型・服装が変わらない
- [ ] 既存4体と並べて見分けがつく（シルエット・主色が違う）
- [ ] 画風が「少しかわいらしい」範囲で、既存4体とトーンが大きく乖離せず、子ども向けに寄りすぎていない
- [ ] 文字・ロゴ・商標・試験団体のマーク・「公式」「認定」の表記が画像内にない
- [ ] 生成に使ったサービス名・日付・プロンプトの控えを別添（§5）
- [ ] 個人名、実在人物の顔、署名、透かしがない

---

## 3. ITパスポート用キャラの企画案

方針（オーナー決定）: キャラは「その資格に関連するキャラ」にする。資格の内容・分野を連想させるモチーフを使う。ITパスポートは IT・デジタル・ネットワーク・情報の分野に関連するモチーフを、擬人化または動物化する。

共通方針:

- 見た目は、丸みのあるシルエット・やわらかい線・やさしい表情の、少しかわいらしいタッチ（成人向けなので幼くしすぎない）。
- 既存4体（kai, mio, moka, mike）と見分けがつくこと。主色・シルエット・モチーフを重ねない。
- IPA や情報処理試験の公式キャラ、既存の著名キャラクターに似せない。
- 「公式」「認定」を連想させる見た目（団体ロゴ、紋章、試験団体の配色の再現）を避ける。
- 色は既存の `rooms/room_it.webp` が青系なので、重ならないよう青以外を主色にするのが無難（推測。既存4体の主色は未確認のため、画像担当が確認して調整する）。
- 以下の各案のモチーフは、角ばった機械的な見た目にせず、丸みを持たせて親しみやすく描く。
- 名前「サーキ」・キャラid `circa` は確定（商標・類似の確認はオーナー側で了承済み。確認内容の記録はオーナー側）。

### 案1【採用】: 回路ネコ「サーキ」 — 回路・ハードウェアの連想

- コンセプト: 体の模様が基板の配線パターンになっている小さな猫風の生き物。しっぽの先が小さなコネクタ。耳が小さなチップ形。
- 性格: 几帳面で、仕組みを理解するのが好き。
- 成長段階: Lv1 配線が数本 → Lv3 配線が広がり小さなLEDが点く → Lv5 全身の回路が光り、しっぽのコネクタが完成する。
- 資格との関連: ITパスポートのテクノロジ分野（ハードウェア・基盤）。
- 避ける点: 既存4体の1つ（mike）が猫風である可能性があるため、動物種は既存4体を確認してから決める（推測。未確認）。

### 案2【不採用】: データのきつね「ビット（案の仮名）」 — データ・情報の連想

- コンセプト: 0と1、四角いデータブロックが尻尾や耳飾りになっている小さなきつね風の生き物。尻尾がデータブロックの束。
- 性格: 賢く、整理整頓が得意。情報を探すのが好き。
- 成長段階: Lv1 ブロック1個の尻尾 → Lv3 ブロックが連なる → Lv5 ブロックが並んだ立派な尻尾。
- 資格との関連: 情報・データ、ストラテジ（経営・情報活用）の分野。
- 避ける点: 著名な狐キャラ・ロボットキャラの意匠を避ける。

### 案3【不採用】: ネットワークのクラゲ「ネッティ（案の仮名）」 — ネットワーク・クラウドの連想

- コンセプト: ふわふわ浮かぶクラゲ風の生き物。触手が通信線になり、頭の傘が雲（クラウド）の形。
- 性格: おっとりしていて、みんなをつなぐのが好き。
- 成長段階: Lv1 触手2本 → Lv3 触手が増えて小さな光が流れる → Lv5 触手が網目状につながり光が行き交う。
- 資格との関連: ネットワーク・クラウド・情報セキュリティの入口。
- 避ける点: 既存の著名な雲キャラ・クラゲキャラに似ないよう、顔のパーツは小さく簡素にする。

**決定（オーナー）: 案1「回路ネコ」で確定。案2・案3は不採用（比較の記録として残す）。**
名前「サーキ」・キャラid `circa` で確定（商標・類似の確認はオーナー側で了承済み。確認内容の記録はオーナー側）。以下、キャラid を `circa` として書く。

### 補足案（語呂）: 渡り鳥「（仮）ワタリ」

「パスポート」の語呂から連想する旅の渡り鳥案。資格の内容との関連は弱いため、本採用ではなく補足案とする。合格後のスタンプ（special_pass）に結びつけやすい利点はある。

### 他資格に広げるときのモチーフ設計方針

- 資格の分野から連想する。例: G検定=AI（ニューラルネット・学習する生き物）、情報セキュリティ=守り（盾・鍵・番犬）、危険物乙4=危険物・化学（フラスコ・炎・元素）、簿記=帳簿・数字（そろばん・帳簿・電卓）。例は方針の説明であり、確定案ではない。
- 1資格に1体。既存4体と他の資格キャラのシルエット・主色を重ねない。
- 似せてはいけないもの: 試験団体・省庁の公式キャラ、既存の著名キャラクター、企業ロゴや製品アイコン、実在の人物。
- 「公式」「認定」「提携」を連想させる意匠を使わない。資格名の文字を画像に入れない。
- 手順: 分野のキーワードを3つ挙げる → モチーフ2〜3案 → 類似・商標の検索 → オーナー決定、の順で進める。

---

## 4. AI生成のガイド

### 4.1 統一スタイル指定

- 「スタイル固定文」を1つ作り、全画像のプロンプト冒頭に同じ文をそのまま貼る。固定する要素: 画風（フラット/セル塗りなど）、線の太さ、塗りの質感、色数、頭身、背景（無地で後で透過処理）。
- 画風はオーナー指定で「少しかわいらしいタッチ」。丸みのあるシルエット、やわらかい線、やさしい表情、親しみやすい配色にする。頭身は低めすぎない程度（2頭身より高く、3頭身前後を目安）。
- 注意: うかラボは成人向けアプリ。子ども向けに寄せすぎない（過度に幼い顔・大きすぎる目・幼児向けの色使いは避ける）。大人が学習中に見て落ち着ける、ほどよいかわいらしさにする。
- 既存4体とのトーン整合: 作業前に既存4体の Lv1〜5 を並べて見て、画風・頭身・線の太さ・彩度を確認する。既存と大きく乖離しない範囲でかわいらしさを足す（確認手順は省略しない）。サービスにスタイル参照機能があれば、既存キャラそのものではなく、新キャラのリファレンス画像を使う。
- 主色・差し色は16進数カラーコードで固定する（例: 主色、差し色、線色の3色）。

### 4.2 同一キャラを保つ手順

1. キャラシート（正面・横・背面の全身、顔アップ、表情2種）を最初に1枚決める。これを「リファレンス」とする。
2. Lv3（中間）を先に作る。次にLv1、Lv5の順に、リファレンスから成長差を作る（Lv が変わっても変えない特徴を3つ決めておく。例: 目の形、耳/羽/アンテナの形、主色）。
3. 各画像は、サービスの画像参照（image-to-image やキャラ参照機能）にリファレンスを渡して生成する。シードが固定できるサービスではシードも控える。
4. normal と joy は同じ画像からの派生で作る（表情だけ変更）。
5. 一度に作らず、Lv → special → poses → states → scenes → guide の順に進める。1段階ごとに既存4体と並べて確認する。
6. 背景は単色で生成して後から透過処理する。透過処理後に縁の白いふちを確認する。
7. 出力は長辺を揃えてリサイズし、webp（RGBA）に変換する（品質は容量目安に合わせて調整）。

### 4.3 プロンプト雛形

```
[スタイル固定文]
フラットなセル塗り、やわらかく太さ均一の輪郭線、丸みのあるシルエット、やさしい表情、やわらかい配色、3頭身前後（低すぎない）、成人向けで幼すぎない、全身、正面。
[キャラ固定文]
<キャラ名>: <モチーフ>。主色 #______、差し色 #______、輪郭線 #______。
特徴: <変えない特徴3つ>。
[段階/ポーズ]
Lv<1-5>: <成長の特徴>。表情: <normal=穏やか / joy=満面の笑み>。ポーズ: <立ち / 合格で両手を上げる / おじぎ>。
[背景・禁止事項]
背景は無地の単色。文字、ロゴ、透かし、署名、実在の人物や既存キャラクターに似た要素、試験団体の紋章を入れない。
```

- 実在人物に似せない: 人物の名前・職業を指定せず、人型にする場合も特定の人物（著名人、実在の講師など）を連想させる指定を入れない。
- 生成のたびに、プロンプト、サービス名、日付、保存したファイル名を記録する（§5）。

---

## 5. 権利・表記の注意

- 使用するAI画像生成サービスの利用規約（商用利用、生成物の権利、再配布、アプリへの組み込み、プランごとの条件）は、オーナーが確認済みで問題なし（オーナー確認済み。確認内容の記録はオーナー側にある）。商用利用の可否もオーナー確認済みの扱いとする。この文書にはサービス名・プランは記載しない。画像担当は、使ったサービス名・日付を納品メモに記録する（規約の再確認は不要）。
- AI生成物であることの申告: ストア掲載・アプリ内表記について、各ストアのAI生成コンテンツの申告項目を確認する。既存の `docs/store_listing_drafts.md` の AI画像の記載に合わせ、キャラ追加も同じ扱いにする（記載内容は実装時に再確認）。
- 商標・類似: キャラ名と見た目について、既存の商標・著名キャラとの類似を、公開前に検索で確認する。
- 試験団体との関係: 「公式」「提携」「推奨」を連想させる表記・意匠は使わない。ITパスポートの試験名は、他の資格名と同様に事実の記載の範囲で使う。
- 個人情報・OPSEC: 画像のメタデータ（作成者名、パス、サービスのアカウント情報）を削除して納品する。個人名・共有ドライブのURL・APIキー・アカウント情報を、画像・ファイル名・PR・コミットに含めない。

---

## 6. コード側の取り込み設計案（設計のみ。この時点では実装しない）

### 6.1 方針

- 資格キャラは既存の `CharacterPack` を再利用する。`UkalabCharacters` に資格キャラを追加し、`id` で選べるようにする。
- 「資格専用」の意味を持たせるため、`CharacterPack` に任意項目 `certId`（例 `it_passport`）を足す案。無い場合は通常の推しとして扱われる。
- アプリ側（`ukalab_it_passport`）での選び方: 資格キャラは選択画面に追加し、そのアプリのプレミアム購入者のみ選べる（オーナー決定、§6.4）。既定の推しにはしない。
- 保存キー `ukalab.mascot.selected` はうかラボ共通で、端末内でアプリ間共有される可能性がある（`character_selection.dart` のコメントに同様の記載あり）。他アプリでの扱いは §6.4 の7で吸収する。
- 衣装（`outfits/`）は作らない案。`outfitImageBuilder` は null を返し、通常の画像で表示する（既存の「衣装画像がない資格は私服のまま」と同じ挙動）。

### 6.2 変更が必要なファイル候補

| ファイル | 変更内容 |
|---|---|
| `lib/ui/mascot/ukalab_characters.dart` | 新 `CharacterPack` の定義、`all` / `imagePacks` への追加（または `certPacks` を新設）、画像ビルダー。1体ずつラッパーを書く現行方式は増えるほど冗長になるため、`id` から組み立てる共通関数に整理する案 |
| `lib/ui/mascot/mascot_models.dart` | `CharacterPack` に任意の `requiresPremium`（§6.4）と `certId` と、使える画像のセットを示す項目（例: scenes/states がない場合のフォールバック指定）を追加する案 |
| `lib/ui/ukalab_strings.dart` | `characterNames` / `characterRoles`（日本語・英語）に新キャラを追加 |
| `pubspec.yaml` | `assets/mascot/<id>/` とサブディレクトリ（`scenes/` `guide/` `poses/` `states/` `items/`）を登録 |
| `test/ui/ukalab_characters_test.dart` ほか（`ukalab_medals_test`, `mascot_pose_state_test`, `ukalab_accessories_test`） | `all.length == 5` の更新、新キャラの画像存在確認。衣装テストは「衣装なし」を許容する条件分岐が必要 |
| `lib/ui/mascot/mascot_lines.dart` | 新キャラ固有のセリフがあれば追加（`findForbiddenExpressions` の検査に通すこと） |
| `README.md` / `CHANGELOG.md` | キャラ追加の記載、AI生成素材の記載 |
| `lib/ui/mascot/character_selection.dart` | 資格キャラの並び順・見出し、ロック表示・購入導線（§6.4） |

### 6.3 フォールバック

- 画像Bの一部が無い場合に備え、`sceneImageBuilder` / `poseImage` / `stateImage` が null を返したとき、Lv画像で代用する経路が既存の表示ウィジェットにあるかを、実装時に確認する（このドラフトの調査では未確認）。

### 6.4 プレミアム限定の組み込み（オーナー決定）

オーナー決定: 追加の推し（資格専用キャラ）は、その資格アプリのプレミアム購入者（entitlement `premium`、商品 `<app>_premium`）のみ選択できる。既存4体（kai, mio, moka, mike）は従来どおりの仕様（現行の選択画面は「無料で全員選べる」）のまま変えない。

**読んだ事実**（`docs/local_handover_monetization.md` の記述による。権利管理の本体は依存先の `app_common_kit` にあり、今回そのソースは読んでいない）:

- `EntitlementService`（抽象）、`EntitlementState`（`hasNoAds` / `hasPremium` / `premiumExpiresAt`）、`EntitlementIds`（既定の権利名は `noads` と `premium`）、`FakeEntitlementService`、`RevenueCatEntitlementService`、`entitlementServiceProvider` / `entitlementStateProvider`、`PurchaseSection`（購入欄と復元ボタン）が app_common_kit にある。
- `entitlementServiceProvider` の既定は未実装で例外を投げ、各アプリが `ProviderScope.overrides` で差し込む。
- ukalab_core の `lib/` には entitlement 関連のコードは無い（ukalab_core が依存する側）。
- 商品IDは `<app>_premium`（例: `it_passport_premium`）、権利IDは `premium`。

**設計案**（実装は別PR、v0.79.0 想定。この PR では実装しない）:

1. **フラグ**: `CharacterPack` に任意項目 `requiresPremium`（既定 false。既存4体と標準キャラは false のまま）を足す。資格キャラだけ true にする。
2. **判定の置き場所**: ukalab_core の `CharacterSelectScreen` は、権利状態を直接は読まない。アプリが渡す形にする（例: `CharacterSelectScreen(isUnlocked: bool Function(CharacterPack))`、または `Provider<bool>` を override）。理由: 権利の配線は各アプリが `entitlementServiceProvider` を override して持っているため。ukalab_core が app_common_kit の `entitlementStateProvider` を直接 watch できるかは、実装時にコードを読んで決める（未確認）。
3. **未購入時の表示**: 選択画面で資格キャラをロック表示にする（鍵アイコン、「プレミアムで使える」の短い文）。タップしても選択は変えず、アプリが指定する購入導線（設定の購入欄など）を開く。購入前の確認（保護者ゲート等）は既存の `BeforePurchase` の仕組みに任せる。
4. **購入後の解放**: `entitlementStateProvider` の変化でロックが外れる。購入直後に自動で選ぶかは未決（U8）。
5. **失効・返金時のフォールバック**: 保存済みの選択（`ukalab.mascot.selected`）が、ロック中の資格キャラを指していたら、描画時に既定の推し（標準キャラ「うか」）として扱う。保存値は消さず、再購入・復元で権利が戻れば元の資格キャラに戻る。`UkalabCharacters.byId` の呼び出し側（`CharacterSelectionNotifier._load` ほか）で、アンロック判定を通すかを実装時に決める。
6. **復元購入**: 既存の「購入の復元」で `premium` が戻ればロックが外れる。専用の処理は不要（権利状態に従うだけ）。
7. **共有キーの注意**: `ukalab.mascot.selected` は端末内でうかラボ共通。別アプリで選んだ資格キャラが、その資格アプリ以外にも伝わる場合の扱い（他アプリでは未購入扱いでロック→標準キャラ表示）を、上記5のフォールバックで吸収する。
8. **漢検は別扱い**: 漢検は独自ラッパー `PurchasesService` を使い、権利IDが `ad_free`（広告なし）と `premium` の別体系（`docs/local_handover_monetization.md` と `docs/kanken_billing_unification_plan_2026-10-17.md` による）。kit の `entitlementServiceProvider` を override していない。漢検に資格キャラを入れる場合は、統一作業の後に判定の渡し方を決める。この仕様書の対象外。

**注意事項**:

- 実決済が有効なのは、SDKキーを渡した Android ビルドのみ（各アプリの `_useRevenueCat` は `Platform.isAndroid` かつキーが空でないとき。文書の記述による）。それ以外のビルドは `FakeEntitlementService`。乙4は RevenueCat への切替コード自体が無い（Fake のみ）。
- Fake では、購入なしで解放されるか、されないかは、既定の挙動を確認していない（未確認）。文書上は `grantOnPurchase` で購入結果を模擬し、`restorable` で復元を模擬するとだけある。実装時に Fake の既定値を読み、テストで両方（購入前=ロック、購入後=解放）を検査する。
- ストア掲載文・広告に「プレミアムで〇〇（資格キャラ）が使える」と書くのは、実装と商品登録（Play / App Store の `<app>_premium`、RevenueCat の `premium`）が済んでからにする。現時点では書かない。

### 6.5 リリース

- 画像追加はパッケージのサイズを増やす（A+Bで約1〜1.5MB 見込み）。ukalab_core の他アプリ全てに入る点に注意する。キャラ追加は minor バージョン（v0.79.0 想定）として、本仕様書の PR とは別 PR で行う。この PR ではタグも付けない。

---

## 7. 未決事項

| ID | 内容 |
|---|---|
| U1 | （解決）企画案は案1、名前「サーキ」、キャラid `circa` で確定（商標・類似の確認はオーナー側で了承済み） |
| U2 | （解決）画像の範囲は C まで全部（A 13枚＋B 23枚＋C 3枚＝39枚） |
| U4 | （解決）AI画像生成サービスの利用規約はオーナー確認済み。確認内容の記録はオーナー側。サービス名・プランはこの文書に記載しない |
| U5 | 資格キャラの衣装（`outfits/`）を作らない案でよいか（作る場合は追加 3枚x資格数） |
| U6 | 他資格へ広げるときの命名ルール、およびモチーフの決め方は §3 の方針でよいか |
| U7 | （解決）scenes の画像サイズは 460x700 に統一 |
| U8 | （プレミアム限定に伴う新規）購入直後に資格キャラを自動で選ぶか、本人に選ばせるか |
| U9 | （同上）無料でお試し表示（プレビュー。ロック画面で絵だけ見せる、数十秒だけ試す等）を許すか。許す場合の範囲（Lv1 の絵のみ等） |
| U10 | （同上）プレミアムの価格訴求（`<app>_premium` ¥1,500 の説明文・ストア文）で資格キャラをどう扱うか。商品登録・実装が済むまで掲載文には書かない |
| U11 | （同上）失効時のフォールバック先（標準キャラ「うか」でよいか）と、選択状態の保存を消さず残す方針でよいか |
| U12 | （同上）選択画面への判定の渡し方（アプリが関数で渡すか、app_common_kit の権利状態を直接読むか。§6.4 の2） |

---

## 8. 画像担当セッションへの引継ぎ文（サーキ専用・そのまま貼り付け用）

名前「サーキ」とキャラid `circa` は確定済み。下の文をそのまま渡せる。

```
あなたは「うかラボ」の資格専用キャラ「サーキ」の画像を作る担当です。ITパスポート用で、画像の作成と納品だけを行ってください（コードの変更は不要）。

【参照先】
リポジトリ zka32101/ukalab_core の docs/qualification_mascot_spec.md（§2 画像セット、§3 企画案1、§4 AI生成ガイド、§5 権利・表記）。迷ったらこの仕様書を優先してください。

【キャラ設定】
- 名前: サーキ。キャラid: circa（ともに確定）。全39枚を作成してよい。
- 種類: 回路ネコ。ITパスポートの分野（IT・ハードウェア・デジタル・ネットワーク・情報）に関連するモチーフ。
- モチーフ: 体の模様が基板の配線パターンになっている小さな猫風の生き物。しっぽの先が小さなコネクタ、耳が小さなチップ形。
- 性格: 几帳面で、仕組みを理解するのが好き。やさしい表情。
- 配色案: 主色は青以外（既存の IT の部屋の背景が青系のため）。例として、主色=やわらかい緑〜ミント系、差し色=オレンジ系（回路のはんだ・LED）、輪郭線=濃いめの同系色。既存4体の主色を見て、重ならない色に調整し、決めた色は16進数で記録する。
- 成長: Lv1 配線が数本の小さな体 → Lv3 配線が広がり小さなLEDが点く → Lv5 全身の回路が光り、しっぽのコネクタが完成する。Lv が変わっても変えない特徴は、目の形・耳（チップ形）・しっぽのコネクタ・主色の3〜4点に固定する。
- 画風: 少しかわいらしいタッチ。丸みのあるシルエット、やわらかい線、やさしい表情、頭身は3頭身前後（低すぎない）。角ばった機械的な見た目にせず、丸みを持たせる。
- 成人向けアプリなので、子ども向けに寄せすぎない（大きすぎる目、過度に幼い顔、幼児向けの色使いを避ける）。作業前に既存4体（assets/mascot/kai, mio, moka, mike）の Lv1〜5 を見て、画風・頭身・線の太さ・彩度を確認し、大きく乖離しない範囲にする。

【作る全画像（39枚）。形式はすべて webp（RGBA、背景透明）】
A 必須（13枚）、フォルダ直下:
- circa_icon_256.webp（256x256）
- circa_lv1_normal.webp / circa_lv1_joy.webp（Lv2〜Lv5 も同様。計10枚。336x512 を基準、全身、足元の位置をそろえる）
- circa_special_pass.webp（合格の喜び）/ circa_special_bow.webp（おじぎ）（336x512 前後）
B 推奨（23枚）:
- scenes/circa_lv1_eve.webp / circa_lv1_back.webp（Lv2〜Lv5 も同様。計10枚。460x700 に統一）
- states/circa_empty.webp / circa_error.webp / circa_loading.webp / circa_welcome.webp / circa_streak.webp（高さ512、幅は内容に合わせる）
- guide/circa_guide_point.webp / circa_guide_think.webp / circa_guide_teach.webp（736x1120）
- poses/circa_thinking.webp / circa_cheer.webp / circa_hint.webp / circa_rest.webp / circa_fight.webp（高さ512、幅は内容に合わせる）
C 小物（3枚）、items/（高さ512、幅は内容に合わせる）:
- circa_chip.webp（チップ）/ circa_cable.webp（ケーブル）/ circa_laptop.webp（ノートPC）
容量の目安: Lv・special・icon は 1枚 40KB 以下、scenes・guide は 1枚 150KB 以下、states・poses・items は 1枚 60KB 以下。画像内に文字・ロゴ・「公式」表記を入れない。キャラが画像の端で切れないこと。

【同一キャラを保つ手順】
1. キャラシート（正面・横・背面の全身、顔アップ、normal/joy の2表情）を最初に1枚決める。これをリファレンスにする。
2. Lv3 を先に作る。次に Lv1、Lv5 の順に、リファレンスから成長差を作る。
3. 各画像は、サービスの画像参照機能にリファレンスを渡して生成する。シードが固定できるなら控える。
4. normal と joy は同じ画像からの派生で、表情だけ変える（体型・模様は変えない）。
5. 順番は Lv → special → poses → states → scenes → guide → items。1段階ごとに既存4体と並べてトーンを確認する。
6. 背景は単色で生成して後から透過処理し、縁の白いふちを確認する。
7. スタイル固定文を決め、全画像のプロンプトの冒頭にそのまま貼る（例: フラットなセル塗り、やわらかく太さ均一の輪郭線、丸みのあるシルエット、やさしい表情、やわらかい配色、3頭身前後、成人向けで幼すぎない、全身、正面）。

【禁止事項】
- IPA など試験団体・省庁の公式キャラ、既存の著名キャラクター（猫・ロボット・企業マスコットを含む）、実在の人物に似せない。
- 「公式」「認定」「提携」を連想させる意匠（団体ロゴ、紋章、試験団体の配色の再現）を使わない。
- 画像内に文字、ロゴ、透かし、署名を入れない。
- 個人名、共有ドライブのURL、アカウント情報、キー類を、画像のメタデータ・ファイル名・納品メモのいずれにも含めない。メタデータは削除して納品する。

【権利】
AI画像生成サービスの利用規約は、オーナーが確認済みです（再確認は不要）。ただし、全画像がAI生成であることの申告が必要なので、納品メモに書いてください。

【納品形式】
- 上のファイル名・フォルダ構成のとおりの assets/mascot/circa/ を、zip 1つにまとめる（zip の中身は circa/ フォルダ。サブフォルダは scenes/ states/ guide/ poses/ items/）。
- 納品先は依頼元が指定する場所（共有URLはこの文書やPRに書かない）。
- 納品後は、コード取り込み担当のセッションが assets/mascot/circa/ に配置して取り込みます。

【納品メモ（zip に同梱）】
使ったAI画像生成サービス名、作成日、「全画像がAI生成である」旨、スタイル固定文、決めた色（16進数）、各画像のプロンプト、枚数（39枚）、下のチェックリストの結果。

【納品チェックリスト】
- [ ] フォルダ名・ファイル名が上のとおり完全一致（小文字、拡張子 .webp）
- [ ] 枚数: A 13 + B 23 + C 3 = 39枚
- [ ] 全ファイルが webp、RGBA、背景が透明（縁の白いふちなし）
- [ ] サイズが指定の範囲（icon は正方形 256x256）、容量が目安以内
- [ ] Lv1〜5 で同一キャラと分かり、Lv が上がるごとに成長が分かる
- [ ] normal と joy で表情だけが変わっている
- [ ] 既存4体と並べて見分けがつき、トーンが大きく乖離せず、子ども向けに寄りすぎていない
- [ ] 画像内に文字・ロゴ・「公式」表記・署名・透かしがない
- [ ] 公式キャラ・著名キャラ・実在人物に似ていない
- [ ] 個人名・URL・アカウント情報・キー類が、メタデータ・ファイル名・メモにない
- [ ] 納品メモがある（サービス名、作成日、全画像AI生成の旨）
```

---

## 実装状況（PR-C、core 0.81.0）

0.80.0 は学習部品（`learning.dart`）で使用済みのため、PR-C は 0.81.0 とした。タグは作らない。

### 実装したこと

- 資格専用キャラ6体（`noda` `sheru` `hirari` `soro` `sala` `tatsu`）を `UkalabCharacters.qualificationPacks` に追加（`circa` と同じ形式、`requiresPremium: true`）。`appIds` は資格idの綴り（`g_kentei` `info_security` `gen_ai_passport` `boki3` `hazmat4` `kanji_kentei`）。`circa` は `{'it_passport'}` に絞った（PR-D の1行を前倒し）。`all.length == 5` は維持
- 判定の渡し方（U12）: core は権利状態を読まない。アプリが `characterAppIdProvider`（自アプリのID）と `characterPremiumProvider`（プレミアムか）を `ProviderScope` で override する。既定は appId=null・premium=false で、資格キャラは選択画面に出ず、従来どおりの動き
- 選択画面: 共通キャラの下に「資格専用キャラ」の見出しで、自アプリの資格キャラだけを表示（`isAvailableIn`）。プレミアムでなければ鍵アイコン＋「プレミアムで使えます」。タップでプレビュー（Lv1・Lv5 の絵。選択は変えない）。`onLockedTap` を渡したときだけ購入導線のボタンが出る
- 失効（§6.4 の5、U11）: `effectiveCharacterPackProvider` が、使えない資格キャラ（プレミアム切れ・別アプリ）を直前に使っていた共通キャラへ戻す。直前の共通キャラは `ukalab.mascot.lastCommon` に保存する。無ければ標準キャラ「うか」。`ukalab.mascot.selected` は消さないので、権利が戻れば元に戻る。`OshiHomeCard` はこのプロバイダーを使う
- B 画像なしの代替: `sceneImage` / `poseImage` / `stateImage` は資格キャラで null を返す。`MascotWidget` は通常の Lv 画像、`MascotPoseImage` / `MascotStateView` は `MascotWidget`（Lv 画像）で代用する。画像が読み込めなくても例外にせず、標準キャラの描画（アイコンは標準アイコン）に戻る

### §6.3 の答え

「`sceneImageBuilder` / `poseImage` / `stateImage` が null を返したとき、Lv 画像で代用する経路が既存の表示ウィジェットにあるか」:

- `MascotWidget`: ある。`outfitImageBuilder` → `sceneImageBuilder` → `imageBuilder` の順に `??` でたどるため、`sceneImageBuilder` が無い（または null を返す）と Lv 画像になる。ただし画像読み込み失敗時の `errorBuilder` は無かった（PR-C で追加）
- `MascotPoseImage` / `MascotStateView`: 画像が null のときは `MascotWidget(pack: pack)`（= Lv 画像）に戻る経路が既にあった。ただし `poseImage` / `stateImage` は資格キャラでも存在しないファイルの `AssetImage` を返していたため、`errorBuilder` 経由の代替になっていた。PR-C で資格キャラは null を返すようにして、最初から Lv 画像にする
- `sceneImage`（`_circaScene`）は存在しない画像を指していたため、`circa` から `sceneImageBuilder` を外した

### テスト

既存の画像存在テスト（全 `MascotScene` x 全Lv など）は `imagePacks`（共通4体）が対象で、`qualificationPacks` を含まないため、削除や変更なしで B を要求しない。資格キャラは `test/ui/qualification_pack_test.dart`（定義・A 画像の参照・B が null）と `test/ui/qualification_selection_test.dart`（絞り込み・ロック・解除・失効・代替表示・幅320/280 x 文字1〜3倍）で検査する。

### 未決事項（最小実装にした点）

- U8 購入直後の自動選択: しない（本人が選ぶ）
- U9 お試し表示: ロック画面のプレビュー（Lv1・Lv5 の絵のみ）を出す。時間制の試用はしない
- U10 価格訴求・ストア文: 書かない（商品登録・実装後）
- 購入導線: `onLockedTap` をアプリが渡す（設定の購入欄を開くなど）。渡さなければボタンなし
- 画像: PR-A（未取り込み）。それまでは画像が読み込めず、標準キャラ・標準アイコンの表示になる

### PR-D（アプリ別配線）で必要なこと

- 各アプリの `ProviderScope` で `characterAppIdProvider` と `characterPremiumProvider` を override（権利は `entitlementStateProvider` の `hasPremium` など）
- `appIds` の綴り（`boki3` `hazmat4` `kanji_kentei` など）が、各アプリが渡す appId と一致するか確認
- `CharacterSelectScreen(onLockedTap: ...)` で購入欄へ誘導。ホームの推しカードから開く場合は `UkalabOshiCard(onLockedTap: ...)` で渡せる(0.82.1。カードが選択画面にそのまま渡す)
- 漢検は独自 `PurchasesService`（§6.4 の8）のため、判定の渡し方を別途決める
- 実装済み画面で `selectedCharacterPackProvider` を直接 watch しているアプリは `effectiveCharacterPackProvider` に替える
