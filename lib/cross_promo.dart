// うかラボ8アプリ（g_kentei / it_passport / infosecmanage / seisei_ai_passport / boki3 / otsu / kanji / bike_license）の相互紹介。
//
// `cross_promo_kit` の薄いラッパー。紹介カテゴリを「うかラボ」に固定し、
// Firebase の初期化と Remote Config の取得を1回の呼び出しにまとめる。
//
// `ui.dart` には含めない（Firebase 依存を持ち込まないため。
// 使うアプリが `package:ukalab_core/cross_promo.dart` を明示的に import する）。
import 'package:cross_promo_kit/cross_promo_kit.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';

import 'ukalab_app_ids.dart';

export 'ukalab_app_ids.dart';

/// 相互紹介の対象カテゴリ（Remote Config の掲載リストの `category`）。
const kUkalabCrossPromoCategory = 'うかラボ';

/// 相互紹介の初期化。
class UkalabCrossPromo {
  UkalabCrossPromo._();

  static Future<void>? _initFuture;

  /// Firebase を初期化し、続けて `CrossPromoService.init()` を実行する。
  ///
  /// どの段階で失敗しても例外を投げない（既に初期化済み・設定ファイル無し・Web・テスト環境など）。
  /// 呼び出し側の起動を止めないよう `unawaited(UkalabCrossPromo.init())` で呼べる。
  /// 二重に呼んでも1回分しか実行しない（同じ Future を返す）。
  static Future<void> init() => _initFuture ??= _run();

  static Future<void> _run() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
    } catch (_) {
      // 既に初期化済み・設定ファイル無し・Web・テスト環境。起動は止めない。
    }
    try {
      await CrossPromoService.init();
    } catch (_) {
      // kit 側も握りつぶすが、念のため。
    }
  }
}

/// 「他のアプリもチェック！」セクション（うかラボ版）。設定画面などに置く。
///
/// 掲載が0件（未配信・取得失敗・自アプリのみ）のときは何も表示しない。
/// うかラボは大人向けなので `isChildDirected` は付けない。
/// [currentAppId] には本番の applicationId を渡す（自アプリの除外に使う）。
/// [kUkalabAppIds] に無い値を渡すと、debug ビルドでは assert で気づける（release では何もしない）。
class UkalabCrossPromoSection extends StatelessWidget {
  const UkalabCrossPromoSection({
    super.key,
    required this.currentAppId,
    this.isChildDirected = false,
    this.beforeOpenStore,
    this.onOpenStore,
  }) : assert(
          !isChildDirected || beforeOpenStore != null,
          'isChildDirected: true の場合は beforeOpenStore（保護者ゲート）が必須です。',
        );

  final String currentAppId;

  /// 子ども向け設定で広告を配信するアプリ用。true のとき [beforeOpenStore] が必須（kit の assert）。
  /// 既定は false（大人向け・ゲートなし）。
  final bool isChildDirected;

  /// ストアを開く直前のゲート（保護者ゲートなど）。`false` を返すと開かない。
  final Future<bool> Function(BuildContext context)? beforeOpenStore;

  /// ストアを開く直前に呼ばれる任意のフック（タップ計測用）。
  final void Function(PromotedApp app)? onOpenStore;

  @override
  Widget build(BuildContext context) {
    assert(
      isUkalabAppId(currentAppId),
      'currentAppId "$currentAppId" は kUkalabAppIds にありません。'
      '本番の applicationId を渡してください（新しいアプリは ukalab_app_ids.dart に追記）。',
    );
    return CrossPromoSection(
        currentAppId: currentAppId,
        currentCategory: kUkalabCrossPromoCategory,
        isChildDirected: isChildDirected,
        beforeOpenStore: beforeOpenStore,
        onOpenStore: onOpenStore,
      );
  }
}
