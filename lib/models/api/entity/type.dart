import "package:flutter/foundation.dart";

enum EntityType {
  location,
  unknown,
}

EntityType typeFromString(String type) {
  switch (type) {
    case "location":
      return EntityType.location;
  }
  debugPrint("unexpected collection type $type");
  return EntityType.unknown;
}

extension EntityTypeExtn on EntityType {
  String typeToString() {
    switch (this) {
      case EntityType.location:
        return "location";
      case EntityType.unknown:
        return "unknown";
    }
  }
}
