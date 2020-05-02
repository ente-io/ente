import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'core/configuration.dart';
import 'photo_loader.dart';
import 'photo_sync_manager.dart';
import 'ui/home_widget.dart';
import 'package:provider/provider.dart';
import 'package:sentry/sentry.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Configuration.instance.init();
  PhotoSyncManager.instance.sync();

  final SentryClient sentry = new SentryClient(
      dsn: "http://96780dc0b00f4c69a16c02e90d379996@sentry.ente.io/2");

  FlutterError.onError = (FlutterErrorDetails details) async {
    print('Flutter error caught by Sentry');
    FlutterError.dumpErrorToConsole(details, forceReport: true);
    _sendErrorToSentry(sentry, details.exception, details.stack);
  };

  runZoned(
    () => runApp(MyApp()),
    onError: (Object error, StackTrace stackTrace) =>
        _sendErrorToSentry(sentry, error, stackTrace),
  );
}

void _sendErrorToSentry(
    SentryClient sentry, Object error, StackTrace stackTrace) {
  try {
    sentry.captureException(
      exception: error,
      stackTrace: stackTrace,
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
      home: ChangeNotifierProvider<PhotoLoader>.value(
        value: PhotoLoader.instance,
        child: HomeWidget(_title),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      PhotoSyncManager.instance.sync();
    }
  }
}
