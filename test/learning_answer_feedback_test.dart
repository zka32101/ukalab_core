import 'package:ukalab_core/learning.dart';
import 'package:flutter_test/flutter_test.dart';

class _ThrowSound implements SoundBackend {
  @override
  Future<void> play(SoundCue cue, {required double volume}) => throw StateError('no file');
  @override
  Future<void> dispose() => throw StateError('x');
}

class _ThrowHaptic implements HapticBackend {
  @override
  Future<void> light() => throw StateError('unsupported');
  @override
  Future<void> medium() => throw StateError('unsupported');
  @override
  Future<void> heavy() => throw StateError('unsupported');
}

void main() {
  late FakeSoundBackend sound;
  late FakeHapticBackend haptic;
  AnswerFeedback make({bool s = true, bool h = true}) => AnswerFeedback(
        sound: sound,
        haptics: haptic,
        soundEnabled: s,
        hapticsEnabled: h,
        shakeInterval: Duration.zero,
      );
  setUp(() {
    sound = FakeSoundBackend();
    haptic = FakeHapticBackend();
  });

  test('正解・バッジ・コンボは、音と対応する強さの触覚', () async {
    final f = make();
    await f.correct();
    await f.badgeUnlocked();
    await f.combo();
    expect(sound.played.map((e) => e.cue), [SoundCue.correct, SoundCue.badgeUnlocked, SoundCue.combo]);
    expect(haptic.calls, ['light', 'heavy', 'medium']);
  });

  test('不正解は、音と3回の小刻みな触覚', () async {
    final f = make();
    await f.incorrect();
    expect(sound.played.single.cue, SoundCue.incorrect);
    expect(haptic.calls, ['light', 'light', 'light']);
  });

  test('音・触覚は個別に切れる', () async {
    await (make(s: false)..hapticsEnabled = true).correct();
    expect(sound.played, isEmpty);
    expect(haptic.calls, ['light']);

    haptic.calls.clear();
    await make(h: false).correct();
    expect(sound.played.length, 1);
    expect(haptic.calls, isEmpty);
  });

  test('音量は 0〜1 に収め、再生に渡す', () async {
    final f = make()..volume = 5;
    expect(f.volume, 1.0);
    f.volume = -1;
    expect(f.volume, 0.0);
    f.volume = 0.3;
    await f.correct();
    expect(sound.played.single.volume, 0.3);
  });

  test('音源が無い・触覚が非対応でも例外を出さない', () async {
    final f = AnswerFeedback(sound: _ThrowSound(), haptics: _ThrowHaptic(), shakeInterval: Duration.zero);
    await f.correct();
    await f.incorrect();
    await f.tap();
    await f.dispose();
  });

  test('sound が null なら触覚だけ', () async {
    final f = AnswerFeedback(haptics: haptic);
    await f.correct();
    expect(haptic.calls, ['light']);
  });
}
