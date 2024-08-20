// ignore_for_file: always_use_package_imports

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
  late final bool _usingEnteEmail;

  FlagService(this._prefs, this._enteDio) {
    _usingEnteEmail = _prefs.getString("email")?.endsWith("@ente.io") ?? false;
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

  Future<void> _fetch() async {
    try {
      if (!_prefs.containsKey("token")) {
        log("token not found, skip", name: "FlagService");
        return;
      }
      log("fetching feature flags", name: "FlagService");
      final response = await _enteDio.get("/remote-store/feature-flags");
      final remoteFlags = RemoteFlags.fromMap(response.data);
      await _prefs.setString("remote_flags", remoteFlags.toJson());
      _flags = remoteFlags;
    } catch (e) {
      debugPrint("Failed to sync feature flags $e");
    }
  }

  bool get disableCFWorker => flags.disableCFWorker;

  bool get internalUser => flags.internalUser || _usingEnteEmail || kDebugMode;

  bool get betaUser => flags.betaUser;

  bool get internalOrBetaUser => internalUser || betaUser;

  bool get enableStripe => Platform.isIOS ? false : flags.enableStripe;

  bool get mapEnabled => flags.mapEnabled;

  bool get isBetaUser => internalUser || flags.betaUser;

  bool get recoveryKeyVerified => flags.recoveryKeyVerified;

  bool get hasGrantedMLConsent => flags.faceSearchEnabled;

  bool get enableMobMultiPart => flags.enableMobMultiPart || internalUser;
}
