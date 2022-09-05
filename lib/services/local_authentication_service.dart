import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/ui/tools/app_lock.dart';
import 'package:photos/utils/auth_util.dart';
import 'package:photos/utils/toast_util.dart';

class LocalAuthenticationService {
  LocalAuthenticationService._privateConstructor();
  static final LocalAuthenticationService instance =
      LocalAuthenticationService._privateConstructor();

  Future<bool> requestLocalAuthentication(
    BuildContext context,
    String reason,
  ) async {
    if (await LocalAuthentication().isDeviceSupported()) {
      AppLock.of(context).setEnabled(false);
      final result = await requestAuthentication(reason);
      AppLock.of(context).setEnabled(
        Configuration.instance.shouldShowLockScreen(),
      );
      if (!result) {
        showToast(context, reason);
        return false;
      } else {
        return true;
      }
    }
    return true;
  }
}
