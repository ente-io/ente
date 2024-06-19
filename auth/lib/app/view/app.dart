import 'dart:async';
import 'dart:io';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:ente_auth/core/configuration.dart';
import 'package:ente_auth/core/event_bus.dart';
import 'package:ente_auth/ente_theme_data.dart';
import 'package:ente_auth/events/signed_in_event.dart';
import 'package:ente_auth/events/signed_out_event.dart';
import "package:ente_auth/l10n/l10n.dart";
import 'package:ente_auth/locale.dart';
import "package:ente_auth/onboarding/view/onboarding_page.dart";
import 'package:ente_auth/services/authenticator_service.dart';
import 'package:ente_auth/services/update_service.dart';
import 'package:ente_auth/services/user_service.dart';
import 'package:ente_auth/services/window_listener_service.dart';
import 'package:ente_auth/ui/home_page.dart';
import 'package:ente_auth/ui/settings/app_update_dialog.dart';
import 'package:flutter/foundation.dart';
import "package:flutter/material.dart";
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

class App extends StatefulWidget {
  final Locale locale;
  const App({super.key, this.locale = const Locale("en")});

  static void setLocale(BuildContext context, Locale newLocale) {
    _AppState state = context.findAncestorStateOfType<_AppState>()!;
    state.setLocale(newLocale);
  }

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App>
    with WindowListener, TrayListener, WidgetsBindingObserver {
  late StreamSubscription<SignedOutEvent> _signedOutEvent;
  late StreamSubscription<SignedInEvent> _signedInEvent;
  Locale? locale;
  setLocale(Locale newLocale) {
    setState(() {
      locale = newLocale;
    });
  }

  Future<void> initWindowManager() async {
    windowManager.addListener(this);
  }

  Future<void> initTrayManager() async {
    trayManager.addListener(this);
  }

  @override
  void initState() {
    initWindowManager();
    initTrayManager();
    WidgetsBinding.instance.addObserver(this);

    _signedOutEvent = Bus.instance.on<SignedOutEvent>().listen((event) {
      if (mounted) {
        setState(() {});
      }
    });
    _signedInEvent = Bus.instance.on<SignedInEvent>().listen((event) {
      UserService.instance.getUserDetailsV2().ignore();
      if (mounted) {
        setState(() {});
      }
    });
    locale = widget.locale;
    UpdateService.instance.shouldUpdate().then((shouldUpdate) {
      if (shouldUpdate) {
        Future.delayed(Duration.zero, () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AppUpdateDialog(
                UpdateService.instance.getLatestVersionInfo(),
              );
            },
            barrierColor: Colors.black.withOpacity(0.85),
          );
        });
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();

    windowManager.removeListener(this);
    trayManager.removeListener(this);

    _signedOutEvent.cancel();
    _signedInEvent.cancel();
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      if (Configuration.instance.hasConfiguredAccount()) {
        AuthenticatorService.instance.onlineSync().ignore();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid || kDebugMode) {
      return AdaptiveTheme(
        light: lightThemeData,
        dark: darkThemeData,
        initial: AdaptiveThemeMode.system,
        builder: (lightTheme, dartTheme) => MaterialApp(
          title: "ente",
          themeMode: ThemeMode.system,
          theme: lightTheme,
          darkTheme: dartTheme,
          debugShowCheckedModeBanner: false,
          locale: locale,
          supportedLocales: appSupportedLocales,
          localeListResolutionCallback: localResolutionCallBack,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          routes: _getRoutes,
        ),
      );
    } else {
      return MaterialApp(
        title: "ente",
        themeMode: ThemeMode.system,
        theme: lightThemeData,
        darkTheme: darkThemeData,
        debugShowCheckedModeBanner: false,
        locale: locale,
        supportedLocales: appSupportedLocales,
        localeListResolutionCallback: localResolutionCallBack,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        routes: _getRoutes,
      );
    }
  }

  Map<String, WidgetBuilder> get _getRoutes {
    return {
      "/": (context) => Configuration.instance.hasConfiguredAccount() ||
              Configuration.instance.hasOptedForOfflineMode()
          ? const HomePage()
          : const OnboardingPage(),
    };
  }

  @override
  void onWindowResize() {
    WindowListenerService.instance.onWindowResize().ignore();
  }

  @override
  void onTrayIconMouseDown() {
    if (Platform.isWindows) {
      windowManager.show();
    } else {
      trayManager.popUpContextMenu();
    }
  }

  @override
  void onTrayIconRightMouseDown() {
    if (Platform.isWindows) {
      trayManager.popUpContextMenu();
    } else {
      windowManager.show();
    }
  }

  @override
  void onTrayIconRightMouseUp() {}

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'hide_window':
        windowManager.hide();
        break;
      case 'show_window':
        windowManager.show();
        break;
      case 'exit_app':
        windowManager.destroy();
        break;
    }
  }
}
