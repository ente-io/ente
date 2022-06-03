import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';
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
    await sync();
  }

  bool disableCFWorker() {
    try {
      _featureFlags ??=
          FeatureFlags.fromJson(_prefs.getString(kBooleanFeatureFlagsKey));
      return _featureFlags != null
          ? _featureFlags.disableCFWorker
          : FFDefault.disableCFWorker;
    } catch (e) {
      _logger.severe(e);
      return FFDefault.disableCFWorker;
    }
  }

  bool disableUrlSharing() {
    try {
      _featureFlags ??=
          FeatureFlags.fromJson(_prefs.getString(kBooleanFeatureFlagsKey));
      return _featureFlags != null
          ? _featureFlags.disableUrlSharing
          : FFDefault.disableUrlSharing;
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
      _featureFlags ??=
          FeatureFlags.fromJson(_prefs.getString(kBooleanFeatureFlagsKey));
      return _featureFlags != null
          ? _featureFlags.enableStripe
          : FFDefault.enableStripe;
    } catch (e) {
      _logger.severe(e);
      return FFDefault.enableStripe;
    }
  }

  Future<void> sync() async {
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
  bool disableCFWorker = FFDefault.disableCFWorker;
  bool disableUrlSharing = FFDefault.disableUrlSharing;
  bool enableStripe = FFDefault.enableStripe;

  FeatureFlags(
    this.disableCFWorker,
    this.disableUrlSharing,
    this.enableStripe,
  );

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
      json["disableCFWorker"] ?? FFDefault.disableCFWorker,
      json["disableUrlSharing"] ?? FFDefault.disableUrlSharing,
      json["enableStripe"] ?? FFDefault.enableStripe,
    );
  }

  @override
  String toString() {
    return toMap().toString();
  }
}
