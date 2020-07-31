import 'dart:convert';

import 'package:photos/models/file.dart';

class Folder {
  final int id;
  final String name;
  final int ownerID;
  final String deviceFolder;
  final Set<String> sharedWith;
  final int updationTime;
  File thumbnailPhoto;

  Folder(
    this.id,
    this.name,
    this.ownerID,
    this.deviceFolder,
    this.sharedWith,
    this.updationTime,
  );

  static Folder fromMap(Map<String, dynamic> map) {
    if (map == null) return null;

    return Folder(
      map['id'],
      map['name'],
      map['ownerID'],
      map['deviceFolder'],
      Set<String>.from(map['sharedWith']),
      map['updationTime'],
    );
  }

  @override
  String toString() {
    return 'Folder(id: $id, name: $name, ownerID: $ownerID, deviceFolder: $deviceFolder, sharedWith: $sharedWith, updationTime: $updationTime)';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'ownerID': ownerID,
      'deviceFolder': deviceFolder,
      'sharedWith': sharedWith.toList(),
      'updationTime': updationTime,
    };
  }

  String toJson() => json.encode(toMap());

  static Folder fromJson(String source) => fromMap(json.decode(source));

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is Folder && o.id == id;
  }

  @override
  int get hashCode {
    return id.hashCode;
  }
}
