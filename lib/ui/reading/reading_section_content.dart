import 'package:flutter/material.dart';

import '../../experience/chapter_reading.dart';

/// [ReadingSection] を kind（text / table / steps / figure）に応じて描画する。
///
/// 色・文字は `Theme`（ライト/ダーク）に従い、文字拡大で折り返す（高さの固定なし）。
/// 見出しは見出しとして、図は `alt` を読み上げ、手順は「番号. 内容」として読み上げる。
/// 未知の kind は本文（あれば）だけを出す。既存の `ChapterReadingWidget`
/// （`ReadingSectionView` は見出し＋本文のみのデータ型）は変更しない。
class ReadingSectionContent extends StatelessWidget {
  const ReadingSectionContent({
    super.key,
    required this.section,
    this.assetPackage,
  });

  final ReadingSection section;

  /// figure の画像が別パッケージの assets にあるときのパッケージ名。
  final String? assetPackage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final body = section.body.trim();
    final Widget? main = switch (section.kind) {
      kReadingSectionTable when section.table != null => _TableBlock(
        table: section.table!,
      ),
      kReadingSectionSteps when section.steps != null => _StepsBlock(
        steps: section.steps!,
      ),
      kReadingSectionFigure when section.figure != null => _FigureBlock(
        figure: section.figure!,
        assetPackage: assetPackage,
      ),
      _ => null,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          header: true,
          child: Text(
            section.heading,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        if (main != null) ...[const SizedBox(height: 8), main],
        if (body.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(section.body, style: theme.textTheme.bodyLarge),
        ],
      ],
    );
  }
}

class _TableBlock extends StatelessWidget {
  const _TableBlock({required this.table});

  final ReadingTable table;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final cols = table.columns.length;
    Widget cell(String text, {bool head = false}) => Container(
      color: head ? scheme.surfaceContainerHighest : null,
      padding: const EdgeInsets.all(8),
      child: Text(
        text,
        style: head
            ? theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)
            : theme.textTheme.bodyMedium,
      ),
    );
    return Table(
      border: TableBorder.all(color: scheme.outlineVariant),
      defaultVerticalAlignment: TableCellVerticalAlignment.top,
      children: [
        TableRow(
          children: [for (final c in table.columns) cell(c, head: true)],
        ),
        for (final row in table.rows)
          TableRow(
            children: [
              for (var i = 0; i < cols; i++) cell(i < row.length ? row[i] : ''),
            ],
          ),
      ],
    );
  }
}

class _StepsBlock extends StatelessWidget {
  const _StepsBlock({required this.steps});

  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < steps.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == steps.length - 1 ? 0 : 8),
            child: Semantics(
              label: '${i + 1}. ${steps[i]}',
              excludeSemantics: true,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${i + 1}',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: scheme.onPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(steps[i], style: theme.textTheme.bodyLarge),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _FigureBlock extends StatelessWidget {
  const _FigureBlock({required this.figure, this.assetPackage});

  final ReadingFigure figure;
  final String? assetPackage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final caption = figure.caption?.trim() ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          image: true,
          label: figure.alt,
          excludeSemantics: true,
          child: Image.asset(
            figure.asset,
            package: assetPackage,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stack) => Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Row(
                children: [
                  Icon(Icons.image_outlined, color: theme.colorScheme.outline),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(figure.alt, style: theme.textTheme.bodyMedium),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (caption.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(caption, style: theme.textTheme.bodySmall),
        ],
      ],
    );
  }
}
