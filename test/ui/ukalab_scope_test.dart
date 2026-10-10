import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ukalab_core/ui.dart';

void main() {
  testWidgets('UkalabScope に mascotLines を渡せば推しのセリフが差し替わる', (tester) async {
    final lines = {
      MascotTone.gentle: const MascotLines({
        MascotSituation.greeting: ['你好'],
      }),
    };
    late MascotLines resolved;
    await tester.pumpWidget(MaterialApp(
      home: UkalabScope(
        mascotLines: lines,
        child: Builder(builder: (c) {
          resolved = MascotLines.forTone(MascotTone.gentle, custom: UkalabScope.mascotLinesOf(c));
          return const SizedBox();
        }),
      ),
    ));
    expect(resolved.pick(MascotSituation.greeting), '你好');
    // 渡さなければ既定
    expect(MascotLines.forTone(MascotTone.gentle).pick(MascotSituation.greeting), isNot('你好'));
  });
}
