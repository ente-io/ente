import 'dart:convert';

import 'package:flutter/material.dart';

@immutable
class AuthKey {
  final int userID;
  final String encryptedKey;
  final String header;
  final int createdAt;
  final int updatedAt;

  AuthKey(
    this.userID,
    this.encryptedKey,
    this.header,
    this.createdAt,
    this.updatedAt,
  );

  Map<String, dynamic> toMap() {
    return {
      'userID': userID,
      'encryptedKey': encryptedKey,
      'header': header,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory AuthKey.fromMap(Map<String, dynamic> map) {
    return AuthKey(
      map['userID']?.toInt() ?? 0,
      map['encryptedKey']!,
      map['header']!,
      map['createdAt']?.toInt() ?? 0,
      map['updatedAt']?.toInt() ?? 0,
    );
  }

  String toJson() => json.encode(toMap());

  factory AuthKey.fromJson(String source) =>
      AuthKey.fromMap(json.decode(source));
}
