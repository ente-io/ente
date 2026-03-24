import 'dart:async';
import 'dart:io';

import "package:adaptive_theme/adaptive_theme.dart";
import "package:computer/computer.dart";
import 'package:ente_crypto/ente_crypto.dart';
import "package:ente_feature_flag/ente_feature_flag.dart";
import "package:ente_pure_utils/ente_pure_utils.dart";
import "package:ffmpeg_kit_flutter/ffmpeg_kit_config.dart";
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import "package:flutter/rendering.dart";
import "package:flutter/services.dart";
import "package:flutter_displaymode/flutter_displaymode.dart";
import "package:intl/date_symbol_data_local.dart";
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
import 'package:photos/db/upload_locks_db.dart';
import 'package:photos/ente_theme_data.dart';
import "package:photos/l10n/l10n.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/account/user_service.dart";
import 'package:photos/services/app_lifecycle_service.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/services/favorites_service.dart';
import 'package:photos/services/home_widget_service.dart';
import 'package:photos/services/local_file_update_service.dart';
import 'package:photos/services/machine_learning/compute_controller.dart';
import "package:photos/services/machine_learning/face_ml/person/person_service.dart";
import 'package:photos/services/machine_learning/ml_service.dart';
import 'package:photos/services/machine_learning/semantic_search/semantic_search_service.dart';
import 'package:photos/services/memory_lane/memory_lane_service.dart';
import 'package:photos/services/background_run_helper.dart';
import "package:photos/services/notification_service.dart";
import 'package:photos/services/push_service.dart';
import 'package:photos/services/search_service.dart';
import 'package:photos/services/social_notification_coordinator.dart';
import 'package:photos/services/sync/local_sync_service.dart';
import 'package:photos/services/sync/remote_sync_service.dart';
import "package:photos/services/sync/sync_service.dart";
import "package:photos/services/video_preview_service.dart";
import "package:photos/services/wake_lock_service.dart";
import "package:photos/src/rust/frb_generated.dart";
import 'package:photos/ui/tools/app_lock.dart';
import 'package:photos/ui/tools/lock_screen.dart';
import 'package:photos/utils/bg_task_utils.dart';
import "package:photos/utils/email_util.dart";
import 'package:photos/utils/file_uploader.dart';
import "package:photos/utils/lock_screen_settings.dart";
import 'package:rive/rive.dart' as rive;
import 'package:shared_preferences/shared_preferences.dart';

final _logger = Logger("main");

const kLastBGTaskHeartBeatTime = "bg_task_hb_time";
const kLastFGTaskHeartBeatTime = "fg_task_hb_time";
const kHeartBeatFrequency = Duration(seconds: 1);
const kFGSyncFrequency = Duration(minutes: 5);
const kFGHomeWidgetSyncFrequency = Duration(minutes: 15);
const kBGAppRefreshBudget = Duration(seconds: 28);
const kBGProcessingBudget = Duration(seconds: 60);
const kBGPushBudget = Duration(seconds: 28);
const kAndroidBackgroundTaskTimeout = Duration(hours: 1);
const kBGTaskTimeout = kBGAppRefreshBudget;
const kBGPushTimeout = kBGPushBudget;
const kFGTaskDeathTimeoutInMicroseconds = 5000000;
bool isProcessBg = true;
bool _stopHearBeat = false;

bool _isRustInitialized = false;
Future<void>? _rustInitFuture;
Completer<void>? _bootstrapCompleter;

void main() async {
  debugRepaintRainbowEnabled = false;
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isIOS) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }
  FFmpegKitConfig.init().ignore();
  await rive.RiveNative.init();
  MediaKit.ensureInitialized();

  final savedThemeMode = await AdaptiveTheme.getThemeMode();
  await _runInForeground(savedThemeMode);

  if (Platform.isAndroid) FlutterDisplayMode.setHighRefreshRate().ignore();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(systemNavigationBarColor: Color(0x00010000)),
  );

  unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
}

Future<void> _runInForeground(AdaptiveThemeMode? savedThemeMode) async {
  return await runWithLogs(() async {
    _logger.info("Starting app in foreground");
    isProcessBg = false;
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(SemanticSearchService.instance.init());
      unawaited(_warmForegroundDeferredServices());
    });
    unawaited(_scheduleFGSync('appStart in FG'));
  });
}

Future<void> _warmForegroundDeferredServices() async {
  try {
    await MemoryLaneService.instance.init();
    if (flagService.facesTimeline) {
      MemoryLaneService.instance
          .queueFullRecompute(trigger: "startup")
          .ignore();
    } else {
      _logger.info("Memory Lane disabled via feature flag");
    }
  } catch (e, s) {
    _logger.warning("Deferred MemoryLaneService warm failed", e, s);
  }
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
    await HomeWidgetService.instance.initHomeWidget(isBackground);
  } catch (e, s) {
    _logger.severe("Error in syncing home widget", e, s);
  }
}

Future<bool> runBackgroundTask(
  String taskId,
  TimeLogger tlog, {
  String mode = 'normal',
}) async {
  if (Platform.isIOS) {
    final prefs = await SharedPreferences.getInstance();
    if (FlagService.isInternalUserEnabledInPrefs(prefs)) {
      final trigger = BgTaskUtils.backgroundTriggerForTask(taskId);
      final budget = BgTaskUtils.backgroundRunBudgetForTask(taskId);
      bool result = true;
      await runWithLogs(
        () async {
          try {
            result = await _runBackgroundPass(
              trigger: trigger,
              taskId: taskId,
              budget: budget,
            );
          } catch (e, s) {
            result = false;
            _logger.severe(
                "Unhandled background task failure for $taskId", e, s);
          }
        },
        prefix: _backgroundLogPrefix(trigger),
      );
      return result;
    }
  }

  // Check if foreground is recently active to avoid conflicts
  final isRunningInFG = await _isRunningInForeground();

  // If FG was active in last 30 seconds, skip BG work
  if (isRunningInFG) {
    _logger.info(
      "[BG TASK] Foreground recently active, skipping background work",
    );
    return true;
  }

  _logger.info(
    "[BG TASK] No recent foreground activity, proceeding with background work",
  );

  // Mark BG as active
  await _runMinimally(taskId, tlog);
  return true;
}

Future<void> ensureServiceLocatorBootstrap({SharedPreferences? prefs}) async {
  if (ServiceLocator.instance.isInitialized) {
    return;
  }
  final inFlightBootstrap = _bootstrapCompleter;
  if (inFlightBootstrap != null) {
    await inFlightBootstrap.future;
    return;
  }

  final completer = Completer<void>();
  _bootstrapCompleter = completer;
  try {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final sharedPreferences = prefs ?? await SharedPreferences.getInstance();
    _logger.fine("Configuration bootstrap init");
    await Configuration.instance.init();
    _logger.fine("Configuration bootstrap done");
    await NetworkClient.instance.init(packageInfo);
    ServiceLocator.instance.init(
      sharedPreferences,
      NetworkClient.instance.enteDio,
      NetworkClient.instance.getDio(),
      packageInfo,
    );
    completer.complete();
  } catch (e, s) {
    completer.completeError(e, s);
    rethrow;
  } finally {
    _bootstrapCompleter = null;
  }
}

Future<void> _runMinimally(String taskId, TimeLogger tlog) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final useBackgroundBootstrap =
      Platform.isIOS && FlagService.isInternalUserEnabledInPrefs(prefs);
  try {
    await _scheduleHeartBeat(prefs, true);
    await _ensureRustInitialized(via: 'workmanager:$taskId');
    await ensureServiceLocatorBootstrap(prefs: prefs);

    // Initialize early so thermal/battery listeners can warm up while the
    // rest of background services are being initialized.
    final controller = computeController;

    AppLifecycleService.instance.init(prefs);
    AppLifecycleService.instance.onAppInBackground(
      'init via: WorkManager $tlog',
    );

    await Computer.shared().turnOn(workersCount: 4);
    CryptoUtil.init();

    _logger.info("(for debugging) CollectionsService init $tlog");
    await CollectionsService.instance.init(prefs);
    _logger.info("(for debugging) CollectionsService init done $tlog");

    await FileUploader.instance.init(prefs, true);
    LocalFileUpdateService.instance.init(prefs);
    await LocalSyncService.instance.init(prefs);
    RemoteSyncService.instance.init(prefs);
    await SyncService.instance.init(prefs);

    await UserService.instance.init();
    NotificationService.instance.init(prefs);
    SocialNotificationCoordinator.instance.init(prefs);
    await NotificationService.instance.initializeForBackground();

    _logger.info("[BG TASK] update notification");
    updateService.showUpdateNotification().ignore();

    _logger.info("[BG TASK] sync starting");
    await _sync('bgTaskActiveProcess');
    _logger.info("[BG TASK] sync completed");

    _logger.info("[BG TASK] locale fetch");
    final locale = await getLocale();
    await initializeDateFormatting(locale?.languageCode ?? "en");
    _logger.info("[BG TASK] home widget sync");
    await _homeWidgetSync(true);

    await _runBackgroundMLIfEligible(prefs, controller);
    _logger.info("[BG TASK] smart albums sync");
    await smartAlbumsService.syncSmartAlbums();

    _logger.info("[BG TASK] $taskId completed");
  } catch (e, s) {
    if (useBackgroundBootstrap) {
      rethrow;
    }
    _logger.severe("[BG TASK] $taskId error", e, s);
  }
}

Future<void> _runBackgroundMLIfEligible(
  SharedPreferences prefs,
  ComputeController controller,
) async {
  if (!flagService.enableMLInBackground || !hasGrantedMLConsent) {
    return;
  }

  await controller.init();
  final canRunML = controller.requestCompute(ml: true);
  if (!canRunML) {
    _logger.info("[BG TASK] skipping ML, compute requirements not satisfied");
    return;
  }

  bool mlRunStarted = false;
  try {
    await MLService.instance.init();
    PersonService.init(entityService, MLDataDB.instance, prefs);
    mlRunStarted = true;
    await MLService.instance.runAllML(force: false);
  } finally {
    if (!mlRunStarted) {
      controller.releaseCompute(ml: true);
    }
  }
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
    await _ensureRustInitialized(
      via: isBackground ? 'background:$via' : 'foreground:$via',
    );
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    await _logFGHeartBeatInfo(preferences);
    _logger.info("_logFGHeartBeatInfo done $tlog");
    unawaited(_scheduleHeartBeat(preferences, isBackground));
    NotificationService.instance.init(preferences);
    if (isBackground) {
      await NotificationService.instance.initializeForBackground();
    }
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
    SocialNotificationCoordinator.instance.init(preferences);

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

    if (!isBackground && flagService.internalUser) {
      _logger.info("GalleryDownloadQueueService init $tlog");
      await galleryDownloadQueueService.init();
      _logger.info("GalleryDownloadQueueService init done $tlog");
    }

    _logger.info("RitualsService init $tlog");
    await ritualsService.init();
    _logger.info("RitualsService init done $tlog");

    if (!isBackground) {
      await _scheduleFGHomeWidgetSync();
    }

    if (Platform.isIOS) {
      PushService.instance.init().ignore();
    }
    _logger.info("PushService/HomeWidget done $tlog");
    unawaited(MLService.instance.init());
    PersonService.init(entityService, MLDataDB.instance, preferences);
    await PersonService.instance.refreshPersonCache();
    EnteWakeLockService.instance.init(preferences);
    wrappedService.scheduleInitialLoad();
    logLocalSettings();
    initComplete = true;
    _stopHearBeat = true;
    _logger.info("Initialization done $tlog");
  } catch (e, s) {
    _logger.severe("Error in init ", e, s);
    rethrow;
  }
}

Future<void> _ensureRustInitialized({required String via}) async {
  if (_isRustInitialized) {
    return;
  }
  final inFlightInit = _rustInitFuture;
  if (inFlightInit != null) {
    await inFlightInit;
    return;
  }

  _logger.info("Initializing Rust bridge via $via");
  final initFuture = EntePhotosRust.init();
  _rustInitFuture = initFuture;
  try {
    await initFuture;
    _isRustInitialized = true;
  } finally {
    _rustInitFuture = null;
  }
}

void logLocalSettings() {
  final settings = {
    'Show memories': memoriesCacheService.showAnyMemories,
    'Smart memories enabled': localSettings.isSmartMemoriesEnabled,
    'ML enabled': flagService.hasGrantedMLConsent,
    'ML local indexing enabled': localSettings.isMLLocalIndexingEnabled,
    'Multipart upload enabled': localSettings.userEnabledMultiplePart,
    'Gallery grid size': localSettings.getPhotoGridSize(),
    'Video streaming enabled':
        VideoPreviewService.instance.isVideoStreamingEnabled,
  };

  final formattedSettings =
      settings.entries.map((e) => '${e.key}: ${e.value}').join(', ');
  _logger.info('Local settings - $formattedSettings');
}

void _heartBeatOnInit(int i) {
  if (i <= 15 && !_stopHearBeat) {
    Future.delayed(const Duration(seconds: 1), () {
      if (_stopHearBeat) {
        _logger.info("Stopping Heartbeat check at $i");
        return;
      }
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

Future<bool> _isAnotherBackgroundRunAlive() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.reload();
  return _hasRecentHeartbeat(
    prefs,
    kLastBGTaskHeartBeatTime,
    (Platform.isIOS ? kBGAppRefreshBudget : kAndroidBackgroundTaskTimeout) +
        activeLeaseGrace,
  );
}

bool _hasRecentHeartbeat(SharedPreferences prefs, String key, Duration maxAge) {
  final lastHeartbeat = prefs.getInt(key) ?? 0;
  if (lastHeartbeat == 0) {
    return false;
  }

  final currentTime = DateTime.now().microsecondsSinceEpoch;
  return lastHeartbeat > currentTime - maxAge.inMicroseconds;
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (!Platform.isIOS) {
    return;
  }

  final prefs = await SharedPreferences.getInstance();
  if (FlagService.isInternalUserEnabledInPrefs(prefs)) {
    await Firebase.initializeApp();
    await _firebaseMessagingBackgroundHandlerWithHandoff(message);
    return;
  }

  final bool isRunningInFG = await _isRunningInForeground(); // hb
  final bool isInForeground = AppLifecycleService.instance.isForeground;
  if (isRunningInFG) {
    _logger.info(
      "Background push received when app is alive and runningInFG: $isRunningInFG inForeground: $isInForeground",
    );
    if (PushService.shouldSync(message)) {
      // FG is active, let it handle the sync
      _logger.info("Foreground is active, skipping background sync from push");
      // Could optionally trigger a sync event that FG can handle
    }
  } else {
    // App is dead or FG is not active
    runWithLogs(
      () async {
        _logger.info("Background push received, no active foreground");

        // Mark BG as active before starting
        await prefs.setInt(
          kLastBGTaskHeartBeatTime,
          DateTime.now().microsecondsSinceEpoch,
        );

        await _init(true, via: 'firebasePush');
        if (PushService.shouldSync(message)) {
          await _sync('firebaseBgSyncNoActiveProcess');
        }
      },
      prefix: "[fbg]",
    ).ignore();
  }
}

Future<void> _firebaseMessagingBackgroundHandlerWithHandoff(
  RemoteMessage message,
) async {
  await runWithLogs(
    () => _runBackgroundPass(
      trigger: BackgroundTrigger.remotePush,
      taskId: "remote_push_sync",
      budget: kBGPushBudget,
      pushPayload: message.data.map((key, value) => MapEntry(key, "$value")),
    ),
    prefix: _backgroundLogPrefix(BackgroundTrigger.remotePush),
  );
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

String _backgroundLogPrefix(BackgroundTrigger trigger) {
  return switch (trigger) {
    BackgroundTrigger.remotePush => "[fbg]",
    BackgroundTrigger.bgAppRefresh => "[bg-refresh]",
    BackgroundTrigger.bgProcessing || BackgroundTrigger.workmanager => "[bg]",
  };
}

Future<bool> _runBackgroundPass({
  required BackgroundTrigger trigger,
  required String taskId,
  required Duration budget,
  Map<String, String>? pushPayload,
}) async {
  final attempt = await prepareBackgroundRun(
    logger: _logger,
    taskId: taskId,
    budget: budget,
    requiresSyncPush: trigger == BackgroundTrigger.remotePush,
    isRunningInForeground: _isRunningInForeground,
    isAnotherBackgroundRunAlive: _isAnotherBackgroundRunAlive,
    pushPayload: trigger == BackgroundTrigger.remotePush ? pushPayload : null,
  );
  if (!attempt.shouldRun) {
    _logger.info("Skipping $taskId: ${attempt.skipReason!.name}");
    return true;
  }

  bool success = true;
  try {
    await _runMinimally(taskId, TimeLogger());
    if (trigger == BackgroundTrigger.bgProcessing &&
        taskId == BgTaskUtils.iOSBackgroundProcessingTask) {
      await BgTaskUtils.handleIOSBackgroundProcessingTaskStart(
        source: "_runBackgroundPass:$taskId",
      );
    }
  } catch (e, s) {
    success = false;
    _logger.severe("Background run failed for $taskId", e, s);
    await BgTaskUtils.releaseResourcesForKill(taskId, attempt.prefs);
  } finally {
    await finishBackgroundRun(attempt);
  }

  return success;
}
