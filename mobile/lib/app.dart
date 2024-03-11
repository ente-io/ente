import "dart:async";
import 'dart:io';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:background_fetch/background_fetch.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:home_widget/home_widget.dart' as hw;
import 'package:logging/logging.dart';
import 'package:media_extension/media_extension_action_types.dart';
import 'package:photos/ente_theme_data.dart';
import "package:photos/generated/l10n.dart";
import "package:photos/l10n/l10n.dart";
import "package:photos/models/collection/collection_items.dart";
import 'package:photos/services/app_lifecycle_service.dart';
import "package:photos/services/collections_service.dart";
import "package:photos/services/favorites_service.dart";
import "package:photos/services/home_widget_service.dart";
import "package:photos/services/machine_learning/machine_learning_controller.dart";
import 'package:photos/services/sync_service.dart';
import 'package:photos/ui/tabs/home_widget.dart';
import "package:photos/ui/viewer/actions/file_viewer.dart";
import "package:photos/ui/viewer/gallery/collection_page.dart";
import "package:photos/utils/intent_util.dart";
import "package:photos/utils/navigation_util.dart";

class EnteApp extends StatefulWidget {
  final Future<void> Function(String) runBackgroundTask;
  final Future<void> Function(String) killBackgroundTask;
  final AdaptiveThemeMode? savedThemeMode;
  final Locale locale;

  const EnteApp(
    this.runBackgroundTask,
    this.killBackgroundTask,
    this.locale,
    this.savedThemeMode, {
    Key? key,
  }) : super(key: key);

  static void setLocale(BuildContext context, Locale newLocale) {
    final state = context.findAncestorStateOfType<_EnteAppState>()!;
    state.setLocale(newLocale);
  }

  @override
  State<EnteApp> createState() => _EnteAppState();
}

class _EnteAppState extends State<EnteApp> with WidgetsBindingObserver {
  final _logger = Logger("EnteAppState");
  late Locale locale;

  @override
  void initState() {
    _logger.info('init App');
    super.initState();
    locale = widget.locale;
    setupIntentAction();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkForWidgetLaunch();
    hw.HomeWidget.widgetClicked.listen(_launchedFromWidget);
  }

  void _checkForWidgetLaunch() {
    hw.HomeWidget.initiallyLaunchedFromHomeWidget().then(_launchedFromWidget);
  }

  Future<void> _launchedFromWidget(Uri? uri) async {
    if (uri == null) return;
    final collectionID =
        await FavoritesService.instance.getFavoriteCollectionID();
    if (collectionID == null) {
      return;
    }
    final collection = CollectionsService.instance.getCollectionByID(
      collectionID,
    );
    if (collection == null) {
      return;
    }
    unawaited(HomeWidgetService.instance.initHomeWidget());

    final thumbnail = await CollectionsService.instance.getCover(collection);
    unawaited(
      routeToPage(
        context,
        CollectionPage(
          CollectionWithThumbnail(
            collection,
            thumbnail,
          ),
        ),
      ),
    );
  }

  setLocale(Locale newLocale) {
    setState(() {
      locale = newLocale;
    });
  }

  void setupIntentAction() async {
    final mediaExtentionAction = Platform.isAndroid
        ? await initIntentAction()
        : MediaExtentionAction(action: IntentAction.main);
    AppLifecycleService.instance.setMediaExtensionAction(mediaExtentionAction);
    if (mediaExtentionAction.action == IntentAction.main) {
      _configureBackgroundFetch();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid || kDebugMode) {
      return Listener(
        onPointerDown: (event) {
          MachineLearningController.instance.onUserInteraction();
        },
        child: AdaptiveTheme(
          light: lightThemeData,
          dark: darkThemeData,
          initial: widget.savedThemeMode ?? AdaptiveThemeMode.system,
          builder: (lightTheme, dartTheme) => MaterialApp(
            title: "ente",
            themeMode: ThemeMode.system,
            theme: lightTheme,
            darkTheme: dartTheme,
            home: AppLifecycleService.instance.mediaExtensionAction.action ==
                    IntentAction.view
                ? const FileViewer()
                : const HomeWidget(),
            debugShowCheckedModeBanner: false,
            builder: EasyLoading.init(),
            locale: locale,
            supportedLocales: appSupportedLocales,
            localeListResolutionCallback: localResolutionCallBack,
            localizationsDelegates: const [
              ...AppLocalizations.localizationsDelegates,
              S.delegate,
            ],
          ),
        ),
      );
    } else {
      return MaterialApp(
        title: "ente",
        themeMode: ThemeMode.system,
        theme: lightThemeData,
        darkTheme: darkThemeData,
        home: const HomeWidget(),
        debugShowCheckedModeBanner: false,
        builder: EasyLoading.init(),
        locale: locale,
        supportedLocales: appSupportedLocales,
        localeListResolutionCallback: localResolutionCallBack,
        localizationsDelegates: const [
          ...AppLocalizations.localizationsDelegates,
          S.delegate,
        ],
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
