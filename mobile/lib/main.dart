import 'dart:async';
import 'dart:io';

import "package:adaptive_theme/adaptive_theme.dart";
import "package:computer/computer.dart";
import 'package:ente_crypto/ente_crypto.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import "package:flutter/rendering.dart";
import "package:flutter/services.dart";
import "package:flutter_displaymode/flutter_displaymode.dart";
import 'package:logging/logging.dart';
import "package:media_kit/media_kit.dart";
import "package:package_info_plus/package_info_plus.dart";
import 'package:path_provider/path_provider.dart';
import 'package:photos/app.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/core/error-reporting/super_logging.dart';
import 'package:photos/core/errors.dart';
import 'package:photos/core/network/network.dart';
import "package:photos/db/ml/db.dart";
import 'package:photos/ente_theme_data.dart';
import "package:photos/extensions/stop_watch.dart";
import "package:photos/l10n/l10n.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/account/user_service.dart";
import 'package:photos/services/app_lifecycle_service.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/services/favorites_service.dart';
import 'package:photos/services/home_widget_service.dart';
import 'package:photos/services/local_file_update_service.dart';
import "package:photos/services/machine_learning/face_ml/person/person_service.dart";
import 'package:photos/services/machine_learning/ml_service.dart';
import 'package:photos/services/machine_learning/semantic_search/semantic_search_service.dart';
import "package:photos/services/notification_service.dart";
import 'package:photos/services/push_service.dart';
import 'package:photos/services/search_service.dart';
import 'package:photos/services/sync/local_sync_service.dart';
import 'package:photos/services/sync/remote_sync_service.dart';
import "package:photos/services/sync/sync_service.dart";
import "package:photos/services/video_preview_service.dart";
import "package:photos/services/wake_lock_service.dart";
import 'package:photos/ui/tools/app_lock.dart';
import 'package:photos/ui/tools/lock_screen.dart';
import "package:photos/utils/email_util.dart";
import 'package:photos/utils/file_uploader.dart';
import "package:photos/utils/lock_screen_settings.dart";
import 'package:shared_preferences/shared_preferences.dart';

final _logger = Logger("main");

const kLastBGTaskHeartBeatTime = "bg_task_hb_time";
const kLastFGTaskHeartBeatTime = "fg_task_hb_time";
const kHeartBeatFrequency = Duration(seconds: 1);
const kFGSyncFrequency = Duration(minutes: 5);
const kFGHomeWidgetSyncFrequency = Duration(minutes: 15);
const kBGTaskTimeout = Duration(seconds: 28);
const kBGPushTimeout = Duration(seconds: 28);
const kFGTaskDeathTimeoutInMicroseconds = 5000000;

void main() async {
  debugRepaintRainbowEnabled = false;
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  final savedThemeMode = await AdaptiveTheme.getThemeMode();
  await _runInForeground(savedThemeMode);

  if (Platform.isAndroid) FlutterDisplayMode.setHighRefreshRate().ignore();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Color(0x00010000),
    ),
  );

  unawaited(
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
    ),
  );
}

Future<void> _runInForeground(AdaptiveThemeMode? savedThemeMode) async {
  return await runWithLogs(() async {
    _logger.info("Starting app in foreground");
    await _init(false, via: 'mainMethod');
    final Locale? locale = await getLocale(noFallback: true);
    runApp(
      AppLock(
        builder: (args) => EnteApp(locale, savedThemeMode),
        lockScreen: const LockScreen(),
        enabled: await Configuration.instance.shouldShowLockScreen() ||
            localSettings.isOnGuestView(),
        locale: locale,
        lightTheme: lightThemeData,
        darkTheme: darkThemeData,
        savedThemeMode: _themeMode(savedThemeMode),
      ),
    );
    unawaited(_scheduleFGSync('appStart in FG'));
  });
}

ThemeMode _themeMode(AdaptiveThemeMode? savedThemeMode) {
  if (savedThemeMode == null) return ThemeMode.system;
  if (savedThemeMode.isLight) return ThemeMode.light;
  if (savedThemeMode.isDark) return ThemeMode.dark;
  return ThemeMode.system;
}

Future<void> _homeWidgetSync([bool isBackground = false]) async {
  if (isBackground && Platform.isIOS) {
    _logger.info("Home widget sync skipped in background on iOS");
    return;
  }

  try {
    await HomeWidgetService.instance.initHomeWidget();
  } catch (e, s) {
    _logger.severe("Error in syncing home widget", e, s);
  }
}

Future<void> runBackgroundTask(
  String taskId,
  TimeLogger tlog, {
  String mode = 'normal',
}) async {
  await _runMinimally(taskId, tlog);
}

Future<void> _runMinimally(String taskId, TimeLogger tlog) async {
  final PackageInfo packageInfo = await PackageInfo.fromPlatform();
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  await Configuration.instance.init();

  // App LifeCycle
  AppLifecycleService.instance.init(prefs);
  AppLifecycleService.instance.onAppInBackground('init via: WorkManager $tlog');

  // Crypto rel.
  await Computer.shared().turnOn(workersCount: 4);
  CryptoUtil.init();

  // Init Network Utils
  await NetworkClient.instance.init(packageInfo);

  // Global Services
  ServiceLocator.instance.init(
    prefs,
    NetworkClient.instance.enteDio,
    NetworkClient.instance.getDio(),
    packageInfo,
  );

  await CollectionsService.instance.init(prefs);

  // Upload & Sync Related
  await FileUploader.instance.init(prefs, true);
  LocalFileUpdateService.instance.init(prefs);
  await LocalSyncService.instance.init(prefs);
  RemoteSyncService.instance.init(prefs);
  await SyncService.instance.init(prefs);

  // Misc Services
  await UserService.instance.init();
  NotificationService.instance.init(prefs);
  if (Platform.isAndroid) HomeWidgetService.instance.init(prefs);

  // Begin Execution
  // only runs for android
  updateService.showUpdateNotification().ignore();
  await _sync('bgTaskActiveProcess');
  // only runs for android
  await _homeWidgetSync(true);
}

Future<void> _init(bool isBackground, {String via = ''}) async {
  try {
    bool initComplete = false;
    final TimeLogger tlog = TimeLogger();
    Future.delayed(const Duration(seconds: 15), () {
      if (!initComplete && !isBackground) {
        _logger.severe("Stuck on splash screen for >= 15 seconds");
        triggerSendLogs(
          "support@ente.io",
          "Stuck on splash screen for >= 15 seconds on ${Platform.operatingSystem}",
          null,
        );
      }
    });
    if (!isBackground) _heartBeatOnInit(0);
    _logger.info("Initializing...  inBG =$isBackground via: $via $tlog");
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    await _logFGHeartBeatInfo(preferences);
    _logger.info("_logFGHeartBeatInfo done $tlog");
    unawaited(_scheduleHeartBeat(preferences, isBackground));
    NotificationService.instance.init(preferences);
    AppLifecycleService.instance.init(preferences);
    if (isBackground) {
      AppLifecycleService.instance.onAppInBackground('init via: $via $tlog');
    } else {
      AppLifecycleService.instance.onAppInForeground('init via: $via $tlog');
    }
    // Start workers asynchronously. No need to wait for them to start
    Computer.shared().turnOn(workersCount: 4).ignore();
    CryptoUtil.init();

    _logger.info("Lockscreen init $tlog");
    unawaited(LockScreenSettings.instance.init(preferences));

    _logger.info("Configuration init $tlog");
    await Configuration.instance.init();
    _logger.info("Configuration done $tlog");

    _logger.info("NetworkClient init $tlog");
    await NetworkClient.instance.init(packageInfo);
    _logger.info("NetworkClient init done $tlog");

    ServiceLocator.instance.init(
      preferences,
      NetworkClient.instance.enteDio,
      NetworkClient.instance.getDio(),
      packageInfo,
    );

    _logger.info("UserService init $tlog");
    await UserService.instance.init();
    _logger.info("UserService init done $tlog");

    _logger.info("CollectionsService init $tlog");
    await CollectionsService.instance.init(preferences);
    _logger.info("CollectionsService init done $tlog");

    FavoritesService.instance.initFav().ignore();
    LocalFileUpdateService.instance.init(preferences);
    SearchService.instance.init();

    _logger.info("FileUploader init $tlog");
    await FileUploader.instance.init(preferences, isBackground);
    _logger.info("FileUploader init done $tlog");

    _logger.info("LocalSyncService init $tlog");
    await LocalSyncService.instance.init(preferences);
    _logger.info("LocalSyncService init done $tlog");

    RemoteSyncService.instance.init(preferences);
    _logger.info("RemoteFileMLService done $tlog");

    _logger.info("SyncService init $tlog");
    await SyncService.instance.init(preferences);
    _logger.info("SyncService init done $tlog");

    HomeWidgetService.instance.init(preferences);

    if (!isBackground) {
      await _scheduleFGHomeWidgetSync();
    }

    if (Platform.isIOS) {
      PushService.instance.init().then((_) {
        FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler,
        );
      }).ignore();
    }
    _logger.info("PushService/HomeWidget done $tlog");
    VideoPreviewService.instance.init(preferences);
    unawaited(SemanticSearchService.instance.init());
    unawaited(MLService.instance.init());
    await PersonService.init(
      entityService,
      MLDataDB.instance,
      preferences,
    );
    EnteWakeLockService.instance.init(preferences);
    logLocalSettings();
    initComplete = true;
    _logger.info("Initialization done $tlog");
  } catch (e, s) {
    _logger.severe("Error in init ", e, s);
    rethrow;
  }
}

void logLocalSettings() {
  _logger.info("Show memories: ${memoriesCacheService.showAnyMemories}");
  _logger
      .info("Smart memories enabled: ${localSettings.isSmartMemoriesEnabled}");
  _logger.info("Ml is enabled: ${flagService.hasGrantedMLConsent}");
  _logger.info(
    "ML local indexing is enabled: ${localSettings.isMLLocalIndexingEnabled}",
  );
  _logger.info(
    "Multipart upload is enabled: ${localSettings.userEnabledMultiplePart}",
  );
  _logger.info("Gallery grid size: ${localSettings.getPhotoGridSize()}");
  _logger.info(
    "Video streaming is enalbed: ${VideoPreviewService.instance.isVideoStreamingEnabled}",
  );
}

void _heartBeatOnInit(int i) {
  if (i <= 15) {
    Future.delayed(const Duration(seconds: 1), () {
      _logger.info("init Heartbeat $i");
      _heartBeatOnInit(i + 1);
    });
  }
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
      _logger.warning("Sync error", e, s);
    }
  }
}

Future runWithLogs(Function() function, {String prefix = ""}) async {
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
    // ignore: unawaited_futures
    _scheduleHeartBeat(prefs, isBackground);
  });
}

Future<void> _scheduleFGHomeWidgetSync() async {
  Future.delayed(kFGHomeWidgetSyncFrequency, () async {
    unawaited(_homeWidgetSyncPeriodic());
  });
}

Future<void> _homeWidgetSyncPeriodic() async {
  await _homeWidgetSync();
  Future.delayed(kFGHomeWidgetSyncFrequency, () async {
    unawaited(_homeWidgetSyncPeriodic());
  });
}

Future<void> _scheduleFGSync(String caller) async {
  await _sync(caller);
  Future.delayed(kFGSyncFrequency, () async {
    unawaited(_scheduleFGSync('fgSyncCron'));
  });
}

Future<bool> _isRunningInForeground() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.reload();
  final currentTime = DateTime.now().microsecondsSinceEpoch;
  final lastFGHeartBeatTime = DateTime.fromMicrosecondsSinceEpoch(
    prefs.getInt(kLastFGTaskHeartBeatTime) ?? 0,
  );
  return lastFGHeartBeatTime.microsecondsSinceEpoch >
      (currentTime - kFGTaskDeathTimeoutInMicroseconds);
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  final bool isRunningInFG = await _isRunningInForeground(); // hb
  final bool isInForeground = AppLifecycleService.instance.isForeground;
  if (await _isRunningInForeground()) {
    _logger.info(
      "Background push received when app is alive and runningInFS: $isRunningInFG inForeground: $isInForeground",
    );
    if (PushService.shouldSync(message)) {
      await _sync('firebaseBgSyncActiveProcess');
    }
  } else {
    // App is dead
    runWithLogs(
      () async {
        _logger.info("Background push received");
        await _init(true, via: 'firebasePush');
        if (PushService.shouldSync(message)) {
          await _sync('firebaseBgSyncNoActiveProcess');
        }
      },
      prefix: "[fbg]",
    ).ignore();
  }
}

Future<void> _logFGHeartBeatInfo(SharedPreferences prefs) async {
  final bool isRunningInFG = await _isRunningInForeground();
  await prefs.reload();
  final lastFGTaskHeartBeatTime = prefs.getInt(kLastFGTaskHeartBeatTime) ?? 0;
  final String lastRun = lastFGTaskHeartBeatTime == 0
      ? 'never'
      : DateTime.fromMicrosecondsSinceEpoch(lastFGTaskHeartBeatTime).toString();
  _logger.info('isAlreadyRunningFG: $isRunningInFG, last Beat: $lastRun');
}
