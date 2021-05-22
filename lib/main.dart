import 'dart:async';

import 'package:background_fetch/background_fetch.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/network.dart';
import 'package:photos/db/upload_locks_db.dart';
import 'package:photos/services/billing_service.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/services/memories_service.dart';
import 'package:photos/services/notification_service.dart';
import 'package:photos/services/sync_service.dart';
import 'package:photos/services/update_service.dart';
import 'package:photos/ui/app_lock.dart';
import 'package:photos/ui/home_widget.dart';
import 'package:photos/ui/lock_screen.dart';
import 'package:photos/utils/crypto_util.dart';
import 'package:photos/utils/file_uploader.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:super_logging/super_logging.dart';
import 'package:logging/logging.dart';

final _logger = Logger("main");

Completer<void> _initializationStatus;
const kLastBGTaskHeartBeatTime = "bg_task_hb_time";
const kLastFGTaskHeartBeatTime = "fg_task_hb_time";
const kHeartBeatFrequency = Duration(seconds: 1);
const kFGSyncFrequency = Duration(minutes: 5);
const kFGTaskDeathTimeoutInMicroseconds = 5000000;

final themeData = ThemeData(
  fontFamily: 'Ubuntu',
  brightness: Brightness.dark,
  hintColor: Colors.grey,
  accentColor: Color.fromRGBO(45, 194, 98, 0.2),
  buttonColor: Color.fromRGBO(45, 194, 98, 1.0),
  buttonTheme: ButtonThemeData().copyWith(
    buttonColor: Color.fromRGBO(45, 194, 98, 1.0),
  ),
  toggleableActiveColor: Colors.green[400],
  scaffoldBackgroundColor: Colors.black,
  backgroundColor: Colors.black,
  appBarTheme: AppBarTheme().copyWith(
    color: Color.fromRGBO(10, 20, 20, 1.0),
  ),
  cardColor: Color.fromRGBO(10, 15, 15, 1.0),
  dialogTheme: DialogTheme().copyWith(
    backgroundColor: Color.fromRGBO(10, 15, 15, 1.0),
  ),
  textSelectionTheme: TextSelectionThemeData().copyWith(
    cursorColor: Colors.white.withOpacity(0.5),
  ),
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _runInForeground();
  BackgroundFetch.registerHeadlessTask(_headlessTaskHandler);
}

Future<void> _runInForeground() async {
  return await _runWithLogs(() async {
    _logger.info("Starting app in foreground");
    await _init(false);
    _scheduleFGSync();
    runApp(AppLock(
      builder: (args) => EnteApp(),
      lockScreen: LockScreen(),
      enabled: Configuration.instance.shouldShowLockScreen(),
      themeData: themeData,
    ));
  });
}

Future _runInBackground(String taskId) async {
  if (_initializationStatus == null) {
    _runWithLogs(() async {
      _backgroundTask(taskId);
    }, prefix: "[bg]");
  } else {
    _backgroundTask(taskId);
  }
}

void _backgroundTask(String taskId) async {
  await Future.delayed(Duration(seconds: 3));
  if (await _isRunningInForeground()) {
    _logger.info("FG task running, skipping BG task");
    BackgroundFetch.finish(taskId);
    return;
  } else {
    _logger.info("FG task is not running");
  }
  _logger.info("[BackgroundFetch] Event received: $taskId");
  _scheduleBGTaskKill(taskId);
  await _init(true);
  await _sync(isAppInBackground: true);
  BackgroundFetch.finish(taskId);
}

void _headlessTaskHandler(HeadlessTask task) {
  if (task.timeout) {
    BackgroundFetch.finish(task.taskId);
  } else {
    _runInBackground(task.taskId);
  }
}

Future<void> _init(bool isBackground) async {
  if (_initializationStatus != null) {
    return _initializationStatus.future;
  }
  _initializationStatus = Completer<void>();
  _scheduleHeartBeat(isBackground);
  _logger.info("Initializing...");
  InAppPurchaseConnection.enablePendingPurchases();
  CryptoUtil.init();
  await NotificationService.instance.init();
  await Network.instance.init();
  await Configuration.instance.init();
  await UpdateService.instance.init();
  await BillingService.instance.init();
  await CollectionsService.instance.init();
  await FileUploader.instance.init(isBackground);
  await SyncService.instance.init(isBackground);
  await MemoriesService.instance.init();
  _logger.info("Initialization done");
  _initializationStatus.complete();
}

Future<void> _sync({bool isAppInBackground = false}) async {
  if (SyncService.instance.isSyncInProgress()) {
    _logger.info("Sync is already in progress, skipping");
    return;
  }
  if (isAppInBackground) {
    _logger.info("Syncing in background");
  }
  try {
    await SyncService.instance.sync();
  } catch (e, s) {
    _logger.severe("Sync error", e, s);
  }
}

Future _runWithLogs(Function() function, {String prefix = ""}) async {
  await SuperLogging.main(LogConfig(
    body: function,
    logDirPath: (await getTemporaryDirectory()).path + "/logs",
    maxLogFiles: 5,
    sentryDsn: kDebugMode ? SENTRY_DEBUG_DSN : SENTRY_DSN,
    enableInDebugMode: true,
    prefix: prefix,
  ));
}

Future<void> _scheduleHeartBeat(bool isBackground) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(
      isBackground ? kLastBGTaskHeartBeatTime : kLastFGTaskHeartBeatTime,
      DateTime.now().microsecondsSinceEpoch);
  Future.delayed(kHeartBeatFrequency, () async {
    _scheduleHeartBeat(isBackground);
  });
}

Future<void> _scheduleFGSync() async {
  await _sync();
  Future.delayed(kFGSyncFrequency, () async {
    _scheduleFGSync();
  });
}

void _scheduleBGTaskKill(String taskId) async {
  if (await _isRunningInForeground()) {
    _logger.info("Found app in FG, committing seppuku.");
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
  return (prefs.getInt(kLastFGTaskHeartBeatTime) ?? 0) >
      (currentTime - kFGTaskDeathTimeoutInMicroseconds);
}

Future<void> _killBGTask(String taskId) async {
  await UploadLocksDB.instance.releaseLocksAcquiredByOwnerBefore(
      ProcessType.background.toString(), DateTime.now().microsecondsSinceEpoch);
  final prefs = await SharedPreferences.getInstance();
  prefs.remove(kLastBGTaskHeartBeatTime);
  BackgroundFetch.finish(taskId);
}

class EnteApp extends StatelessWidget with WidgetsBindingObserver {
  static const _homeWidget = const HomeWidget();

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addObserver(this);
    _configureBackgroundFetch();
    return MaterialApp(
      title: "ente",
      theme: themeData,
      home: _homeWidget,
      debugShowCheckedModeBanner: false,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _logger.info("App resumed");
      _sync();
    }
  }

  void _configureBackgroundFetch() {
    BackgroundFetch.configure(
        BackgroundFetchConfig(
          minimumFetchInterval: 15,
          forceAlarmManager: false,
          stopOnTerminate: false,
          startOnBoot: true,
          enableHeadless: true,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresStorageNotLow: false,
          requiresDeviceIdle: false,
          requiredNetworkType: NetworkType.NONE,
        ), (String taskId) async {
      await _runInBackground(taskId);
    }, (taskId) {
      _logger.info("BG task timeout");
      _killBGTask(taskId);
    }).then((int status) {
      _logger.info('[BackgroundFetch] configure success: $status');
    }).catchError((e) {
      _logger.info('[BackgroundFetch] configure ERROR: $e');
    });
  }
}
