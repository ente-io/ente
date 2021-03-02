import 'dart:async';

import 'package:background_fetch/background_fetch.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/services/billing_service.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/services/memories_service.dart';
import 'package:photos/services/sync_service.dart';
import 'package:photos/ui/home_widget.dart';
import 'package:photos/utils/crypto_util.dart';
import 'package:super_logging/super_logging.dart';
import 'package:logging/logging.dart';

final _logger = Logger("main");

Completer<void> _initializationStatus;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _runInForeground();
  // BackgroundFetch.registerHeadlessTask(_headlessTaskHandler);
}

Future<void> _runInForeground() async {
  return await _runWithLogs(() async {
    _logger.info("Starting app in foreground");
    await _init();
    _sync();
    runApp(MyApp());
  });
}

Future _runInBackground(String taskId) async {
  if (_initializationStatus == null) {
    _runWithLogs(() async {
      _logger.info("[BackgroundFetch] Event received: $taskId");
      await _init();
      await _sync(isAppInBackground: true);
      BackgroundFetch.finish(taskId);
    });
  } else {
    _logger.info("[BackgroundFetch] Event received: $taskId");
    await _init();
    await _sync(isAppInBackground: true);
    BackgroundFetch.finish(taskId);
  }
}

void _headlessTaskHandler(HeadlessTask task) {
  if (task.timeout) {
    BackgroundFetch.finish(task.taskId);
  } else {
    _runInBackground(task.taskId);
  }
}

Future<void> _init() async {
  if (_initializationStatus != null) {
    return _initializationStatus.future;
  }
  _initializationStatus = Completer<void>();
  _logger.info("Initializing...");
  InAppPurchaseConnection.enablePendingPurchases();
  CryptoUtil.init();
  await Configuration.instance.init();
  await BillingService.instance.init();
  await CollectionsService.instance.init();
  await SyncService.instance.init();
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
    await SyncService.instance.sync(isAppInBackground: isAppInBackground);
  } catch (e, s) {
    _logger.severe("Sync error", e, s);
  }
}

Future _runWithLogs(Function() function) async {
  await SuperLogging.main(LogConfig(
    body: function,
    logDirPath: (await getTemporaryDirectory()).path + "/logs",
    maxLogFiles: 5,
    sentryDsn: kDebugMode ? SENTRY_DEBUG_DSN : SENTRY_DSN,
    enableInDebugMode: true,
  ));
}

class MyApp extends StatelessWidget with WidgetsBindingObserver {
  final _title = 'ente';
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addObserver(this);

    // Configure BackgroundFetch.
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
    }).then((int status) {
      _logger.info('[BackgroundFetch] configure success: $status');
    }).catchError((e) {
      _logger.info('[BackgroundFetch] configure ERROR: $e');
    });

    return MaterialApp(
      title: _title,
      theme: ThemeData(
        fontFamily: 'Ubuntu',
        brightness: Brightness.dark,
        hintColor: Colors.grey,
        accentColor: Color.fromRGBO(45, 194, 98, 1.0),
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
        cardColor: Color.fromRGBO(25, 25, 25, 1.0),
        dialogTheme: DialogTheme().copyWith(
          backgroundColor: Color.fromRGBO(20, 20, 20, 1.0),
        ),
      ),
      home: HomeWidget(_title),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _logger.info("App resumed");
      _sync();
    }
  }
}
