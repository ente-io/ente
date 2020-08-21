import 'dart:async';

import 'package:computer/computer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/favorite_files_repository.dart';
import 'package:photos/folder_service.dart';
import 'package:photos/memories_service.dart';
import 'package:photos/photo_sync_manager.dart';
import 'package:photos/ui/home_widget.dart';
import 'package:sentry/sentry.dart';
import 'package:super_logging/super_logging.dart';
import 'package:logging/logging.dart';
import 'package:uni_links/uni_links.dart';

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
  await PhotoSyncManager.instance.init();
  await MemoriesService.instance.init();
  await FavoriteFilesRepository.instance.init();
  await initDeepLinks();
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
  PhotoSyncManager.instance.sync().catchError((e) {
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

Future<void> initDeepLinks() async {
  // Platform messages may fail, so we use a try/catch PlatformException.
  try {
    String initialLink = await getInitialLink();
    // Parse the link and warn the user, if it is not correct,
    // but keep in mind it could be `null`.
    if (initialLink != null) {
      _logger.info("Initial link received: " + initialLink);
    } else {
      _logger.info("No initial link received.");
    }
  } on PlatformException {
    // Handle exception by warning the user their action did not succeed
    // return?
    _logger.severe("PlatformException thrown while getting initial link");
  }

  // Attach a listener to the stream
  getLinksStream().listen((String link) {
    _logger.info("Link received: " + link);
  }, onError: (err) {
    _logger.severe(err);
  });
}

class MyApp extends StatelessWidget with WidgetsBindingObserver {
  final _title = 'ente';
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
