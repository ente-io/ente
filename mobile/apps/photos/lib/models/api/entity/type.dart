import "package:flutter/foundation.dart";

enum EntityType {
  location,
  person,
  cgroup,
  unknown,
  smartAlbum,
}

EntityType typeFromString(String type) {
  switch (type) {
    case "location":
      return EntityType.location;
    case "person":
      return EntityType.location;
    case "cgroup":
      return EntityType.cgroup;
    case "sconfig":
      return EntityType.cgroup;
  }
  debugPrint("unexpected entity type $type");
  return EntityType.unknown;
}

extension EntityTypeExtn on EntityType {
  bool isZipped() {
    switch (this) {
      case EntityType.location:
      case EntityType.person:
      case EntityType.smartAlbum:
        return false;
      default:
        return true;
    }
  }

  String typeToString() {
    switch (this) {
      case EntityType.location:
        return "location";
      case EntityType.person:
        return "person";
      case EntityType.cgroup:
        return "cgroup";
      case EntityType.smartAlbum:
        return "smart_album";
      case EntityType.unknown:
        return "unknown";
    }
  }
}
