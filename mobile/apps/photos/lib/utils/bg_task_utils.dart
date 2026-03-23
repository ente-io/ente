import "dart:io";

import "package:ente_feature_flag/ente_feature_flag.dart";
import "package:ente_pure_utils/ente_pure_utils.dart";
import "package:flutter/foundation.dart";
import "package:logging/logging.dart";
import "package:permission_handler/permission_handler.dart";
import "package:photos/db/upload_locks_db.dart";
import "package:photos/main.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/background_run_helper.dart";
import "package:photos/utils/ios_background_handoff.dart" as ios_handoff;
import "package:shared_preferences/shared_preferences.dart";
import "package:workmanager/workmanager.dart" as workmanager;
import "package:workmanager_apple/workmanager_apple.dart";

@pragma('vm:entry-point')
void callbackDispatcher() {
  workmanager.Workmanager().executeTask((taskName, inputData) async {
    final TimeLogger tlog = TimeLogger();
    Future<bool> result = Future.error("Task didn't run");
    final prefs = await SharedPreferences.getInstance();

    if (Platform.isIOS &&
        (FlagService.isInternalUserEnabledInPrefs(prefs) ||
            taskName == BgTaskUtils.iOSBackgroundProcessingTask)) {
      return _runHandoffCallbackTask(taskName, prefs);
    }

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
              return true;
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

Future<bool> _runHandoffCallbackTask(
  String taskName,
  SharedPreferences prefs,
) async {
  final TimeLogger tlog = TimeLogger();
  final shouldRescheduleProcessingTask =
      Platform.isIOS && taskName == BgTaskUtils.iOSBackgroundProcessingTask;
  bool didHandleExpiration = false;
  Future<void> maybeReschedule(String source) async {
    if (shouldRescheduleProcessingTask && !didHandleExpiration) {
      await BgTaskUtils.handleIOSBackgroundProcessingTaskCompletion(
        source: "callbackDispatcher:$taskName:$source",
      );
    }
  }

  await WorkmanagerApple.setTaskExpirationHandler((expiredTaskName) async {
    if (expiredTaskName != taskName || didHandleExpiration) {
      return;
    }

    didHandleExpiration = true;
    BgTaskUtils.$.warning(
      "Task expired via iOS expirationHandler: $taskName",
    );
    await BgTaskUtils.releaseResourcesForKill(taskName, prefs);
    if (shouldRescheduleProcessingTask) {
      await BgTaskUtils.handleIOSBackgroundProcessingTaskCompletion(
        source: "callbackDispatcher:$taskName:expired",
      );
    }
  });
  try {
    BgTaskUtils.$.info('Task started $tlog');
    final result = Platform.isIOS
        ? await runBackgroundTask(taskName, tlog)
        : await runBackgroundTask(taskName, tlog).timeout(
            BgTaskUtils.backgroundRunBudgetForTask(taskName),
            onTimeout: () async {
              BgTaskUtils.$.warning("Task timed out: $taskName");
              if (!didHandleExpiration) {
                await BgTaskUtils.releaseResourcesForKill(taskName, prefs);
              }
              await maybeReschedule("timeout");
              return true;
            },
          );
    await maybeReschedule("success");
    BgTaskUtils.$.info('Task run completed ($result) $tlog');
    return result;
  } catch (e) {
    BgTaskUtils.$.warning('Task error: $e');
    if (!didHandleExpiration) {
      await BgTaskUtils.releaseResourcesForKill(taskName, prefs);
    }
    await maybeReschedule("error");
    return Platform.isIOS ? false : true;
  } finally {
    await WorkmanagerApple.clearTaskExpirationHandler();
  }
}

class BgTaskUtils {
  static final $ = Logger("BgTaskUtils");
  static const iOSBackgroundAppRefresh = ios_handoff.iOSBackgroundAppRefresh;
  static const iOSBackgroundProcessingTask =
      ios_handoff.iOSBackgroundProcessingTask;
  static const androidPeriodicTask = "io.ente.photos.androidPeriodicTask";
  static const iOSBackgroundProcessingReasonContinuation =
      ios_handoff.iOSBackgroundProcessingReasonContinuation;
  static const iOSBackgroundProcessingReasonMaintenance =
      ios_handoff.iOSBackgroundProcessingReasonMaintenance;

  static BackgroundTrigger backgroundTriggerForTask(String taskId) {
    return ios_handoff.backgroundTriggerForTask(taskId);
  }

  static Duration backgroundRunBudgetForTask(String taskId) {
    return ios_handoff.backgroundRunBudgetForTask(taskId);
  }

  static Future<void> releaseResourcesForKill(
    String taskId,
    SharedPreferences prefs,
  ) async {
    await UploadLocksDB.instance.releaseLocksAcquiredByOwnerBefore(
      "ProcessType.background",
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
    final backgroundTaskIdentifier =
        Platform.isIOS ? iOSBackgroundAppRefresh : androidPeriodicTask;
    try {
      await workmanager.Workmanager().initialize(
        callbackDispatcher,
      );
      if (Platform.isIOS && flagService.enableIOSBackgroundHandoff) {
        await requeueIOSBackgroundTasks(source: "configureWorkmanager");
      } else {
        await workmanager.Workmanager().registerPeriodicTask(
          backgroundTaskIdentifier,
          backgroundTaskIdentifier,
          frequency: Platform.isIOS
              ? const Duration(minutes: 30)
              : const Duration(minutes: 15),
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
        if (Platform.isIOS) {
          await cancelIOSBackgroundProcessingTask(
            source: "configureWorkmanager:legacy",
          );
        }
      }
      $.info("WorkManager configured");

      // Check if task is scheduled (Android only)
      if (Platform.isAndroid) {
        final isScheduled = await workmanager.Workmanager()
            .isScheduledByUniqueName(backgroundTaskIdentifier);
        if (!isScheduled) {
          $.warning(
            "Background task is not scheduled: $backgroundTaskIdentifier",
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
    return ios_handoff.requeueIOSBackgroundTasks(source: source);
  }

  static Future<void> scheduleIOSBackgroundProcessingTask({
    required String source,
    Duration? initialDelay,
    String? reason,
  }) async {
    return ios_handoff.scheduleIOSBackgroundProcessingTask(
      source: source,
      initialDelay: initialDelay,
      reason: reason,
    );
  }

  static Future<void> cancelIOSBackgroundProcessingTask({
    required String source,
  }) async {
    return ios_handoff.cancelIOSBackgroundProcessingTask(source: source);
  }

  static Future<void> handleIOSBackgroundProcessingTaskStart({
    required String source,
  }) async {
    return ios_handoff.handleIOSBackgroundProcessingTaskStart(source: source);
  }

  static Future<void> handleIOSBackgroundProcessingTaskCompletion({
    required String source,
  }) async {
    return ios_handoff.handleIOSBackgroundProcessingTaskCompletion(
      source: source,
    );
  }

  static Duration continuationDelay() => ios_handoff.continuationDelay();

  static Duration maintenanceDelay() => ios_handoff.maintenanceDelay();

  static Future<bool> isIOSBackupEligible() async {
    return ios_handoff.isIOSBackupEligible();
  }

  static IOSBackgroundProcessingSchedule? nextIOSBackgroundProcessingSchedule({
    required bool isBackgroundHandoffEnabled,
    required bool hasActiveUploads,
    required bool isBackupEligible,
  }) {
    return ios_handoff.nextIOSBackgroundProcessingSchedule(
      isBackgroundHandoffEnabled: isBackgroundHandoffEnabled,
      hasActiveUploads: hasActiveUploads,
      isBackupEligible: isBackupEligible,
    );
  }
}

typedef IOSBackgroundProcessingSchedule
    = ios_handoff.IOSBackgroundProcessingSchedule;
