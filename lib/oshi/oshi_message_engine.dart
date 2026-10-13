import 'oshi_message_strings.dart';

/// 推しの一言を決めるための状況。個人情報は含めない。
class OshiMessageContext {
  const OshiMessageContext({
    this.daysSinceLastStudy,
    this.streakDays = 0,
    this.todayAnswered = 0,
    this.todayCorrectRate,
    this.examDaysLeft,
    this.hasWeakTopics = false,
  });

  /// 最後に学習してからの日数（初回・不明は null）。
  final int? daysSinceLastStudy;
  final int streakDays;
  final int todayAnswered;

  /// 今日の正答率 0.0〜1.0（解いていなければ null）。
  final double? todayCorrectRate;

  /// 試験までの日数（未設定は null）。励ましの文脈で軽く触れるだけ。
  final int? examDaysLeft;
  final bool hasWeakTopics;
}

enum OshiMood { warm, cheer, calm, proud }

class OshiMessage {
  const OshiMessage({required this.id, required this.text, required this.mood});

  /// `<状況>_<言い回し番号>`。
  final String id;
  final String text;
  final OshiMood mood;
}

/// 学習状況から、責めない励ましの一言を選ぶ（純 Dart）。
class OshiMessageEngine {
  const OshiMessageEngine({this.strings = OshiMessageStrings.ja});

  final OshiMessageStrings strings;

  /// 日付から seed を作る（同じ日は同じ値で、日替わり）。
  static int seedFromDate(DateTime d) => d.year * 10000 + d.month * 100 + d.day;

  /// 状況の判定。優先順は 久しぶり > 間違いが多い > 連続 > 今日の達成 > 試験 > 苦手 > あいさつ。
  static OshiSituation situationOf(OshiMessageContext c) {
    final rate = c.todayCorrectRate;
    if ((c.daysSinceLastStudy ?? 0) >= 3 && c.todayAnswered == 0) {
      return OshiSituation.welcomeBack;
    }
    if (c.todayAnswered >= 5 && rate != null && rate < 0.5) return OshiSituation.struggling;
    if (c.streakDays >= 3) return OshiSituation.streak;
    if (c.todayAnswered >= 3 && rate != null && rate >= 0.8) return OshiSituation.praise;
    final left = c.examDaysLeft;
    if (left != null && left >= 1 && left <= 120) return OshiSituation.examPace;
    if (c.hasWeakTopics) return OshiSituation.weakTopic;
    if (c.todayAnswered > 0) return OshiSituation.praise;
    return OshiSituation.greeting;
  }

  static OshiMood moodOf(OshiSituation s) => switch (s) {
    OshiSituation.welcomeBack => OshiMood.warm,
    OshiSituation.struggling => OshiMood.calm,
    OshiSituation.streak => OshiMood.cheer,
    OshiSituation.praise => OshiMood.proud,
    OshiSituation.examPace => OshiMood.calm,
    OshiSituation.weakTopic => OshiMood.calm,
    OshiSituation.greeting => OshiMood.warm,
  };

  /// 一言を選ぶ。[seed] が同じなら同じ結果。[salt] を変えると同じ状況で別の言い回しになる（タップ切替用）。
  OshiMessage pick(OshiMessageContext c, {required int seed, int salt = 0}) {
    final s = situationOf(c);
    final list = strings.variants(s);
    if (list.isEmpty) {
      return OshiMessage(id: '${s.name}_0', text: '', mood: moodOf(s));
    }
    final i = (seed + salt).abs() % list.length;
    final text = list[i].replaceAll('{n}', '${c.examDaysLeft ?? 0}');
    return OshiMessage(id: '${s.name}_$i', text: text, mood: moodOf(s));
  }
}
