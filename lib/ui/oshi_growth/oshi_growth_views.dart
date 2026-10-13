import 'package:app_common_kit/app_common_kit.dart' show KitStrings;
import 'package:flutter/material.dart';

import '../../oshi/oshi_growth_engine.dart';
import '../../oshi/oshi_growth_strings.dart';

OshiGrowthStrings _stringsOf(BuildContext context, OshiGrowthStrings? s) =>
    s ?? OshiGrowthStrings.forLanguageCode(KitStrings.of(context).languageCode);

/// 累計の学習量に応じた推しの反応を、吹き出しで見せる。タップで同じ段階の別の一言。
///
/// キャラ画像（[avatar]）か絵文字（[emoji]）を左に置き、吹き出しの上に表情の絵文字とラベルを出す。
/// 文言は [strings]、無ければ `KitStringsScope` の言語（ja・en。他は日本語）。
/// [seed] を省くと [now]（既定は現在）の日付から決まる。「動きを減らす」設定のときは切替の動きを付けない。
class OshiGrowthBubble extends StatefulWidget {
  const OshiGrowthBubble({
    super.key,
    required this.progress,
    this.strings,
    this.seed,
    this.now,
    this.avatar,
    this.emoji = '🌟',
    this.onChanged,
  });

  final OshiGrowthProgress progress;
  final OshiGrowthStrings? strings;
  final int? seed;
  final DateTime? now;

  /// キャラ画像など。null なら [emoji]。
  final Widget? avatar;
  final String emoji;
  final ValueChanged<OshiGrowthReaction>? onChanged;

  @override
  State<OshiGrowthBubble> createState() => _OshiGrowthBubbleState();
}

class _OshiGrowthBubbleState extends State<OshiGrowthBubble> {
  int _salt = 0;

  OshiGrowthReaction _pick(OshiGrowthStrings strings) => OshiGrowthEngine(strings: strings).reaction(
        widget.progress,
        seed: widget.seed ?? OshiGrowthEngine.seedFromDate(widget.now ?? DateTime.now()),
        salt: _salt,
      );

  @override
  Widget build(BuildContext context) {
    final strings = _stringsOf(context, widget.strings);
    final r = _pick(strings);
    if (r.text.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return Semantics(
      container: true,
      button: true,
      label: '${r.label}。${r.text}',
      hint: strings.tapHint,
      excludeSemantics: true,
      onTap: _next,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _next,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                widget.avatar ?? Text(widget.emoji, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: scheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: AnimatedSwitcher(
                      duration: reduce ? Duration.zero : const Duration(milliseconds: 200),
                      child: Column(
                        key: ValueKey(r.id),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${r.emoji} ${r.label}',
                            style: TextStyle(
                              color: scheme.onSecondaryContainer,
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            r.text,
                            style: TextStyle(color: scheme.onSecondaryContainer, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _next() {
    setState(() => _salt++);
    widget.onChanged?.call(_pick(_stringsOf(context, widget.strings)));
  }
}

/// 節目到達を祝うカードの中身（単体でも使える）。ダイアログは [showOshiGrowthDialog]。
///
/// 「動きを減らす」設定のときは出現の動きを付けない。
class OshiGrowthCelebrationCard extends StatelessWidget {
  const OshiGrowthCelebrationCard({
    super.key,
    required this.celebration,
    this.avatar,
  });

  final OshiGrowthCelebration celebration;

  /// 推しの画像など。null なら省く。
  final Widget? avatar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Semantics(
      container: true,
      label: '${celebration.title}。${celebration.body}',
      child: ExcludeSemantics(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: reduce ? 1 : 0.85, end: 1),
          duration: reduce ? Duration.zero : const Duration(milliseconds: 350),
          curve: Curves.easeOutBack,
          builder: (context, v, child) => Transform.scale(scale: v, child: child),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (avatar != null) ...[avatar!, const SizedBox(height: 8)],
              Text(celebration.emoji, style: const TextStyle(fontSize: 48)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: scheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      celebration.title,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: scheme.onSecondaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      celebration.body,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: scheme.onSecondaryContainer, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 節目 [milestone] への到達を祝うダイアログ。閉じるボタンだけ（シェアや続きの催促は出さない）。
///
/// 文言は [strings]、無ければ `KitStringsScope` の言語（ja・en。他は日本語）。
/// 既出判定は `OshiGrowthService.checkHeadline` で行い、返った節目だけをここに渡す。
Future<void> showOshiGrowthDialog(
  BuildContext context, {
  required OshiGrowthMilestone milestone,
  OshiGrowthStrings? strings,
  Widget? avatar,
}) {
  final s = _stringsOf(context, strings);
  final celebration = OshiGrowthEngine(strings: s).celebrate(milestone);
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      content: SingleChildScrollView(
        child: OshiGrowthCelebrationCard(celebration: celebration, avatar: avatar),
      ),
      actions: [
        FilledButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(s.close)),
      ],
    ),
  );
}
