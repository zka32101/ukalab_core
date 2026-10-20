import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 鳴らす効果音の種類。音源（ファイル）はアプリが持つ。
enum SoundCue { correct, incorrect, badgeUnlocked, combo }

/// 効果音の再生。`audioplayers` などでアプリが実装して渡す（キットは音声プラグインに依存しない）。
abstract class SoundBackend {
  Future<void> play(SoundCue cue, {required double volume});
  Future<void> dispose();
}

/// 触覚の出力。既定は [SystemHapticBackend]。
abstract class HapticBackend {
  Future<void> light();
  Future<void> medium();
  Future<void> heavy();
}

/// 端末の触覚フィードバック（`HapticFeedback`）。対応していない端末では何も起きない。
class SystemHapticBackend implements HapticBackend {
  const SystemHapticBackend();

  @override
  Future<void> light() => HapticFeedback.lightImpact();
  @override
  Future<void> medium() => HapticFeedback.mediumImpact();
  @override
  Future<void> heavy() => HapticFeedback.heavyImpact();
}

/// テスト・プレビュー用。呼ばれた順を記録するだけ。
class FakeSoundBackend implements SoundBackend {
  final List<({SoundCue cue, double volume})> played = [];

  @override
  Future<void> play(SoundCue cue, {required double volume}) async => played.add((cue: cue, volume: volume));

  @override
  Future<void> dispose() async {}
}

class FakeHapticBackend implements HapticBackend {
  final List<String> calls = [];

  @override
  Future<void> light() async => calls.add('light');
  @override
  Future<void> medium() async => calls.add('medium');
  @override
  Future<void> heavy() async => calls.add('heavy');
}

/// 解答したときの音と触覚をまとめた共通の窓口。
///
/// - 正解: 音＋軽い触覚 / 不正解: 音＋小刻みの触覚 / バッジ: 音＋強い触覚 / コンボ: 音＋中くらいの触覚
/// - 音・触覚は個別に切れる。音量は 0〜1 に収める（既定 0.7）
/// - 再生や触覚の失敗（音源の未配置・非対応の端末）でアプリを止めない
/// - [sound] が null なら音は鳴らさない（触覚だけ）
class AnswerFeedback {
  AnswerFeedback({
    this.sound,
    HapticBackend haptics = const SystemHapticBackend(),
    this.soundEnabled = true,
    this.hapticsEnabled = true,
    double volume = 0.7,
    this.shakeInterval = const Duration(milliseconds: 50),
  })  : _haptics = haptics,
        _volume = volume.clamp(0.0, 1.0).toDouble();

  final SoundBackend? sound;
  final HapticBackend _haptics;
  final Duration shakeInterval;

  bool soundEnabled;
  bool hapticsEnabled;
  double _volume;

  double get volume => _volume;
  set volume(double v) => _volume = v.clamp(0.0, 1.0).toDouble();

  Future<void> _sound(SoundCue cue) async {
    final s = sound;
    if (s == null || !soundEnabled) return;
    try {
      await s.play(cue, volume: _volume);
    } catch (_) {}
  }

  Future<void> _haptic(Future<void> Function() f) async {
    if (!hapticsEnabled) return;
    try {
      await f();
    } catch (_) {}
  }

  /// 正解。
  Future<void> correct() async {
    await _sound(SoundCue.correct);
    await _haptic(_haptics.light);
  }

  /// 不正解。軽い触覚を3回、小刻みに。
  Future<void> incorrect() async {
    await _sound(SoundCue.incorrect);
    await _haptic(() async {
      for (var i = 0; i < 3; i++) {
        await _haptics.light();
        await Future<void>.delayed(shakeInterval);
      }
    });
  }

  /// バッジ獲得・合格。
  Future<void> badgeUnlocked() async {
    await _sound(SoundCue.badgeUnlocked);
    await _haptic(_haptics.heavy);
  }

  /// コンボ達成。
  Future<void> combo() async {
    await _sound(SoundCue.combo);
    await _haptic(_haptics.medium);
  }

  /// 音だけ・触覚だけが要る場面（UI 操作の触覚など）。
  Future<void> tap() => _haptic(_haptics.light);

  Future<void> dispose() async {
    try {
      await sound?.dispose();
    } catch (_) {}
  }
}

/// アプリの `ProviderScope` で `answerFeedbackProvider.overrideWithValue(AnswerFeedback(sound: MySound()))` する。
/// 既定は音なし・触覚のみ。
final answerFeedbackProvider = Provider<AnswerFeedback>((ref) {
  final f = AnswerFeedback();
  ref.onDispose(f.dispose);
  return f;
});
