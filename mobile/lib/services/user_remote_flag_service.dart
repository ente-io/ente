import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import "package:dio/dio.dart";
import "package:flutter/foundation.dart";
import 'package:logging/logging.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/notification_event.dart';
import "package:photos/service_locator.dart";
import 'package:photos/services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserRemoteFlagService {
  final Dio _enteDio;
  late final _logger = Logger((UserRemoteFlagService).toString());
  final SharedPreferences _prefs;

  static const String recoveryVerificationFlag = "recoveryKeyVerified";
  static const String mapEnabled = "mapEnabled";
  static const String mlEnabled = "faceSearchEnabled";
  static const String needRecoveryKeyVerification =
      "needRecoveryKeyVerification";

  UserRemoteFlagService(this._enteDio, this._prefs) {
    debugPrint("UserRemoteFlagService constructor");
  }

  bool shouldShowRecoveryVerification() {
    if (!_prefs.containsKey(needRecoveryKeyVerification)) {
      // fetch the status from remote
      _refreshRecoveryVerificationFlag().ignore();
      return false;
    } else {
      final bool shouldShow = _prefs.getBool(needRecoveryKeyVerification)!;
      if (shouldShow) {
        // refresh the status to check if user marked it as done on another device
        _refreshRecoveryVerificationFlag().ignore();
      }
      return shouldShow;
    }
  }

  bool getCachedBoolValue(String key) {
    bool defaultValue = false;
    if (key == mapEnabled) {
      defaultValue = flagService.mapEnabled;
    } else if (key == mlEnabled) {
      defaultValue = flagService.hasGrantedMLConsent;
    }
    return _prefs.getBool(key) ?? defaultValue;
  }

  Future<bool> setBoolValue(String key, bool value) async {
    await _updateKeyValue(key, value.toString());
    return _prefs.setBool(key, value);
  }

  // markRecoveryVerificationAsDone is used to track if user has verified their
  // recovery key in the past or not. This helps in avoid showing the same
  // prompt to the user on re-install or signing into a different device
  Future<void> markRecoveryVerificationAsDone() async {
    await _updateKeyValue(recoveryVerificationFlag, true.toString());
    await _prefs.setBool(needRecoveryKeyVerification, false);
  }

  Future<void> _refreshRecoveryVerificationFlag() async {
    _logger.finest('refresh recovery key verification flag');
    final remoteStatusValue =
        await _getValue(recoveryVerificationFlag, "false");
    final bool isNeedVerificationFlagSet =
        _prefs.containsKey(needRecoveryKeyVerification);
    if (remoteStatusValue.toLowerCase() == "true") {
      await _prefs.setBool(needRecoveryKeyVerification, false);
      // If the user verified on different device, then we should refresh
      // the UI to dismiss the Notification.
      if (isNeedVerificationFlagSet) {
        Bus.instance.fire(NotificationEvent());
      }
    } else if (!isNeedVerificationFlagSet) {
      // Verification is not done yet as remoteStatus is false and local flag to
      // show notification isn't set. Set the flag to true if any active
      // session is older than 1 day.
      final activeSessions = await UserService.instance.getActiveSessions();
      final int microSecondsInADay = const Duration(days: 1).inMicroseconds;
      final bool anyActiveSessionOlderThanADay =
          activeSessions.sessions.firstWhereOrNull(
                (e) =>
                    (e.creationTime + microSecondsInADay) <
                    DateTime.now().microsecondsSinceEpoch,
              ) !=
              null;
      if (anyActiveSessionOlderThanADay) {
        await _prefs.setBool(needRecoveryKeyVerification, true);
        Bus.instance.fire(NotificationEvent());
      } else {
        // continue defaulting to no verification prompt
        _logger.finest('No active session older than 1 day');
      }
    }
  }

  Future<String> _getValue(String key, String? defaultValue) async {
    try {
      final Map<String, dynamic> queryParams = {"key": key};
      if (defaultValue != null) {
        queryParams["defaultValue"] = defaultValue;
      }
      final response =
          await _enteDio.get("/remote-store", queryParameters: queryParams);
      if (response.statusCode != HttpStatus.ok) {
        throw Exception("Unexpected status code ${response.statusCode}");
      }
      return response.data["value"];
    } catch (e) {
      _logger.info("Error while fetching bool status for $key", e);
      rethrow;
    }
  }

  // _setBooleanFlag sets the corresponding flag on remote
  // to mark recovery as completed
  Future<void> _updateKeyValue(String key, String value) async {
    try {
      final response = await _enteDio.post(
        "/remote-store/update",
        data: {
          "key": key,
          "value": value,
        },
      );
      if (response.statusCode != HttpStatus.ok) {
        throw Exception("Unexpected state");
      }
    } catch (e) {
      _logger.warning("Failed to set flag for $key", e);
      rethrow;
    }
  }
}
