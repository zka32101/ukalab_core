import 'package:ukalab_core/ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('英語のセリフは全場面にあり、禁止表現を含まない', () {
    const en = MascotLines.gentleEn;
    for (final s in MascotSituation.values) {
      expect(en.of(s), isNotEmpty, reason: '$s');
    }
    for (final line in en.all) {
      expect(findForbiddenExpressions(line), isEmpty, reason: line);
    }
  });

  test('forTone は lang で切り替わり、未対応は日本語', () {
    expect(MascotLines.forTone(MascotTone.gentle, lang: 'en'),
        same(MascotLines.gentleEn));
    expect(MascotLines.forTone(MascotTone.gentle), same(MascotLines.gentle));
    expect(MascotLines.forTone(MascotTone.gentle, lang: 'fr'),
        same(MascotLines.gentle));
  });

  test('英語の禁止表現も検出する', () {
    expect(findForbiddenExpressions('I love you'), isNotEmpty);
    expect(findForbiddenExpressions('Why didn\'t you study'), isNotEmpty);
    expect(findForbiddenExpressions('Great job today'), isEmpty);
  });
}
