import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

/// Used to store the display settings of a code.
class CodeDisplay {
  final bool pinned;
  final bool trashed;
  final int lastUsedAt;
  final int tapCount;
  final List<String> tags;

  CodeDisplay({
    this.pinned = false,
    this.trashed = false,
    this.lastUsedAt = 0,
    this.tapCount = 0,
    this.tags = const [],
  });

  // copyWith
  CodeDisplay copyWith({
    bool? pinned,
    bool? trashed,
    int? lastUsedAt,
    int? tapCount,
    List<String>? tags,
  }) {
    final bool updatedPinned = pinned ?? this.pinned;
    final bool updatedTrashed = trashed ?? this.trashed;
    final int updatedLastUsedAt = lastUsedAt ?? this.lastUsedAt;
    final int updatedTapCount = tapCount ?? this.tapCount;
    final List<String> updatedTags = tags ?? this.tags;

    return CodeDisplay(
      pinned: updatedPinned,
      trashed: updatedTrashed,
      lastUsedAt: updatedLastUsedAt,
      tapCount: updatedTapCount,
      tags: updatedTags,
    );
  }

  factory CodeDisplay.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return CodeDisplay();
    }
    return CodeDisplay(
      pinned: json['pinned'] ?? false,
      trashed: json['trashed'] ?? false,
      lastUsedAt: json['lastUsedAt'] ?? 0,
      tapCount: json['tapCount'] ?? 0,
      tags: List<String>.from(json['tags'] ?? []),
    );
  }

  /// Converts the [CodeDisplay] to a json object.
  /// When [safeParsing] is true, the json will be parsed safely.
  /// If we fail to parse the json, we will return an empty [CodeDisplay].
  static CodeDisplay? fromUri(Uri uri, {bool safeParsing = true}) {
    try {
      if (!uri.queryParameters.containsKey("codeDisplay")) return null;
      final String codeDisplay =
          uri.queryParameters['codeDisplay']!.replaceAll('%2C', ',');
      return _parseCodeDisplayJson(codeDisplay, safeParsing);
    } catch (e, s) {
      Logger("CodeDisplay")
          .severe("Could not parse code display from uri", e, s);
      return null;
    }
  }

  static CodeDisplay _parseCodeDisplayJson(String json, bool safeParsing) {
    try {
      final decodedDisplay = jsonDecode(json);
      return CodeDisplay.fromJson(decodedDisplay);
    } catch (e, s) {
      Logger("CodeDisplay")
          .severe("Could not parse code display from json", e, s);
      // if the json does not end with a }, it's likely bad data is attached.
      // This is a workaround to prevent the app from crashing.
      if (!json.endsWith("}")) {
        final lastBracket = json.lastIndexOf("}");
        if (lastBracket != -1) {
          final validJson = json.substring(0, lastBracket + 1);
          return _parseCodeDisplayJson(validJson, safeParsing);
        }
      }
      if (safeParsing) {
        return CodeDisplay();
      } else {
        rethrow;
      }
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'pinned': pinned,
      'trashed': trashed,
      'lastUsedAt': lastUsedAt,
      'tapCount': tapCount,
      'tags': tags,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CodeDisplay &&
        other.pinned == pinned &&
        other.trashed == trashed &&
        other.lastUsedAt == lastUsedAt &&
        other.tapCount == tapCount &&
        listEquals(other.tags, tags);
  }

  @override
  int get hashCode {
    return pinned.hashCode ^
        trashed.hashCode ^
        lastUsedAt.hashCode ^
        tapCount.hashCode ^
        tags.hashCode;
  }
}
