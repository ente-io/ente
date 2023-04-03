import 'dart:convert';

import 'package:flutter/material.dart';

@immutable
class EntityData {
  final String id;

  // encryptedData will be null for diff items when item is deleted
  final String? encryptedData;
  final String? header;
  final bool isDeleted;
  final int createdAt;
  final int updatedAt;

  const EntityData(
    this.id,
    this.encryptedData,
    this.header,
    this.isDeleted,
    this.createdAt,
    this.updatedAt,
  );

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'encryptedData': encryptedData,
      'header': header,
      'isDeleted': isDeleted,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory EntityData.fromMap(Map<String, dynamic> map) {
    return EntityData(
      map['id'],
      map['encryptedData'],
      map['header'],
      map['isDeleted']!,
      map['createdAt']!,
      map['updatedAt']!,
    );
  }

  String toJson() => json.encode(toMap());

  factory EntityData.fromJson(String source) =>
      EntityData.fromMap(json.decode(source));
}
