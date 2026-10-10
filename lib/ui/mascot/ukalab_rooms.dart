import 'package:flutter/material.dart';

import '../outfit/outfit_models.dart';
import '../theme/ukalab_palette.dart';
import 'mascot_models.dart';
import 'mascot_widget.dart';
import 'ukalab_characters.dart';

/// 推しの部屋（分野色別の背景。キャラは含まない）。
enum UkalabRoom {
  /// 汎用（どの分野にも当てはまらないとき）
  general,
  it,
  ai,

  /// 会計・経営
  accounting,

  /// 技術・安全
  safety,

  /// 言語・教育（漢検の和室）
  language,

  /// 運輸（バイク免許のガレージ）
  transport,
}

/// 部屋の画像と、資格→部屋の対応。
///
/// 画像は本パッケージの `assets/mascot/rooms/room_<name>.webp`（横長 1120×736）と `roomv_<name>.webp`（縦長 736×1120）。
class UkalabRooms {
  const UkalabRooms._();

  /// 横長の画像の縦横比（幅/高さ）。
  static const double aspectRatio = 1120 / 736;

  /// 縦長の画像の縦横比（幅/高さ。壁紙向け）。
  static const double portraitAspectRatio = 736 / 1120;

  static UkalabRoom forCert(UkalabCert cert) {
    switch (cert) {
      case UkalabCert.bikeLicense:
        return UkalabRoom.transport;
      case UkalabCert.kanjiKentei:
      case UkalabCert.japaneseTeacher:
        return UkalabRoom.language;
      default:
        break;
    }
    switch (cert.field) {
      case UkalabField.it:
        return UkalabRoom.it;
      case UkalabField.ai:
        return UkalabRoom.ai;
      case UkalabField.biz:
        return UkalabRoom.accounting;
      case UkalabField.tech:
        return UkalabRoom.safety;
      case UkalabField.lang:
        return UkalabRoom.language;
    }
  }

  /// 画像ファイル名（拡張子なし）。横長は `room_<name>`、縦長は `roomv_<name>`。
  static String file(UkalabRoom room, {bool portrait = false}) => '${portrait ? 'roomv' : 'room'}_${room.name}';

  static ImageProvider image(UkalabRoom room, {bool portrait = false}) =>
      AssetImage('assets/mascot/rooms/${file(room, portrait: portrait)}.webp', package: UkalabCharacters.package);
}

/// 推しの部屋: 背景の上に、選んだ推し（衣装・場面ポーズ込み）を立たせた絵。
///
/// 壁紙や合格祝いカードの元になる。画像として保存するときは `RepaintBoundary` で包んで
/// `toImage` する（動かさないので [MascotWidget.animate] は false）。
class UkalabOshiRoom extends StatelessWidget {
  const UkalabOshiRoom({
    super.key,
    required this.pack,
    this.room = UkalabRoom.general,
    this.stage = MascotStage.lv1,
    this.expression = MascotExpression.normal,
    this.outfit,
    this.scene,
    this.line,
    this.characterHeight = 0.88,
    this.portrait = false,
  });

  /// 資格から部屋を決める。
  UkalabOshiRoom.forCert({
    Key? key,
    required UkalabCert cert,
    required CharacterPack pack,
    MascotStage stage = MascotStage.lv1,
    MascotExpression expression = MascotExpression.normal,
    Outfit? outfit,
    MascotScene? scene,
    String? line,
    double characterHeight = 0.88,
    bool portrait = false,
  }) : this(
          key: key,
          pack: pack,
          room: UkalabRooms.forCert(cert),
          stage: stage,
          expression: expression,
          outfit: outfit,
          scene: scene,
          line: line,
          characterHeight: characterHeight,
          portrait: portrait,
        );

  final CharacterPack pack;
  final UkalabRoom room;
  final MascotStage stage;
  final MascotExpression expression;
  final Outfit? outfit;
  final MascotScene? scene;

  /// 吹き出しのセリフ（任意）。
  final String? line;

  /// 部屋の高さに対する推しの高さ（0〜1）。
  final double characterHeight;

  /// true なら縦長の背景（壁紙向け）。
  final bool portrait;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: portrait ? UkalabRooms.portraitAspectRatio : UkalabRooms.aspectRatio,
      child: LayoutBuilder(
        builder: (context, c) {
          final h = c.maxHeight * characterHeight;
          return Stack(
            fit: StackFit.expand,
            children: [
              Image(image: UkalabRooms.image(room, portrait: portrait), fit: BoxFit.cover, excludeFromSemantics: true),
              Align(
                alignment: const Alignment(0, 0.92),
                child: MascotWidget(
                  pack: pack,
                  stage: stage,
                  expression: expression,
                  outfit: outfit,
                  scene: scene,
                  size: h,
                  animate: false,
                  line: line,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
