import 'dart:convert';

import 'package:flutter/foundation.dart';

class Folder {
  final int id;
  final String name;
  final String owner;
  final String deviceFolder;
  final Set<String> sharedWith;
  final int updateTimestamp;

  Folder(
    this.id,
    this.name,
    this.owner,
    this.deviceFolder,
    this.sharedWith,
    this.updateTimestamp,
  );

  static Folder fromMap(Map<String, dynamic> map) {
    if (map == null) return null;

    return Folder(
      map['id'],
      map['name'],
      map['owner'],
      map['deviceFolder'],
      Set<String>.from(map['sharedWith']),
      map['updateTimestamp'],
    );
  }

  @override
  String toString() {
    return 'Folder(id: $id, name: $name, owner: $owner, deviceFolder: $deviceFolder, sharedWith: $sharedWith, updateTimestamp: $updateTimestamp)';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'owner': owner,
      'deviceFolder': deviceFolder,
      'sharedWith': sharedWith.toList(),
      'updateTimestamp': updateTimestamp,
    };
  }

  String toJson() => json.encode(toMap());

  static Folder fromJson(String source) => fromMap(json.decode(source));

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is Folder &&
        o.id == id &&
        o.name == name &&
        o.owner == owner &&
        o.deviceFolder == deviceFolder &&
        setEquals(o.sharedWith, sharedWith) &&
        o.updateTimestamp == updateTimestamp;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        owner.hashCode ^
        deviceFolder.hashCode ^
        sharedWith.hashCode ^
        updateTimestamp.hashCode;
  }
}
