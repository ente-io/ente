import "package:system_info_plus/system_info_plus.dart";

/// The total amount of RAM in the device in MB
int? deviceTotalRAM;

bool get enoughRamForLocalIndexing =>
    deviceTotalRAM == null || deviceTotalRAM! >= 5 * 1024;

/// Return the total amount of RAM in the device in MB
Future<int?> checkDeviceTotalRAM() async {
  deviceTotalRAM ??= await SystemInfoPlus.physicalMemory; // returns in MB
  return deviceTotalRAM;
}
