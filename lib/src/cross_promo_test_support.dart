// テスト専用: Remote Config を経由せず、掲載リストの JSON を直接渡して表示する。
//
// `cross_promo.dart` からは export しない（kit の `@visibleForTesting` を公開APIに出さないため）。
// テストだけが `package:ukalab_core/src/cross_promo_test_support.dart` を import する。
// kit の `appsOverride` は絞り込みを通さないので、本番と同じ `parseApps`
// （自アプリ除外・カテゴリ絞り込み）を通してから渡す。
// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'package:cross_promo_kit/cross_promo_kit.dart';
import 'package:flutter/widgets.dart';

import '../cross_promo.dart';

/// [UkalabCrossPromoSection] と同じ設定（うかラボ絞り込み）で、[rawJson] の掲載リストを表示する。
Widget ukalabCrossPromoSectionForTest({
  required String currentAppId,
  required String rawJson,
}) =>
    CrossPromoSection(
      currentAppId: currentAppId,
      currentCategory: kUkalabCrossPromoCategory,
      appsOverride: CrossPromoService.parseApps(
        rawJson,
        currentAppId: currentAppId,
        currentCategory: kUkalabCrossPromoCategory,
      ),
    );
