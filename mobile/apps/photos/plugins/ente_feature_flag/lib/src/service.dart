// ignore_for_file: always_use_package_imports

import "dart:async";
import "dart:convert";
import "dart:developer";
import "dart:io";

import "package:dio/dio.dart";
import "package:flutter/foundation.dart";
import "package:shared_preferences/shared_preferences.dart";

import "model.dart";

class FlagService {
  final SharedPreferences _prefs;
  final Dio _enteDio;

  FlagService(this._prefs, this._enteDio) {
    Future.delayed(const Duration(seconds: 5), () {
      _fetch();
    });
  }

  RemoteFlags? _flags;

  RemoteFlags get flags {
    try {
      if (!_prefs.containsKey("remote_flags")) {
        _fetch().ignore();
      }
      _flags ??= RemoteFlags.fromMap(
        jsonDecode(_prefs.getString("remote_flags") ?? "{}"),
      );
      return _flags!;
    } catch (e) {
      debugPrint("Failed to get feature flags $e");
      return RemoteFlags.defaultValue;
    }
  }

  bool get disableCFWorker => flags.disableCFWorker;

  bool get internalUser => flags.internalUser || kDebugMode;

  bool get betaUser => flags.betaUser;

  bool get internalOrBetaUser => internalUser || betaUser;

  bool get enableStripe => Platform.isIOS ? false : flags.enableStripe;

  bool get mapEnabled => flags.mapEnabled;

  bool get isBetaUser => internalUser || flags.betaUser;

  bool get recoveryKeyVerified => flags.recoveryKeyVerified;

  bool get hasGrantedMLConsent => flags.faceSearchEnabled;

  bool get enableMobMultiPart => flags.enableMobMultiPart || internalUser;

  String get castUrl => flags.castUrl;

  String get customDomain => flags.customDomain;

  bool hasSyncedAccountFlags() {
    return _prefs.containsKey("remote_flags");
  }

  Future<void> setMapEnabled(bool isEnabled) async {
    await _updateKeyValue("mapEnabled", isEnabled.toString());
    _updateFlags(flags.copyWith(mapEnabled: isEnabled));
  }

  Future<void> setMLConsent(bool isEnabled) async {
    await _updateKeyValue("faceSearchEnabled", isEnabled.toString());
    _updateFlags(flags.copyWith(faceSearchEnabled: isEnabled));
  }

  Future<void> setRecoveryKeyVerified(bool isVerified) async {
    await _updateKeyValue("recoveryKeyVerified", isVerified.toString());
    _updateFlags(flags.copyWith(recoveryKeyVerified: isVerified));
  }

  Completer<void>? _fetchCompleter;
  Future<void> _fetch() async {
    if (!_prefs.containsKey("token")) {
      log("token not found, skip", name: "FlagService");
      return;
    }
    if (_fetchCompleter != null) {
      await _fetchCompleter!.future;
      return;
    }
    _fetchCompleter = Completer<void>();
    try {
      log("fetching feature flags", name: "FlagService");
      final response = await _enteDio.get("/remote-store/feature-flags");
      final remoteFlags = RemoteFlags.fromMap(response.data);
      await _prefs.setString("remote_flags", remoteFlags.toJson());
      _flags = remoteFlags;
    } catch (e) {
      debugPrint("Failed to sync feature flags $e");
    } finally {
      _fetchCompleter?.complete();
      _fetchCompleter = null;
    }
  }

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
      debugPrint("Failed to set flag for $key $e");
      rethrow;
    }
  }

  void _updateFlags(RemoteFlags flags) {
    _flags = flags;
    _prefs.setString("remote_flags", flags.toJson());
    _fetch().ignore();
  }
}
