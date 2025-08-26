import 'dart:async';
import 'dart:io';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:ente_accounts/services/user_service.dart';
import 'package:ente_crypto_dart/ente_crypto_dart.dart';
import 'package:ente_lock_screen/lock_screen_settings.dart';
import 'package:ente_lock_screen/ui/app_lock.dart';
import 'package:ente_lock_screen/ui/lock_screen.dart';
import 'package:ente_logging/logging.dart';
import 'package:ente_network/network.dart';
import "package:ente_strings/l10n/strings_localizations.dart";
import "package:ente_ui/theme/theme_config.dart";
import 'package:ente_ui/utils/window_listener_service.dart';
import 'package:ente_utils/platform_util.dart';
import "package:flutter/material.dart";
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:locker/app.dart';
import 'package:locker/core/locale.dart';
import 'package:locker/l10n/app_localizations.dart';
import 'package:locker/services/collections/collections_api_client.dart';
import "package:locker/services/collections/collections_db.dart";
import 'package:locker/services/collections/collections_service.dart';
import 'package:locker/services/configuration.dart';
import 'package:locker/services/files/download/service_locator.dart';
import "package:locker/services/files/links/links_client.dart";
import "package:locker/services/files/links/links_service.dart";
import "package:locker/services/trash/trash_db.dart";
import 'package:locker/services/trash/trash_service.dart';
import 'package:locker/ui/pages/home_page.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

final _logger = Logger("main");

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (PlatformUtil.isDesktop()) {
    await windowManager.ensureInitialized();
    await WindowListenerService.instance.init();
    final WindowOptions windowOptions = WindowOptions(
      size: WindowListenerService.instance.getWindowSize(),
      maximumSize: const Size(8192, 8192),
    );
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
      _initSystemTray().ignore();
    });
  }

  await _runInForeground();
  if (Platform.isAndroid) {
    FlutterDisplayMode.setHighRefreshRate().ignore();
  }
}

Future<void> _initSystemTray() async {
  if (PlatformUtil.isMobile()) return;
  final String path = Platform.isWindows
      ? 'assets/icons/locker-icon.ico'
      : 'assets/icons/locker-icon.png';
  await trayManager.setIcon(path);
  final Menu menu = Menu(
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

Future<void> _runInForeground() async {
  AppThemeConfig.initialize(EnteApp.locker);
  final savedThemeMode = _themeMode(await AdaptiveTheme.getThemeMode());
  return await _runWithLogs(() async {
    _logger.info("Starting app in foreground");
    try {
      await _init(false, via: 'mainMethod');
    } catch (e, s) {
      _logger.severe("Failed to init", e, s);
      rethrow;
    }
    final Locale? locale = await getLocale(noFallback: true);
    runApp(
      AppLock(
        builder: (args) => App(locale: locale),
        lockScreen: LockScreen(Configuration.instance),
        enabled: await LockScreenSettings.instance.shouldShowLockScreen(),
        locale: locale,
        savedThemeMode: savedThemeMode,
        supportedLocales: appSupportedLocales,
        localizationsDelegates: const [
          ...StringsLocalizations.localizationsDelegates,
          ...AppLocalizations.localizationsDelegates,
        ],
        localeListResolutionCallback: localResolutionCallBack,
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
      enableInDebugMode: true,
      prefix: prefix,
    ),
  );
}

Future<void> _init(bool bool, {String? via}) async {
  final SharedPreferences preferences = await SharedPreferences.getInstance();
  final PackageInfo packageInfo = await PackageInfo.fromPlatform();

  await CryptoUtil.init();

  await CollectionDB.instance.init();
  await TrashDB.instance.init();

  await Configuration.instance.init([
    CollectionDB.instance,
    TrashDB.instance,
  ]);

  await Network.instance.init(Configuration.instance);
  await UserService.instance.init(Configuration.instance, const HomePage());
  await LockScreenSettings.instance.init(Configuration.instance);
  await CollectionApiClient.instance.init();
  await CollectionService.instance.init();
  await LinksClient.instance.init();
  await LinksService.instance.init();
  await ServiceLocator.instance.init(
    preferences,
    Network.instance.enteDio,
    Network.instance.getDio(),
    packageInfo,
  );
  await TrashService.instance.init(preferences);
}
