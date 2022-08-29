import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/core/network.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FeatureFlagService {
  FeatureFlagService._privateConstructor();

  static final FeatureFlagService instance =
      FeatureFlagService._privateConstructor();
  static const kBooleanFeatureFlagsKey = "feature_flags_key";

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
      return FeatureFlags.defaultFlags;
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

  bool enableMissingLocationMigration() {
    // only needs to be enabled for android
    if (!Platform.isAndroid) {
      return false;
    }
    try {
      return _getFeatureFlags().enableMissingLocationMigration;
    } catch (e) {
      _logger.severe(e);
      return FFDefault.enableMissingLocationMigration;
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

  bool enableSearch() {
    try {
      return _isInternalUserOrDebugBuild() || _getFeatureFlags().enableSearch;
    } catch (e) {
      _logger.severe("failed to getSearchFeatureFlag", e);
      return FFDefault.enableSearch;
    }
  }

  bool _isInternalUserOrDebugBuild() {
    final String email = Configuration.instance.getEmail();
    return (email != null && email.endsWith("@ente.io")) || kDebugMode;
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
  static FeatureFlags defaultFlags = FeatureFlags(
    disableCFWorker: FFDefault.disableCFWorker,
    disableUrlSharing: FFDefault.disableUrlSharing,
    enableStripe: FFDefault.enableStripe,
    enableMissingLocationMigration: FFDefault.enableMissingLocationMigration,
    enableSearch: FFDefault.enableSearch,
  );

  final bool disableCFWorker;
  final bool disableUrlSharing;
  final bool enableStripe;
  final bool enableMissingLocationMigration;
  final bool enableSearch;

  FeatureFlags({
    @required this.disableCFWorker,
    @required this.disableUrlSharing,
    @required this.enableStripe,
    @required this.enableMissingLocationMigration,
    @required this.enableSearch,
  });

  Map<String, dynamic> toMap() {
    return {
      "disableCFWorker": disableCFWorker,
      "disableUrlSharing": disableUrlSharing,
      "enableStripe": enableStripe,
      "enableMissingLocationMigration": enableMissingLocationMigration,
      "enableSearch": enableSearch,
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
      enableMissingLocationMigration: json["enableMissingLocationMigration"] ??
          FFDefault.enableMissingLocationMigration,
      enableSearch: json["enableSearch"] ?? FFDefault.enableSearch,
    );
  }

  @override
  String toString() {
    return toMap().toString();
  }
}
