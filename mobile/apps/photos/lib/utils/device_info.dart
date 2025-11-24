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

Future<bool> isSamsungSSeries() async {
  try {
    if (!Platform.isAndroid) return false;

    final AndroidDeviceInfo androidInfo = await deviceInfoPlugin.androidInfo;
    final model = androidInfo.model;

    // Explicit list of Samsung S-series model prefixes (2018+)
    const sSeriesPrefixes = [
      // Galaxy S9 (2018)
      'SM-G960', 'SM-G965',

      // Galaxy S10 (2019)
      'SM-G970', 'SM-G973', 'SM-G975', 'SM-G977',

      // Galaxy S20 (2020)
      'SM-G780', 'SM-G781', 'SM-G980', 'SM-G981',
      'SM-G985', 'SM-G986', 'SM-G988',

      // Galaxy S21 (2021)
      'SM-G990', 'SM-G991', 'SM-G996', 'SM-G998',

      // Galaxy S22 (2022)
      'SM-S901', 'SM-S906', 'SM-S908',

      // Galaxy S23 (2023)
      'SM-S711', 'SM-S911', 'SM-S916', 'SM-S918',

      // Galaxy S24 (2024)
      'SM-S721', 'SM-S921', 'SM-S926', 'SM-S928',
    ];

    // Check if device model starts with any of the S-series prefixes
    return sSeriesPrefixes.any((prefix) => model.startsWith(prefix));
  } catch (e) {
    Logger("device_info").warning("isSamsungSSeries check failed", e);
    return false;
  }
}
