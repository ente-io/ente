import "dart:async";
import "dart:io";

import "package:grace_window_ios/grace_window_ios.dart";
import "package:logging/logging.dart";
import "package:photos/db/upload_locks_db.dart";
import "package:photos/service_locator.dart";
import "package:photos/utils/bg_task_utils.dart";
import "package:photos/utils/file_uploader.dart";
import "package:shared_preferences/shared_preferences.dart";

class UploadBackgroundCoordinator {
  UploadBackgroundCoordinator._privateConstructor();

  static final UploadBackgroundCoordinator instance =
      UploadBackgroundCoordinator._privateConstructor();

  static const _keyIOSUploadGraceActive = "ios_bg_upload_grace_active";

  final _logger = Logger("UploadBackgroundCoordinator");

  Future<void> onAppBackground() async {
    if (!Platform.isIOS || !flagService.enableIOSBackgroundHandoff) {
      return;
    }

    if (FileUploader.instance.hasActiveUploads) {
      if (!flagService.enableIOSBackgroundGraceWindow) {
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_keyIOSUploadGraceActive) ?? false) {
        return;
      }

      _logger.info("Starting iOS upload grace window");
      await GraceWindowIos.beginGraceWindow("ente-upload-grace-window");
      await prefs.setBool(_keyIOSUploadGraceActive, true);
      unawaited(_waitForGraceWindowExpiration());
      return;
    }

    if (await BgTaskUtils.isIOSBackupEligible()) {
      await BgTaskUtils.scheduleIOSBackgroundProcessingTask(
        source: "appBackground:maintenance",
        initialDelay: BgTaskUtils.maintenanceDelay(),
        reason: BgTaskUtils.iOSBackgroundProcessingReasonMaintenance,
      );
    }
  }

  Future<void> onAppForeground() async {
    if (!Platform.isIOS || !flagService.enableIOSBackgroundHandoff) {
      return;
    }

    if (!flagService.enableIOSBackgroundGraceWindow) {
      await BgTaskUtils.cancelIOSBackgroundProcessingTask(
        source: "appForeground",
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final graceWasActive = prefs.getBool(_keyIOSUploadGraceActive) ?? false;

    if (graceWasActive) {
      final cutoffMicros = DateTime.now().microsecondsSinceEpoch;

      _logger.info("Finishing iOS upload grace window and reconciling uploads");
      await GraceWindowIos.endGraceWindow();
      final didExpireGraceWindow = await GraceWindowIos.consumeExpiredState();
      await prefs.remove(_keyIOSUploadGraceActive);
      if (didExpireGraceWindow) {
        _logger.info(
          "Grace window expiration was observed natively before foreground recovery",
        );
        await UploadLocksDB.instance.releaseLocksAcquiredByOwnerBefore(
          ProcessType.foreground.toString(),
          cutoffMicros,
        );
      }
      await FileUploader.instance.reconcileAfterBackground();
    }

    await BgTaskUtils.cancelIOSBackgroundProcessingTask(
      source: "appForeground",
    );
  }

  /// Best-effort same-process expiration detection via a pending MethodChannel
  /// call. Swift holds the result and completes it when the native expiration
  /// handler fires. If this path misses (e.g. process suspended before
  /// delivery), [onAppForeground] catches it via [consumeExpiredState].
  Future<void> _waitForGraceWindowExpiration() async {
    final expired = await GraceWindowIos.awaitExpiration();
    if (!expired) {
      return;
    }

    final cutoffMicros = DateTime.now().microsecondsSinceEpoch;

    _logger.info("iOS upload grace window expired (via pending call)");

    // Consume the durable marker *before* releasing locks so that
    // onAppForeground (which can run between any two awaits here) won't
    // see the marker and do a second lock release against freshly
    // reacquired locks.
    await GraceWindowIos.consumeExpiredState();

    // Schedule continuation now that we know expiration actually happened.
    await BgTaskUtils.scheduleIOSBackgroundProcessingTask(
      source: "graceWindowExpired",
      initialDelay: BgTaskUtils.continuationDelay(),
      reason: BgTaskUtils.iOSBackgroundProcessingReasonContinuation,
    );

    await UploadLocksDB.instance.releaseLocksAcquiredByOwnerBefore(
      ProcessType.foreground.toString(),
      cutoffMicros,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIOSUploadGraceActive);
  }
}
