# うかラボ 共通 Firebase（ukalab-prod / ukalab-dev）

> v0.53.0 で `app_common_kit` の `firebase/` から、この `ukalab_core` に移した（うかラボ専用のため）。

設計書: 決定事項ログ §5・追補 決定24。うかラボ全体で **本番1つ＋開発1つ**。同じ Google アカウントで全資格のデータを引き継ぐ（匿名認証 → Google／Apple へのリンクで uid が変わらない）。

| 項目 | 本番 | 開発 |
|---|---|---|
| プロジェクト ID | `ukalab-prod` | `ukalab-dev` |
| コンソール | https://console.firebase.google.com/project/ukalab-prod/overview | https://console.firebase.google.com/project/ukalab-dev/overview |
| 作成日 | 2026-10-03 | 2026-10-03 |
| Firestore | `(default)`、**asia-northeast1**（変更不可）、ルール配備済み | 同左 |
| 所有アカウント | yourwishdev@gmail.com | 同左 |

漢字マスター検定（`kanken-b5ac9`）と小学コレ系は、決定どおり別プロジェクトのまま。バイク免許コレは現在 `bike-fb1ad`（本番移行は別途判断）。

## このフォルダの中身
| ファイル | 内容 |
|---|---|
| `firestore.rules` | 共通ルール。`users/{uid}/exams/{examId}/…` は本人のみ（examId は登録済みの資格だけ）、`feedback` は本人のみ作成・閲覧、それ以外は全拒否 |
| `test_rules.py` | ルールの検査（15ケース）。**配備せず**、Firebase Rules の検証 API で確かめる。Java・エミュレータは不要 |
| `firebase.json`・`.firebaserc` | Firestore ルールとプロジェクトの別名（`dev`・`prod`） |

## 使い方
```bash
cd firebase
python test_rules.py ukalab-dev          # ルールの検査（gcloud ログインが必要）
firebase deploy --only firestore:rules --project ukalab-dev     # 開発へ
firebase deploy --only firestore:rules --project ukalab-prod    # 本番へ
```
- **`firebase deploy` は必ず `--only` と `--project` を付ける。`--force` は付けない**（共有プロジェクトでは他アプリの関数などを消す事故につながる）
- 先に dev で確かめてから prod へ

## 新しい資格を足すとき
1. `UkalabCert` に資格を追加（ukalab_core の `lib/ui/theme/ukalab_palette.dart`）
2. `firestore.rules` の `examIds()` に、その id を追加（**追加を忘れると、その資格のデータは書けない**）
3. `test_rules.py` を通し、dev → prod の順に配備

## 状態（2026-10-03）
### 済み
- プロジェクト作成（本番・開発）
- Firestore 作成（東京）とルール配備
- 必要な API の有効化（Firestore、Rules、Identity Toolkit、Remote Config）

### あなたの作業（画面での操作。API では課金が要る、または認証情報が要るため）
本番・開発の**両方**で行う。

1. **Authentication を始める**: コンソール →「Authentication」→「始める」 → ログイン方法で**匿名**を有効にする
   - ※ API（Identity Platform）経由だと**課金（Blaze）が必要**になる。コンソールの「始める」からなら課金なしで進められる
2. **Google ログイン**を有効にする（サポートメールを選ぶ）
3. **Apple ログイン**を有効にする（Apple Developer の Services ID・チーム ID・キー ID・秘密鍵が必要。iOS 公開前でよい）
4. **Google Analytics** を有効にする（コンソール →「プロジェクトの設定」→「統合」）
5. **Crashlytics** はアプリの初回起動後に、コンソールの Crashlytics から有効化
6. **Remote Config**: 必要になったら、コンソールで最初の値を公開
7. 課金（Blaze）は、Cloud Functions（フィードバックの GitHub Issue 自動化など）を使うときに必要。課金の有効化は、あなたの操作

### アプリの接続（資格ごと）
- 資格アプリを作るたびに、コンソール →「アプリを追加」で Android／iOS を登録し、`google-services.json`・`GoogleService-Info.plist` をアプリに置く（`.gitignore` 済み）。アプリの ID は資格ごとに決めてから
- App Check は実装時に設定
