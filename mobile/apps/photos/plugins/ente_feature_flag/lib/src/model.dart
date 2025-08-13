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
  final String castUrl;
  final String customDomain;
  final String customDomainCNAME;

  RemoteFlags({
    required this.enableStripe,
    required this.disableCFWorker,
    required this.mapEnabled,
    required this.faceSearchEnabled,
    required this.recoveryKeyVerified,
    required this.internalUser,
    required this.betaUser,
    required this.enableMobMultiPart,
    required this.castUrl,
    required this.customDomain,
    required this.customDomainCNAME,
  });

  // CopyWith
  RemoteFlags copyWith({
    bool? enableStripe,
    bool? disableCFWorker,
    bool? mapEnabled,
    bool? faceSearchEnabled,
    bool? recoveryKeyVerified,
    bool? internalUser,
    bool? betaUser,
    bool? enableMobMultiPart,
    String? castUrl,
    String? customDomain,
    String? customDomainCNAME,
  }) {
    return RemoteFlags(
      enableStripe: enableStripe ?? this.enableStripe,
      disableCFWorker: disableCFWorker ?? this.disableCFWorker,
      mapEnabled: mapEnabled ?? this.mapEnabled,
      faceSearchEnabled: faceSearchEnabled ?? this.faceSearchEnabled,
      recoveryKeyVerified: recoveryKeyVerified ?? this.recoveryKeyVerified,
      internalUser: internalUser ?? this.internalUser,
      betaUser: betaUser ?? this.betaUser,
      enableMobMultiPart: enableMobMultiPart ?? this.enableMobMultiPart,
      castUrl: castUrl ?? this.castUrl,
      customDomain: customDomain ?? this.customDomain,
      customDomainCNAME: customDomainCNAME ?? this.customDomainCNAME,
    );
  }

  static RemoteFlags defaultValue = RemoteFlags(
    enableStripe: Platform.isAndroid,
    disableCFWorker: false,
    mapEnabled: false,
    faceSearchEnabled: false,
    recoveryKeyVerified: true,
    internalUser: kDebugMode,
    betaUser: kDebugMode,
    enableMobMultiPart: false,
    castUrl: "https://cast.ente.io",
    customDomain: "",
    customDomainCNAME: "my.ente.io",
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
      'castUrl': castUrl,
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
      castUrl: map['castUrl'] ?? defaultValue.castUrl,
      customDomain: map['customDomain'] ?? defaultValue.customDomain,
      customDomainCNAME:
          map['customDomainCNAME'] ?? defaultValue.customDomainCNAME,
    );
  }
}
