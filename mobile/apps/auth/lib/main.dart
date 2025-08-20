import 'dart:async';
import 'dart:io';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:ente_accounts/services/user_service.dart';
import "package:ente_auth/app/view/app.dart";
import 'package:ente_auth/core/configuration.dart';
import 'package:ente_auth/core/constants.dart';
import 'package:ente_auth/ente_theme_data.dart';
import 'package:ente_auth/l10n/l10n.dart'; 
import 'package:ente_auth/locale.dart';
import 'package:ente_auth/services/authenticator_service.dart';
import 'package:ente_auth/services/billing_service.dart';
import 'package:ente_auth/services/notification_service.dart';
import 'package:ente_auth/services/preference_service.dart';
import 'package:ente_auth/services/update_service.dart';
import 'package:ente_auth/services/window_listener_service.dart';
import 'package:ente_auth/store/authenticator_db.dart';
import 'package:ente_auth/store/code_display_store.dart';
import 'package:ente_auth/store/code_store.dart';
import 'package:ente_auth/ui/home_page.dart';
import 'package:ente_auth/ui/utils/icon_utils.dart';
import 'package:ente_auth/utils/directory_utils.dart';
import 'package:ente_auth/utils/platform_util.dart';
import 'package:ente_auth/utils/window_protocol_handler.dart';
import 'package:ente_crypto_dart/ente_crypto_dart.dart';
import 'package:ente_lock_screen/lock_screen_settings.dart';
import 'package:ente_lock_screen/ui/app_lock.dart';
import 'package:ente_lock_screen/ui/lock_screen.dart';
import 'package:ente_logging/logging.dart';
import 'package:ente_network/network.dart';
import 'package:ente_strings/l10n/strings_localizations.dart';
import 'package:ente_ui/theme/theme_config.dart';
import 'package:flutter/foundation.dart';
import "package:flutter/material.dart";
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

final _logger = Logger("main");

Future<void> initSystemTray() async {
  if (PlatformUtil.isMobile()) return;
  String path = Platform.isWindows
      ? 'assets/icons/auth-icon.ico'
      : Platform.isMacOS
          ? 'assets/icons/auth-icon-monochrome.png'
          : 'assets/icons/auth-icon.png';
  await trayManager.setIcon(path, isTemplate: true);
  Menu menu = Menu(
    items: [
      MenuItem(
        key: 'hide_window',
        label: 'Hide Window',
      ),
      MenuItem(
        key: 'show_window',
        label: 'Show Window',
      ),
      MenuItem.separator(),
      MenuItem(
        key: 'exit_app',
        label: 'Exit App',
      ),
    ],
  );
  await trayManager.setContextMenu(menu);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (PlatformUtil.isDesktop()) {
    await windowManager.ensureInitialized();
    await WindowListenerService.instance.init();
    WindowOptions windowOptions = WindowOptions(
      size: WindowListenerService.instance.getWindowSize(),
      maximumSize: const Size(8192, 8192),
    );
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await DirectoryUtils.migrateNamingChanges();
      await windowManager.show();
      await windowManager.focus();
      initSystemTray().ignore();
    });
  }

  await _runInForeground();
  if (Platform.isAndroid) {
    FlutterDisplayMode.setHighRefreshRate().ignore();
  }
}

Future<void> _runInForeground() async {
  AppThemeConfig.initialize(EnteApp.auth);
  final savedThemeMode = _themeMode(await AdaptiveTheme.getThemeMode());
  final configuration = Configuration.instance;
  return await _runWithLogs(() async {
    _logger.info("Starting app in foreground");
    try {
      await _init(false, via: 'mainMethod');
    } catch (e, s) {
      _logger.severe("Failed to init", e, s);
      rethrow;
    }
    final Locale? locale = await getLocale(noFallback: true);
    unawaited(UpdateService.instance.showUpdateNotification());
    runApp(
      AppLock(
        builder: (args) => App(locale: locale),
        lockScreen: LockScreen(configuration),
        enabled: await LockScreenSettings.instance.shouldShowLockScreen(),
        locale: locale,
        lightTheme: lightThemeData,
        darkTheme: darkThemeData,
        savedThemeMode: savedThemeMode,
        localeListResolutionCallback: localResolutionCallBack,
        localizationsDelegates:  const [
          ...StringsLocalizations.localizationsDelegates,
          ...AppLocalizations.localizationsDelegates,
        ],
        supportedLocales: appSupportedLocales,
        backgroundLockLatency: const Duration(seconds: 0),
      ),
    );
  });
}

ThemeMode _themeMode(AdaptiveThemeMode? savedThemeMode) {
  if (savedThemeMode == null) return ThemeMode.system;
  if (savedThemeMode.isLight) return ThemeMode.light;
  if (savedThemeMode.isDark) return ThemeMode.dark;
  return ThemeMode.system;
}

Future _runWithLogs(Function() function, {String prefix = ""}) async {
  String dir = "";
  try {
    dir = "${(await getApplicationSupportDirectory()).path}/logs";
  } catch (_) {}
  await SuperLogging.main(
    LogConfig(
      body: function,
      logDirPath: dir,
      maxLogFiles: 5,
      sentryDsn: sentryDSN,
      enableInDebugMode: true,
      prefix: prefix,
    ),
  );
}

void _registerWindowsProtocol() {
  const kWindowsScheme = 'enteauth';
  // Register our protocol only on Windows platform
  if (!kIsWeb && Platform.isWindows) {
    WindowsProtocolHandler()
        .register(kWindowsScheme, executable: null, arguments: null);
  }
}

Future<void> _init(bool bool, {String? via}) async {
  _registerWindowsProtocol();
  await CryptoUtil.init();

  await PreferenceService.instance.init();
  await CodeStore.instance.init();
  await CodeDisplayStore.instance.init();
  await Configuration.instance.init([AuthenticatorDB.instance]);
  await Network.instance.init(Configuration.instance);
  await UserService.instance.init(Configuration.instance, const HomePage());
  await AuthenticatorService.instance.init();
  await BillingService.instance.init();
  await NotificationService.instance.init();
  await UpdateService.instance.init();
  await IconUtils.instance.init();
  await LockScreenSettings.instance.init(Configuration.instance);
}
