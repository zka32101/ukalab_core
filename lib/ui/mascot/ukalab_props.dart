import 'package:flutter/widgets.dart';

import 'ukalab_characters.dart';

/// 推しの部屋に置く小物（透過画像）。
///
/// 「部屋が育つ」「合格コレクション棚」などで、学習量や合格に応じて部屋に並べる素材。
/// 置き方（どの小物をいつ出すか）はアプリ側の仕組みで決める。画像は文字を含まない。
enum UkalabProp {
  bookshelf,
  blackboard,
  trophy,
  plant,
  lamp,
  globe,
  clock,
  flasks,
  toolbox,
  abacus,
  frame,
  badges,
}

class UkalabProps {
  const UkalabProps._();

  /// 画像ファイル名（拡張子なし）。
  static String file(UkalabProp prop) => 'prop_${prop.name}';

  /// 小物の画像（896×896・背景透過）。
  static ImageProvider image(UkalabProp prop) =>
      AssetImage('assets/mascot/props/${file(prop)}.webp', package: UkalabCharacters.package);
}
