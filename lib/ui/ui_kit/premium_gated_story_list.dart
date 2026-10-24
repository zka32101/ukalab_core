import 'package:flutter/material.dart';

import '../../experience/story_mode.dart' show StoryScenario;

/// [PremiumGatedStoryListView] の1行ぶんの表示内容。
///
/// コアの [StoryScenario] からは [PremiumGatedStoryItem.fromScenario] で作る。
/// アプリ側のモデル（AI下書きの印や関連用語を足したもの）からは、
/// 必要な項目だけを渡して作ればよい。
@immutable
class PremiumGatedStoryItem {
  const PremiumGatedStoryItem({
    required this.id,
    required this.title,
    required this.chapterCount,
    this.footer,
  });

  factory PremiumGatedStoryItem.fromScenario(StoryScenario scenario, {Widget? footer}) =>
      PremiumGatedStoryItem(
        id: scenario.scenarioId,
        title: scenario.title,
        chapterCount: scenario.chapters.length,
        footer: footer,
      );

  /// シナリオID（[PremiumGatedStoryListView.isFree] と各コールバックに渡る）。
  final String id;
  final String title;
  final int chapterCount;

  /// タイル末尾のスロット（関連用語のチップなど）。ロック中でも表示する。
  final Widget? footer;
}

/// 「最初のN本は無料、残りはプレミアム」の体験型シナリオ一覧。
///
/// - 無料の判定は [isFree]（id で判定）。省略時は先頭から [freeCount] 本が無料。
/// - [hasPremium] が true なら全開放（ロックアイコンも出さない）。
/// - ロック中のタイルをタップしたら [onLockedTap]。省略時は [lockedMessage] の
///   SnackBar を出す。ペイウォールへ誘導する場合は [onLockedTap] で呼び出し側が決める。
/// - 開けるタイルをタップしたら [onOpen]。
/// - [draftNotice] を渡すと、一覧の先頭に AI 下書きの注記を出す。
/// - 広告は一切出さない。
///
/// 画面（Scaffold・AppBar・読み込み中の表示）は持たない。`ListView` だけを返すので、
/// 呼び出し側の Scaffold の body に置く。文字倍率が大きくても折り返して収まる。
class PremiumGatedStoryListView extends StatelessWidget {
  const PremiumGatedStoryListView({
    super.key,
    required this.items,
    required this.hasPremium,
    required this.onOpen,
    this.freeCount = 2,
    this.isFree,
    this.onLockedTap,
    this.intro,
    this.draftNotice,
    this.chapterUnit = '章',
    this.freeLabel = '無料',
    this.premiumLabel = 'プレミアム',
    this.lockedMessage = defaultLockedMessage,
    this.padding = const EdgeInsets.all(16),
  });

  /// 既定のロック案内（SnackBar の文言）。
  static const String defaultLockedMessage = 'このシナリオはプレミアムの機能です。設定から購入できます。';

  final List<PremiumGatedStoryItem> items;
  final bool hasPremium;
  final ValueChanged<PremiumGatedStoryItem> onOpen;

  /// [isFree] が null のとき、先頭から何本を無料にするか。
  final int freeCount;

  /// id から無料かを返す。渡すと [freeCount] より優先する。
  final bool Function(String id)? isFree;

  /// ロック中のタイルをタップしたとき。null なら [lockedMessage] の SnackBar。
  final ValueChanged<PremiumGatedStoryItem>? onLockedTap;

  /// 一覧の先頭の説明文。
  final String? intro;

  /// AI 下書きの注記（例: 「学習用の架空シナリオ(AI下書き・専門確認前)」）。
  final String? draftNotice;

  /// 「全N◯」の単位（例: 'か月'・'場面'）。
  final String chapterUnit;
  final String freeLabel;
  final String premiumLabel;
  final String lockedMessage;
  final EdgeInsetsGeometry padding;

  bool _free(int index, PremiumGatedStoryItem item) =>
      isFree != null ? isFree!(item.id) : index < freeCount;

  void _tap(BuildContext context, int index, PremiumGatedStoryItem item) {
    if (_free(index, item) || hasPremium) {
      onOpen(item);
      return;
    }
    final handler = onLockedTap;
    if (handler != null) {
      handler(item);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(lockedMessage)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: padding,
      children: [
        if (intro != null) ...[
          Text(intro!, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 4),
        ],
        if (draftNotice != null) ...[
          Text(
            draftNotice!,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
          ),
          const SizedBox(height: 12),
        ],
        for (var i = 0; i < items.length; i++) ...[
          _tile(context, theme, i, items[i]),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _tile(BuildContext context, ThemeData theme, int index, PremiumGatedStoryItem item) {
    final free = _free(index, item);
    final locked = !free && !hasPremium;
    final footer = item.footer;
    final label = free ? freeLabel : premiumLabel;
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(item.title),
            subtitle: Text(
              '全${item.chapterCount}$chapterUnit ・ $label',
              style: theme.textTheme.bodySmall,
            ),
            trailing: locked
                ? Icon(Icons.lock_outline, color: theme.colorScheme.outline, semanticLabel: 'ロック中')
                : const Icon(Icons.chevron_right),
            onTap: () => _tap(context, index, item),
          ),
          if (footer != null)
            Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 12), child: footer),
        ],
      ),
    );
  }
}
