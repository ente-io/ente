import 'dart:io';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:background_fetch/background_fetch.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:logging/logging.dart';
import 'package:media_extension/media_extension.dart';
import 'package:media_extension/media_extension_action_types.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/services/app_lifecycle_service.dart';
import 'package:photos/services/sync_service.dart';
import 'package:photos/ui/home_widget.dart';

class EnteApp extends StatefulWidget {
  final Future<void> Function(String) runBackgroundTask;
  final Future<void> Function(String) killBackgroundTask;

  const EnteApp(
    this.runBackgroundTask,
    this.killBackgroundTask, {
    Key? key,
  }) : super(key: key);

  @override
  State<EnteApp> createState() => _EnteAppState();
}

class _EnteAppState extends State<EnteApp> with WidgetsBindingObserver {
  final _logger = Logger("EnteAppState");
  final _mediaExtensionPlugin = MediaExtension();

  @override
  void initState() {
    _logger.info('init App');
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  Future<IntentAction> initIntentAction() async {
    IntentAction intentAction = IntentAction.main;
    try {
      final actionResult = await _mediaExtensionPlugin.getIntentAction();
      intentAction = actionResult.action!;
    } on PlatformException {
      intentAction = IntentAction.unknown;
    }
    if (intentAction == IntentAction.main) {
      _configureBackgroundFetch();
    }
    return intentAction;
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid || kDebugMode) {
      return FutureBuilder(
        future: initIntentAction(),
        builder: (BuildContext context, AsyncSnapshot<IntentAction> snapshot) {
          return snapshot.data != null
              ? AdaptiveTheme(
                  light: lightThemeData,
                  dark: darkThemeData,
                  initial: AdaptiveThemeMode.system,
                  builder: (lightTheme, dartTheme) => MaterialApp(
                    title: "ente",
                    themeMode: ThemeMode.system,
                    theme: lightTheme,
                    darkTheme: dartTheme,
                    home: HomeWidget(intentAction: snapshot.data!),
                    debugShowCheckedModeBanner: false,
                    builder: EasyLoading.init(),
                    supportedLocales: AppLocalizations.supportedLocales,
                    localizationsDelegates:
                        AppLocalizations.localizationsDelegates,
                  ),
                )
              : Container();
        },
      );
    } else {
      return MaterialApp(
        title: "ente",
        themeMode: ThemeMode.system,
        theme: lightThemeData,
        darkTheme: darkThemeData,
        home: const HomeWidget(intentAction: IntentAction.main),
        debugShowCheckedModeBanner: false,
        builder: EasyLoading.init(),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final String stateChangeReason = 'app -> $state';
    if (state == AppLifecycleState.resumed) {
      AppLifecycleService.instance
          .onAppInForeground(stateChangeReason + ': sync now');
      SyncService.instance.sync();
    } else {
      AppLifecycleService.instance.onAppInBackground(stateChangeReason);
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
          requiresBatteryNotLow: true,
          requiresCharging: false,
          requiresStorageNotLow: false,
          requiresDeviceIdle: false,
          requiredNetworkType: NetworkType.ANY,
        ), (String taskId) async {
      await widget.runBackgroundTask(taskId);
    }, (taskId) {
      _logger.info("BG task timeout taskID: $taskId");
      widget.killBackgroundTask(taskId);
    }).then((int status) {
      _logger.info('[BackgroundFetch] configure success: $status');
    }).catchError((e) {
      _logger.info('[BackgroundFetch] configure ERROR: $e');
    });
  }
}
