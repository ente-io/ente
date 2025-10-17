import "dart:convert";

import "package:flutter/foundation.dart" show immutable;

@immutable
class WrappedResult {
  WrappedResult({
    required List<WrappedCard> cards,
    required this.year,
    this.badgeKey,
  }) : cards = List<WrappedCard>.unmodifiable(cards);

  final List<WrappedCard> cards;
  final int year;
  final String? badgeKey;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      "year": year,
      "badgeKey": badgeKey,
      "cards": cards.map((WrappedCard card) => card.toJson()).toList(),
    };
  }

  static WrappedResult fromJson(Map<String, Object?> json) {
    final List<dynamic> rawCards = json["cards"] as List<dynamic>? ?? const [];
    return WrappedResult(
      cards: rawCards
          .map(
            (dynamic entry) =>
                WrappedCard.fromJson((entry as Map).cast<String, Object?>()),
          )
          .toList(growable: false),
      year: json["year"] as int? ?? DateTime.now().year,
      badgeKey: json["badgeKey"] as String?,
    );
  }

  static WrappedResult? decode(String source) {
    if (source.isEmpty) {
      return null;
    }
    final Object? decoded = jsonDecode(source);
    if (decoded is! Map) {
      return null;
    }
    final Map<String, Object?> data = Map<String, Object?>.from(decoded);
    return WrappedResult.fromJson(data);
  }

  String encode() {
    return jsonEncode(toJson());
  }
}

@immutable
class WrappedCard {
  WrappedCard({
    required this.type,
    required this.title,
    this.subtitle,
    List<MediaRef> media = const <MediaRef>[],
    Map<String, Object?> meta = const <String, Object?>{},
  })  : media = List<MediaRef>.unmodifiable(media),
        meta = Map<String, Object?>.unmodifiable(meta);

  final WrappedCardType type;
  final String title;
  final String? subtitle;
  final List<MediaRef> media;
  final Map<String, Object?> meta;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      "type": type.name,
      "title": title,
      "subtitle": subtitle,
      "media": media.map((MediaRef ref) => ref.toJson()).toList(),
      "meta": meta,
    };
  }

  static WrappedCard fromJson(Map<String, Object?> json) {
    final String? typeName = json["type"] as String?;
    final WrappedCardType cardType = WrappedCardType.values.firstWhere(
      (WrappedCardType value) => value.name == typeName,
      orElse: () => WrappedCardType.statsTotals,
    );

    final List<dynamic> rawMedia = json["media"] as List<dynamic>? ?? const [];
    final List<MediaRef> mediaRefs = rawMedia
        .map(
          (dynamic entry) =>
              MediaRef.fromJson((entry as Map).cast<String, Object?>()),
        )
        .toList(growable: false);

    final Map<String, Object?> meta =
        (json["meta"] as Map?)?.cast<String, Object?>() ?? <String, Object?>{};

    return WrappedCard(
      type: cardType,
      title: json["title"] as String? ?? "",
      subtitle: json["subtitle"] as String?,
      media: mediaRefs,
      meta: meta,
    );
  }
}

@immutable
class MediaRef {
  const MediaRef(this.uploadedFileID);

  final int uploadedFileID;

  Map<String, Object?> toJson() {
    return <String, Object?>{"uploadedFileID": uploadedFileID};
  }

  static MediaRef fromJson(Map<String, Object?> json) {
    return MediaRef(json["uploadedFileID"] as int? ?? 0);
  }
}

enum WrappedCardType {
  statsTotals,
  statsVelocity,
  busiestDay,
  longestStreak,
  longestGap,
  topPerson,
  topThreePeople,
  groupVsSolo,
  newFaces,
  newPlaces,
  topCities,
  mostVisitedSpot,
  thenAndNow,
  yearInColor,
  monochrome,
  panoramas,
  biggestShot,
  top9Wow,
  favorites,
  albums,
  topEvents,
  bestOf25,
  badge,
}
