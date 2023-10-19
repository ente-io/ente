import 'dart:io';

import "package:device_info_plus/device_info_plus.dart";
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
// https://gist.github.com/adamawolf/3048717
final Set<String> iOSLowEndMachineCodes = <String>{
  "iPhone5,1", //iPhone 5 (GSM)
  "iPhone5,2", //iPhone 5 (GSM+CDMA)
  "iPhone5,3", //iPhone 5C (GSM)
  "iPhone5,4", //iPhone 5C (Global)
  "iPhone6,1", //iPhone 5S (GSM)
  "iPhone6,2", //iPhone 5S (Global)
  "iPhone7,1", //iPhone 6 Plus
  "iPhone7,2", //iPhone 6
  "iPhone8,1", // iPhone 6s
  "iPhone8,2", // iPhone 6s Plus
  "iPhone8,4", // iPhone SE (GSM)
  "iPhone9,1", // iPhone 7
  "iPhone9,2", // iPhone 7 Plus
  "iPhone9,3", // iPhone 7
  "iPhone9,4", // iPhone 7 Plus
  "iPhone10,1", // iPhone 8
  "iPhone10,2", // iPhone 8 Plus
  "iPhone10,3", // iPhone X Global
  "iPhone10,4", // iPhone 8
  "iPhone10,5", //  iPhone 8
};

Future<bool> isLowSpecDevice() async {
  try {
    if (Platform.isIOS) {
      final IosDeviceInfo iosInfo = await deviceInfoPlugin.iosInfo;
      debugPrint("ios utc name ${iosInfo.utsname.machine}");
      return iOSLowEndMachineCodes.contains(iosInfo.utsname.machine);
    }
  } catch (e) {
    Logger("device_info").severe("deviceSpec check failed", e);
  }
  return false;
}

Future<bool> isAndroidSDKVersionLowerThan(int inputSDK) async {
  if (Platform.isAndroid) {
    final AndroidDeviceInfo androidInfo = await deviceInfoPlugin.androidInfo;
    return androidInfo.version.sdkInt < inputSDK;
  } else {
    return false;
  }
}
