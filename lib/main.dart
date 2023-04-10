import 'dart:async';
import 'dart:io';

import "package:adaptive_theme/adaptive_theme.dart";
import 'package:background_fetch/background_fetch.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import "package:flutter/rendering.dart";
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photos/app.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/core/error-reporting/super_logging.dart';
import 'package:photos/core/errors.dart';
import 'package:photos/core/network/network.dart';
import 'package:photos/db/upload_locks_db.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/services/app_lifecycle_service.dart';
import 'package:photos/services/billing_service.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/services/favorites_service.dart';
import 'package:photos/services/feature_flag_service.dart';
import 'package:photos/services/local_file_update_service.dart';
import 'package:photos/services/local_sync_service.dart';
import 'package:photos/services/memories_service.dart';
import 'package:photos/services/notification_service.dart';
import "package:photos/services/object_detection/object_detection_service.dart";
import 'package:photos/services/push_service.dart';
import 'package:photos/services/remote_sync_service.dart';
import 'package:photos/services/search_service.dart';
import "package:photos/services/storage_bonus_service.dart";
import 'package:photos/services/sync_service.dart';
import 'package:photos/services/trash_sync_service.dart';
import 'package:photos/services/update_service.dart';
import 'package:photos/services/user_remote_flag_service.dart';
import 'package:photos/services/user_service.dart';
import 'package:photos/ui/tools/app_lock.dart';
import 'package:photos/ui/tools/lock_screen.dart';
import 'package:photos/utils/crypto_util.dart';
import 'package:photos/utils/file_uploader.dart';
import 'package:photos/utils/local_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _logger = Logger("main");

bool _isProcessRunning = false;
const kLastBGTaskHeartBeatTime = "bg_task_hb_time";
const kLastFGTaskHeartBeatTime = "fg_task_hb_time";
const kHeartBeatFrequency = Duration(seconds: 1);
const kFGSyncFrequency = Duration(minutes: 5);
const kBGTaskTimeout = Duration(seconds: 25);
const kBGPushTimeout = Duration(seconds: 28);
const kFGTaskDeathTimeoutInMicroseconds = 5000000;
const kBackgroundLockLatency = Duration(seconds: 3);

void main() async {
  debugRepaintRainbowEnabled = false;
  WidgetsFlutterBinding.ensureInitialized();
  final savedThemeMode = await AdaptiveTheme.getThemeMode();
  await _runInForeground(savedThemeMode);
  BackgroundFetch.registerHeadlessTask(_headlessTaskHandler);
}

Future<void> _runInForeground(AdaptiveThemeMode? savedThemeMode) async {
  return await _runWithLogs(() async {
    _logger.info("Starting app in foreground");
    await _init(false, via: 'mainMethod');
    unawaited(_scheduleFGSync('appStart in FG'));
    runApp(
      AppLock(
        builder: (args) =>
            EnteApp(_runBackgroundTask, _killBGTask, savedThemeMode),
        lockScreen: const LockScreen(),
        enabled: Configuration.instance.shouldShowLockScreen(),
        lightTheme: lightThemeData,
        darkTheme: darkThemeData,
        backgroundLockLatency: kBackgroundLockLatency,
        savedThemeMode: _themeMode(savedThemeMode),
      ),
    );
  });
}

ThemeMode _themeMode(AdaptiveThemeMode? savedThemeMode) {
  if (savedThemeMode == null) return ThemeMode.system;
  if (savedThemeMode.isLight) return ThemeMode.light;
  if (savedThemeMode.isDark) return ThemeMode.dark;
  return ThemeMode.system;
}

Future<void> _runBackgroundTask(String taskId, {String mode = 'normal'}) async {
  if (_isProcessRunning) {
    _logger.info("Background task triggered when process was already running");
    await _sync('bgTaskActiveProcess');
    BackgroundFetch.finish(taskId);
  } else {
    _runWithLogs(
      () async {
        _logger.info("Starting background task in $mode mode");
        _runInBackground(taskId);
      },
      prefix: "[bg]",
    );
  }
}

Future<void> _runInBackground(String taskId) async {
  await Future.delayed(const Duration(seconds: 3));
  if (await _isRunningInForeground()) {
    _logger.info("FG task running, skipping BG taskID: $taskId");
    BackgroundFetch.finish(taskId);
    return;
  } else {
    _logger.info("FG task is not running");
  }
  _logger.info("[BackgroundFetch] Event received: $taskId");
  _scheduleBGTaskKill(taskId);
  if (Platform.isIOS) {
    _scheduleSuicide(kBGTaskTimeout, taskId); // To prevent OS from punishing us
  }
  await _init(true, via: 'runViaBackgroundTask');
  UpdateService.instance.showUpdateNotification();
  await _sync('bgSync');
  BackgroundFetch.finish(taskId);
}

// https://stackoverflow.com/a/73796478/546896
@pragma('vm:entry-point')
void _headlessTaskHandler(HeadlessTask task) {
  debugPrint("_headlessTaskHandler");
  if (task.timeout) {
    BackgroundFetch.finish(task.taskId);
  } else {
    _runBackgroundTask(task.taskId, mode: "headless");
  }
}

Future<void> _init(bool isBackground, {String via = ''}) async {
  _isProcessRunning = true;
  _logger.info("Initializing...  inBG =$isBackground via: $via");
  final SharedPreferences preferences = await SharedPreferences.getInstance();
  await _logFGHeartBeatInfo();
  _scheduleHeartBeat(preferences, isBackground);
  if (isBackground) {
    AppLifecycleService.instance.onAppInBackground('init via: $via');
  } else {
    AppLifecycleService.instance.onAppInForeground('init via: $via');
  }
  CryptoUtil.init();
  await NotificationService.instance.init();
  await NetworkClient.instance.init();
  await Configuration.instance.init();
  await UserService.instance.init();
  await UserRemoteFlagService.instance.init();
  await UpdateService.instance.init();
  BillingService.instance.init();
  await CollectionsService.instance.init(preferences);
  FavoritesService.instance.initFav().ignore();
  await FileUploader.instance.init(preferences, isBackground);
  await LocalSyncService.instance.init(preferences);
  TrashSyncService.instance.init(preferences);
  RemoteSyncService.instance.init(preferences);
  await SyncService.instance.init(preferences);
  MemoriesService.instance.init();
  LocalSettings.instance.init(preferences);
  LocalFileUpdateService.instance.init(preferences);
  SearchService.instance.init();
  StorageBonusService.instance.init(preferences);
  if (Platform.isIOS) {
    PushService.instance.init().then((_) {
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );
    });
  }
  FeatureFlagService.instance.init();
  if (FeatureFlagService.instance.isInternalUserOrDebugBuild()) {
    await ObjectDetectionService.instance.init();
  }
  _logger.info("Initialization done");
}

Future<void> _sync(String caller) async {
  if (!AppLifecycleService.instance.isForeground) {
    _logger.info("Syncing in background caller $caller");
  } else {
    _logger.info("Syncing in foreground caller $caller");
  }
  try {
    await SyncService.instance.sync();
  } catch (e, s) {
    if (!isHandledSyncError(e)) {
      _logger.severe("Sync error", e, s);
    }
  }
}

Future _runWithLogs(Function() function, {String prefix = ""}) async {
  await SuperLogging.main(
    LogConfig(
      body: function,
      logDirPath: (await getApplicationSupportDirectory()).path + "/logs",
      maxLogFiles: 5,
      sentryDsn: kDebugMode ? sentryDebugDSN : sentryDSN,
      tunnel: sentryTunnel,
      enableInDebugMode: true,
      prefix: prefix,
    ),
  );
}

Future<void> _scheduleHeartBeat(
  SharedPreferences prefs,
  bool isBackground,
) async {
  await prefs.setInt(
    isBackground ? kLastBGTaskHeartBeatTime : kLastFGTaskHeartBeatTime,
    DateTime.now().microsecondsSinceEpoch,
  );
  Future.delayed(kHeartBeatFrequency, () async {
    _scheduleHeartBeat(prefs, isBackground);
  });
}

Future<void> _scheduleFGSync(String caller) async {
  await _sync(caller);
  Future.delayed(kFGSyncFrequency, () async {
    unawaited(_scheduleFGSync('fgSyncCron'));
  });
}

void _scheduleBGTaskKill(String taskId) async {
  if (await _isRunningInForeground()) {
    _logger.info("Found app in FG, committing seppuku. $taskId");
    await _killBGTask(taskId);
    return;
  }
  Future.delayed(kHeartBeatFrequency, () async {
    _scheduleBGTaskKill(taskId);
  });
}

Future<bool> _isRunningInForeground() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.reload();
  final currentTime = DateTime.now().microsecondsSinceEpoch;
  final lastFGHeartBeatTime = DateTime.fromMicrosecondsSinceEpoch(
    prefs.getInt(kLastFGTaskHeartBeatTime) ?? 0,
  );
  _logger.info("Last FG heart beat @ ", lastFGHeartBeatTime.toString());
  return lastFGHeartBeatTime.microsecondsSinceEpoch >
      (currentTime - kFGTaskDeathTimeoutInMicroseconds);
}

Future<void> _killBGTask([String? taskId]) async {
  await UploadLocksDB.instance.releaseLocksAcquiredByOwnerBefore(
    ProcessType.background.toString(),
    DateTime.now().microsecondsSinceEpoch,
  );
  final prefs = await SharedPreferences.getInstance();
  prefs.remove(kLastBGTaskHeartBeatTime);
  if (taskId != null) {
    BackgroundFetch.finish(taskId);
  }
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  final bool isRunningInFG = await _isRunningInForeground(); // hb
  final bool isInForeground = AppLifecycleService.instance.isForeground;
  if (_isProcessRunning) {
    _logger.info(
      "Background push received when app is alive and runningInFS: $isRunningInFG inForeground: $isInForeground",
    );
    if (PushService.shouldSync(message)) {
      await _sync('firebaseBgSyncActiveProcess');
    }
  } else {
    // App is dead
    _runWithLogs(
      () async {
        _logger.info("Background push received");
        if (Platform.isIOS) {
          _scheduleSuicide(kBGPushTimeout); // To prevent OS from punishing us
        }
        await _init(true, via: 'firebasePush');
        if (PushService.shouldSync(message)) {
          await _sync('firebaseBgSyncNoActiveProcess');
        }
      },
      prefix: "[fbg]",
    );
  }
}

Future<void> _logFGHeartBeatInfo() async {
  final bool isRunningInFG = await _isRunningInForeground();
  final prefs = await SharedPreferences.getInstance();
  await prefs.reload();
  final lastFGTaskHeartBeatTime = prefs.getInt(kLastFGTaskHeartBeatTime) ?? 0;
  final String lastRun = lastFGTaskHeartBeatTime == 0
      ? 'never'
      : DateTime.fromMicrosecondsSinceEpoch(lastFGTaskHeartBeatTime).toString();
  _logger.info('isAlreaduunningFG: $isRunningInFG, last Beat: $lastRun');
}

void _scheduleSuicide(Duration duration, [String? taskID]) {
  final taskIDVal = taskID ?? 'no taskID';
  _logger.warning("Schedule seppuku taskID: $taskIDVal");
  Future.delayed(duration, () {
    _logger.warning("TLE, committing seppuku for taskID: $taskIDVal");
    _killBGTask(taskID);
  });
}
