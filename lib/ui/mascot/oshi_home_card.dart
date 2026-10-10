import 'package:app_common_kit/app_common_kit.dart';
import '../ukalab_scope.dart';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../coin/coin_provider.dart';
import '../outfit/outfit_models.dart';
import '../outfit/outfit_provider.dart';
import '../outfit/pass_report.dart';
import '../outfit/wardrobe_screen.dart';
import '../theme/ukalab_palette.dart';
import 'character_selection.dart';
import 'mascot_lines.dart';
import 'mascot_logic.dart';
import 'mascot_models.dart';
import 'mascot_widget.dart';

/// ホームに置く「推し」カードの完成品。アプリは資格と成長段階を渡すだけで使える。
///
/// - 選んだ推し（[selectedCharacterPackProvider]）と、着ている衣装を表示する
/// - 試験日・連続学習・久しぶり（おかえり）に合わせたひとこと。タップで切り替わる
/// - メニュー: 推しを選ぶ／着替え・ショップ／試験の結果を報告／通常・小さく・非表示
/// - 表示設定（通常/小さく/非表示）は [appId] ごとに端末内へ保存する
///
/// 成長段階の求め方はアプリごとに違うので、[stage] はアプリが計算して渡す
/// （習得度から [MasteryModel.standard] で求めるのが標準）。
class UkalabOshiCard extends ConsumerStatefulWidget {
  const UkalabOshiCard({
    super.key,
    required this.cert,
    required this.stage,
    required this.appId,
    this.examDate,
    this.streakDays = 0,
    this.studiedToday = false,
    this.daysSinceLastStudy,
    this.onShare,
    this.greeting,
    this.now,
  });

  final UkalabCert cert;
  final MascotStage stage;

  /// 表示設定の保存キーに使う（例: `boki3`）。
  final String appId;
  final DateTime? examDate;
  final int streakDays;
  final bool studiedToday;
  final int? daysSinceLastStudy;

  /// 合格報告の共有ボタン（アプリが OS の共有シートを実装して渡す）。
  final Future<void> Function(Uint8List png)? onShare;

  /// 特別な状況がないときのあいさつ。null なら標準のセリフ集。
  final String Function(DateTime now, int seed)? greeting;

  /// テスト用の現在時刻。
  final DateTime? now;

  @override
  ConsumerState<UkalabOshiCard> createState() => _UkalabOshiCardState();
}

enum _Action { choose, wardrobe, passReport }

class _UkalabOshiCardState extends ConsumerState<UkalabOshiCard> {
  int _seed = 0;
  MascotDisplay _display = MascotDisplay.normal;

  String get _key => 'ukalab.oshi.display.${widget.appId}';

  @override
  void initState() {
    super.initState();
    _loadDisplay();
  }

  Future<void> _loadDisplay() async {
    try {
      final p = await SharedPreferences.getInstance();
      final v = p.getString(_key);
      if (v == null || !mounted) return;
      setState(() {
        _display = MascotDisplay.values.firstWhere((e) => e.name == v, orElse: () => MascotDisplay.normal);
      });
    } catch (_) {}
  }

  Future<void> _setDisplay(MascotDisplay d) async {
    setState(() => _display = d);
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_key, d.name);
    } catch (_) {}
  }

  MascotSituation _situation(MascotDayState day, DateTime now) {
    switch (day.examPhase(now)) {
      case ExamPhase.today:
        return MascotSituation.examToday;
      case ExamPhase.eve:
        return MascotSituation.examEve;
      case ExamPhase.close:
        return MascotSituation.examClose;
      case ExamPhase.approaching:
        return MascotSituation.examApproaching;
      case ExamPhase.none:
        break;
    }
    if (day.isWelcomeBack) return MascotSituation.welcomeBack;
    if (day.studiedToday) return MascotSituation.studied;
    if (day.streakDays >= 3) return MascotSituation.streak;
    return MascotSituation.greeting;
  }

  MascotScene? _scene(MascotSituation s) {
    switch (s) {
      case MascotSituation.examEve:
        return MascotScene.eve;
      case MascotSituation.welcomeBack:
        return MascotScene.welcomeBack;
      case MascotSituation.streak:
        return MascotScene.streak;
      default:
        return null;
    }
  }

  void _onMenu(Object value) {
    if (value is MascotDisplay) {
      _setDisplay(value);
      return;
    }
    final pack = ref.read(selectedCharacterPackProvider);
    // 積まれる画面・ダイアログは Scope の外になりうるので、このカードの文言を渡す。
    final strings = KitStrings.of(context);
    final now = widget.now ?? DateTime.now();
    final phase = MascotDayState(examDate: widget.examDate).examPhase(now);
    switch (value as _Action) {
      case _Action.choose:
        Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const CharacterSelectScreen()));
      case _Action.wardrobe:
        Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) =>
              WardrobeScreen(cert: widget.cert, examPhase: phase, stage: widget.stage, pack: pack, strings: strings),
        ));
      case _Action.passReport:
        showPassReportDialog(
          context,
          ref,
          cert: widget.cert,
          stage: widget.stage,
          pack: pack,
          onShare: widget.onShare,
          strings: strings,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pack = ref.watch(selectedCharacterPackProvider);
    final now = widget.now ?? DateTime.now();
    final day = MascotDayState(
      studiedToday: widget.studiedToday,
      streakDays: widget.streakDays,
      daysSinceLastStudy: widget.daysSinceLastStudy,
      examDate: widget.examDate,
    );
    final phase = day.examPhase(now);
    final situation = _situation(day, now);

    // コインと衣装は付加機能。未設定でも画面は出す。
    int? balance;
    try {
      balance = ref.watch(coinProvider).balance;
    } catch (_) {}
    Outfit? outfit;
    try {
      outfit = ref.watch(equippedOutfitProvider);
    } catch (_) {}

    final s = KitStrings.of(context);
    final lines = MascotLines.forTone(
      pack.tone,
      lang: s.languageCode,
      custom: UkalabScope.mascotLinesOf(context),
    );
    final line = (situation == MascotSituation.greeting && widget.greeting != null)
        ? widget.greeting!(now, _seed)
        : lines.pick(situation, seed: _seed);
    final small = _display == MascotDisplay.small;

    final menu = PopupMenuButton<Object>(
      tooltip: s.oshiMenuTooltip,
      icon: const Icon(Icons.more_vert),
      onSelected: _onMenu,
      itemBuilder: (_) => [
        PopupMenuItem(value: _Action.choose, child: Text(s.oshiChoose)),
        PopupMenuItem(value: _Action.wardrobe, child: Text(s.wardrobeTitle)),
        PopupMenuItem(value: _Action.passReport, child: Text(s.oshiPassReport)),
        const PopupMenuDivider(),
        PopupMenuItem(value: MascotDisplay.normal, child: Text(s.oshiDisplayNormal)),
        PopupMenuItem(value: MascotDisplay.small, child: Text(s.oshiDisplaySmall)),
        PopupMenuItem(value: MascotDisplay.hidden, child: Text(s.oshiDisplayHidden)),
      ],
    );

    if (_display == MascotDisplay.hidden) {
      return Card(
        child: ListTile(
          title: Text(balance == null ? s.oshiName : s.coinBalance(balance), style: theme.textTheme.labelLarge),
          subtitle: Text(s.oshiHiddenNote),
          trailing: menu,
        ),
      );
    }

    final mascot = MascotWidget(
      pack: pack,
      stage: widget.stage,
      outfit: outfit,
      scene: _scene(situation),
      expression: day.expression,
      examPhase: phase,
      display: _display,
      size: small ? 56 : 88,
      line: small ? null : line,
      onTap: () => setState(() => _seed++),
    );
    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${pack.isBuiltIn ? s.oshiYours : pack.name}  Lv${widget.stage.level}', style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(small ? line : s.oshiTapHint, style: theme.textTheme.bodySmall),
        if (balance != null) ...[
          const SizedBox(height: 4),
          Text(s.coinBalance(balance), style: theme.textTheme.labelMedium),
        ],
        const SizedBox(height: 4),
        StreakBadge(days: widget.streakDays),
      ],
    );

    // 通常表示は吹き出し（最大200dp）が横幅を取るので、推しを上、説明を下の行に置く。
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
        child: small
            ? Row(children: [mascot, const SizedBox(width: 12), Expanded(child: info), menu])
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(child: mascot),
                  const SizedBox(height: 8),
                  Row(children: [Expanded(child: info), menu]),
                ],
              ),
      ),
    );
  }
}
