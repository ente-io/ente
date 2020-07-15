import 'dart:async';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/favorite_files_repository.dart';
import 'package:photos/folder_service.dart';
import 'package:photos/photo_sync_manager.dart';
import 'package:photos/ui/home_widget.dart';
import 'package:sentry/sentry.dart';
import 'package:super_logging/super_logging.dart';
import 'package:logging/logging.dart';

final logger = Logger("main");

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SuperLogging.main(LogConfig(
    body: _main,
    logDirPath: (await getTemporaryDirectory()).path + "/logs",
    enableInDebugMode: true,
  ));
}

void _main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Configuration.instance.init();
  await PhotoSyncManager.instance.init();
  FavoriteFilesRepository.instance.init();
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
    logger.warning(e);
  });
  PhotoSyncManager.instance.sync().catchError((e) {
    logger.warning(e);
  });
}

void _sendErrorToSentry(SentryClient sentry, Object error, StackTrace stack) {
  logger.shout("Uncaught error", error, stack);
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
  final _title = 'Photos';
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addObserver(this);

    return MaterialApp(
      title: _title,
      theme: ThemeData.dark(),
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
