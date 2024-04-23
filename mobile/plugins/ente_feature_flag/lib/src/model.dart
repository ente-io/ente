import "dart:convert";
import "dart:io";

import "package:flutter/foundation.dart";

class RemoteFlags {
  final bool enableStripe;
  final bool disableCFWorker;
  final bool mapEnabled;
  final bool faceSearchEnabled;
  final bool passKeyEnabled;
  final bool recoveryKeyVerified;
  final bool internalUser;
  final bool betaUser;

  RemoteFlags({
    required this.enableStripe,
    required this.disableCFWorker,
    required this.mapEnabled,
    required this.faceSearchEnabled,
    required this.passKeyEnabled,
    required this.recoveryKeyVerified,
    required this.internalUser,
    required this.betaUser,
  });

  static RemoteFlags defaultValue = RemoteFlags(
    enableStripe: Platform.isAndroid,
    disableCFWorker: false,
    mapEnabled: false,
    faceSearchEnabled: false,
    passKeyEnabled: false,
    recoveryKeyVerified: false,
    internalUser: kDebugMode,
    betaUser: kDebugMode,
  );

  String toJson() => json.encode(toMap());
  Map<String, dynamic> toMap() {
    return {
      'enableStripe': enableStripe,
      'disableCFWorker': disableCFWorker,
      'mapEnabled': mapEnabled,
      'faceSearchEnabled': faceSearchEnabled,
      'passKeyEnabled': passKeyEnabled,
      'recoveryKeyVerified': recoveryKeyVerified,
      'internalUser': internalUser,
      'betaUser': betaUser,
    };
  }

  factory RemoteFlags.fromMap(Map<String, dynamic> map) {
    return RemoteFlags(
      enableStripe: map['enableStripe'] ?? defaultValue.enableStripe,
      disableCFWorker: map['disableCFWorker'] ?? defaultValue.disableCFWorker,
      mapEnabled: map['mapEnabled'] ?? defaultValue.mapEnabled,
      faceSearchEnabled:
          map['faceSearchEnabled'] ?? defaultValue.faceSearchEnabled,
      passKeyEnabled: map['passKeyEnabled'] ?? defaultValue.passKeyEnabled,
      recoveryKeyVerified:
          map['recoveryKeyVerified'] ?? defaultValue.recoveryKeyVerified,
      internalUser: map['internalUser'] ?? defaultValue.internalUser,
      betaUser: map['betaUser'] ?? defaultValue.betaUser,
    );
  }
}
