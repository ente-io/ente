import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

late DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();

// https://gist.github.com/adamawolf/3048717
late Set<String> iOSLowEndMachineCodes = <String>{
  "iPhone5,2",
  "iPhone5,3",
  "iPhone5,4",
  "iPhone6,1",
  "iPhone6,2",
  "iPhone7,2",
  "iPhone7,1",
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
