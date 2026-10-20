import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ukalab_core/ui.dart';

void main() {
  const circa = UkalabCharacters.circa;

  test('circa の定義: id・プレミアム限定・対象アプリ・衣装なし', () {
    expect(circa.id, 'circa');
    expect(circa.name, 'サーキ');
    expect(circa.isBuiltIn, false);
    expect(circa.requiresPremium, true);
    expect(circa.appIds, {'g_kentei', 'it_passport', 'info_security', 'gen_ai_passport'});
    expect(circa.isAvailableIn('it_passport'), true);
    expect(circa.isAvailableIn('boki3'), false);
    expect(circa.outfitImageBuilder, isNull); // 衣装は作らない（通常の画像で表示）
    expect(circa.imageBuilder!(MascotStage.lv1, MascotExpression.normal), isNotNull);
    expect(circa.sceneImageBuilder!(MascotScene.eve, MascotStage.lv3), isNotNull);
  });

  test('既存キャラは requiresPremium=false・appIds=null のまま', () {
    for (final p in UkalabCharacters.all) {
      expect(p.requiresPremium, false, reason: p.id);
      expect(p.appIds, isNull, reason: p.id);
      expect(p.isAvailableIn('anything'), true, reason: p.id);
    }
  });

  test('qualificationPacks は all / imagePacks に混ざらず、byId で解決できる', () {
    expect(UkalabCharacters.qualificationPacks.map((p) => p.id), ['circa']);
    expect(UkalabCharacters.all.map((p) => p.id), ['standard', 'kai', 'mio', 'moka', 'mike']);
    expect(UkalabCharacters.imagePacks.map((p) => p.id), ['kai', 'mio', 'moka', 'mike']);
    expect(UkalabCharacters.byId('circa').id, 'circa');
    expect(UkalabCharacters.byId('circa').requiresPremium, true);
    expect(UkalabCharacters.byId('zzz').id, 'standard');
    expect(UkalabCharacters.icon(circa), isNotNull);
    expect(UkalabCharacters.specialPassImage('circa'), isNotNull);
    expect(UkalabCharacters.poseImage('circa', MascotPose.cheer), isNotNull);
  });

  test('名前と役割の文言が全言語にある', () {
    expect(UkalabStrings.ja.characterNames['circa'], 'サーキ');
    expect(UkalabStrings.en.characterNames['circa'], 'Circa');
    for (final s in [UkalabStrings.ja, UkalabStrings.en]) {
      expect(s.characterRoles['circa'], isNotEmpty);
    }
    expect(UkalabStrings.ja.characterRoles['circa'], contains('回路ネコ'));
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
