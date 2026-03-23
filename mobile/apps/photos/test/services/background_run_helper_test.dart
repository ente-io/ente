import "package:flutter_test/flutter_test.dart";
import "package:logging/logging.dart";
import "package:photos/services/background_run_helper.dart";
import "package:shared_preferences/shared_preferences.dart";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group("BackgroundRunHelper", () {
    late SharedPreferences prefs;
    late BackgroundRunHelper helper;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      helper = BackgroundRunHelper(
        logger: Logger("BackgroundRunHelperTest"),
        isRunningInForeground: () async => false,
        isAnotherBackgroundRunAlive: () async => false,
      );
    });

    test("ignores non-sync remote pushes", () async {
      final attempt = await helper.prepareRun(
        trigger: BackgroundTrigger.remotePush,
        taskId: "remote_push_sync",
        budget: const Duration(seconds: 1),
        pushPayload: const {"action": "noop"},
      );

      expect(attempt.shouldRun, isFalse);
      expect(attempt.skipReason, BackgroundSkipReason.nonSyncPush);
    });

    test("dedupes when foreground is active", () async {
      helper = BackgroundRunHelper(
        logger: Logger("BackgroundRunHelperTest"),
        isRunningInForeground: () async => true,
        isAnotherBackgroundRunAlive: () async => false,
      );

      final attempt = await helper.prepareRun(
        trigger: BackgroundTrigger.remotePush,
        taskId: "remote_push_sync",
        budget: const Duration(seconds: 1),
        pushPayload: const {"action": "sync"},
      );

      expect(attempt.shouldRun, isFalse);
      expect(attempt.skipReason, BackgroundSkipReason.foregroundActive);
    });

    test("dedupes when another background run is alive", () async {
      await prefs.setString(
        BackgroundRunHelper.keyActiveBackgroundRunToken,
        "other-run",
      );
      await prefs.setInt(
        BackgroundRunHelper.keyActiveBackgroundRunStartedAt,
        DateTime.now()
            .subtract(const Duration(seconds: 10))
            .microsecondsSinceEpoch,
      );

      helper = BackgroundRunHelper(
        logger: Logger("BackgroundRunHelperTest"),
        isRunningInForeground: () async => false,
        isAnotherBackgroundRunAlive: () async => true,
      );

      final attempt = await helper.prepareRun(
        trigger: BackgroundTrigger.remotePush,
        taskId: "remote_push_sync",
        budget: const Duration(seconds: 1),
        pushPayload: const {"action": "sync"},
      );

      expect(attempt.shouldRun, isFalse);
      expect(attempt.skipReason, BackgroundSkipReason.backgroundActive);
    });

    test("replaces stale lease and clears it on finish", () async {
      await prefs.setString(
        BackgroundRunHelper.keyActiveBackgroundRunToken,
        "stale-run",
      );
      await prefs.setInt(
        BackgroundRunHelper.keyActiveBackgroundRunStartedAt,
        DateTime.now()
            .subtract(const Duration(seconds: 10))
            .microsecondsSinceEpoch,
      );

      final attempt = await helper.prepareRun(
        trigger: BackgroundTrigger.remotePush,
        taskId: "remote_push_sync",
        budget: const Duration(seconds: 1),
        pushPayload: const {"action": "sync"},
      );

      expect(attempt.shouldRun, isTrue);
      expect(attempt.skipReason, isNull);
      expect(
        prefs.getString(BackgroundRunHelper.keyActiveBackgroundRunToken),
        startsWith("remote_push_sync:"),
      );

      await helper.finishRun(attempt);

      expect(
        prefs.getString(BackgroundRunHelper.keyActiveBackgroundRunToken),
        isNull,
      );
      expect(
        prefs.getInt(BackgroundRunHelper.keyActiveBackgroundRunStartedAt),
        isNull,
      );
    });

    test("does not clear a newer lease after reload", () async {
      final attempt = await helper.prepareRun(
        trigger: BackgroundTrigger.remotePush,
        taskId: "remote_push_sync",
        budget: const Duration(seconds: 1),
        pushPayload: const {"action": "sync"},
      );

      expect(attempt.shouldRun, isTrue);
      final replacementStartedAt = DateTime.now().microsecondsSinceEpoch;
      await prefs.setString(
        BackgroundRunHelper.keyActiveBackgroundRunToken,
        "replacement-run",
      );
      await prefs.setInt(
        BackgroundRunHelper.keyActiveBackgroundRunStartedAt,
        replacementStartedAt,
      );

      await helper.finishRun(attempt);

      expect(
        prefs.getString(BackgroundRunHelper.keyActiveBackgroundRunToken),
        "replacement-run",
      );
      expect(
        prefs.getInt(BackgroundRunHelper.keyActiveBackgroundRunStartedAt),
        replacementStartedAt,
      );
    });
  });
}
