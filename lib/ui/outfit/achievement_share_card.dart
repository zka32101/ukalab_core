import 'dart:ui' show Rect;

import 'package:flutter/material.dart';

import '../file_export/save_file.dart';
import '../theme/ukalab_palette.dart';
import '../ukalab_strings.dart';
import 'share_card.dart';

/// 「達成」共有カードの内容。**個人情報を入れる欄は作らない**
/// （名前・ユーザーID・メールなし。資格名・見出し・指標・日付の文字列だけ）。
/// 欄を増やすときは、個人情報にならないことを確認し test/achievement_share_card_test.dart を更新する。
class AchievementShareData {
  const AchievementShareData({
    required this.certLabel,
    required this.headline,
    this.metricText,
    this.dateLabel,
  });

  /// 資格名（例: 「ITパスポート」）。
  final String certLabel;

  /// 見出し（例: 「分野を100%制覇」）。事実だけを書く。
  final String headline;

  /// 指標（任意。例: 「12/40問」「連続7日」）。
  final String? metricText;

  /// 日付の表記（任意。例: 「2026年10月24日」）。呼び出し側で整形して渡す。
  final String? dateLabel;
}

/// 達成の共有カード。幅いっぱいの 4:5 縦長。画像化は [captureShareCard]、
/// 共有は [shareAchievementCard]。合格を示す文言は持たない（達成の事実だけを出す）。
class AchievementShareCard extends StatelessWidget {
  const AchievementShareCard({super.key, required this.data, required this.cert, this.strings});

  final AchievementShareData data;
  final UkalabCert cert;

  /// null なら最も近い `KitStringsScope`（無ければ日本語）。
  final UkalabStrings? strings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = strings ?? UkalabStrings.of(context);
    final p = UkalabPalette.resolve(field: cert.field, cert: cert, brightness: theme.brightness);
    final text = theme.textTheme;
    final metric = data.metricText;
    final date = data.dateLabel;
    final label = [data.certLabel, data.headline, ?metric, ?date].join('、');
    // 共有する「画像」なので、端末の文字サイズ設定に左右されないよう文字倍率は固定する。
    return MediaQuery.withNoTextScaling(
      child: Semantics(
        container: true,
        label: label,
        excludeSemantics: true,
        child: AspectRatio(
          aspectRatio: 4 / 5,
          child: Container(
            key: const ValueKey('achievementCardSurface'),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: p.fill, width: 4),
            ),
            padding: const EdgeInsets.all(24),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox(
                width: 320,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      s.shareCardBrand,
                      key: const ValueKey('achievementBrand'),
                      style: text.labelMedium?.copyWith(color: p.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: p.primaryContainer,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        data.certLabel,
                        key: const ValueKey('achievementCert'),
                        style: text.titleMedium?.copyWith(color: p.onPrimaryContainer),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Icon(Icons.emoji_events, size: 72, color: p.fill),
                    const SizedBox(height: 20),
                    Text(
                      data.headline,
                      key: const ValueKey('achievementHeadline'),
                      style: text.headlineSmall?.copyWith(color: p.textPrimary, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (metric != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        metric,
                        key: const ValueKey('achievementMetric'),
                        style: text.titleLarge?.copyWith(color: p.textPrimary),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (date != null) ...[
                      const SizedBox(height: 20),
                      Text(
                        date,
                        key: const ValueKey('achievementDate'),
                        style: text.bodyMedium?.copyWith(color: p.textSecondary),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// [boundaryKey] の RepaintBoundary を PNG にして共有する（[captureShareCard] を再利用）。
/// [saver] を省くと [defaultFileSaver]（Web はダウンロード、他は OS 共有シート）。
/// 共有できたら true、共有シートを閉じたなら false。
Future<bool> shareAchievementCard(
  GlobalKey boundaryKey, {
  String fileName = 'ukalab_achievement.png',
  double pixelRatio = 3,
  FileSaver? saver,
  Rect? sharePositionOrigin,
}) async {
  final png = await captureShareCard(boundaryKey, pixelRatio: pixelRatio);
  return (saver ?? defaultFileSaver)(
    bytes: png,
    fileName: fileName,
    mimeType: 'image/png',
    sharePositionOrigin: sharePositionOrigin,
  );
}
