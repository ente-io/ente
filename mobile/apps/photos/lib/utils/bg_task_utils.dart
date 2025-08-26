import "dart:io";

import "package:flutter/foundation.dart";
import "package:logging/logging.dart";
import "package:permission_handler/permission_handler.dart";
import "package:photos/db/upload_locks_db.dart";
import "package:photos/extensions/stop_watch.dart";
import "package:photos/main.dart";
import "package:photos/utils/file_uploader.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:workmanager/workmanager.dart" as workmanager;

@pragma('vm:entry-point')
void callbackDispatcher() {
  workmanager.Workmanager().executeTask((taskName, inputData) async {
    final TimeLogger tlog = TimeLogger();
    Future<bool> result = Future.error("Task didn't run");
    final prefs = await SharedPreferences.getInstance();

    await runWithLogs(
      () async {
        try {
          BgTaskUtils.$.info('Task started $tlog');
          await runBackgroundTask(taskName, tlog).timeout(
            Platform.isIOS ? kBGTaskTimeout : const Duration(hours: 1),
            onTimeout: () async {
              BgTaskUtils.$.warning(
                "TLE, committing seppuku for taskID: $taskName",
              );
              await BgTaskUtils.releaseResourcesForKill(taskName, prefs);
            },
          );
          BgTaskUtils.$.info('Task run successful $tlog');
          result = Future.value(true);
        } catch (e) {
          BgTaskUtils.$.warning('Task error: $e');
          await BgTaskUtils.releaseResourcesForKill(taskName, prefs);
          result = Future.error(e.toString());
        }
      },
      prefix: "[bg]",
    ).onError((_, __) {
      result = Future.error("Didn't finished correctly!");
      return;
    });

    return result;
  });
}

class BgTaskUtils {
  static final $ = Logger("BgTaskUtils");

  static Future<void> releaseResourcesForKill(
    String taskId,
    SharedPreferences prefs,
  ) async {
    await UploadLocksDB.instance.releaseLocksAcquiredByOwnerBefore(
      ProcessType.background.toString(),
      DateTime.now().microsecondsSinceEpoch,
    );
    await prefs.remove(kLastBGTaskHeartBeatTime);
  }

  static Future configureWorkmanager() async {
    if (Platform.isIOS) {
      final status = await Permission.backgroundRefresh.status;
      if (status != PermissionStatus.granted) {
        $.warning(
          "Background refresh permission is not granted. Please grant it to start the background service.",
        );
        return;
      }
    }
    $.warning("Configuring Work Manager for background tasks");
    const iOSBackgroundAppRefresh = "io.ente.frame.iOSBackgroundAppRefresh";
    const androidPeriodicTask = "io.ente.photos.androidPeriodicTask";
    final backgroundTaskIdentifier =
        Platform.isIOS ? iOSBackgroundAppRefresh : androidPeriodicTask;
    try {
      await workmanager.Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: false,
      );
      await workmanager.Workmanager().registerPeriodicTask(
        backgroundTaskIdentifier,
        backgroundTaskIdentifier,
        frequency: Platform.isIOS
            ? const Duration(minutes: 30)
            : const Duration(minutes: 15),
        initialDelay: kDebugMode ? Duration.zero : const Duration(minutes: 10),
        constraints: workmanager.Constraints(
          networkType: workmanager.NetworkType.connected,
          requiresCharging: false,
          requiresStorageNotLow: false,
          requiresDeviceIdle: false,
        ),
        existingWorkPolicy: workmanager.ExistingWorkPolicy.append,
        backoffPolicy: workmanager.BackoffPolicy.linear,
        backoffPolicyDelay: const Duration(minutes: 15),
      );
      $.info("WorkManager configured");
    } catch (e) {
      $.warning("Failed to configure WorkManager: $e");
    }
  }
}
