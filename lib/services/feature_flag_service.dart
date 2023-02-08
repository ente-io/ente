import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/core/network/network.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FeatureFlagService {
  FeatureFlagService._privateConstructor();

  static final FeatureFlagService instance =
      FeatureFlagService._privateConstructor();
  static const _featureFlagsKey = "feature_flags_key";

  final _logger = Logger("FeatureFlagService");
  FeatureFlags? _featureFlags;
  late SharedPreferences _prefs;

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
        FeatureFlags.fromJson(_prefs.getString(_featureFlagsKey)!);
    // if nothing is cached, use defaults as temporary fallback
    if (_featureFlags == null) {
      return FeatureFlags.defaultFlags;
    }
    return _featureFlags!;
  }

  bool disableCFWorker() {
    try {
      return _getFeatureFlags().disableCFWorker;
    } catch (e) {
      _logger.severe(e);
      return FFDefault.disableCFWorker;
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

  bool isInternalUserOrDebugBuild() {
    final String? email = Configuration.instance.getEmail();
    return (email != null && email.endsWith("@ente.io")) || kDebugMode;
  }

  Future<void> fetchFeatureFlags() async {
    try {
      final response = await NetworkClient.instance
          .getDio()
          .get("https://static.ente.io/feature_flags.json");
      final flagsResponse = FeatureFlags.fromMap(response.data);
      _prefs.setString(_featureFlagsKey, flagsResponse.toJson());
      _featureFlags = flagsResponse;
    } catch (e) {
      _logger.severe("Failed to sync feature flags ", e);
    }
  }
}

class FeatureFlags {
  static FeatureFlags defaultFlags = FeatureFlags(
    disableCFWorker: FFDefault.disableCFWorker,
    enableStripe: FFDefault.enableStripe,
  );

  final bool disableCFWorker;
  final bool enableStripe;

  FeatureFlags({
    required this.disableCFWorker,
    required this.enableStripe,
  });

  Map<String, dynamic> toMap() {
    return {
      "disableCFWorker": disableCFWorker,
      "enableStripe": enableStripe,
    };
  }

  String toJson() => json.encode(toMap());

  factory FeatureFlags.fromJson(String source) =>
      FeatureFlags.fromMap(json.decode(source));

  factory FeatureFlags.fromMap(Map<String, dynamic> json) {
    return FeatureFlags(
      disableCFWorker: json["disableCFWorker"] ?? FFDefault.disableCFWorker,
      enableStripe: json["enableStripe"] ?? FFDefault.enableStripe,
    );
  }
}
