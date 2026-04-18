import 'dart:io';

import "package:device_info_plus/device_info_plus.dart";
import 'package:logging/logging.dart';

DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();

Future<bool> isAndroidSDKVersionLowerThan(int inputSDK) async {
  if (Platform.isAndroid) {
    final AndroidDeviceInfo androidInfo = await deviceInfoPlugin.androidInfo;
    return androidInfo.version.sdkInt < inputSDK;
  } else {
    return false;
  }
}

Future<String?> getDeviceInfo() async {
  try {
    if (Platform.isIOS) {
      final IosDeviceInfo iosInfo = await deviceInfoPlugin.iosInfo;
      return iosInfo.utsname.machine;
    } else if (Platform.isAndroid) {
      final AndroidDeviceInfo androidInfo = await deviceInfoPlugin.androidInfo;

      return "${androidInfo.brand} ${androidInfo.model} Android ${androidInfo.version.release}";
    } else {
      return "Not iOS or Android";
    }
  } catch (e) {
    Logger("device_info").severe("deviceSpec check failed", e);
    return null;
  }
}
