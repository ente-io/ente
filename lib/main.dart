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
import 'package:ente_auth/store/code_store.dart';
import 'package:ente_auth/ui/tools/app_lock.dart';
import 'package:ente_auth/ui/tools/lock_screen.dart';
import 'package:ente_auth/ui/utils/icon_utils.dart';
import 'package:ente_auth/utils/platform_util.dart';
import 'package:ente_crypto_dart/ente_crypto_dart.dart';
import "package:flutter/material.dart";
import 'package:flutter/scheduler.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:privacy_screen/privacy_screen.dart';
import 'package:uni_links_desktop/uni_links_desktop.dart';

final _logger = Logger("main");

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _runInForeground();
  await _setupPrivacyScreen();
  FlutterDisplayMode.setHighRefreshRate();
}

Future<void> _runInForeground() async {
  final savedThemeMode = _themeMode(await AdaptiveTheme.getThemeMode());
  return await _runWithLogs(() async {
    _logger.info("Starting app in foreground");
    await _init(false, via: 'mainMethod');
    final Locale locale = await getLocale();
    UpdateService.instance.showUpdateNotification();
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

Future<void> _init(bool bool, {String? via}) async {
  if (Platform.isWindows) {
    registerProtocol('unilinks');
  }
  await initCryptoUtil();

  await PreferenceService.instance.init();
  await CodeStore.instance.init();
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
  if (!PlatformUtil.isMobile()) return;
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
