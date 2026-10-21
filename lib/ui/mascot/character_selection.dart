import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'mascot_models.dart';
import 'mascot_widget.dart';
import 'ukalab_characters.dart';
import '../ukalab_strings.dart';

/// 選んだ推し（端末内）。キーはうかラボ共通なので、同じ端末の別アプリでも同じ推しになる。
/// （アプリごとにサンドボックスが別なら共有されない。その場合も各アプリ内では保存される）
///
/// 資格専用キャラを選んでいるときも、直前に選んだ共通キャラ（[lastCommon]）を別キーで覚えておく。
/// プレミアムが切れたときなど、資格専用キャラを使えなくなったら [lastCommon] に戻すため
/// （[effectiveCharacterPackProvider]）。保存している選択そのものは消さない。
class CharacterSelectionNotifier extends StateNotifier<CharacterPack> {
  CharacterSelectionNotifier() : super(CharacterPack.standard) {
    _load();
  }

  static const prefsKey = 'ukalab.mascot.selected';

  /// 直前に選んだ共通キャラ(標準キャラ・画像4体)のid。
  static const lastCommonPrefsKey = 'ukalab.mascot.lastCommon';

  CharacterPack _lastCommon = CharacterPack.standard;

  /// 直前に使っていた共通キャラ。未選択なら標準キャラ。
  CharacterPack get lastCommon => _lastCommon;

  Future<void> _load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final selected = UkalabCharacters.byId(p.getString(prefsKey));
      if (UkalabCharacters.isQualification(selected)) {
        final last = UkalabCharacters.byId(p.getString(lastCommonPrefsKey));
        _lastCommon = UkalabCharacters.isQualification(last) ? CharacterPack.standard : last;
      } else {
        _lastCommon = selected;
      }
      state = selected;
    } catch (_) {
      // 読めなければ標準キャラのまま。
    }
  }

  Future<void> select(CharacterPack pack) async {
    final isCommon = !UkalabCharacters.isQualification(pack);
    if (isCommon) _lastCommon = pack;
    state = pack;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(prefsKey, pack.id);
      if (isCommon) await p.setString(lastCommonPrefsKey, pack.id);
    } catch (_) {}
  }
}

/// 現在の推し。標準キャラ（うか）が既定。
///
/// 保存されている選択そのもの。資格専用キャラのアプリ・プレミアム判定は通っていない。
/// 表示には [effectiveCharacterPackProvider] を使う。
final selectedCharacterPackProvider =
    StateNotifierProvider<CharacterSelectionNotifier, CharacterPack>((ref) => CharacterSelectionNotifier());

/// このアプリのID(`UkalabCert` の綴り。例 `it_passport`)。資格専用キャラを絞り込む。
///
/// 既定は null で、資格専用キャラは選択画面に出ず、選択中でも共通キャラに戻る(従来どおりの動き)。
/// アプリが `ProviderScope(overrides: [characterAppIdProvider.overrideWithValue('it_passport')])` で渡す。
final characterAppIdProvider = Provider<String?>((ref) => null);

/// プレミアム購入者か。core は権利状態を読まないので、アプリが
/// `characterPremiumProvider.overrideWith((ref) => ref.watch(entitlementStateProvider).hasPremium)`
/// のように渡す。既定は false(資格専用キャラはロック)。
final characterPremiumProvider = Provider<bool>((ref) => false);

/// [pack] を今使えるか。共通キャラは常に true。
/// 資格専用キャラは、[appId] のアプリで有効で、[CharacterPack.requiresPremium] なら [isPremium] のときだけ true。
bool isCharacterUnlocked(CharacterPack pack, {required String? appId, required bool isPremium}) {
  if (!UkalabCharacters.isQualification(pack)) return true;
  if (appId == null || !pack.isAvailableIn(appId)) return false;
  return !pack.requiresPremium || isPremium;
}

/// 実際に表示する推し。[selected] を使えるならそのまま、使えない資格専用キャラ(プレミアム失効・別アプリ)なら
/// 直前に使っていた共通キャラ [lastCommon] に戻す。
CharacterPack resolveCharacterPack({
  required CharacterPack selected,
  required CharacterPack lastCommon,
  required String? appId,
  required bool isPremium,
}) {
  if (isCharacterUnlocked(selected, appId: appId, isPremium: isPremium)) return selected;
  return UkalabCharacters.isQualification(lastCommon) ? CharacterPack.standard : lastCommon;
}

/// 画面に出す推し。アプリ・プレミアムの判定を通した結果([resolveCharacterPack])。
/// 失効しても保存値は消さないので、権利が戻れば元の資格専用キャラに戻る。
final effectiveCharacterPackProvider = Provider<CharacterPack>((ref) {
  final selected = ref.watch(selectedCharacterPackProvider);
  final appId = ref.watch(characterAppIdProvider);
  final premium = ref.watch(characterPremiumProvider);
  final last = ref.read(selectedCharacterPackProvider.notifier).lastCommon;
  return resolveCharacterPack(selected: selected, lastCommon: last, appId: appId, isPremium: premium);
});

/// 推しを選ぶ画面。共通キャラは無料で全員選べる。
///
/// 続けて、このアプリ([characterAppIdProvider])の資格専用キャラを別枠で出す。プレミアム購入者
/// ([characterPremiumProvider])でなければロック表示で、タップするとプレビュー(選択は不可)を出す。
/// [onLockedTap] を渡すと、プレビューに購入導線のボタンが出る(購入の画面はアプリ側が開く)。
class CharacterSelectScreen extends ConsumerWidget {
  const CharacterSelectScreen({super.key, this.onLockedTap});

  /// プレビューの購入導線ボタンが押されたとき(設定の購入欄を開くなど)。null ならボタンを出さない。
  final VoidCallback? onLockedTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(effectiveCharacterPackProvider);
    final appId = ref.watch(characterAppIdProvider);
    final premium = ref.watch(characterPremiumProvider);
    final strings = UkalabStrings.of(context);
    final qualification = UkalabCharacters.qualificationPacksFor(appId);

    Widget card(CharacterPack p) {
      final unlocked = isCharacterUnlocked(p, appId: appId, isPremium: premium);
      return _CharacterCard(
        pack: p,
        selected: selected.id == p.id,
        locked: !unlocked,
        strings: strings,
        onTap: unlocked
            ? () => ref.read(selectedCharacterPackProvider.notifier).select(p)
            : () => _showPreview(context, p, strings),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(strings.oshiChoose)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final p in UkalabCharacters.all) card(p),
          if (qualification.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
              child: Semantics(
                header: true,
                child: Text(strings.characterQualificationHeading, style: Theme.of(context).textTheme.titleMedium),
              ),
            ),
            for (final p in qualification) card(p),
          ],
        ],
      ),
    );
  }

  /// ロック中のキャラのプレビュー(Lv1 と Lv5 の絵を見せるだけ。選択は変えない)。
  void _showPreview(BuildContext context, CharacterPack pack, UkalabStrings strings) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.characterNames[pack.id] ?? pack.name),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  MascotWidget(pack: pack, stage: MascotStage.lv1, size: 96, animate: false),
                  MascotWidget(pack: pack, stage: MascotStage.lv5, size: 96, animate: false),
                ],
              ),
              const SizedBox(height: 12),
              Text(strings.characterRoles[pack.id] ?? '', textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(strings.characterPreviewNote, textAlign: TextAlign.center),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text(strings.close)),
          if (onLockedTap != null)
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                onLockedTap!();
              },
              child: Text(strings.characterPurchaseAction),
            ),
        ],
      ),
    );
  }
}

class _CharacterCard extends StatelessWidget {
  const _CharacterCard({
    required this.pack,
    required this.selected,
    required this.locked,
    required this.strings,
    required this.onTap,
  });

  final CharacterPack pack;
  final bool selected;
  final bool locked;
  final UkalabStrings strings;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final role = strings.characterRoles[pack.id] ?? '';
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: selected ? theme.colorScheme.primary : Colors.transparent, width: 2),
      ),
      child: ListTile(
        leading: _Face(pack: pack),
        title: Text(strings.characterNames[pack.id] ?? pack.name),
        subtitle: locked
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [Text(role), Text(strings.characterPremiumNote)],
              )
            : Text(role),
        trailing: locked
            ? const Icon(Icons.lock_outline)
            : (selected ? const Icon(Icons.check_circle) : null),
        onTap: onTap,
      ),
    );
  }
}

class _Face extends StatelessWidget {
  const _Face({required this.pack});

  final CharacterPack pack;

  @override
  Widget build(BuildContext context) {
    final icon = UkalabCharacters.icon(pack);
    const fallback = Icon(Icons.science_outlined);
    return CircleAvatar(
      radius: 24,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      // 標準キャラ（画像なし）のアイコンが、アプリのテーマによっては背景と同色で見えなくなるため、
      // 前景色を明示する（バイク免許で一行目のアイコンが空白になっていた）。
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      // 画像が無い・読み込めないときは例外にせず、標準のアイコンを出す。
      child: icon == null
          ? fallback
          : ClipOval(
              child: Image(
                image: icon,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                excludeFromSemantics: true,
                errorBuilder: (_, __, ___) => fallback,
              ),
            ),
    );
  }
}
