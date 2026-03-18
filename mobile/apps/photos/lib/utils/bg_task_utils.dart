import "dart:io";

import "package:ente_pure_utils/ente_pure_utils.dart";
import "package:flutter/foundation.dart";
import "package:logging/logging.dart";
import "package:permission_handler/permission_handler.dart";
import "package:photos/core/configuration.dart";
import "package:photos/db/upload_locks_db.dart";
import "package:photos/main.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/background_run_helper.dart";
import "package:photos/utils/file_uploader.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:workmanager/workmanager.dart" as workmanager;
import "package:workmanager_apple/workmanager_apple.dart";

const _kIOSBackgroundRefreshCadence = Duration(minutes: 15);
const _kIOSBackgroundProcessingContinuationDelay = Duration(seconds: 60);
const _kIOSBackgroundProcessingMaintenanceCadence = Duration(days: 1);
const _kDebugIOSBackgroundProcessingMaintenanceCadence = Duration(minutes: 15);

@pragma('vm:entry-point')
void callbackDispatcher() {
  workmanager.Workmanager().executeTask((taskName, inputData) async {
    final TimeLogger tlog = TimeLogger();
    final prefs = await SharedPreferences.getInstance();
    final shouldRescheduleProcessingTask =
        Platform.isIOS && taskName == BgTaskUtils.iOSBackgroundProcessingTask;
    bool didHandleExpiration = false;
    await WorkmanagerApple.setTaskExpirationHandler((expiredTaskName) async {
      if (expiredTaskName != taskName || didHandleExpiration) {
        return;
      }

      didHandleExpiration = true;
      BgTaskUtils.$
          .warning("Task expired via iOS expirationHandler: $taskName");
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
                if (shouldRescheduleProcessingTask && !didHandleExpiration) {
                  await BgTaskUtils.handleIOSBackgroundProcessingTaskCompletion(
                    source: "callbackDispatcher:$taskName:timeout",
                  );
                }
                return true;
              },
            );
      if (shouldRescheduleProcessingTask && !didHandleExpiration) {
        await BgTaskUtils.handleIOSBackgroundProcessingTaskCompletion(
          source: "callbackDispatcher:$taskName:success",
        );
      }
      BgTaskUtils.$.info('Task run completed ($result) $tlog');
      return result;
    } catch (e) {
      BgTaskUtils.$.warning('Task error: $e');
      if (!didHandleExpiration) {
        await BgTaskUtils.releaseResourcesForKill(taskName, prefs);
      }
      if (shouldRescheduleProcessingTask && !didHandleExpiration) {
        await BgTaskUtils.handleIOSBackgroundProcessingTaskCompletion(
          source: "callbackDispatcher:$taskName:error",
        );
      }
      return Platform.isIOS ? false : true;
    } finally {
      await WorkmanagerApple.clearTaskExpirationHandler();
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
  static const iOSBackgroundProcessingReasonContinuation = "continuation";
  static const iOSBackgroundProcessingReasonMaintenance = "maintenance";
  static const _keyIOSBackgroundProcessingReason =
      "ios_bg_upload_processing_reason";
  static const _keyIOSBackgroundProcessingScheduledAt =
      "ios_bg_upload_processing_scheduled_at";

  static BackgroundTrigger backgroundTriggerForTask(String taskId) {
    if (!Platform.isIOS) {
      return BackgroundTrigger.workmanager;
    }

    return taskId == iOSBackgroundProcessingTask
        ? BackgroundTrigger.bgProcessing
        : BackgroundTrigger.bgAppRefresh;
  }

  static Duration backgroundRunBudgetForTask(String taskId) {
    return switch (backgroundTriggerForTask(taskId)) {
      BackgroundTrigger.bgProcessing => kBGProcessingBudget,
      BackgroundTrigger.bgAppRefresh => kBGAppRefreshBudget,
      BackgroundTrigger.workmanager => kAndroidBackgroundTaskTimeout,
      BackgroundTrigger.remotePush => kBGPushBudget,
    };
  }

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
    if (!flagService.enableIOSUploadBackgroundHandoff) {
      await workmanager.Workmanager().cancelByUniqueName(
        iOSBackgroundProcessingTask,
      );
      await _clearIOSBackgroundProcessingSchedulingState();
    }
  }

  static Future<void> scheduleIOSBackgroundProcessingTask({
    required String source,
    Duration? initialDelay,
    String? reason,
  }) async {
    if (!Platform.isIOS) {
      return;
    }

    final delay = initialDelay ?? _maintenanceDelay();
    final prefs = await SharedPreferences.getInstance();
    final isUploadHandoffEnabled = flagService.enableIOSUploadBackgroundHandoff;
    if (!isUploadHandoffEnabled && reason != null) {
      $.info(
        "Skipping iOS background processing schedule from $source "
        "because upload handoff flag is disabled",
      );
      return;
    }
    await prefs.setInt(
      _keyIOSBackgroundProcessingScheduledAt,
      DateTime.now().microsecondsSinceEpoch,
    );
    if (reason == null) {
      await prefs.remove(_keyIOSBackgroundProcessingReason);
    } else {
      await prefs.setString(_keyIOSBackgroundProcessingReason, reason);
    }

    $.info(
      "Scheduling iOS background processing task from $source "
      "(delay=$delay, reason=${reason ?? "none"})",
    );

    await workmanager.Workmanager().registerProcessingTask(
      iOSBackgroundProcessingTask,
      iOSBackgroundProcessingTask,
      initialDelay: delay,
      constraints: workmanager.Constraints(
        networkType: workmanager.NetworkType.connected,
        requiresCharging: false,
      ),
    );
  }

  static Future<void> cancelIOSBackgroundProcessingTask({
    required String source,
  }) async {
    if (!Platform.isIOS) {
      return;
    }

    $.info("Cancelling iOS background processing task from $source");
    await workmanager.Workmanager().cancelByUniqueName(
      iOSBackgroundProcessingTask,
    );
    await _clearIOSBackgroundProcessingSchedulingState();
  }

  static Future<void> handleIOSBackgroundProcessingTaskStart({
    required String source,
  }) async {
    if (!Platform.isIOS) {
      return;
    }

    final isUploadHandoffEnabled = flagService.enableIOSUploadBackgroundHandoff;
    if (!isUploadHandoffEnabled) {
      await _clearIOSBackgroundProcessingSchedulingState();
      return;
    }

    final nextSchedule = nextIOSBackgroundProcessingSchedule(
      isUploadHandoffEnabled: isUploadHandoffEnabled,
      hasActiveUploads: FileUploader.instance.hasActiveUploads,
      isBackupEligible: await isIOSBackupEligible(),
    );
    if (nextSchedule != null) {
      await scheduleIOSBackgroundProcessingTask(
        source: "$source:start",
        initialDelay: nextSchedule.delay,
        reason: nextSchedule.reason,
      );
    } else {
      await _clearIOSBackgroundProcessingSchedulingState();
    }
  }

  static Future<void> handleIOSBackgroundProcessingTaskCompletion({
    required String source,
  }) async {
    if (!Platform.isIOS) {
      return;
    }

    await ensureServiceLocatorBootstrap();
    final prefs = await SharedPreferences.getInstance();
    final isUploadHandoffEnabled = flagService.enableIOSUploadBackgroundHandoff;
    if (!isUploadHandoffEnabled) {
      await _clearIOSBackgroundProcessingSchedulingState();
      return;
    }
    await prefs.reload();
    final reason = prefs.getString(_keyIOSBackgroundProcessingReason);
    await _clearIOSBackgroundProcessingSchedulingState();

    final nextSchedule = nextIOSBackgroundProcessingSchedule(
      isUploadHandoffEnabled: isUploadHandoffEnabled,
      hasActiveUploads: FileUploader.instance.hasActiveUploads,
      isBackupEligible: await isIOSBackupEligible(),
    );
    if (nextSchedule != null) {
      await scheduleIOSBackgroundProcessingTask(
        source: "$source:${reason ?? nextSchedule.reason}",
        initialDelay: nextSchedule.delay,
        reason: nextSchedule.reason,
      );
    }
  }

  static Duration continuationDelay() =>
      _kIOSBackgroundProcessingContinuationDelay;

  static Duration maintenanceDelay() => _maintenanceDelay();

  static Future<void> _clearIOSBackgroundProcessingSchedulingState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIOSBackgroundProcessingReason);
    await prefs.remove(_keyIOSBackgroundProcessingScheduledAt);
  }

  static Future<bool> isIOSBackupEligible() async {
    if (!Platform.isIOS || !Configuration.instance.hasConfiguredAccount()) {
      return false;
    }

    final photoPermission = await Permission.photos.status;
    final hasPhotoAccess = photoPermission == PermissionStatus.granted ||
        photoPermission == PermissionStatus.limited;
    if (!hasPhotoAccess) {
      return false;
    }

    return backupPreferenceService.hasSelectedAnyBackupFolder;
  }

  static IOSBackgroundProcessingSchedule? nextIOSBackgroundProcessingSchedule({
    required bool isUploadHandoffEnabled,
    required bool hasActiveUploads,
    required bool isBackupEligible,
  }) {
    if (!isUploadHandoffEnabled) {
      return null;
    }
    if (hasActiveUploads) {
      return const IOSBackgroundProcessingSchedule(
        delay: _kIOSBackgroundProcessingContinuationDelay,
        reason: iOSBackgroundProcessingReasonContinuation,
      );
    }
    if (isBackupEligible) {
      return IOSBackgroundProcessingSchedule(
        delay: _maintenanceDelay(),
        reason: iOSBackgroundProcessingReasonMaintenance,
      );
    }
    return null;
  }

  static Duration _maintenanceDelay() {
    if (kDebugMode) {
      return _kDebugIOSBackgroundProcessingMaintenanceCadence;
    }
    return _kIOSBackgroundProcessingMaintenanceCadence;
  }
}

class IOSBackgroundProcessingSchedule {
  const IOSBackgroundProcessingSchedule({
    required this.delay,
    required this.reason,
  });

  final Duration delay;
  final String reason;
}
