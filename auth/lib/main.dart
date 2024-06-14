import 'dart:async';
import 'dart:io';

import 'package:adaptive_theme/adaptive_theme.dart';
import "package:ente_auth/app/view/app.dart";
import 'package:ente_auth/core/configuration.dart';
import 'package:ente_auth/core/constants.dart';
import 'package:ente_auth/core/logging/super_logging.dart';
import 'package:ente_auth/core/network.dart';
import 'package:ente_auth/ente_theme_data.dart';
import 'package:ente_auth/locale.dart';
import 'package:ente_auth/services/authenticator_service.dart';
import 'package:ente_auth/services/billing_service.dart';
import 'package:ente_auth/services/notification_service.dart';
import 'package:ente_auth/services/preference_service.dart';
import 'package:ente_auth/services/update_service.dart';
import 'package:ente_auth/services/user_remote_flag_service.dart';
import 'package:ente_auth/services/user_service.dart';
import 'package:ente_auth/services/window_listener_service.dart';
import 'package:ente_auth/store/code_display_store.dart';
import 'package:ente_auth/store/code_store.dart';
import 'package:ente_auth/ui/tools/app_lock.dart';
import 'package:ente_auth/ui/tools/lock_screen.dart';
import 'package:ente_auth/ui/utils/icon_utils.dart';
import 'package:ente_auth/utils/platform_util.dart';
import 'package:ente_auth/utils/window_protocol_handler.dart';
import 'package:ente_crypto_dart/ente_crypto_dart.dart';
import 'package:flutter/foundation.dart';
import "package:flutter/material.dart";
import 'package:flutter/scheduler.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:privacy_screen/privacy_screen.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

final _logger = Logger("main");

Future<void> initSystemTray() async {
  if (PlatformUtil.isMobile()) return;
  String path = Platform.isWindows
      ? 'assets/icons/auth-icon.ico'
      : 'assets/icons/auth-icon.png';
  await trayManager.setIcon(path);
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
    );
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
      initSystemTray().ignore();
    });
  }

  await _runInForeground();
  await _setupPrivacyScreen();
  if (Platform.isAndroid) {
    FlutterDisplayMode.setHighRefreshRate().ignore();
  }
}

Future<void> _runInForeground() async {
  final savedThemeMode = _themeMode(await AdaptiveTheme.getThemeMode());
  return await _runWithLogs(() async {
    _logger.info("Starting app in foreground");
    await _init(false, via: 'mainMethod');
    final Locale locale = await getLocale();
    unawaited(UpdateService.instance.showUpdateNotification());
    runApp(
      AppLock(
        builder: (args) => App(locale: locale),
        lockScreen: const LockScreen(),
        enabled: Configuration.instance.shouldShowLockScreen(),
        locale: locale,
        lightTheme: lightThemeData,
        darkTheme: darkThemeData,
        savedThemeMode: savedThemeMode,
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
  await initCryptoUtil();

  await PreferenceService.instance.init();
  await CodeStore.instance.init();
  await CodeDisplayStore.instance.init();
  await Configuration.instance.init();
  await Network.instance.init();
  await UserService.instance.init();
  await UserRemoteFlagService.instance.init();
  await AuthenticatorService.instance.init();
  await BillingService.instance.init();
  await NotificationService.instance.init();
  await UpdateService.instance.init();
  await IconUtils.instance.init();
}

Future<void> _setupPrivacyScreen() async {
  if (!PlatformUtil.isMobile() || kDebugMode) return;
  final brightness =
      SchedulerBinding.instance.platformDispatcher.platformBrightness;
  bool isInDarkMode = brightness == Brightness.dark;
  await PrivacyScreen.instance.enable(
    iosOptions: const PrivacyIosOptions(
      enablePrivacy: true,
      privacyImageName: "LaunchImage",
      lockTrigger: IosLockTrigger.didEnterBackground,
    ),
    androidOptions: const PrivacyAndroidOptions(
      enableSecure: true,
    ),
    backgroundColor: isInDarkMode ? Colors.black : Colors.white,
    blurEffect:
        isInDarkMode ? PrivacyBlurEffect.dark : PrivacyBlurEffect.extraLight,
  );
}
