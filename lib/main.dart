// @dart=2.9
import "package:ente_auth/app/view/app.dart";
import 'package:ente_auth/core/configuration.dart';
import 'package:ente_auth/core/logging/super_logging.dart';
import 'package:ente_auth/core/network.dart';
import 'package:ente_auth/ente_theme_data.dart';
import 'package:ente_auth/services/authenticator_service.dart';
import 'package:ente_auth/services/billing_service.dart';
import 'package:ente_auth/services/update_service.dart';
import 'package:ente_auth/services/user_remote_flag_service.dart';
import 'package:ente_auth/services/user_service.dart';
import 'package:ente_auth/store/code_store.dart';
import 'package:ente_auth/ui/tools/app_lock.dart';
import 'package:ente_auth/ui/tools/lock_screen.dart';
import 'package:ente_auth/utils/crypto_util.dart';
import "package:flutter/material.dart";
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';

final _logger = Logger("main");

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _runInForeground();
}

Future<void> _runInForeground() async {
  return await _runWithLogs(() async {
    _logger.info("Starting app in foreground");
    await _init(false, via: 'mainMethod');
    runApp(
      AppLock(
        builder: (args) => const App(),
        lockScreen: const LockScreen(),
        enabled: Configuration.instance.shouldShowLockScreen(),
        lightTheme: lightThemeData,
        darkTheme: darkThemeData,
      ),
    );
  });
}

Future _runWithLogs(Function() function, {String prefix = ""}) async {
  await SuperLogging.main(
    LogConfig(
      body: function,
      logDirPath: (await getApplicationSupportDirectory()).path + "/logs",
      maxLogFiles: 5,
      enableInDebugMode: true,
      prefix: prefix,
    ),
  );
}

Future<void> _init(bool bool, {String via}) async {
  InAppPurchaseConnection.enablePendingPurchases();
  CryptoUtil.init();
  await CodeStore.instance.init();
  await Configuration.instance.init();
  await Network.instance.init();
  await UserService.instance.init();
  await UserRemoteFlagService.instance.init();
  await UpdateService.instance.init();
  await AuthenticatorService.instance.init();
  await BillingService.instance.init();
}
