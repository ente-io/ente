import "dart:async";
import 'dart:io';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:home_widget/home_widget.dart' as hw;
import 'package:logging/logging.dart';
import 'package:media_extension/media_extension_action_types.dart';
import "package:photos/core/event_bus.dart";
import 'package:photos/ente_theme_data.dart';
import "package:photos/events/memories_changed_event.dart";
import "package:photos/events/people_changed_event.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/l10n/l10n.dart";
import "package:photos/service_locator.dart";
import 'package:photos/services/app_lifecycle_service.dart';
import "package:photos/services/home_widget_service.dart";
import "package:photos/services/memory_home_widget_service.dart";
import "package:photos/services/people_home_widget_service.dart";
import 'package:photos/services/sync/sync_service.dart';
import 'package:photos/ui/tabs/home_widget.dart';
import "package:photos/ui/viewer/actions/file_viewer.dart";
import "package:photos/utils/bg_task_utils.dart";
import "package:photos/utils/intent_util.dart";
import "package:photos/utils/standalone/debouncer.dart";

class EnteApp extends StatefulWidget {
  final AdaptiveThemeMode? savedThemeMode;
  final Locale? locale;

  const EnteApp(
    this.locale,
    this.savedThemeMode, {
    super.key,
  });

  static void setLocale(BuildContext context, Locale newLocale) {
    final state = context.findAncestorStateOfType<_EnteAppState>()!;
    state.setLocale(newLocale);
  }

  @override
  State<EnteApp> createState() => _EnteAppState();
}

class _EnteAppState extends State<EnteApp> with WidgetsBindingObserver {
  late Locale? locale;
  late StreamSubscription<MemoriesChangedEvent> _memoriesChangedSubscription;
  final _logger = Logger("EnteAppState");
  late StreamSubscription<PeopleChangedEvent> _peopleChangedSubscription;
  late Debouncer _changeCallbackDebouncer;

  @override
  void initState() {
    _logger.info('init App');
    super.initState();
    locale = widget.locale;
    setupIntentAction();
    WidgetsBinding.instance.addObserver(this);
    setupSubscription();
  }

  void setupSubscription() {
    _memoriesChangedSubscription =
        Bus.instance.on<MemoriesChangedEvent>().listen(
      (event) async {
        await MemoryHomeWidgetService.instance.memoryChanged();
      },
    );
    _changeCallbackDebouncer = Debouncer(const Duration(milliseconds: 1500));
    _peopleChangedSubscription = Bus.instance.on<PeopleChangedEvent>().listen(
      (event) async {
        _changeCallbackDebouncer.run(
          () async {
            unawaited(PeopleHomeWidgetService.instance.checkPeopleChanged());
            unawaited(smartAlbumsService.syncSmartAlbums());
          },
        );
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkForWidgetLaunch();
  }

  Future<void> _checkForWidgetLaunch() async {
    await HomeWidgetService.instance.setAppGroup();
    await hw.HomeWidget.initiallyLaunchedFromHomeWidget().then(
      (uri) => HomeWidgetService.instance.onLaunchFromWidget(uri, context),
    );
    hw.HomeWidget.widgetClicked.listen(
      (uri) => HomeWidgetService.instance.onLaunchFromWidget(uri, context),
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
      await BgTaskUtils.configureWorkmanager();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid || kDebugMode) {
      return Listener(
        onPointerDown: (event) {
          computeController.onUserInteraction();
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
                        IntentAction.view &&
                    (AppLifecycleService.instance.mediaExtensionAction.type ==
                            MediaType.image ||
                        AppLifecycleService
                                .instance.mediaExtensionAction.type ==
                            MediaType.video)
                ? const FileViewer()
                : const HomeWidget(),
            debugShowCheckedModeBanner: false,
            builder: EasyLoading.init(),
            locale: locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localeListResolutionCallback: localResolutionCallBack,
            localizationsDelegates: const [
              ...AppLocalizations.localizationsDelegates,
            ],
          ),
        ),
      );
    } else {
      return Listener(
        onPointerDown: (event) {
          computeController.onUserInteraction();
        },
        child: MaterialApp(
          title: "ente",
          themeMode: ThemeMode.system,
          theme: lightThemeData,
          darkTheme: darkThemeData,
          home: const HomeWidget(),
          debugShowCheckedModeBanner: false,
          builder: EasyLoading.init(),
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localeListResolutionCallback: localResolutionCallBack,
          localizationsDelegates: const [
            ...AppLocalizations.localizationsDelegates,
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _memoriesChangedSubscription.cancel();
    _peopleChangedSubscription.cancel();
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
}
