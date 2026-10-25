// うかラボ全8アプリの正規 applicationId（Android）。
//
// 公開済みの不統一なID（`ukalab_otsu` / `ukarulab.kanji`）も、変更せずそのまま載せる。
// 新しいアプリを足すときはここに追記する（相互紹介の `currentAppId` の取り違えを debug で検出するため）。

/// うかラボ全アプリの正規 applicationId。
const List<String> kUkalabAppIds = [
  'com.yourwish.ukalab.g_kentei',
  'com.yourwish.ukalab.it_passport',
  'com.yourwish.ukalab.infosecmanage',
  'com.yourwish.ukalab.seisei_ai_passport',
  'com.yourwish.ukalab.boki3',
  'com.yourwish.ukalab_otsu',
  'com.yourwish.ukarulab.kanji',
  'com.yourwish.ukalab.bike_license',
];

/// [appId] が [kUkalabAppIds] に含まれるか。
bool isUkalabAppId(String appId) => kUkalabAppIds.contains(appId);
