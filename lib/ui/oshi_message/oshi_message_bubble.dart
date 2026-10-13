import 'package:app_common_kit/app_common_kit.dart' show KitStrings;
import 'package:flutter/material.dart';

import '../../oshi/oshi_message_engine.dart';
import '../../oshi/oshi_message_strings.dart';

/// 推しの一言を吹き出しで見せる。キャラ画像（[avatar]）か絵文字（[emoji]）を左に置き、タップで別の一言。
///
/// 文言は [strings]、無ければ `KitStringsScope` の言語（ja・en。他は日本語）。
/// [seed] を省くと [now]（既定は現在）の日付から決まる。「動きを減らす」設定のときは切替の動きを付けない。
class OshiMessageBubble extends StatefulWidget {
  const OshiMessageBubble({
    super.key,
    required this.situation,
    this.strings,
    this.seed,
    this.now,
    this.avatar,
    this.emoji = '🌟',
    this.onChanged,
  });

  final OshiMessageContext situation;
  final OshiMessageStrings? strings;
  final int? seed;
  final DateTime? now;

  /// キャラ画像など。null なら [emoji]。
  final Widget? avatar;
  final String emoji;
  final ValueChanged<OshiMessage>? onChanged;

  @override
  State<OshiMessageBubble> createState() => _OshiMessageBubbleState();
}

class _OshiMessageBubbleState extends State<OshiMessageBubble> {
  int _salt = 0;

  @override
  Widget build(BuildContext context) {
    final strings =
        widget.strings ?? OshiMessageStrings.forLanguageCode(KitStrings.of(context).languageCode);
    final engine = OshiMessageEngine(strings: strings);
    final seed = widget.seed ?? OshiMessageEngine.seedFromDate(widget.now ?? DateTime.now());
    final msg = engine.pick(widget.situation, seed: seed, salt: _salt);
    if (msg.text.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return Semantics(
      container: true,
      button: true,
      label: msg.text,
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
                      child: Text(
                        msg.text,
                        key: ValueKey(msg.id),
                        style: TextStyle(color: scheme.onSecondaryContainer, height: 1.4),
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
    final strings =
        widget.strings ?? OshiMessageStrings.forLanguageCode(KitStrings.of(context).languageCode);
    final seed = widget.seed ?? OshiMessageEngine.seedFromDate(widget.now ?? DateTime.now());
    widget.onChanged?.call(
      OshiMessageEngine(strings: strings).pick(widget.situation, seed: seed, salt: _salt),
    );
  }
}
