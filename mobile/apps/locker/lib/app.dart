import 'dart:async';
import 'dart:io';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:ente_accounts/services/user_service.dart';
import 'package:ente_events/event_bus.dart';
import 'package:ente_events/models/signed_in_event.dart';
import 'package:ente_events/models/signed_out_event.dart';
import 'package:ente_strings/l10n/strings_localizations.dart';
import 'package:ente_ui/theme/colors.dart';
import 'package:ente_ui/theme/ente_theme_data.dart';
import 'package:ente_ui/utils/window_listener_service.dart';
import 'package:flutter/foundation.dart';
import "package:flutter/material.dart";
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:locker/core/locale.dart';
import 'package:locker/l10n/l10n.dart';
import 'package:locker/services/configuration.dart';
import 'package:locker/ui/pages/home_page.dart';
import 'package:locker/ui/pages/onboarding_page.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

class App extends StatefulWidget {
  final Locale? locale;
  const App({super.key, this.locale = const Locale("en")});

  static void setLocale(BuildContext context, Locale newLocale) {
    final _AppState state = context.findAncestorStateOfType<_AppState>()!;
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
  Widget build(BuildContext context) {
    final schemes = ColorSchemeBuilder.fromCustomColors(
      primary700: const Color(0xFF1565C0), // Dark blue
      primary500: const Color(0xFF2196F3), // Material blue
      primary400: const Color(0xFF42A5F5), // Light blue
      primary300: const Color(0xFF90CAF9), // Very light blue
      iconButtonColor: const Color(0xFF1976D2), // Custom icon color
      gradientButtonBgColors: const [
        Color(0xFF1565C0),
        Color(0xFF2196F3),
        Color(0xFF42A5F5),
      ],
    );

    final lightTheme = createAppThemeData(
      brightness: Brightness.light,
      colorScheme: schemes.light,
    );

    final darkTheme = createAppThemeData(
      brightness: Brightness.dark,
      colorScheme: schemes.dark,
    );

    Widget buildApp() {
      if (Platform.isAndroid ||
          Platform.isWindows ||
          Platform.isLinux ||
          kDebugMode) {
        return AdaptiveTheme(
          light: lightTheme,
          dark: darkTheme,
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
              StringsLocalizations.delegate,
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
          theme: lightTheme,
          darkTheme: darkTheme,
          debugShowCheckedModeBanner: false,
          locale: locale,
          supportedLocales: appSupportedLocales,
          localeListResolutionCallback: localResolutionCallBack,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            StringsLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          routes: _getRoutes,
        );
      }
    }

    // Wrap the app with MediaQuery to control text scaling and ensure
    // consistent font sizes across Android and iOS
    return MediaQuery.withClampedTextScaling(
      minScaleFactor: 0.8,
      maxScaleFactor: 1.3,
      child: buildApp(),
    );
  }

  Map<String, WidgetBuilder> get _getRoutes {
    return {
      "/": (context) => Configuration.instance.hasConfiguredAccount()
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
