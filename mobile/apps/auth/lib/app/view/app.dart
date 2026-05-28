import 'dart:async';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:ente_accounts/services/user_service.dart';
import 'package:ente_auth/core/configuration.dart';
import 'package:ente_auth/ente_theme_data.dart';
import 'package:ente_auth/l10n/l10n.dart';
import 'package:ente_auth/locale.dart';
import 'package:ente_auth/onboarding/view/onboarding_page.dart';
import 'package:ente_auth/services/authenticator_service.dart';
import 'package:ente_auth/services/update_service.dart';
import 'package:ente_auth/ui/home_page.dart';
import 'package:ente_auth/ui/settings/app_update_dialog.dart';
import 'package:ente_events/event_bus.dart';
import 'package:ente_events/models/signed_in_event.dart';
import 'package:ente_events/models/signed_out_event.dart';
import 'package:ente_logging/logging.dart';
import 'package:ente_strings/l10n/strings_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class App extends StatefulWidget {
  final Locale? locale;
  final AdaptiveThemeMode savedThemeMode;
  const App({
    super.key,
    this.locale = const Locale("en"),
    this.savedThemeMode = AdaptiveThemeMode.system,
  });

  static void setLocale(BuildContext context, Locale newLocale) {
    _AppState state = context.findAncestorStateOfType<_AppState>()!;
    state.setLocale(newLocale);
  }

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with WidgetsBindingObserver {
  static final Logger _renderErrorLogger = Logger('RenderError');
  late StreamSubscription<SignedOutEvent> _signedOutEvent;
  late StreamSubscription<SignedInEvent> _signedInEvent;
  Locale? locale;
  void setLocale(Locale newLocale) {
    setState(() {
      locale = newLocale;
    });
  }

  @override
  void initState() {
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
    UpdateService.instance.showUpdateNotification().then((shouldUpdate) {
      if (shouldUpdate) {
        Future.delayed(Duration.zero, () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AppUpdateDialog(
                UpdateService.instance.getLatestVersionInfo(),
              );
            },
            barrierColor: Colors.black.withValues(alpha: 0.85),
          );
        });
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();

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
    return AdaptiveTheme(
      light: lightThemeData,
      dark: darkThemeData,
      initial: widget.savedThemeMode,
      builder: (lightTheme, darkTheme) => Builder(
        builder: (context) => MaterialApp(
          title: "ente",
          themeMode: _themeMode(AdaptiveTheme.of(context).mode),
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
          builder: _materialAppBuilder,
        ),
      ),
    );
  }

  ThemeMode _themeMode(AdaptiveThemeMode mode) {
    if (mode.isLight) return ThemeMode.light;
    if (mode.isDark) return ThemeMode.dark;
    return ThemeMode.system;
  }

  Map<String, WidgetBuilder> get _getRoutes {
    return {
      "/": (context) =>
          Configuration.instance.hasConfiguredAccount() ||
              Configuration.instance.hasOptedForOfflineMode()
          ? const HomePage()
          : const OnboardingPage(),
    };
  }

  Widget _materialAppBuilder(BuildContext context, Widget? widget) {
    if (!kDebugMode) {
      Widget errorWidget = Center(
        child: Text(context.l10n.somethingWentWrongMessage),
      );
      if (widget is Scaffold || widget is Navigator) {
        errorWidget = Scaffold(body: Center(child: errorWidget));
      }

      ErrorWidget.builder = (FlutterErrorDetails details) {
        _renderErrorLogger.severe(
          'Unhandled rendering error',
          details.exception,
          details.stack,
        );
        return errorWidget;
      };
    }

    if (widget != null) {
      return widget;
    }
    throw StateError('widget is null');
  }
}
