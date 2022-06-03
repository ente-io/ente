import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/core/network.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FeatureFlagService {
  FeatureFlagService._privateConstructor();

  static final FeatureFlagService instance =
      FeatureFlagService._privateConstructor();
  static const kBooleanFeatureFlagsKey = "feature_flags_key";
  FeatureFlags defaultFlags = FeatureFlags(
      disableCFWorker: FFDefault.disableCFWorker,
      disableUrlSharing: FFDefault.disableUrlSharing,
      enableStripe: FFDefault.enableStripe);

  final _logger = Logger("FeatureFlagService");
  FeatureFlags _featureFlags;
  SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    // Fetch feature flags from network in async manner.
    // Intention of delay is to give more CPU cycles to other tasks
    Future.delayed(
      const Duration(seconds: 5),
      () {
        fetchFeatureFlags();
      },
    );
  }

  FeatureFlags _getFeatureFlags() {
    _featureFlags ??=
        FeatureFlags.fromJson(_prefs.getString(kBooleanFeatureFlagsKey));
    // if nothing is cached, use defaults as temporary fallback
    if (_featureFlags == null) {
      return defaultFlags;
    }
    return _featureFlags;
  }

  bool disableCFWorker() {
    try {
      return _getFeatureFlags().disableCFWorker;
    } catch (e) {
      _logger.severe(e);
      return FFDefault.disableCFWorker;
    }
  }

  bool disableUrlSharing() {
    try {
      return _getFeatureFlags().disableUrlSharing;
    } catch (e) {
      _logger.severe(e);
      return FFDefault.disableUrlSharing;
    }
  }

  bool enableStripe() {
    if (Platform.isIOS) {
      return false;
    }
    try {
      return _getFeatureFlags().enableStripe;
    } catch (e) {
      _logger.severe(e);
      return FFDefault.enableStripe;
    }
  }

  Future<void> fetchFeatureFlags() async {
    try {
      final response = await Network.instance
          .getDio()
          .get("https://static.ente.io/feature_flags.json");
      final flagsResponse = FeatureFlags.fromMap(response.data);
      if (flagsResponse != null) {
        _prefs.setString(kBooleanFeatureFlagsKey, flagsResponse.toJson());
        _featureFlags = flagsResponse;
      }
    } catch (e) {
      _logger.severe("Failed to sync feature flags ", e);
    }
  }
}

class FeatureFlags {
  final bool disableCFWorker;
  final bool disableUrlSharing;
  final bool enableStripe;

  FeatureFlags({
    @required this.disableCFWorker,
    @required this.disableUrlSharing,
    @required this.enableStripe,
  });

  Map<String, dynamic> toMap() {
    return {
      "disableCFWorker": disableCFWorker,
      "disableUrlSharing": disableUrlSharing,
      "enableStripe": enableStripe,
    };
  }

  String toJson() => json.encode(toMap());

  factory FeatureFlags.fromJson(String source) =>
      FeatureFlags.fromMap(json.decode(source));

  factory FeatureFlags.fromMap(Map<String, dynamic> json) {
    return FeatureFlags(
      disableCFWorker: json["disableCFWorker"] ?? FFDefault.disableCFWorker,
      disableUrlSharing:
          json["disableUrlSharing"] ?? FFDefault.disableUrlSharing,
      enableStripe: json["enableStripe"] ?? FFDefault.enableStripe,
    );
  }

  @override
  String toString() {
    return toMap().toString();
  }
}
