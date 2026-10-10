import 'package:flutter/widgets.dart';

import '../outfit/outfit_models.dart';
import '../theme/ukalab_palette.dart';

/// 成長段階（習得度で決まる。Lv1〜5）。
enum MascotStage {
  lv1,
  lv2,
  lv3,
  lv4,
  lv5;

  int get level => index + 1;
}

/// 表情。責める・落ち込む表情は作らない。
enum MascotExpression { normal, joy }

/// 場面別・案内役のポーズ（画像パックのみ）。標準キャラ（コード描画）には無い。
enum MascotScene {
  /// 試験日の前日: 応援のポーズ
  eve,

  /// 久しぶりに開いた: おかえりのポーズ
  welcomeBack,

  /// 連続して学習している: 炎のポーズ
  streak,

  /// 案内役: 指さし（レベルに関係なく Lv1 の絵）
  guidePoint,

  /// 案内役: 考える（電球）
  guideThink,

  /// 案内役: 白紙の本を見せて教える
  guideTeach;

  /// 案内役のポーズか（学習の進み具合に関係なく使える）。
  bool get isGuide => index >= MascotScene.guidePoint.index;
}

/// 試験日が近いときの装い（日程連動。無料）。
enum ExamPhase {
  /// 試験日を設定していない／まだ遠い
  none,

  /// 30日以内
  approaching,

  /// 7日以内（はちまき）
  close,

  /// 前日
  eve,

  /// 当日
  today,
}

/// 口調。セリフの文言はパックごとに管理する。
enum MascotTone { gentle, cool, cheerful, relaxed }

/// 表示サイズ（設定: 推しを小さく／非表示）。
enum MascotDisplay { normal, small, hidden }

/// 画像パックの画像を返す関数。null ならコード描画に戻す。
typedef MascotImageBuilder = ImageProvider? Function(
  MascotStage stage,
  MascotExpression expression,
);

/// 衣装を着た姿の画像を返す関数。null なら通常の画像（[MascotImageBuilder]）に戻す。
typedef MascotOutfitImageBuilder = ImageProvider? Function(
  Outfit outfit,
  MascotStage stage,
);

/// 場面別のポーズ画像を返す関数。null なら通常の画像（[MascotImageBuilder]）に戻す。
typedef MascotSceneImageBuilder = ImageProvider? Function(
  MascotScene scene,
  MascotStage stage,
);

/// キャラクターパック（データ）。ロジックは共通で、見た目とセリフの口調だけが違う。
///
/// 標準キャラ（フラスコの助手）は [CharacterPack.standard] で、コード描画のため画像不要。
/// AI 画像のパックは [imageBuilder] を渡して作る（選択時に取得する想定）。
class CharacterPack {
  const CharacterPack({
    required this.id,
    required this.name,
    required this.tone,
    this.imageBuilder,
    this.outfitImageBuilder,
    this.sceneImageBuilder,
    this.fieldAccent = const {},
    this.signature,
  });

  final String id;
  final String name;
  final MascotTone tone;

  /// 段階×表情の画像。null ならコード描画（標準キャラ）。
  final MascotImageBuilder? imageBuilder;

  /// 衣装を着た姿の画像。null または結果が null のときは通常の画像を使う。
  final MascotOutfitImageBuilder? outfitImageBuilder;

  /// 場面別のポーズ画像。null または結果が null のときは通常の画像を使う。
  final MascotSceneImageBuilder? sceneImageBuilder;

  /// 分野ごとの差し色。なければ分野色（テーマ）を使う。
  final Map<UkalabField, Color> fieldAccent;

  /// 配信データの署名（検証は配信を実装するときに追加）。
  final String? signature;

  bool get isBuiltIn => imageBuilder == null;

  /// 標準キャラ「フラスコの助手」（仮名「うか」）。
  static const CharacterPack standard = CharacterPack(
    id: 'standard',
    name: 'うか',
    tone: MascotTone.gentle,
  );
}
