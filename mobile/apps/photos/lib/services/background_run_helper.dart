import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum BackgroundTrigger {
  workmanager,
  bgAppRefresh,
  bgProcessing,
  remotePush,
}

enum BackgroundSkipReason {
  nonSyncPush,
  foregroundActive,
  backgroundActive,
}

class BackgroundRunAttempt {
  const BackgroundRunAttempt._({
    required this.prefs,
    required this.leaseToken,
    required this.skipReason,
  });

  const BackgroundRunAttempt.run({
    required SharedPreferences prefs,
    required String leaseToken,
  }) : this._(
          prefs: prefs,
          leaseToken: leaseToken,
          skipReason: null,
        );

  const BackgroundRunAttempt.skip({
    required SharedPreferences prefs,
    required BackgroundSkipReason skipReason,
  }) : this._(
          prefs: prefs,
          leaseToken: null,
          skipReason: skipReason,
        );

  final SharedPreferences prefs;
  final String? leaseToken;
  final BackgroundSkipReason? skipReason;

  bool get shouldRun => leaseToken != null;
}

class BackgroundRunHelper {
  static const keyActiveBackgroundRunToken = "bg_active_run_token";
  static const keyActiveBackgroundRunStartedAt = "bg_active_run_started_at";
  static const activeLeaseGrace = Duration(seconds: 30);
  static const activeLeaseStartupGrace = Duration(seconds: 5);

  final Logger _logger;
  final Future<bool> Function() _isRunningInForeground;
  final Future<bool> Function() _isAnotherBackgroundRunAlive;

  BackgroundRunHelper({
    required Logger logger,
    required Future<bool> Function() isRunningInForeground,
    required Future<bool> Function() isAnotherBackgroundRunAlive,
  })  : _logger = logger,
        _isRunningInForeground = isRunningInForeground,
        _isAnotherBackgroundRunAlive = isAnotherBackgroundRunAlive;

  Future<BackgroundRunAttempt> prepareRun({
    required BackgroundTrigger trigger,
    required String taskId,
    required Duration budget,
    Map<String, String>? pushPayload,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();

    if (trigger == BackgroundTrigger.remotePush &&
        !_shouldProcessPush(pushPayload)) {
      return BackgroundRunAttempt.skip(
        prefs: prefs,
        skipReason: BackgroundSkipReason.nonSyncPush,
      );
    }

    if (await _isRunningInForeground()) {
      return BackgroundRunAttempt.skip(
        prefs: prefs,
        skipReason: BackgroundSkipReason.foregroundActive,
      );
    }

    final leaseToken = await _tryAcquireLease(
      prefs,
      taskId: taskId,
      budget: budget,
    );
    if (leaseToken == null) {
      return BackgroundRunAttempt.skip(
        prefs: prefs,
        skipReason: BackgroundSkipReason.backgroundActive,
      );
    }

    return BackgroundRunAttempt.run(
      prefs: prefs,
      leaseToken: leaseToken,
    );
  }

  Future<void> finishRun(BackgroundRunAttempt attempt) async {
    final leaseToken = attempt.leaseToken;
    if (leaseToken == null) {
      return;
    }

    await attempt.prefs.reload();
    if (attempt.prefs.getString(keyActiveBackgroundRunToken) != leaseToken) {
      return;
    }

    await attempt.prefs.remove(keyActiveBackgroundRunToken);
    await attempt.prefs.remove(keyActiveBackgroundRunStartedAt);
  }

  bool _shouldProcessPush(Map<String, String>? pushPayload) {
    if (pushPayload == null || pushPayload.isEmpty) {
      return false;
    }

    return pushPayload["action"] == "sync";
  }

  Future<String?> _tryAcquireLease(
    SharedPreferences prefs, {
    required String taskId,
    required Duration budget,
  }) async {
    final existingToken = prefs.getString(keyActiveBackgroundRunToken);
    final existingStart = prefs.getInt(keyActiveBackgroundRunStartedAt) ?? 0;
    final now = DateTime.now().microsecondsSinceEpoch;
    final leaseIsFresh = existingStart >
        now - budget.inMicroseconds - activeLeaseGrace.inMicroseconds;

    if (existingToken != null) {
      final hasRecentHeartbeat = await _isAnotherBackgroundRunAlive();
      final withinStartupGrace =
          existingStart > now - activeLeaseStartupGrace.inMicroseconds;

      if (hasRecentHeartbeat || (leaseIsFresh && withinStartupGrace)) {
        return null;
      }

      _logger.info(
        "Replacing stale background lease for $taskId "
        "(leaseIsFresh=$leaseIsFresh, hasRecentHeartbeat=$hasRecentHeartbeat, "
        "withinStartupGrace=$withinStartupGrace)",
      );
    }

    final leaseToken = "$taskId:$now";
    await prefs.setString(keyActiveBackgroundRunToken, leaseToken);
    await prefs.setInt(keyActiveBackgroundRunStartedAt, now);
    return leaseToken;
  }
}
