import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ukalab_core/ui.dart';

void main() {
  const circa = UkalabCharacters.circa;

  test('circa の定義: id・プレミアム限定・ITパスポート専用・衣装なし・B(場面別)なし', () {
    expect(circa.id, 'circa');
    expect(circa.name, 'サーキ');
    expect(circa.isBuiltIn, false);
    expect(circa.requiresPremium, true);
    expect(circa.appIds, {'it_passport'});
    expect(circa.isAvailableIn('it_passport'), true);
    expect(circa.isAvailableIn('boki3'), false);
    expect(circa.isAvailableIn('g_kentei'), false);
    expect(circa.outfitImageBuilder, isNull); // 衣装は作らない（通常の画像で表示）
    expect(circa.imageBuilder!(MascotStage.lv1, MascotExpression.normal), isNotNull);
    expect(circa.sceneImageBuilder, isNull); // 資格専用キャラは A と C のみ。場面別は Lv 画像で代用
  });

  test('既存キャラは requiresPremium=false・appIds=null のまま', () {
    for (final p in UkalabCharacters.all) {
      expect(p.requiresPremium, false, reason: p.id);
      expect(p.appIds, isNull, reason: p.id);
      expect(p.isAvailableIn('anything'), true, reason: p.id);
    }
  });

  test('qualificationPacks は all / imagePacks に混ざらず、byId で解決できる', () {
    expect(UkalabCharacters.qualificationPacks.map((p) => p.id), ['circa', 'noda', 'sheru', 'hirari', 'soro', 'sala', 'tatsu']);
    expect(UkalabCharacters.all.map((p) => p.id), ['standard', 'kai', 'mio', 'moka', 'mike']);
    expect(UkalabCharacters.imagePacks.map((p) => p.id), ['kai', 'mio', 'moka', 'mike']);
    expect(UkalabCharacters.byId('circa').id, 'circa');
    expect(UkalabCharacters.byId('circa').requiresPremium, true);
    expect(UkalabCharacters.byId('zzz').id, 'standard');
    expect(UkalabCharacters.icon(circa), isNotNull);
    expect(UkalabCharacters.specialPassImage('circa'), isNotNull);
    expect(UkalabCharacters.poseImage('circa', MascotPose.cheer), isNull); // B は無い
  });

  test('名前と役割の文言が全言語にある', () {
    expect(UkalabStrings.ja.characterNames['circa'], 'サーキ');
    expect(UkalabStrings.en.characterNames['circa'], 'Circa');
    for (final s in [UkalabStrings.ja, UkalabStrings.en]) {
      expect(s.characterRoles['circa'], isNotEmpty);
    }
    expect(UkalabStrings.ja.characterRoles['circa'], contains('回路ネコ'));
  });

  test('資格専用キャラ7体: appIds・プレミアム限定・衣装なし・B なし・A の画像参照', () {
    const expected = {
      'circa': {'it_passport'},
      'noda': {'g_kentei'},
      'sheru': {'info_security'},
      'hirari': {'gen_ai_passport'},
      'soro': {'boki3'},
      'sala': {'hazmat4'},
      'tatsu': {'kanji_kentei'},
    };
    expect(UkalabCharacters.qualificationPacks.length, expected.length);
    for (final p in UkalabCharacters.qualificationPacks) {
      expect(p.appIds, expected[p.id], reason: p.id);
      expect(p.requiresPremium, true, reason: p.id);
      expect(p.isBuiltIn, false, reason: p.id);
      expect(p.outfitImageBuilder, isNull, reason: p.id);
      expect(p.sceneImageBuilder, isNull, reason: p.id);
      expect(UkalabCharacters.hasSceneImages(p.id), false, reason: p.id);
      expect(UkalabCharacters.byId(p.id).id, p.id);
      expect(UkalabCharacters.icon(p), isNotNull, reason: p.id);
      expect(UkalabCharacters.specialPassImage(p.id), isNotNull, reason: p.id);
      expect(UkalabCharacters.specialBowImage(p.id), isNotNull, reason: p.id);
      for (final s in MascotStage.values) {
        for (final e in MascotExpression.values) {
          expect(p.imageBuilder!(s, e), isNotNull, reason: p.id);
        }
      }
      // 場面別・ポーズ・状態(B)は null を返す(存在しないファイルを指さない)
      for (final sc in MascotScene.values) {
        expect(UkalabCharacters.sceneImage(p.id, sc, MascotStage.lv3), isNull, reason: '${p.id} $sc');
      }
      for (final po in MascotPose.values) {
        expect(UkalabCharacters.poseImage(p.id, po), isNull, reason: '${p.id} $po');
      }
      for (final st in MascotState.values) {
        expect(UkalabCharacters.stateImage(p.id, st), isNull, reason: '${p.id} $st');
      }
    }
  });

  test('appId での絞り込み(qualificationPacksFor)', () {
    expect(UkalabCharacters.qualificationPacksFor('it_passport').map((p) => p.id), ['circa']);
    expect(UkalabCharacters.qualificationPacksFor('g_kentei').map((p) => p.id), ['noda']);
    expect(UkalabCharacters.qualificationPacksFor('kanji_kentei').map((p) => p.id), ['tatsu']);
    expect(UkalabCharacters.qualificationPacksFor('unknown_app'), isEmpty);
    expect(UkalabCharacters.qualificationPacksFor(null), isEmpty);
  });

  test('名前と役割の文言が全言語・全資格キャラにある', () {
    const ids = ['circa', 'noda', 'sheru', 'hirari', 'soro', 'sala', 'tatsu'];
    for (final s in [UkalabStrings.ja, UkalabStrings.en, UkalabStrings.ko, UkalabStrings.zhHans, UkalabStrings.zhHant]) {
      for (final id in ids) {
        expect(s.characterRoles[id], isNotEmpty, reason: id);
      }
      expect(s.characterQualificationHeading, isNotEmpty);
      expect(s.characterPremiumNote, isNotEmpty);
      expect(s.characterPreviewNote, isNotEmpty);
      expect(s.characterPurchaseAction, isNotEmpty);
      // 非公式の立場: 保証・公式を思わせる語を使わない
      final all = [
        ...ids.map((i) => s.characterRoles[i]!),
        s.characterQualificationHeading,
        s.characterPremiumNote,
        s.characterPreviewNote,
        s.characterPurchaseAction,
      ].join(' ');
      for (final w in ['公式', '認定', '保証', 'official', 'certified', 'guarantee']) {
        expect(all.toLowerCase().contains(w), false, reason: w);
      }
    }
    expect(UkalabStrings.ja.characterNames['noda'], 'ノーダ');
    expect(UkalabStrings.en.characterNames['tatsu'], 'Tatsu');
  });

  // 画像は PR-A で入る。ディレクトリがあるときだけ検査する。
  final dir = Directory('assets/mascot/circa');
  test('circa の画像（assets/mascot/circa/ があるときだけ）', () {
    for (final s in MascotStage.values) {
      for (final e in MascotExpression.values) {
        final n = e == MascotExpression.joy ? 'joy' : 'normal';
        expect(File('assets/mascot/circa/circa_lv${s.level}_$n.webp').existsSync(), true);
      }
    }
    expect(File('assets/mascot/circa/circa_icon_256.webp').existsSync(), true);
  }, skip: dir.existsSync() ? false : 'assets/mascot/circa/ は PR-A で追加');
}
