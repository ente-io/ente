import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

enum BackgroundSkipReason {
  nonSyncPush,
  foregroundActive,
  backgroundActive,
}

const keyActiveBackgroundRunToken = "bg_active_run_token";
const keyActiveBackgroundRunStartedAt = "bg_active_run_started_at";
const activeLeaseGrace = Duration(seconds: 30);
const activeLeaseStartupGrace = Duration(seconds: 5);

Future<BackgroundRunAttempt> prepareBackgroundRun({
  required Logger logger,
  required String taskId,
  required Duration budget,
  required Future<bool> Function() isRunningInForeground,
  required Future<bool> Function() isAnotherBackgroundRunAlive,
  Map<String, String>? pushPayload,
}) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.reload();

  if (pushPayload != null &&
      pushPayload.isNotEmpty &&
      pushPayload["action"] != "sync") {
    return BackgroundRunAttempt.skip(
      prefs: prefs,
      skipReason: BackgroundSkipReason.nonSyncPush,
    );
  }

  if (await isRunningInForeground()) {
    return BackgroundRunAttempt.skip(
      prefs: prefs,
      skipReason: BackgroundSkipReason.foregroundActive,
    );
  }

  final leaseToken = await _tryAcquireBackgroundLease(
    prefs,
    logger: logger,
    taskId: taskId,
    budget: budget,
    isAnotherBackgroundRunAlive: isAnotherBackgroundRunAlive,
  );
  if (leaseToken == null) {
    return BackgroundRunAttempt.skip(
      prefs: prefs,
      skipReason: BackgroundSkipReason.backgroundActive,
    );
  }

  return BackgroundRunAttempt.run(prefs: prefs, leaseToken: leaseToken);
}

Future<void> finishBackgroundRun(BackgroundRunAttempt attempt) async {
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

Future<String?> _tryAcquireBackgroundLease(
  SharedPreferences prefs, {
  required Logger logger,
  required String taskId,
  required Duration budget,
  required Future<bool> Function() isAnotherBackgroundRunAlive,
}) async {
  final existingToken = prefs.getString(keyActiveBackgroundRunToken);
  final existingStart = prefs.getInt(keyActiveBackgroundRunStartedAt) ?? 0;
  final now = DateTime.now().microsecondsSinceEpoch;
  final leaseIsFresh = existingStart >
      now - budget.inMicroseconds - activeLeaseGrace.inMicroseconds;

  if (existingToken != null) {
    final hasRecentHeartbeat = await isAnotherBackgroundRunAlive();
    final withinStartupGrace =
        existingStart > now - activeLeaseStartupGrace.inMicroseconds;

    if (hasRecentHeartbeat || (leaseIsFresh && withinStartupGrace)) {
      return null;
    }

    logger.info(
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
