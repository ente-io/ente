import "package:flutter/foundation.dart";

enum EntityType {
  location,
  person,
  cgroup,
  unknown,
}

EntityType typeFromString(String type) {
  switch (type) {
    case "location":
      return EntityType.location;
    case "person":
      return EntityType.location;
    case "cgroup":
      return EntityType.cgroup;
  }
  debugPrint("unexpected entity type $type");
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
      case EntityType.cgroup:
        return "cgroup";
      case EntityType.unknown:
        return "unknown";
    }
  }
}
