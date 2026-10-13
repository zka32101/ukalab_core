import 'package:flutter/material.dart';

/// ホーム画面の分類分け用の共通部品。文言は持たない（見出し・ラベルはアプリが渡す）。
/// 色・角丸・余白は Theme（ColorScheme）から取る。

bool _reduceMotion(BuildContext context) =>
    MediaQuery.maybeOf(context)?.disableAnimations ?? false;

/// ホームのセクション見出し。`Semantics(header: true)`。
class HomeSectionHeader extends StatelessWidget {
  const HomeSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
  });

  final String title;
  final String? subtitle;

  /// アイコンや絵文字（`Icon` / `Text('🎯')` など）。装飾として読み上げ対象から外す。
  final Widget? leading;

  /// 「すべて見る」などのアクション。
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          if (leading != null) ...[
            ExcludeSemantics(child: leading!),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Semantics(
              header: true,
              container: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                ],
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// タイルに付けるバッジ。
class HomeMenuBadge {
  const HomeMenuBadge._(this.kind, this.text);

  /// 未読の点。
  const HomeMenuBadge.dot() : this._(_BadgeKind.dot, null);

  /// 件数（0 以下は表示しない）。99 を超えたら「99+」。
  factory HomeMenuBadge.count(int n) =>
      HomeMenuBadge._(_BadgeKind.count, n > 99 ? '99+' : '$n');

  /// 「NEW」などの短いラベル（文言はアプリが渡す）。
  const HomeMenuBadge.label(String text) : this._(_BadgeKind.label, text);

  /// プレミアム印（星アイコン）。
  const HomeMenuBadge.premium() : this._(_BadgeKind.premium, null);

  final _BadgeKind kind;
  final String? text;

  bool get isVisible =>
      !(kind == _BadgeKind.count && (text == null || text == '0' || text!.startsWith('-')));
}

enum _BadgeKind { dot, count, label, premium }

class _BadgeView extends StatelessWidget {
  const _BadgeView(this.badge);
  final HomeMenuBadge badge;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final style = Theme.of(context)
        .textTheme
        .labelSmall
        ?.copyWith(color: cs.onError, fontWeight: FontWeight.bold);
    switch (badge.kind) {
      case _BadgeKind.dot:
        return Container(
          key: const ValueKey('home-badge-dot'),
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: cs.error, shape: BoxShape.circle),
        );
      case _BadgeKind.premium:
        return Icon(Icons.workspace_premium,
            key: const ValueKey('home-badge-premium'),
            size: 20,
            color: cs.tertiary);
      case _BadgeKind.count:
      case _BadgeKind.label:
        final isLabel = badge.kind == _BadgeKind.label;
        return Container(
          key: ValueKey(isLabel ? 'home-badge-label' : 'home-badge-count'),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: isLabel ? cs.tertiary : cs.error,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            badge.text!,
            style: isLabel ? style?.copyWith(color: cs.onTertiary) : style,
          ),
        );
    }
  }
}

String? _badgeSemantics(HomeMenuBadge? b) =>
    (b == null || !b.isVisible) ? null : b.text;

/// 1 列版のメニュータイル。最小タップ領域 48dp。
class HomeMenuTile extends StatelessWidget {
  const HomeMenuTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.badge,
    this.showChevron = true,
    this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final HomeMenuBadge? badge;
  final bool showChevron;
  final Color? iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final hasBadge = badge != null && badge!.isVisible;
    return Semantics(
      container: true,
      button: true,
      enabled: onTap != null,
      label: [title, if (subtitle != null) subtitle!, if (_badgeSemantics(badge) != null) _badgeSemantics(badge)!]
          .join('、'),
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(icon, color: iconColor ?? cs.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: theme.textTheme.bodyLarge
                                ?.copyWith(color: cs.onSurface)),
                        if (subtitle != null)
                          Text(subtitle!,
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: cs.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  if (hasBadge) ...[
                    const SizedBox(width: 8),
                    _BadgeView(badge!),
                  ],
                  if (showChevron) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// [HomeMenuGrid] の 1 項目。
class HomeMenuItem {
  const HomeMenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.badge,
    this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final HomeMenuBadge? badge;
  final Color? iconColor;
  final VoidCallback? onTap;
}

/// コンパクトな 2 列グリッド。幅が [minWidthForTwoColumns] 未満、または文字倍率が
/// [maxTextScaleForTwoColumns] を超えたら 1 列（[HomeMenuTile]）にフォールバックする。
class HomeMenuGrid extends StatelessWidget {
  const HomeMenuGrid({
    super.key,
    required this.items,
    this.minWidthForTwoColumns = 360,
    this.maxTextScaleForTwoColumns = 1.3,
    this.spacing = 8,
  });

  final List<HomeMenuItem> items;
  final double minWidthForTwoColumns;
  final double maxTextScaleForTwoColumns;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(builder: (context, constraints) {
        final two = constraints.maxWidth >= minWidthForTwoColumns &&
            scale <= maxTextScaleForTwoColumns;
        final cols = two ? 2 : 1;
        final rows = <Widget>[];
        for (var i = 0; i < items.length; i += cols) {
          final cells = <Widget>[];
          for (var j = 0; j < cols; j++) {
            final idx = i + j;
            cells.add(Expanded(
              child: idx < items.length
                  ? _cell(items[idx], compact: two)
                  : const SizedBox.shrink(),
            ));
            if (j < cols - 1) cells.add(SizedBox(width: spacing));
          }
          rows.add(Padding(
            padding: EdgeInsets.only(top: rows.isEmpty ? 0 : spacing),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: cells,
              ),
            ),
          ));
        }
        return Column(
          key: ValueKey('home-grid-$cols'),
          children: rows,
        );
      }),
    );
  }

  Widget _cell(HomeMenuItem it, {required bool compact}) => HomeMenuTile(
        icon: it.icon,
        title: it.title,
        subtitle: it.subtitle,
        badge: it.badge,
        iconColor: it.iconColor,
        showChevron: !compact,
        onTap: it.onTap,
      );
}

/// 見出し + 子。[collapsible] で畳める。折りたたみ状態の保存はアプリ側
/// （[expandedListenable] / [onExpandedChanged]）で行い、core は永続化しない。
class HomeSection extends StatefulWidget {
  const HomeSection({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.collapsible = false,
    this.initiallyExpanded = true,
    this.expandedListenable,
    this.onExpandedChanged,
    required this.child,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final bool collapsible;
  final bool initiallyExpanded;

  /// 渡すと開閉状態をこの値で持つ（アプリ側で永続化したい場合）。
  final ValueNotifier<bool>? expandedListenable;
  final ValueChanged<bool>? onExpandedChanged;
  final Widget child;

  @override
  State<HomeSection> createState() => _HomeSectionState();
}

class _HomeSectionState extends State<HomeSection> {
  late bool _expanded =
      widget.expandedListenable?.value ?? widget.initiallyExpanded;

  @override
  void initState() {
    super.initState();
    widget.expandedListenable?.addListener(_sync);
  }

  @override
  void didUpdateWidget(HomeSection old) {
    super.didUpdateWidget(old);
    if (old.expandedListenable != widget.expandedListenable) {
      old.expandedListenable?.removeListener(_sync);
      widget.expandedListenable?.addListener(_sync);
      _sync();
    }
  }

  @override
  void dispose() {
    widget.expandedListenable?.removeListener(_sync);
    super.dispose();
  }

  void _sync() {
    final v = widget.expandedListenable?.value;
    if (v != null && v != _expanded && mounted) setState(() => _expanded = v);
  }

  void _toggle() {
    final next = !_expanded;
    setState(() => _expanded = next);
    widget.expandedListenable?.value = next;
    widget.onExpandedChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final expanded = !widget.collapsible || _expanded;
    Widget header = HomeSectionHeader(
      title: widget.title,
      subtitle: widget.subtitle,
      leading: widget.leading,
      trailing: widget.collapsible
          ? Row(mainAxisSize: MainAxisSize.min, children: [
              if (widget.trailing != null) widget.trailing!,
              Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                  color: cs.onSurfaceVariant),
            ])
          : widget.trailing,
    );
    if (widget.collapsible) {
      header = Semantics(
        expanded: _expanded,
        child: InkWell(
          onTap: _toggle,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Align(alignment: Alignment.centerLeft, child: header),
          ),
        ),
      );
    }
    final reduce = _reduceMotion(context);
    final body = Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: widget.child,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        if (!widget.collapsible)
          body
        else if (reduce)
          (expanded ? body : const SizedBox.shrink())
        else
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.topCenter,
            child: expanded ? body : const SizedBox(width: double.infinity),
          ),
      ],
    );
  }
}
