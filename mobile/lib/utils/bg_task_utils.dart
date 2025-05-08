import "dart:io";

import "package:logging/logging.dart";
import "package:permission_handler/permission_handler.dart";
import "package:photos/db/upload_locks_db.dart";
import "package:photos/main.dart";
import "package:photos/utils/file_uploader.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:workmanager/workmanager.dart" as workmanager;
import "package:workmanager/workmanager.dart";

@pragma('vm:entry-point')
void callbackDispatcher() {
  workmanager.Workmanager().executeTask((taskName, inputData) async {
    try {
      await runBackgroundTask(taskName);
      return true;
    } catch (e) {
      BgTaskUtils.$.info('[WorkManager] task error: $e');
      await BgTaskUtils.killBGTask(taskName);
      return false;
    }
  });
}

class BgTaskUtils {
  static final $ = Logger("BgTaskUtils");

  static Future<void> killBGTask([String? taskId]) async {
    await UploadLocksDB.instance.releaseLocksAcquiredByOwnerBefore(
      ProcessType.background.toString(),
      DateTime.now().microsecondsSinceEpoch,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(kLastBGTaskHeartBeatTime);
    if (taskId != null) {
      await Workmanager().cancelByUniqueName(taskId);
    }
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
    final backgrounTaskIdentifier =
        Platform.isIOS ? iOSBackgroundAppRefresh : androidPeriodicTask;
    try {
      await workmanager.Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: true, // TODO: Remove when merged to production
      );
      await workmanager.Workmanager().registerPeriodicTask(
        backgrounTaskIdentifier,
        backgrounTaskIdentifier,
        frequency: const Duration(minutes: 15),
        initialDelay: const Duration(minutes: 10),
        constraints: workmanager.Constraints(
          networkType: workmanager.NetworkType.connected,
          requiresCharging: false,
          requiresStorageNotLow: false,
          requiresDeviceIdle: false,
        ),
        existingWorkPolicy: workmanager.ExistingWorkPolicy.keep,
        backoffPolicy: workmanager.BackoffPolicy.linear,
        backoffPolicyDelay: const Duration(minutes: 15),
      );
    } catch (e) {
      $.warning("Failed to configure WorkManager: $e");
    }
    $.info("WorkManager configured");
  }
}
