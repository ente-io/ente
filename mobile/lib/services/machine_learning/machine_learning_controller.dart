import "dart:async";
import "dart:io";

import "package:battery_info/battery_info_plugin.dart";
import "package:battery_info/model/android_battery_info.dart";
import "package:battery_info/model/iso_battery_info.dart";
import "package:logging/logging.dart";
import "package:photos/core/configuration.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/events/machine_learning_control_event.dart";

class MachineLearningController {
  final _logger = Logger("MachineLearningController");

  static const kMaximumTemperature = 42; // 42 degree celsius
  static const kMinimumBatteryLevel = 20; // 20%
  final kDefaultInteractionTimeout = Duration(seconds: Platform.isIOS ? 5 : 15);
  static const kUnhealthyStates = ["over_heat", "over_voltage", "dead"];

  bool _isDeviceHealthy = true;
  bool _isUserInteracting = true;
  bool _canRunML = false;
  bool mlInteractionOverride = false;
  late Timer _userInteractionTimer;

  bool get isDeviceHealthy => _isDeviceHealthy;

  MachineLearningController() {
    if (Configuration.instance.getUserID() == null) {
      return;
    }
    _logger.info('MachineLearningController constructor');
    _startInteractionTimer(kDefaultInteractionTimeout);
    if (Platform.isIOS) {
      BatteryInfoPlugin()
          .iosBatteryInfoStream
          .listen((IosBatteryInfo? batteryInfo) {
        _oniOSBatteryStateUpdate(batteryInfo);
      });
    }
    if (Platform.isAndroid) {
      BatteryInfoPlugin()
          .androidBatteryInfoStream
          .listen((AndroidBatteryInfo? batteryInfo) {
        _onAndroidBatteryStateUpdate(batteryInfo);
      });
    }
    _logger.info('init done');
  }

  void onUserInteraction() {
    if (Configuration.instance.getUserID() == null) {
      return;
    }
    if (!_isUserInteracting) {
      _logger.info("User is interacting with the app");
      _isUserInteracting = true;
      _fireControlEvent();
    }
    _resetTimer();
  }

  bool _canRunGivenUserInteraction() {
    return !_isUserInteracting || mlInteractionOverride;
  }

  void forceOverrideML({required bool turnOn}) {
    _logger.info("Forcing to turn on ML: $turnOn");
    mlInteractionOverride = turnOn;
    _fireControlEvent();
  }

  void _fireControlEvent() {
    final shouldRunML = _isDeviceHealthy && _canRunGivenUserInteraction();
    if (shouldRunML != _canRunML) {
      _canRunML = shouldRunML;
      _logger.info(
        "Firing event: $shouldRunML      (device health: $_isDeviceHealthy, user interaction: $_isUserInteracting, mlInteractionOverride: $mlInteractionOverride)",
      );
      Bus.instance.fire(MachineLearningControlEvent(shouldRunML));
    }
  }

  void _startInteractionTimer(Duration timeout) {
    _userInteractionTimer = Timer(timeout, () {
      _logger.info("User is not interacting with the app");
      _isUserInteracting = false;
      _fireControlEvent();
    });
  }

  void _resetTimer() {
    _userInteractionTimer.cancel();
    _startInteractionTimer(kDefaultInteractionTimeout);
  }

  void _onAndroidBatteryStateUpdate(AndroidBatteryInfo? batteryInfo) {
    _logger.info("Battery info: ${batteryInfo!.toJson()}");
    _isDeviceHealthy = _computeIsAndroidDeviceHealthy(batteryInfo);
    _fireControlEvent();
  }

  void _oniOSBatteryStateUpdate(IosBatteryInfo? batteryInfo) {
    _logger.info("Battery info: ${batteryInfo!.toJson()}");
    _isDeviceHealthy = _computeIsiOSDeviceHealthy(batteryInfo);
    _fireControlEvent();
  }

  bool _computeIsAndroidDeviceHealthy(AndroidBatteryInfo info) {
    return _hasSufficientBattery(info.batteryLevel ?? kMinimumBatteryLevel) &&
        _isAcceptableTemperature(info.temperature ?? kMaximumTemperature) &&
        _isBatteryHealthy(info.health ?? "");
  }

  bool _computeIsiOSDeviceHealthy(IosBatteryInfo info) {
    return _hasSufficientBattery(info.batteryLevel ?? kMinimumBatteryLevel);
  }

  bool _hasSufficientBattery(int batteryLevel) {
    return batteryLevel >= kMinimumBatteryLevel;
  }

  bool _isAcceptableTemperature(int temperature) {
    return temperature <= kMaximumTemperature;
  }

  bool _isBatteryHealthy(String health) {
    return !kUnhealthyStates.contains(health);
  }
}
