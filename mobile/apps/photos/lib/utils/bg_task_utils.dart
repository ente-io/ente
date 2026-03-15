import "dart:io";

import "package:ente_pure_utils/ente_pure_utils.dart";
import "package:flutter/foundation.dart";
import "package:logging/logging.dart";
import "package:permission_handler/permission_handler.dart";
import "package:photos/db/upload_locks_db.dart";
import "package:photos/main.dart";
import "package:photos/utils/file_uploader.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:workmanager/workmanager.dart" as workmanager;

const _kIOSBackgroundRefreshCadence = Duration(minutes: 15);
const _kIOSBackgroundProcessingCadence = Duration(hours: 1);

@pragma('vm:entry-point')
void callbackDispatcher() {
  workmanager.Workmanager().executeTask((taskName, inputData) async {
    final TimeLogger tlog = TimeLogger();
    final prefs = await SharedPreferences.getInstance();
    final shouldRescheduleProcessingTask =
        Platform.isIOS && taskName == BgTaskUtils.iOSBackgroundProcessingTask;
    try {
      BgTaskUtils.$.info('Task started $tlog');
      final result = await runBackgroundTask(taskName, tlog).timeout(
        Platform.isIOS ? kBGTaskTimeout : kAndroidBackgroundTaskTimeout,
        onTimeout: () async {
          BgTaskUtils.$.warning("Task timed out: $taskName");
          await BgTaskUtils.releaseResourcesForKill(taskName, prefs);
          return true;
        },
      );
      BgTaskUtils.$.info('Task run completed ($result) $tlog');
      return result;
    } catch (e) {
      BgTaskUtils.$.warning('Task error: $e');
      await BgTaskUtils.releaseResourcesForKill(taskName, prefs);
      return true;
    } finally {
      if (shouldRescheduleProcessingTask) {
        await BgTaskUtils.scheduleIOSBackgroundProcessingTask(
          source: "callbackDispatcher:$taskName",
        );
      }
    }
  });
}

class BgTaskUtils {
  static final $ = Logger("BgTaskUtils");
  static const iOSBackgroundAppRefresh =
      "io.ente.frame.iOSBackgroundAppRefresh";
  static const iOSBackgroundProcessingTask =
      "io.ente.frame.iOSBackgroundProcessing";
  static const androidPeriodicTask = "io.ente.photos.androidPeriodicTask";

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
    try {
      await workmanager.Workmanager().initialize(
        callbackDispatcher,
      );
      if (Platform.isIOS) {
        await requeueIOSBackgroundTasks(source: "configureWorkmanager");
      } else {
        await workmanager.Workmanager().registerPeriodicTask(
          androidPeriodicTask,
          androidPeriodicTask,
          frequency: const Duration(minutes: 15),
          initialDelay:
              kDebugMode ? Duration.zero : const Duration(minutes: 10),
          constraints: workmanager.Constraints(
            networkType: workmanager.NetworkType.connected,
            requiresCharging: false,
            requiresStorageNotLow: false,
            requiresDeviceIdle: false,
          ),
          existingWorkPolicy: workmanager.ExistingPeriodicWorkPolicy.update,
          backoffPolicy: workmanager.BackoffPolicy.linear,
          backoffPolicyDelay: const Duration(minutes: 15),
        );
      }
      $.info("WorkManager configured");

      // Check if task is scheduled (Android only)
      if (Platform.isAndroid) {
        final isScheduled = await workmanager.Workmanager()
            .isScheduledByUniqueName(androidPeriodicTask);
        if (!isScheduled) {
          $.warning(
            "Background task is not scheduled: $androidPeriodicTask",
          );
        }
      }
    } catch (e) {
      $.warning("Failed to configure WorkManager: $e");
    }
  }

  static Future<void> requeueIOSBackgroundTasks({
    required String source,
  }) async {
    if (!Platform.isIOS) {
      return;
    }

    $.info("Requeueing iOS background tasks from $source");

    await workmanager.Workmanager().registerPeriodicTask(
      iOSBackgroundAppRefresh,
      iOSBackgroundAppRefresh,
      frequency: _kIOSBackgroundRefreshCadence,
      initialDelay: _kIOSBackgroundRefreshCadence,
      constraints: workmanager.Constraints(
        networkType: workmanager.NetworkType.connected,
        requiresCharging: false,
        requiresStorageNotLow: false,
        requiresDeviceIdle: false,
      ),
      existingWorkPolicy: workmanager.ExistingPeriodicWorkPolicy.update,
      backoffPolicy: workmanager.BackoffPolicy.linear,
      backoffPolicyDelay: _kIOSBackgroundRefreshCadence,
    );
    await scheduleIOSBackgroundProcessingTask(source: source);
  }

  static Future<void> scheduleIOSBackgroundProcessingTask({
    required String source,
  }) async {
    if (!Platform.isIOS) {
      return;
    }

    $.info("Scheduling iOS background processing task from $source");

    await workmanager.Workmanager().registerProcessingTask(
      iOSBackgroundProcessingTask,
      iOSBackgroundProcessingTask,
      initialDelay: _kIOSBackgroundProcessingCadence,
      constraints: workmanager.Constraints(
        networkType: workmanager.NetworkType.connected,
        requiresCharging: false,
      ),
    );
  }
}
