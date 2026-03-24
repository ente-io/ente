import "package:flutter_test/flutter_test.dart";
import "package:logging/logging.dart";
import "package:photos/services/background_run_helper.dart";
import "package:shared_preferences/shared_preferences.dart";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group("prepareBackgroundRun", () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test("ignores non-sync remote pushes", () async {
      final attempt = await prepareBackgroundRun(
        logger: Logger("BackgroundRunHelperTest"),
        taskId: "remote_push_sync",
        budget: const Duration(seconds: 1),
        isRunningInForeground: () async => false,
        isAnotherBackgroundRunAlive: () async => false,
        pushPayload: const {"action": "noop"},
      );

      expect(attempt.shouldRun, isFalse);
      expect(attempt.skipReason, BackgroundSkipReason.nonSyncPush);
    });

    test("dedupes when foreground is active", () async {
      final attempt = await prepareBackgroundRun(
        logger: Logger("BackgroundRunHelperTest"),
        taskId: "remote_push_sync",
        budget: const Duration(seconds: 1),
        isRunningInForeground: () async => true,
        isAnotherBackgroundRunAlive: () async => false,
        pushPayload: const {"action": "sync"},
      );

      expect(attempt.shouldRun, isFalse);
      expect(attempt.skipReason, BackgroundSkipReason.foregroundActive);
    });

    test("dedupes when another background run is alive", () async {
      await prefs.setString(keyActiveBackgroundRunToken, "other-run");
      await prefs.setInt(
        keyActiveBackgroundRunStartedAt,
        DateTime.now()
            .subtract(const Duration(seconds: 10))
            .microsecondsSinceEpoch,
      );

      final attempt = await prepareBackgroundRun(
        logger: Logger("BackgroundRunHelperTest"),
        taskId: "remote_push_sync",
        budget: const Duration(seconds: 1),
        isRunningInForeground: () async => false,
        isAnotherBackgroundRunAlive: () async => true,
        pushPayload: const {"action": "sync"},
      );

      expect(attempt.shouldRun, isFalse);
      expect(attempt.skipReason, BackgroundSkipReason.backgroundActive);
    });

    test("replaces stale lease and clears it on finish", () async {
      await prefs.setString(keyActiveBackgroundRunToken, "stale-run");
      await prefs.setInt(
        keyActiveBackgroundRunStartedAt,
        DateTime.now()
            .subtract(const Duration(seconds: 10))
            .microsecondsSinceEpoch,
      );

      final attempt = await prepareBackgroundRun(
        logger: Logger("BackgroundRunHelperTest"),
        taskId: "remote_push_sync",
        budget: const Duration(seconds: 1),
        isRunningInForeground: () async => false,
        isAnotherBackgroundRunAlive: () async => false,
        pushPayload: const {"action": "sync"},
      );

      expect(attempt.shouldRun, isTrue);
      expect(attempt.skipReason, isNull);
      expect(
        prefs.getString(keyActiveBackgroundRunToken),
        startsWith("remote_push_sync:"),
      );

      await finishBackgroundRun(attempt);

      expect(prefs.getString(keyActiveBackgroundRunToken), isNull);
      expect(prefs.getInt(keyActiveBackgroundRunStartedAt), isNull);
    });

    test("does not clear a newer lease after reload", () async {
      final attempt = await prepareBackgroundRun(
        logger: Logger("BackgroundRunHelperTest"),
        taskId: "remote_push_sync",
        budget: const Duration(seconds: 1),
        isRunningInForeground: () async => false,
        isAnotherBackgroundRunAlive: () async => false,
        pushPayload: const {"action": "sync"},
      );

      expect(attempt.shouldRun, isTrue);
      final replacementStartedAt = DateTime.now().microsecondsSinceEpoch;
      await prefs.setString(keyActiveBackgroundRunToken, "replacement-run");
      await prefs.setInt(
        keyActiveBackgroundRunStartedAt,
        replacementStartedAt,
      );

      await finishBackgroundRun(attempt);

      expect(prefs.getString(keyActiveBackgroundRunToken), "replacement-run");
      expect(
        prefs.getInt(keyActiveBackgroundRunStartedAt),
        replacementStartedAt,
      );
    });
  });
}
