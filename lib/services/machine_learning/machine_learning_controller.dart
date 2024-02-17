import "dart:io";

import "package:battery_info/battery_info_plugin.dart";
import "package:battery_info/enums/charging_status.dart";
import "package:battery_info/model/android_battery_info.dart";
import "package:logging/logging.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/events/machine_learning_control_event.dart";

class MachineLearningController {
  MachineLearningController._privateConstructor();

  static final MachineLearningController instance =
      MachineLearningController._privateConstructor();

  final _logger = Logger("MachineLearningController");

  static const kMaximumTemperature = 36; // 36 degree celsius
  static const kMinimumBatteryLevel = 20; // 20%

  void init() {
    if (Platform.isAndroid) {
      BatteryInfoPlugin()
          .androidBatteryInfoStream
          .listen((AndroidBatteryInfo? batteryInfo) {
        _logger.info("Battery info: ${batteryInfo!.toJson()}");
        if (_shouldRunMachineLearning(batteryInfo)) {
          Bus.instance.fire(MachineLearningControlEvent(true));
        } else {
          Bus.instance.fire(MachineLearningControlEvent(false));
        }
      });
    }
  }

  void onUserInteractionEvent(bool isUserInteracting) {
    Bus.instance.fire(MachineLearningControlEvent(!isUserInteracting));
  }

  bool _shouldRunMachineLearning(AndroidBatteryInfo info) {
    if (info.chargingStatus == ChargingStatus.Charging ||
        info.chargingStatus == ChargingStatus.Full) {
      return _isAcceptableTemperature(
        info.temperature ?? kMaximumTemperature,
      );
    }
    return _hasSufficientBattery(info.batteryLevel ?? kMinimumBatteryLevel) &&
        _isAcceptableTemperature(info.temperature ?? kMaximumTemperature);
  }

  bool _hasSufficientBattery(int batteryLevel) {
    return batteryLevel >= kMinimumBatteryLevel;
  }

  bool _isAcceptableTemperature(int temperature) {
    return temperature <= kMaximumTemperature;
  }
}
