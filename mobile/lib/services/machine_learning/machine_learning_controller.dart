import "dart:async";
import "dart:io";

import "package:battery_info/battery_info_plugin.dart";
import "package:battery_info/model/android_battery_info.dart";
import "package:battery_info/model/iso_battery_info.dart";
import "package:flutter/foundation.dart";
import "package:logging/logging.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/events/machine_learning_control_event.dart";
import "package:thermal/thermal.dart";

class MachineLearningController {
  final _logger = Logger("MachineLearningController");

  static const kMaximumTemperatureAndroid = 42; // 42 degree celsius
  static const kMinimumBatteryLevel = 20; // 20%
  final kDefaultInteractionTimeout = Duration(seconds: Platform.isIOS ? 5 : 15);
  static const kUnhealthyStates = ["over_heat", "over_voltage", "dead"];

  static final _thermal = Thermal();
  IosBatteryInfo? _iosLastBatteryInfo;
  AndroidBatteryInfo? _androidLastBatteryInfo;
  ThermalStatus? _lastThermalStatus;

  bool _isDeviceHealthy = true;
  bool _isUserInteracting = true;
  bool _canRunML = false;
  bool mlInteractionOverride = false;
  late Timer _userInteractionTimer;

  bool get isDeviceHealthy => _isDeviceHealthy;

  MachineLearningController() {
    _logger.info('MachineLearningController constructor');
    _startInteractionTimer(kDefaultInteractionTimeout);
    if (Platform.isIOS) {
      if (kDebugMode) {
        _logger.info(
          "iOS battery info stream is not available in simulator, disabling in debug mode",
        );
        // if you need to test on physical device, uncomment this check
        return;
      }
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
    _thermal.onThermalStatusChanged.listen((ThermalStatus thermalState) {
      _onThermalStateUpdate(thermalState);
    });
    _logger.info('init done ');
  }

  void onUserInteraction() {
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
    _androidLastBatteryInfo = batteryInfo;
    _logger.info("Battery info: ${batteryInfo!.toJson()}");
    _isDeviceHealthy = _computeIsAndroidDeviceHealthy();
    _fireControlEvent();
  }

  void _oniOSBatteryStateUpdate(IosBatteryInfo? batteryInfo) {
    _iosLastBatteryInfo = batteryInfo;
    _logger.info("Battery info: ${batteryInfo!.toJson()}");
    _isDeviceHealthy = _computeIsiOSDeviceHealthy();
    _fireControlEvent();
  }

  void _onThermalStateUpdate(ThermalStatus? thermalStatus) {
    _lastThermalStatus = thermalStatus;
    _logger.info("Thermal status: $thermalStatus");
    _isDeviceHealthy = _computeIsAndroidDeviceHealthy();
    _fireControlEvent();
  }

  bool _computeIsAndroidDeviceHealthy() {
    return _hasSufficientBattery(
          _androidLastBatteryInfo?.batteryLevel ?? kMinimumBatteryLevel,
        ) &&
        _isAcceptableTemperatureAndroid(
          _androidLastBatteryInfo?.temperature ?? kMaximumTemperatureAndroid,
        ) &&
        _isBatteryHealthyAndroid(_androidLastBatteryInfo?.health ?? "") &&
        _isAcceptableThermalState();
  }

  bool _computeIsiOSDeviceHealthy() {
    return _hasSufficientBattery(
          _iosLastBatteryInfo?.batteryLevel ?? kMinimumBatteryLevel,
        ) &&
        _isAcceptableThermalState();
  }

  bool _isAcceptableThermalState() {
    switch (_lastThermalStatus) {
      case null:
        _logger.info("Thermal status is null, assuming acceptable temperature");
        return true;
      case ThermalStatus.none:
      case ThermalStatus.light:
      case ThermalStatus.moderate:
        _logger.info("Thermal status is acceptable: $_lastThermalStatus");
        return true;
      case ThermalStatus.severe:
      case ThermalStatus.critical:
      case ThermalStatus.emergency:
      case ThermalStatus.shutdown:
        _logger.warning("Thermal status is unacceptable: $_lastThermalStatus");
        return false;
    }
  }

  bool _hasSufficientBattery(int batteryLevel) {
    return batteryLevel >= kMinimumBatteryLevel;
  }

  bool _isAcceptableTemperatureAndroid(int temperature) {
    return temperature <= kMaximumTemperatureAndroid;
  }

  bool _isBatteryHealthyAndroid(String health) {
    return !kUnhealthyStates.contains(health);
  }
}
