import 'package:app_common_kit/app_common_kit.dart';
import 'package:app_common_kit/hands_free_tts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ukalab_core/ui.dart';

void main() {
  test('kit v3.5.0 のながらセッション API を core の依存経由で import できる', () {
    // core の ui.dart と同時に import しても名前が衝突しないこと
    expect(UkalabStrings, isNotNull);
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

  test('kit v3.5.0: ながらセッションに onAnswered を引数として渡せる', () {
    final answered = <(String, int, bool)>[];
    final controller = NagaraSessionController(
      questions: const [
        NagaraQuestion(id: 'q1', prompt: 'もんだい', choices: ['A', 'B'], correctIndex: 0),
      ],
      backend: FakeSpeechBackend(),
      settings: () => const HandsFreeSettings(),
      onAnswered: (NagaraQuestion q, int chosen, bool correct) => answered.add((q.id, chosen, correct)),
      onWrongAnswer: (q, chosen) {},
    );
    expect(controller.onAnswered, isNotNull);
    expect(controller.total, 1);
    controller.dispose();
  });
}
