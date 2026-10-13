import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ukalab_core/ui.dart';

void main() {
  test('4体×ポーズ5種・状態5種の画像が存在する', () {
    for (final p in UkalabCharacters.imagePacks) {
      for (final pose in MascotPose.values) {
        final img = UkalabCharacters.poseImage(p.id, pose)! as AssetImage;
        expect(File(img.assetName).existsSync(), true, reason: img.assetName);
      }
      for (final st in MascotState.values) {
        final img = UkalabCharacters.stateImage(p.id, st)! as AssetImage;
        expect(File(img.assetName).existsSync(), true, reason: img.assetName);
      }
    }
  });

  test('標準キャラは画像なし（コード描画）', () {
    expect(UkalabCharacters.poseImage('standard', MascotPose.cheer), isNull);
    expect(UkalabCharacters.stateImage('standard', MascotState.empty), isNull);
  });

  test('MascotScene.streak は新素材 states/<id>_streak を全Lvで返す（API互換）', () {
    for (final s in MascotStage.values) {
      final img = UkalabCharacters.sceneImage('kai', MascotScene.streak, s)! as AssetImage;
      expect(img.assetName, 'assets/mascot/kai/states/kai_streak.webp');
      expect(UkalabCharacters.kai.sceneImageBuilder!(MascotScene.streak, s), isNotNull);
    }
  });

  testWidgets('MascotStateView: メッセージとボタン、読み込み中はインジケーター', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MascotStateView.empty(
            pack: UkalabCharacters.mio,
            message: 'まだありません',
            actionLabel: 'はじめる',
            onAction: () => tapped = true,
          ),
        ),
      ),
    );
    expect(find.text('まだありません'), findsOneWidget);
    await tester.tap(find.text('はじめる'));
    expect(tapped, true);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MascotStateView.loading(pack: CharacterPack.standard, message: '読み込み中'),
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(MascotWidget), findsOneWidget);
  });
}
