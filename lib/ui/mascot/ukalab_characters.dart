import 'package:flutter/widgets.dart';

import '../outfit/outfit_models.dart';
import '../theme/ukalab_palette.dart';
import 'mascot_models.dart';

/// うかラボ共通の推し（AI画像の4体）。標準キャラ「うか」は [CharacterPack.standard]。
///
/// 画像は本パッケージの `assets/mascot/<id>/`。衣装は `outfits/<資格id>_<normal|pass|exam>.webp`。
/// 場面別ポーズは `scenes/<id>_lv<1-5>_<eve|back|streak>.webp`、案内役ポーズは `guide/<id>_guide_<point|think|teach>.webp`。
/// 衣装の画像があるのは、いまは漢字検定・バイク免許・G検定・簿記3級・危険物乙4・生成AIパスポート（ない資格は私服のまま）。
class UkalabCharacters {
  const UkalabCharacters._();

  static const String package = 'ukalab_core';

  /// 衣装画像のある資格。
  static const Set<String> costumedCerts = {
    'kanji_kentei',
    'bike_license',
    'g_kentei',
    'boki3',
    'hazmat4',
    'gen_ai_passport',
  };

  static const kai = CharacterPack(
    id: 'kai',
    name: 'カイ',
    tone: MascotTone.gentle,
    imageBuilder: _kaiImage,
    outfitImageBuilder: _kaiOutfit,
    sceneImageBuilder: _kaiScene,
  );
  static const mio = CharacterPack(
    id: 'mio',
    name: 'ミオ',
    tone: MascotTone.cheerful,
    imageBuilder: _mioImage,
    outfitImageBuilder: _mioOutfit,
    sceneImageBuilder: _mioScene,
  );
  static const moka = CharacterPack(
    id: 'moka',
    name: 'モカ',
    tone: MascotTone.relaxed,
    imageBuilder: _mokaImage,
    outfitImageBuilder: _mokaOutfit,
    sceneImageBuilder: _mokaScene,
  );
  static const mike = CharacterPack(
    id: 'mike',
    name: 'ミケ',
    tone: MascotTone.cool,
    imageBuilder: _mikeImage,
    outfitImageBuilder: _mikeOutfit,
    sceneImageBuilder: _mikeScene,
  );

  /// 選べる全員（標準キャラ＋画像4体）。
  static const List<CharacterPack> all = [CharacterPack.standard, kai, mio, moka, mike];

  /// 画像4体だけ。
  static const List<CharacterPack> imagePacks = [kai, mio, moka, mike];

  static CharacterPack byId(String? id) {
    for (final p in all) {
      if (p.id == id) return p;
    }
    return CharacterPack.standard;
  }

  /// 小さな顔アイコン（選択画面用）。標準キャラは null（コード描画）。
  static ImageProvider? icon(CharacterPack pack) {
    if (pack.isBuiltIn) return null;
    return AssetImage('assets/mascot/${pack.id}/${pack.id}_icon_256.webp', package: package);
  }

  static ImageProvider levelImage(String id, MascotStage stage, MascotExpression e) => AssetImage(
        'assets/mascot/$id/${id}_lv${stage.level}_${e == MascotExpression.joy ? 'joy' : 'normal'}.webp',
        package: package,
      );

  /// 衣装の画像ファイル名（拡張子なし）。画像がなければ null。
  ///
  /// 通常衣装=normal・合格記念=pass・試験日=exam。準備完了は通常衣装の絵を使う。
  /// バイク免許の通常はLv5で lv5 の絵に変わる。
  static String? outfitFile(Outfit o, MascotStage stage) {
    if (!costumedCerts.contains(o.cert.id)) return null;
    final String kind;
    switch (o.kind) {
      case OutfitKind.passMemorial:
        kind = 'pass';
      case OutfitKind.examDay:
        kind = 'exam';
      case OutfitKind.regular:
      case OutfitKind.readiness:
        kind = (o.cert == UkalabCert.bikeLicense && stage.level >= 5) ? 'lv5' : 'normal';
    }
    if (kind == 'exam' && o.cert == UkalabCert.bikeLicense) return '${o.cert.id}_normal';
    return '${o.cert.id}_$kind';
  }

  static ImageProvider? outfitImage(String id, Outfit o, MascotStage stage) {
    final f = outfitFile(o, stage);
    if (f == null) return null;
    return AssetImage('assets/mascot/$id/outfits/$f.webp', package: package);
  }

  /// 場面別ポーズの画像ファイル名（拡張子なし）。前日・おかえり・連続は Lv ごとの絵（[stage]）、案内役は Lv1 の絵。
  static String sceneFile(String id, MascotScene scene, [MascotStage stage = MascotStage.lv1]) {
    switch (scene) {
      case MascotScene.eve:
        return '${id}_lv${stage.level}_eve';
      case MascotScene.welcomeBack:
        return '${id}_lv${stage.level}_back';
      case MascotScene.streak:
        return '${id}_lv${stage.level}_streak';
      case MascotScene.guidePoint:
        return '${id}_guide_point';
      case MascotScene.guideThink:
        return '${id}_guide_think';
      case MascotScene.guideTeach:
        return '${id}_guide_teach';
    }
  }

  /// 場面別ポーズの画像。前日・おかえり・連続は Lv1〜5 のそれぞれの姿（名札・かばん・腕章・卒業帽など）で返す。
  /// 案内役ポーズ（guide*）はレベルに関係なく Lv1 の絵を返す。
  static ImageProvider? sceneImage(String id, MascotScene scene, MascotStage stage) {
    if (scene.isGuide) {
      return AssetImage('assets/mascot/$id/guide/${sceneFile(id, scene)}.webp', package: package);
    }
    return AssetImage('assets/mascot/$id/scenes/${sceneFile(id, scene, stage)}.webp', package: package);
  }

  static ImageProvider? _kaiImage(MascotStage s, MascotExpression e) => levelImage('kai', s, e);
  static ImageProvider? _mioImage(MascotStage s, MascotExpression e) => levelImage('mio', s, e);
  static ImageProvider? _mokaImage(MascotStage s, MascotExpression e) => levelImage('moka', s, e);
  static ImageProvider? _mikeImage(MascotStage s, MascotExpression e) => levelImage('mike', s, e);
  static ImageProvider? _kaiOutfit(Outfit o, MascotStage s) => outfitImage('kai', o, s);
  static ImageProvider? _kaiScene(MascotScene sc, MascotStage s) => sceneImage('kai', sc, s);
  static ImageProvider? _mioOutfit(Outfit o, MascotStage s) => outfitImage('mio', o, s);
  static ImageProvider? _mioScene(MascotScene sc, MascotStage s) => sceneImage('mio', sc, s);
  static ImageProvider? _mokaOutfit(Outfit o, MascotStage s) => outfitImage('moka', o, s);
  static ImageProvider? _mokaScene(MascotScene sc, MascotStage s) => sceneImage('moka', sc, s);
  static ImageProvider? _mikeOutfit(Outfit o, MascotStage s) => outfitImage('mike', o, s);
  static ImageProvider? _mikeScene(MascotScene sc, MascotStage s) => sceneImage('mike', sc, s);
}
