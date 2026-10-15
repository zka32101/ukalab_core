import 'dart:math' as math;

import 'peer_stats.dart';
import 'peer_stats_source.dart';

/// 端末ごとのランダムな匿名 ID（UUID v4 形式）。端末ローカルにだけ保存し、アプリを消すと失われる。
/// Firebase Auth の uid・広告 ID・端末固有 ID とは無関係で、他のデータと結び付けない。
class InstallId {
  const InstallId._();

  static final RegExp _pattern = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$');

  /// Firestore ルールの `installId.matches('^[0-9a-f-]{36}$')` を満たす UUID v4 を作る。
  static String generate([math.Random? random]) {
    final r = random ?? math.Random.secure();
    final b = List<int>.generate(16, (_) => r.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40; // version 4
    b[8] = (b[8] & 0x3f) | 0x80; // variant
    final h = b.map((e) => e.toRadixString(16).padLeft(2, '0')).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
  }

  static bool isValid(String id) => _pattern.hasMatch(id);
}

/// installId の保存先。実装は端末ローカル（`SharedPrefsInstallIdStore`）。
abstract interface class InstallIdStore {
  /// 保存済みならそれを、無ければ作って保存して返す。
  Future<String> getOrCreate();

  /// 保存済みの ID を捨てる（「参加をやめる」ときに呼べる。次回は別人として数えられる）。
  Future<void> clear();
}

/// 年少者向けの保護者ゲート。送信は「ゲートを通した」場合だけ許可する。
///
/// 非対話の [isAllowed] は送信のたびに呼ぶ（ダイアログは出さない）。
/// 対話の [request] は、設定で「参加する」をオンにするときだけ呼ぶ。
/// app_common_kit の保護者ゲートを使う実装は `ParentalPeerStatsGate`（`ui.dart`）。
abstract interface class PeerStatsGate {
  /// 既にゲートを通した（許可済み）か。UI は出さない。
  Future<bool> isAllowed();

  /// ゲートを通す（UI を出してよい）。通ったら許可を記録して true。
  Future<bool> request();

  /// 許可を取り消す（参加をオフにしたとき）。
  Future<void> revoke();
}

/// 成人向けアプリ用。ゲートなしで常に許可（オプトイン自体は `PeerStatsSettings` で必須）。
class NoPeerStatsGate implements PeerStatsGate {
  const NoPeerStatsGate();
  @override
  Future<bool> isAllowed() async => true;
  @override
  Future<bool> request() async => true;
  @override
  Future<void> revoke() async {}
}

/// 「その試験について最後に送った日（`yyyy-MM-dd`、日本時間）」の保存先。
abstract interface class PeerSentDateStore {
  Future<String?> read(String examId);
  Future<void> write(String examId, String dateKey);
}

/// 送信済みデータの削除依頼（installId 指定。実装は Cloud Function の callable を呼ぶ）。
abstract interface class PeerStatsEraser {
  /// サーバ上の自分の値を削除する。成功で true。
  Future<bool> erase({required String examId});
}

enum PeerSendResult {
  sent,
  /// オプトインがオフ（既定）。
  disabled,
  /// 保護者ゲート未通過。表示のみ。
  gateBlocked,
  /// 今日（日本時間）は送信済み。
  alreadySentToday,
  /// 送信に失敗（握りつぶし、次回に回す）。
  failed,
}

/// 日本時間（UTC+9）の暦日。連続日数・日次 1 回の判定はすべてこの日付で揃える。
String peerJstDateKey(DateTime now) {
  final j = now.toUtc().add(const Duration(hours: 9));
  return PeerStatsView.dateKey(DateTime.utc(j.year, j.month, j.day));
}

/// 送信条件の判定と送信。条件: オプトイン ON、かつ ゲート通過済み、かつ 当日（日本時間）未送信。
/// 例外は投げない（失敗は [PeerSendResult.failed] で返し、記録しないので次回また試す）。
///
/// 学習を 1 件記録した後に呼ぶ想定（「今日学習した人」を数えるため、起動時には呼ばない）。
class PeerStatsSender {
  PeerStatsSender({
    required this.settings,
    required this.gate,
    required this.sink,
    required this.sentDates,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final PeerStatsSettings settings;
  final PeerStatsGate gate;
  final PeerStatsSink sink;
  final PeerSentDateStore sentDates;
  final DateTime Function() _clock;

  /// [streakDays] は kit の `loadCurrentStreak()`（当日未学習でも前日までの連続は数え、2 日以上空いたら 0）、
  /// [totalQuestions] は延べ回答数、[examDate] は設定済みの試験日（未設定は null）。
  Future<PeerSendResult> maybeSend({
    required String examId,
    required int streakDays,
    required int totalQuestions,
    DateTime? examDate,
  }) async {
    try {
      if (!await settings.isSharingEnabled()) return PeerSendResult.disabled;
      if (!await gate.isAllowed()) return PeerSendResult.gateBlocked;
      final today = peerJstDateKey(_clock());
      if (await sentDates.read(examId) == today) return PeerSendResult.alreadySentToday;
      await sink.submit(PeerContribution(
        examId: examId,
        dateKey: today,
        streakDays: streakDays,
        totalQuestions: totalQuestions,
        examDate: examDate == null ? null : PeerStatsView.dateKey(examDate),
      ));
      await sentDates.write(examId, today);
      return PeerSendResult.sent;
    } catch (_) {
      return PeerSendResult.failed;
    }
  }
}

/// 端末が書く値の形（Firestore ルールの許可キー・値域と一致させる）。
/// 入るのは day / streakDays / totalQuestions / examDate / updatedAt だけ。
class PeerDevicePayload {
  const PeerDevicePayload._();

  static const int maxStreak = 3650;
  static const int maxTotalQuestions = 1000000;
  static final RegExp _date = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  /// [updatedAt] はサーバ時刻（本番は `FieldValue.serverTimestamp()`）。値域外は丸める。
  static Map<String, Object?> build(PeerContribution c, {required Object updatedAt}) => {
        'day': c.dateKey,
        'streakDays': c.streakDays.clamp(0, maxStreak),
        'totalQuestions': c.totalQuestions.clamp(0, maxTotalQuestions),
        if (c.examDate != null && _date.hasMatch(c.examDate!)) 'examDate': c.examDate,
        'updatedAt': updatedAt,
      };

  static String path(String examId, String installId) => 'peer_devices/$examId/devices/$installId';
}
