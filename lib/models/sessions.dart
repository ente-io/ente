import 'dart:convert';

import 'package:flutter/foundation.dart';

class Sessions {
  final List<Session> sessions;

  Sessions(
    this.sessions,
  );

  Sessions copyWith({
    List<Session> sessions,
  }) {
    return Sessions(
      sessions ?? this.sessions,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sessions': sessions?.map((x) => x.toMap())?.toList(),
    };
  }

  factory Sessions.fromMap(Map<String, dynamic> map) {
    return Sessions(
      List<Session>.from(map['sessions']?.map((x) => Session.fromMap(x))),
    );
  }

  String toJson() => json.encode(toMap());

  factory Sessions.fromJson(String source) =>
      Sessions.fromMap(json.decode(source));

  @override
  String toString() => 'Sessions(sessions: $sessions)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Sessions && listEquals(other.sessions, sessions);
  }

  @override
  int get hashCode => sessions.hashCode;
}

class Session {
  final String token;
  final int creationTime;
  final String ip;
  final String userAgent;
  final int lastUsedTime;

  Session(this.token, this.creationTime, this.ip, this.userAgent,
      this.lastUsedTime);

  Session copyWith({
    String token,
    int creationTime,
    String ip,
    String userAgent,
    int lastUsedTime,
  }) {
    return Session(
      token ?? this.token,
      creationTime ?? this.creationTime,
      ip ?? this.ip,
      userAgent ?? this.userAgent,
      lastUsedTime ?? this.lastUsedTime,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'token': token,
      'creationTime': creationTime,
      'ip': ip,
      'userAgent': userAgent,
      'lastUsedTime': lastUsedTime,
    };
  }

  factory Session.fromMap(Map<String, dynamic> map) {
    return Session(
      map['token'],
      map['creationTime'],
      map['ip'],
      map['userAgent'],
      map['lastUsedTime'],
    );
  }

  String toJson() => json.encode(toMap());

  factory Session.fromJson(String source) =>
      Session.fromMap(json.decode(source));

  @override
  String toString() {
    return 'Session(token: $token, creationTime: $creationTime, ip: $ip, userAgent: $userAgent, lastUsedTime: $lastUsedTime)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Session &&
        other.token == token &&
        other.creationTime == creationTime &&
        other.ip == ip &&
        other.userAgent == userAgent &&
        other.lastUsedTime == lastUsedTime;
  }

  @override
  int get hashCode {
    return token.hashCode ^
        creationTime.hashCode ^
        ip.hashCode ^
        userAgent.hashCode ^
        lastUsedTime.hashCode;
  }
}
