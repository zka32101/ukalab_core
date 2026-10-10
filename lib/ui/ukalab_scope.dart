import 'package:flutter/widgets.dart';

import 'mascot/mascot_lines.dart';
import 'mascot/mascot_models.dart';

/// うかラボ専用の文言の差し込み口。`MaterialApp.builder` など Navigator より上に置く。
///
/// 推しのセリフを、アプリ側で差し替える（口調 → セリフ集）。渡さなければ既定のセリフ集。
/// 画面の文言（`KitStrings`）やラボの文言（`LabStrings`）は、app_common_kit の `KitStringsScope` で渡す。
class UkalabScope extends InheritedWidget {
  const UkalabScope({super.key, this.mascotLines, required super.child});

  final Map<MascotTone, MascotLines>? mascotLines;

  /// 最も近い [UkalabScope] の [mascotLines]。無ければ null。
  static Map<MascotTone, MascotLines>? mascotLinesOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<UkalabScope>()?.mascotLines;

  @override
  bool updateShouldNotify(UkalabScope old) => mascotLines != old.mascotLines;
}
