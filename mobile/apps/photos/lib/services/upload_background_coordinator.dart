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
  UploadBackgroundCoordinator._privateConstructor() {
    _ensureGraceWindowListener();
  }

  static final UploadBackgroundCoordinator instance =
      UploadBackgroundCoordinator._privateConstructor();

  static const _keyIOSUploadGraceActive = "ios_bg_upload_grace_active";

  final _logger = Logger("UploadBackgroundCoordinator");
  // ignore: cancel_subscriptions
  StreamSubscription<void>? _graceWindowExpiredSubscription;

  void _ensureGraceWindowListener() {
    if (_graceWindowExpiredSubscription != null) {
      return;
    }
    _graceWindowExpiredSubscription =
        GraceWindowIos.onGraceWindowExpired.listen(
      (_) {
        unawaited(onGraceWindowExpired());
      },
    );
  }

  Future<void> onAppBackground() async {
    if (!Platform.isIOS || !flagService.enableIOSUploadBackgroundHandoff) {
      return;
    }

    if (FileUploader.instance.hasActiveUploads) {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_keyIOSUploadGraceActive) ?? false) {
        return;
      }

      _logger.info("Starting iOS upload grace window");
      await GraceWindowIos.beginGraceWindow("ente-upload-grace-window");
      await prefs.setBool(_keyIOSUploadGraceActive, true);
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
    if (!Platform.isIOS || !flagService.enableIOSUploadBackgroundHandoff) {
      return;
    }

    _logger.info("Finishing iOS upload grace window and reconciling uploads");
    await GraceWindowIos.endGraceWindow();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIOSUploadGraceActive);
    await BgTaskUtils.cancelIOSBackgroundProcessingTask(
      source: "appForeground",
    );
    await FileUploader.instance.reconcileAfterBackground();
  }

  Future<void> onGraceWindowExpired() async {
    if (!Platform.isIOS || !flagService.enableIOSUploadBackgroundHandoff) {
      return;
    }

    _logger.info("iOS upload grace window expired");
    await BgTaskUtils.scheduleIOSBackgroundProcessingTask(
      source: "graceWindowExpired",
      initialDelay: BgTaskUtils.continuationDelay(),
      reason: BgTaskUtils.iOSBackgroundProcessingReasonContinuation,
    );
    final now = DateTime.now().microsecondsSinceEpoch;
    await UploadLocksDB.instance.releaseLocksAcquiredByOwnerBefore(
      ProcessType.foreground.toString(),
      now,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIOSUploadGraceActive);
    await GraceWindowIos.endGraceWindow();
  }
}
