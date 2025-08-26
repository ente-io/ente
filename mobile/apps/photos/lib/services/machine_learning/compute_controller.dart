import "dart:async";
import "dart:io";

import "package:battery_info/battery_info_plugin.dart";
import "package:battery_info/model/android_battery_info.dart";
import "package:battery_info/model/iso_battery_info.dart";
import "package:flutter/foundation.dart";
import "package:logging/logging.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/events/compute_control_event.dart";
import "package:thermal/thermal.dart";

enum _ComputeRunState {
  idle,
  runningML,
  generatingStream,
}

class ComputeController {
  final _logger = Logger("ComputeController");

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
  bool _canRunCompute = false;
  bool interactionOverride = false;
  late Timer _userInteractionTimer;

  _ComputeRunState _currentRunState = _ComputeRunState.idle;
  bool _waitingToRunML = false;

  bool get isDeviceHealthy => _isDeviceHealthy;

  ComputeController() {
    _logger.info('ComputeController constructor');
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

  bool requestCompute({bool ml = false, bool stream = false}) {
    _logger.info("Requesting compute: ml: $ml, stream: $stream");
    if (!_isDeviceHealthy || !_canRunGivenUserInteraction()) {
      _logger.info("Device not healthy or user interacting, denying request.");
      return false;
    }
    bool result = false;
    if (ml) {
      result = _requestML();
    } else if (stream) {
      result = _requestStream();
    } else {
      _logger.severe("No compute request specified, denying request.");
    }
    return result;
  }

  bool _requestML() {
    if (_currentRunState == _ComputeRunState.idle) {
      _currentRunState = _ComputeRunState.runningML;
      _waitingToRunML = false;
      _logger.info("ML request granted");
      return true;
    } else if (_currentRunState == _ComputeRunState.runningML) {
      return true;
    }
    _logger.info(
      "ML request denied, current state: $_currentRunState, wants to run ML: $_waitingToRunML",
    );
    _waitingToRunML = true;
    return false;
  }

  bool _requestStream() {
    if (_currentRunState == _ComputeRunState.idle && !_waitingToRunML) {
      _logger.info("Stream request granted");
      _currentRunState = _ComputeRunState.generatingStream;
      return true;
    } else if (_currentRunState == _ComputeRunState.generatingStream &&
        !_waitingToRunML) {
      return true;
    }
    _logger.info(
      "Stream request denied, current state: $_currentRunState, wants to run ML: $_waitingToRunML",
    );
    return false;
  }

  void releaseCompute({bool ml = false, bool stream = false}) {
    _logger.info(
      "Releasing compute: ml: $ml, stream: $stream, current state: $_currentRunState",
    );

    if (ml) {
      if (_currentRunState == _ComputeRunState.runningML) {
        _currentRunState = _ComputeRunState.idle;
      }
      _waitingToRunML = false;
    } else if (stream) {
      if (_currentRunState == _ComputeRunState.generatingStream) {
        _currentRunState = _ComputeRunState.idle;
      }
    }
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
    return !_isUserInteracting || interactionOverride;
  }

  void forceOverrideML({required bool turnOn}) {
    _logger.info("Forcing to turn on ML: $turnOn");
    interactionOverride = turnOn;
    _fireControlEvent();
  }

  void _fireControlEvent() {
    final shouldRunCompute = _isDeviceHealthy && _canRunGivenUserInteraction();
    if (shouldRunCompute != _canRunCompute) {
      _canRunCompute = shouldRunCompute;
      _logger.info(
        "Firing event: $shouldRunCompute      (device health: $_isDeviceHealthy, user interaction: $_isUserInteracting, mlInteractionOverride: $interactionOverride)",
      );
      Bus.instance.fire(ComputeControlEvent(shouldRunCompute));
    }
  }

  void _startInteractionTimer(Duration timeout) {
    _userInteractionTimer = Timer(timeout, () {
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
    _isDeviceHealthy = Platform.isAndroid
        ? _computeIsAndroidDeviceHealthy()
        : _computeIsiOSDeviceHealthy();
    _fireControlEvent();
  }

  bool _computeIsAndroidDeviceHealthy() {
    return _hasSufficientBattery(
          _androidLastBatteryInfo?.batteryLevel ?? kMinimumBatteryLevel,
        ) &&
        _isAcceptableTemperatureAndroid() &&
        _isBatteryHealthyAndroid() &&
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
        return true;
      case ThermalStatus.none:
      case ThermalStatus.light:
      case ThermalStatus.moderate:
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

  bool _isAcceptableTemperatureAndroid() {
    return (_androidLastBatteryInfo?.temperature ??
            kMaximumTemperatureAndroid) <=
        kMaximumTemperatureAndroid;
  }

  bool _isBatteryHealthyAndroid() {
    return !kUnhealthyStates.contains(_androidLastBatteryInfo?.health ?? "");
  }
}
