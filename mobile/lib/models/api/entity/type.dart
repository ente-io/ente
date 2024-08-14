import "package:flutter/foundation.dart";

enum EntityType {
  location,
  person,
  personV2,
  unknown,
}

EntityType typeFromString(String type) {
  switch (type) {
    case "location":
      return EntityType.location;
    case "person":
      return EntityType.location;
    case "person_v2":
      return EntityType.personV2;
  }
  debugPrint("unexpected collection type $type");
  return EntityType.unknown;
}

extension EntityTypeExtn on EntityType {
  bool isZipped() {
    if (this == EntityType.location || this == EntityType.person) {
      return false;
    }
    return true;
  }

  String typeToString() {
    switch (this) {
      case EntityType.location:
        return "location";
      case EntityType.person:
        return "person";
      case EntityType.personV2:
        return "person_v2";
      case EntityType.unknown:
        return "unknown";
    }
  }
}
