import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ukalab_core/ui.dart';

void main() {
  test('kit v3.1.0 のながらセッション API を core の依存経由で import できる', () {
    expect(NagaraSessionController, isNotNull);
    expect(NagaraSessionView, isNotNull);
    expect(NagaraStrings, isNotNull);
    const s = HandsFreeSettings();
    expect(s.thinkSeconds, HandsFreeSettings.defaultThinkSeconds);
    expect(s.betweenSeconds, HandsFreeSettings.defaultBetweenSeconds);
    expect(s.autoAdvance, isTrue);
    final AwaitableSpeechBackend backend = FakeSpeechBackend();
    expect(backend, isA<SpeechBackend>());
  });
}
