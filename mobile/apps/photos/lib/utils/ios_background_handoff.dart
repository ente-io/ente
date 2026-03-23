import "dart:io";

import "package:flutter/foundation.dart";
import "package:permission_handler/permission_handler.dart";
import "package:photos/core/configuration.dart";
import "package:photos/main.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/background_run_helper.dart";
import "package:photos/utils/file_uploader.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:workmanager/workmanager.dart" as workmanager;

const iOSBackgroundAppRefresh = "io.ente.frame.iOSBackgroundAppRefresh";
const iOSBackgroundProcessingTask = "io.ente.frame.iOSBackgroundProcessing";
const iOSBackgroundProcessingReasonContinuation = "continuation";
const iOSBackgroundProcessingReasonMaintenance = "maintenance";

const _kIOSBackgroundRefreshCadence = Duration(minutes: 15);
const _kBackgroundPeriodicInitialDelay = Duration(minutes: 10);
const _kIOSBackgroundProcessingContinuationDelay = Duration(seconds: 60);
const _kIOSBackgroundProcessingMaintenanceCadence = Duration(days: 1);
const _kDebugIOSBackgroundProcessingMaintenanceCadence = Duration(minutes: 15);

const _keyIOSBackgroundProcessingReason = "ios_bg_upload_processing_reason";
const _keyIOSBackgroundProcessingScheduledAt =
    "ios_bg_upload_processing_scheduled_at";

BackgroundTrigger backgroundTriggerForTask(String taskId) {
  if (!Platform.isIOS) {
    return BackgroundTrigger.workmanager;
  }

  return taskId == iOSBackgroundProcessingTask
      ? BackgroundTrigger.bgProcessing
      : BackgroundTrigger.bgAppRefresh;
}

Duration backgroundRunBudgetForTask(String taskId) {
  return switch (backgroundTriggerForTask(taskId)) {
    BackgroundTrigger.bgProcessing => kBGProcessingBudget,
    BackgroundTrigger.bgAppRefresh => kBGAppRefreshBudget,
    BackgroundTrigger.workmanager => kAndroidBackgroundTaskTimeout,
    BackgroundTrigger.remotePush => kBGPushBudget,
  };
}

Future<void> requeueIOSBackgroundTasks({
  required String source,
}) async {
  if (!Platform.isIOS) {
    return;
  }

  await workmanager.Workmanager().registerPeriodicTask(
    iOSBackgroundAppRefresh,
    iOSBackgroundAppRefresh,
    frequency: _kIOSBackgroundRefreshCadence,
    initialDelay: kDebugMode ? Duration.zero : _kBackgroundPeriodicInitialDelay,
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
}

Future<void> scheduleIOSBackgroundProcessingTask({
  required String source,
  Duration? initialDelay,
  String? reason,
}) async {
  if (!Platform.isIOS) {
    return;
  }

  final delay = initialDelay ?? _maintenanceDelay();
  final prefs = await SharedPreferences.getInstance();
  if (!flagService.enableIOSBackgroundHandoff) {
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

Future<void> cancelIOSBackgroundProcessingTask({
  required String source,
}) async {
  if (!Platform.isIOS) {
    return;
  }

  await workmanager.Workmanager().cancelByUniqueName(
    iOSBackgroundProcessingTask,
  );
  await _clearIOSBackgroundProcessingSchedulingState();
}

Future<void> handleIOSBackgroundProcessingTaskStart({
  required String source,
}) async {
  if (!Platform.isIOS) {
    return;
  }

  if (!flagService.enableIOSBackgroundHandoff) {
    await _clearIOSBackgroundProcessingSchedulingState();
    return;
  }

  final nextSchedule = nextIOSBackgroundProcessingSchedule(
    isBackgroundHandoffEnabled: true,
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

Future<void> handleIOSBackgroundProcessingTaskCompletion({
  required String source,
}) async {
  if (!Platform.isIOS) {
    return;
  }

  await ensureServiceLocatorBootstrap();
  final prefs = await SharedPreferences.getInstance();
  if (!flagService.enableIOSBackgroundHandoff) {
    await _clearIOSBackgroundProcessingSchedulingState();
    return;
  }
  await prefs.reload();
  final reason = prefs.getString(_keyIOSBackgroundProcessingReason);
  await _clearIOSBackgroundProcessingSchedulingState();

  final nextSchedule = nextIOSBackgroundProcessingSchedule(
    isBackgroundHandoffEnabled: true,
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

Duration continuationDelay() => _kIOSBackgroundProcessingContinuationDelay;

Duration maintenanceDelay() => _maintenanceDelay();

Future<bool> isIOSBackupEligible() async {
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

IOSBackgroundProcessingSchedule? nextIOSBackgroundProcessingSchedule({
  required bool isBackgroundHandoffEnabled,
  required bool hasActiveUploads,
  required bool isBackupEligible,
}) {
  if (!isBackgroundHandoffEnabled) {
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

Future<void> clearIOSBackgroundProcessingSchedulingState() async {
  await _clearIOSBackgroundProcessingSchedulingState();
}

Future<void> _clearIOSBackgroundProcessingSchedulingState() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_keyIOSBackgroundProcessingReason);
  await prefs.remove(_keyIOSBackgroundProcessingScheduledAt);
}

Duration _maintenanceDelay() {
  if (kDebugMode) {
    return _kDebugIOSBackgroundProcessingMaintenanceCadence;
  }
  return _kIOSBackgroundProcessingMaintenanceCadence;
}

class IOSBackgroundProcessingSchedule {
  const IOSBackgroundProcessingSchedule({
    required this.delay,
    required this.reason,
  });

  final Duration delay;
  final String reason;
}
