import 'package:flutter/material.dart';

import '../../experience/chapter_reading.dart';
import 'reading_number_wrap.dart';

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

/// 表の列数がこの値以上のとき、内容に応じた列幅配分（収まらなければ横スクロール）にする。
/// これ未満（2・3列）は従来どおり均等幅の [Table]。
const int _kWideTableColumns = 4;

/// 短い文言（この文字数以下）は列幅の下限を「1行で収まる幅」にする。
const int _kShortCellChars = 8;

/// 長い文言でも列幅の下限にする文字数（全角換算）。
const int _kLongCellMinChars = 6;

/// 横スクロール時に1列へ割り当てる幅の上限（文字数。語の幅が超えるときは語を優先）。
const int _kScrollColumnMaxChars = 10;

const double _kCellPadding = 8;

class _TableBlock extends StatefulWidget {
  const _TableBlock({required this.table});

  final ReadingTable table;

  @override
  State<_TableBlock> createState() => _TableBlockState();
}

class _TableBlockState extends State<_TableBlock> {
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  ReadingTable get table => widget.table;

  Widget _cell(BuildContext context, String text, {bool head = false}) {
    final theme = Theme.of(context);
    return Container(
      color: head ? theme.colorScheme.surfaceContainerHighest : null,
      padding: const EdgeInsets.all(_kCellPadding),
      child: readingNumberSafeText(text, style: _cellStyle(theme, head)),
    );
  }

  TextStyle? _cellStyle(ThemeData theme, bool head) => head
      ? theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)
      : theme.textTheme.bodyMedium;

  Widget _buildTable(BuildContext context, Map<int, TableColumnWidth>? widths) {
    final cols = table.columns.length;
    return Table(
      columnWidths: widths,
      border: TableBorder.all(color: Theme.of(context).colorScheme.outlineVariant),
      defaultVerticalAlignment: TableCellVerticalAlignment.top,
      children: [
        TableRow(
          children: [
            for (final c in table.columns) _cell(context, c, head: true),
          ],
        ),
        for (final row in table.rows)
          TableRow(
            children: [
              for (var i = 0; i < cols; i++)
                _cell(context, i < row.length ? row[i] : ''),
            ],
          ),
      ],
    );
  }

  double _width(
    String text,
    TextStyle style,
    TextScaler scaler,
    TextDirection dir,
  ) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: dir,
      textScaler: scaler,
    )..layout();
    final w = tp.width;
    tp.dispose();
    return w;
  }

  /// 各列の（下限, 1行で収まる幅, 横スクロール時の幅）。padding を含む。
  List<({double min, double natural, double scroll})> _measure(
    BuildContext context,
  ) {
    final theme = Theme.of(context);
    final base = DefaultTextStyle.of(context).style;
    final scaler = MediaQuery.textScalerOf(context);
    final dir = Directionality.of(context);
    final cols = table.columns.length;
    final bodyStyle = base.merge(_cellStyle(theme, false));
    final headStyle = base.merge(_cellStyle(theme, true));
    final longMin = _width('国' * _kLongCellMinChars, bodyStyle, scaler, dir);
    final scrollCap = _width(
      '国' * _kScrollColumnMaxChars,
      bodyStyle,
      scaler,
      dir,
    );
    const pad = _kCellPadding * 2;
    return [
      for (var c = 0; c < cols; c++)
        () {
          var min = 0.0;
          var natural = 0.0;
          for (var r = -1; r < table.rows.length; r++) {
            final raw = r < 0
                ? table.columns[c]
                : (c < table.rows[r].length ? table.rows[r][c] : '');
            if (raw.isEmpty) continue;
            final style = r < 0 ? headStyle : bodyStyle;
            final shown = keepReadingNumbersTogether(raw);
            final full = _width(shown, style, scaler, dir);
            var cellMin = full;
            if (raw.runes.length > _kShortCellChars) {
              var tokenMax = 0.0;
              for (final t in readingUnbreakableTokens(raw)) {
                final w = _width(keepReadingNumbersTogether(t), style, scaler, dir);
                if (w > tokenMax) tokenMax = w;
              }
              cellMin = (tokenMax > longMin ? tokenMax : longMin);
              if (cellMin > full) cellMin = full;
            }
            if (cellMin > min) min = cellMin;
            if (full > natural) natural = full;
          }
          final minW = min + pad;
          final naturalW = natural + pad;
          final cap = scrollCap + pad;
          final scrollW = naturalW < cap ? naturalW : cap;
          return (
            min: minW,
            natural: naturalW,
            scroll: scrollW > minW ? scrollW : minW,
          );
        }(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final cols = table.columns.length;
    if (cols < _kWideTableColumns) return _buildTable(context, null);
    return LayoutBuilder(
      builder: (context, constraints) {
        final avail = constraints.maxWidth;
        if (!avail.isFinite) return _buildTable(context, null);
        final m = _measure(context);
        // 従来の均等幅で全列の下限を満たすなら、従来と同じ見た目。
        final equal = avail / cols;
        if (m.every((c) => c.min <= equal + 0.5)) {
          return _buildTable(context, null);
        }
        final sumMin = m.fold<double>(0, (a, c) => a + c.min);
        if (sumMin <= avail) {
          // 収まる: 下限＋余りを「1行幅との差」に比例して配分し、全幅に広げる。
          final extra = avail - sumMin;
          final sumGap = m.fold<double>(0, (a, c) => a + (c.natural - c.min));
          final double factor = sumGap <= 0
              ? 0.0
              : (extra / sumGap).clamp(0.0, 1.0).toDouble();
          final used = sumMin + sumGap * factor;
          final spare = (avail - used) / cols;
          return _buildTable(context, {
            for (var i = 0; i < cols; i++)
              i: FlexColumnWidth(
                m[i].min + (m[i].natural - m[i].min) * factor + spare,
              ),
          });
        }
        // 収まらない: 表全体を横スクロール（行→列の順序は Table のまま）。
        final widths = [for (final c in m) c.scroll.ceilToDouble()];
        final total = widths.fold<double>(0, (a, w) => a + w);
        return Scrollbar(
          controller: _scroll,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _scroll,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(bottom: 12),
            child: SizedBox(
              width: total,
              child: _buildTable(context, {
                for (var i = 0; i < cols; i++) i: FixedColumnWidth(widths[i]),
              }),
            ),
          ),
        );
      },
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
