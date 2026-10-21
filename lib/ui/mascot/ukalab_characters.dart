import 'package:flutter/widgets.dart';

import '../outfit/outfit_models.dart';
import '../theme/ukalab_palette.dart';
import 'mascot_models.dart';

/// うかラボ共通の推し（AI画像の4体）。標準キャラ「うか」は [CharacterPack.standard]。
///
/// 画像は本パッケージの `assets/mascot/<id>/`。衣装は `outfits/<資格id>_<normal|pass|exam>.webp`。
/// 場面別ポーズは `scenes/<id>_lv<1-5>_<eve|back>.webp`（連続は `states/<id>_streak.webp`）、案内役ポーズは `guide/<id>_guide_<point|think|teach>.webp`。
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
    'it_passport',
    'info_security',
    'data_management',
    'ds_kentei',
    'fe',
    'gen_ai_practitioner',
    'sme_consultant',
    'sme_ma',
    'denken3',
    'drone',
    'japanese_teacher',
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

  /// 資格専用キャラ「サーキ」(ITパスポート専用、回路ネコ)。プレミアム限定。衣装は作らない(outfitImageBuilder なし=通常の画像)。
  ///
  /// 資格専用キャラの画像は A(icon・Lv1〜5 の normal/joy・special_pass/bow)と C(items)のみ。
  /// B(scenes/states/guide/poses)は無いので sceneImageBuilder は持たず、場面・ポーズは Lv 画像で代用する。
  /// 画像は PR-A で `assets/mascot/<id>/` に入れる。pubspec.yaml への登録も PR-A で行う
  /// (ディレクトリが空だと Flutter のビルドが失敗するため、画像が入るまで登録しない)。
  /// 画像はすべて AI 生成。試験団体とは関係のないキャラ。
  static const circa = CharacterPack(
    id: 'circa',
    name: 'サーキ',
    tone: MascotTone.cool,
    imageBuilder: _circaImage,
    requiresPremium: true,
    appIds: {'it_passport'},
  );

  /// 資格専用キャラ「ノーダ」(G検定。タコ。主色は青紫、差し色は光の点の黄)。
  static const noda = CharacterPack(
    id: 'noda',
    name: 'ノーダ',
    tone: MascotTone.cool,
    imageBuilder: _nodaImage,
    requiresPremium: true,
    appIds: {'g_kentei'},
  );

  /// 資格専用キャラ「シェル」(情報セキュリティマネジメント。カメ。主色は深緑、差し色は鍵の金)。
  static const sheru = CharacterPack(
    id: 'sheru',
    name: 'シェル',
    tone: MascotTone.gentle,
    imageBuilder: _sheruImage,
    requiresPremium: true,
    appIds: {'info_security'},
  );

  /// 資格専用キャラ「ヒラリ」(生成AIパスポート。蝶。主色は蘭色、差し色は羽の縁の黄)。
  static const hirari = CharacterPack(
    id: 'hirari',
    name: 'ヒラリ',
    tone: MascotTone.cheerful,
    imageBuilder: _hirariImage,
    requiresPremium: true,
    appIds: {'gen_ai_passport'},
  );

  /// 資格専用キャラ「ソロ」(簿記3級。ハリネズミ。主色はえんじ、差し色は珠のクリーム)。
  /// appIds は資格id(`boki3`)の綴り。アプリ側の識別子との一致は PR-D で確認する。
  static const soro = CharacterPack(
    id: 'soro',
    name: 'ソロ',
    tone: MascotTone.relaxed,
    imageBuilder: _soroImage,
    requiresPremium: true,
    appIds: {'boki3'},
  );

  /// 資格専用キャラ「サラ」(危険物乙4。火とかげ。主色は紅、差し色は火の黄)。
  /// appIds は資格id(`hazmat4`)の綴り。アプリ側の識別子との一致は PR-D で確認する。
  static const sala = CharacterPack(
    id: 'sala',
    name: 'サラ',
    tone: MascotTone.cheerful,
    imageBuilder: _salaImage,
    requiresPremium: true,
    appIds: {'hazmat4'},
  );

  /// 資格専用キャラ「タツ」(漢検。小さな龍。主色は墨黒、差し色は朱)。
  /// appIds は資格id(`kanji_kentei`)の綴り。アプリ側の識別子との一致は PR-D で確認する。
  static const tatsu = CharacterPack(
    id: 'tatsu',
    name: 'タツ',
    tone: MascotTone.gentle,
    imageBuilder: _tatsuImage,
    requiresPremium: true,
    appIds: {'kanji_kentei'},
  );

  /// 選べる全員（標準キャラ＋画像4体）。
  static const List<CharacterPack> all = [CharacterPack.standard, kai, mio, moka, mike];

  /// 画像4体だけ。
  static const List<CharacterPack> imagePacks = [kai, mio, moka, mike];

  /// 資格専用キャラ。[all] には含めない(選択画面が appId で絞って別枠に出す)。
  static const List<CharacterPack> qualificationPacks = [circa, noda, sheru, hirari, soro, sala, tatsu];

  /// [appId] のアプリで有効な資格専用キャラ。[appId] が null なら空(アプリが未設定のときは出さない)。
  static List<CharacterPack> qualificationPacksFor(String? appId) =>
      appId == null ? const [] : [for (final p in qualificationPacks) if (p.isAvailableIn(appId)) p];

  /// 資格専用キャラか([qualificationPacks] に含まれるか)。
  static bool isQualification(CharacterPack pack) => qualificationPacks.any((p) => p.id == pack.id);

  /// [all] と [qualificationPacks] から id で探す。不明な id は標準キャラ。
  /// 資格キャラのプレミアム・アプリ判定は呼び出し側（アプリ）で行う。
  static CharacterPack byId(String? id) {
    for (final p in all) {
      if (p.id == id) return p;
    }
    for (final p in qualificationPacks) {
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

  /// 特別ポーズ（合格の喜び）。`assets/mascot/<id>/<id>_special_pass.webp`。標準キャラは null。
  static ImageProvider? specialPassImage(String id) => _special(id, 'pass');

  /// 特別ポーズ（おじぎ。お礼・あいさつ用）。`assets/mascot/<id>/<id>_special_bow.webp`。標準キャラは null。
  static ImageProvider? specialBowImage(String id) => _special(id, 'bow');

  static ImageProvider? _special(String id, String kind) {
    if (!_hasImages(id)) return null;
    return AssetImage('assets/mascot/$id/${id}_special_$kind.webp', package: package);
  }

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
        return '${id}_streak'; // 新素材（全Lv共通）。画像は states/
      case MascotScene.guidePoint:
        return '${id}_guide_point';
      case MascotScene.guideThink:
        return '${id}_guide_think';
      case MascotScene.guideTeach:
        return '${id}_guide_teach';
    }
  }

  /// 場面別ポーズ・ポーズ・状態の画像(B)があるキャラか。資格専用キャラには B が無い(A と C のみ)。
  static bool hasSceneImages(String id) => imagePacks.any((p) => p.id == id);

  /// 場面別ポーズの画像。前日・おかえり・連続は Lv1〜5 のそれぞれの姿（名札・かばん・腕章・卒業帽など）で返す。
  /// 案内役ポーズ（guide*）はレベルに関係なく Lv1 の絵を返す。B が無いキャラは null。
  static ImageProvider? sceneImage(String id, MascotScene scene, MascotStage stage) {
    if (!hasSceneImages(id)) return null; // 資格専用キャラ・標準キャラ: 呼び出し側が Lv 画像に戻す
    if (scene.isGuide) {
      return AssetImage('assets/mascot/$id/guide/${sceneFile(id, scene)}.webp', package: package);
    }
    if (scene == MascotScene.streak) return stateImage(id, MascotState.streak);
    return AssetImage('assets/mascot/$id/scenes/${sceneFile(id, scene, stage)}.webp', package: package);
  }

  /// 場面別ポーズの画像があるフォルダ（`guide` / `scenes` / `states`）。
  static String sceneDir(MascotScene scene) =>
      scene.isGuide ? 'guide' : (scene == MascotScene.streak ? 'states' : 'scenes');

  static bool _hasImages(String id) =>
      imagePacks.any((p) => p.id == id) || qualificationPacks.any((p) => p.id == id);

  /// 表情・しぐさのポーズ画像（`poses/<id>_<pose>.webp`）。標準キャラ・資格専用キャラ(B 無し)・未知の id は null。
  static ImageProvider? poseImage(String id, MascotPose pose) =>
      hasSceneImages(id) ? AssetImage('assets/mascot/$id/poses/${id}_${pose.name}.webp', package: package) : null;

  /// 共通画面用の状態ポーズ画像（`states/<id>_<state>.webp`）。標準キャラ・資格専用キャラ(B 無し)・未知の id は null。
  static ImageProvider? stateImage(String id, MascotState state) =>
      hasSceneImages(id) ? AssetImage('assets/mascot/$id/states/${id}_${state.name}.webp', package: package) : null;

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
  static ImageProvider? _circaImage(MascotStage s, MascotExpression e) => levelImage('circa', s, e);
  static ImageProvider? _nodaImage(MascotStage s, MascotExpression e) => levelImage('noda', s, e);
  static ImageProvider? _sheruImage(MascotStage s, MascotExpression e) => levelImage('sheru', s, e);
  static ImageProvider? _hirariImage(MascotStage s, MascotExpression e) => levelImage('hirari', s, e);
  static ImageProvider? _soroImage(MascotStage s, MascotExpression e) => levelImage('soro', s, e);
  static ImageProvider? _salaImage(MascotStage s, MascotExpression e) => levelImage('sala', s, e);
  static ImageProvider? _tatsuImage(MascotStage s, MascotExpression e) => levelImage('tatsu', s, e);
}
