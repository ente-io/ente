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
}

@immutable
class MediaRef {
  const MediaRef(this.uploadedFileID);

  final int uploadedFileID;
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
