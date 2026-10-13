/// プレゼントの種類。
enum OshiGiftKind { outfit, background }

enum OshiGiftConditionType { streakDays, medalId, mockPass }

/// プレゼントの解放条件。
class OshiGiftCondition {
  const OshiGiftCondition.streakDays(this.days)
    : type = OshiGiftConditionType.streakDays,
      medalId = null;
  const OshiGiftCondition.medal(String id)
    : type = OshiGiftConditionType.medalId,
      days = null,
      medalId = id;
  const OshiGiftCondition.mockPass()
    : type = OshiGiftConditionType.mockPass,
      days = null,
      medalId = null;

  final OshiGiftConditionType type;

  /// [OshiGiftConditionType.streakDays] の日数。
  final int? days;

  /// [OshiGiftConditionType.medalId] のメダルID。
  final String? medalId;

  bool isMet(OshiGiftProgress p) => switch (type) {
    OshiGiftConditionType.streakDays => p.streakDays >= (days ?? 1 << 30),
    OshiGiftConditionType.medalId => p.earnedMedalIds.contains(medalId),
    OshiGiftConditionType.mockPass => p.mockPassed,
  };
}

/// 解放判定に使う進捗。個人情報は含めない。
class OshiGiftProgress {
  const OshiGiftProgress({
    this.streakDays = 0,
    this.earnedMedalIds = const {},
    this.mockPassed = false,
  });

  final int streakDays;
  final Set<String> earnedMedalIds;
  final bool mockPassed;
}

/// プレゼント 1 件の定義（画像を持たない純 Dart 側）。画像付きは UI 側の `OshiGift`。
class OshiGiftSpec {
  const OshiGiftSpec({
    required this.id,
    required this.kind,
    required this.condition,
    required this.name,
  });

  final String id;
  final OshiGiftKind kind;
  final OshiGiftCondition condition;
  final String name;
}

/// 進捗から、新しく解放されたプレゼントを返す（純 Dart・冪等）。
///
/// 未達のものを催促する仕組みは持たない（解放された分だけを返す）。
class OshiGiftEngine {
  const OshiGiftEngine();

  /// 条件を満たし、かつ [alreadyUnlocked] に無いもの（定義リストの順）。同じ入力なら同じ結果。
  List<G> newlyUnlocked<G extends OshiGiftSpec>({
    required OshiGiftProgress progress,
    required Iterable<G> gifts,
    Set<String> alreadyUnlocked = const {},
  }) {
    final seen = <String>{...alreadyUnlocked};
    final out = <G>[];
    for (final g in gifts) {
      if (seen.contains(g.id)) continue;
      if (g.condition.isMet(progress)) {
        seen.add(g.id);
        out.add(g);
      }
    }
    return out;
  }
}
