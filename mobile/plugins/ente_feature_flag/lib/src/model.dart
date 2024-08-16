import "dart:convert";
import "dart:io";

import "package:flutter/foundation.dart";

class RemoteFlags {
  final bool enableStripe;
  final bool disableCFWorker;
  final bool mapEnabled;
  final bool faceSearchEnabled;
  final bool recoveryKeyVerified;
  final bool internalUser;
  final bool betaUser;
  final bool enableMobMultiPart;

  RemoteFlags({
    required this.enableStripe,
    required this.disableCFWorker,
    required this.mapEnabled,
    required this.faceSearchEnabled,
    required this.recoveryKeyVerified,
    required this.internalUser,
    required this.betaUser,
    required this.enableMobMultiPart,
  });

  static RemoteFlags defaultValue = RemoteFlags(
    enableStripe: Platform.isAndroid,
    disableCFWorker: false,
    mapEnabled: false,
    faceSearchEnabled: false,
    recoveryKeyVerified: false,
    internalUser: kDebugMode,
    betaUser: kDebugMode,
    enableMobMultiPart: false,
  );

  String toJson() => json.encode(toMap());
  Map<String, dynamic> toMap() {
    return {
      'enableStripe': enableStripe,
      'disableCFWorker': disableCFWorker,
      'mapEnabled': mapEnabled,
      'faceSearchEnabled': faceSearchEnabled,
      'recoveryKeyVerified': recoveryKeyVerified,
      'internalUser': internalUser,
      'betaUser': betaUser,
      'enableMobMultiPart': enableMobMultiPart,
    };
  }

  factory RemoteFlags.fromMap(Map<String, dynamic> map) {
    return RemoteFlags(
      enableStripe: map['enableStripe'] ?? defaultValue.enableStripe,
      disableCFWorker: map['disableCFWorker'] ?? defaultValue.disableCFWorker,
      mapEnabled: map['mapEnabled'] ?? defaultValue.mapEnabled,
      faceSearchEnabled:
          map['faceSearchEnabled'] ?? defaultValue.faceSearchEnabled,
      recoveryKeyVerified:
          map['recoveryKeyVerified'] ?? defaultValue.recoveryKeyVerified,
      internalUser: map['internalUser'] ?? defaultValue.internalUser,
      betaUser: map['betaUser'] ?? defaultValue.betaUser,
      enableMobMultiPart:
          map['enableMobMultiPart'] ?? defaultValue.enableMobMultiPart,
    );
  }
}
