// @dart=2.9
import 'dart:async';
import 'dart:io';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:ente_auth/core/configuration.dart';
import 'package:ente_auth/core/event_bus.dart';
import 'package:ente_auth/ente_theme_data.dart';
import 'package:ente_auth/events/account_configured_event.dart';
import 'package:ente_auth/events/user_logged_out_event.dart';
import "package:ente_auth/l10n/l10n.dart";
import "package:ente_auth/onboarding/view/onboarding_page.dart";
import 'package:ente_auth/ui/home_page.dart';
import 'package:flutter/foundation.dart';
import "package:flutter/material.dart";
import 'package:flutter_easyloading/flutter_easyloading.dart';
import "package:flutter_localizations/flutter_localizations.dart";

class App extends StatefulWidget {
  const App({Key key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  StreamSubscription<UserLoggedOutEvent> _loggedOutEvent;
  StreamSubscription<AccountConfiguredEvent> _accountConfiguredEvent;

  @override
  void initState() {
    _loggedOutEvent = Bus.instance.on<UserLoggedOutEvent>().listen((event) {
      if (mounted) {
        setState(() {});
      }
    });
    _accountConfiguredEvent =
        Bus.instance.on<AccountConfiguredEvent>().listen((event) {
      if (mounted) {
        setState(() {});
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _loggedOutEvent.cancel();
    _accountConfiguredEvent.cancel();
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
          builder: EasyLoading.init(),
          supportedLocales: AppLocalizations.supportedLocales,
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
        builder: EasyLoading.init(),
        supportedLocales: AppLocalizations.supportedLocales,
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
      "/": (context) => Configuration.instance.hasConfiguredAccount()
          ? const HomePage()
          : const OnboardingPage(),
    };
  }
}
