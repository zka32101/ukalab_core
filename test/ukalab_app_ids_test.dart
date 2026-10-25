import 'package:flutter_test/flutter_test.dart';
import 'package:ukalab_core/ukalab_core.dart';

void main() {
  test('正規IDは8件で重複せず、公開済みの不統一IDもそのまま', () {
    expect(kUkalabAppIds, hasLength(8));
    expect(kUkalabAppIds.toSet(), hasLength(8));
    expect(kUkalabAppIds, containsAll(<String>[
      'com.yourwish.ukalab.g_kentei',
      'com.yourwish.ukalab.it_passport',
      'com.yourwish.ukalab.infosecmanage',
      'com.yourwish.ukalab.seisei_ai_passport',
      'com.yourwish.ukalab.boki3',
      'com.yourwish.ukalab_otsu',
      'com.yourwish.ukarulab.kanji',
      'com.yourwish.ukalab.bike_license',
    ]));
  });

  test('isUkalabAppId', () {
    expect(isUkalabAppId('com.yourwish.ukalab_otsu'), isTrue);
    expect(isUkalabAppId('com.yourwish.ukalab.otsu'), isFalse);
    expect(isUkalabAppId(''), isFalse);
  });
}
