import 'dart:async';

import 'package:computer/computer.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/services/favorites_service.dart';
import 'package:photos/services/folder_service.dart';
import 'package:photos/services/memories_service.dart';
import 'package:photos/services/sync_service.dart';
import 'package:photos/ui/home_widget.dart';
import 'package:sentry/sentry.dart';
import 'package:super_logging/super_logging.dart';
import 'package:logging/logging.dart';

final _logger = Logger("main");

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SuperLogging.main(LogConfig(
    body: _main,
    logDirPath: (await getTemporaryDirectory()).path + "/logs",
    enableInDebugMode: true,
  ));
}

void _main() async {
  Computer().turnOn(
    workersCount: 4,
    areLogsEnabled: false,
  );
  await Configuration.instance.init();
  await SyncService.instance.init();
  await MemoriesService.instance.init();
  await FavoritesService.instance.init();
  _sync();

  final SentryClient sentry = new SentryClient(dsn: SENTRY_DSN);

  FlutterError.onError = (FlutterErrorDetails details) async {
    FlutterError.dumpErrorToConsole(details, forceReport: true);
    _sendErrorToSentry(sentry, details.exception, details.stack);
  };

  runZoned(
    () => runApp(MyApp()),
    onError: (Object error, StackTrace stackTrace) =>
        _sendErrorToSentry(sentry, error, stackTrace),
  );
}

void _sync() async {
  FolderSharingService.instance.sync().catchError((e) {
    _logger.warning(e);
  });
  SyncService.instance.sync().catchError((e) {
    _logger.warning(e);
  });
}

void _sendErrorToSentry(SentryClient sentry, Object error, StackTrace stack) {
  _logger.shout("Uncaught error", error, stack);
  try {
    sentry.captureException(
      exception: error,
      stackTrace: stack,
    );
    print('Error sent to sentry.io: $error');
  } catch (e) {
    print('Sending report to sentry.io failed: $e');
    print('Original error: $error');
  }
}

class MyApp extends StatelessWidget with WidgetsBindingObserver {
  final _title = 'ente';
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addObserver(this);

    return MaterialApp(
      title: _title,
      theme: ThemeData.dark().copyWith(
        hintColor: Colors.grey,
        accentColor: Colors.pink[400],
        buttonColor: Colors.pink,
        buttonTheme: ButtonThemeData().copyWith(
          buttonColor: Colors.pink,
        ),
        toggleableActiveColor: Colors.pink[400],
      ),
      home: HomeWidget(_title),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _sync();
    }
  }
}
