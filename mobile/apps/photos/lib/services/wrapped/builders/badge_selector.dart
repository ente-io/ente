part of "package:photos/services/wrapped/candidate_builders.dart";

class WrappedBadgeSelection {
  const WrappedBadgeSelection({
    required this.badgeKey,
    required this.card,
    required this.candidatesMeta,
  });

  final String badgeKey;
  final WrappedCard card;
  final List<Map<String, Object?>> candidatesMeta;
}

class WrappedBadgeSelector {
  const WrappedBadgeSelector._();

  static const String _kBadgeKeyConsistency = "consistency_champ";
  static const String _kBadgeKeyPortraitPro = "portrait_pro";
  static const String _kBadgeKeyPeoplePerson = "people_person";
  static const String _kBadgeKeyGlobetrotter = "globetrotter";
  static const String _kBadgeKeyPetParent = "pet_parent";
  static const String _kBadgeKeyMinimalist = "minimalist_shooter";

  static const String _kPetGenericQuery =
      "A portrait photo of a beloved pet at home";
  static const Map<String, String> _kPetTypeQueries = <String, String>{
    "cat": "A close-up photograph of a house cat",
    "dog": "A close-up photograph of a pet dog",
  };

  static const double _kPetSimilarityThreshold = 0.24;

  static Set<String> get requiredTextQueries {
    return <String>{
      _kPetGenericQuery,
      ..._kPetTypeQueries.values,
    };
  }

  static WrappedBadgeSelection select({
    required WrappedEngineContext context,
    required List<WrappedCard> existingCards,
  }) {
    // Existing cards kept for future badge tweaks (no-op for now).
    existingCards;

    final _BadgeComputationContext metrics =
        _BadgeComputationContext.fromEngineContext(
      context: context,
    );

    final List<_BadgeCandidate> candidates = <_BadgeCandidate>[];
    void addCandidate(_BadgeCandidate? candidate) {
      if (candidate != null) {
        candidates.add(candidate);
      }
    }

    addCandidate(_buildConsistencyChamp(metrics));
    addCandidate(_buildPortraitPro(metrics));
    addCandidate(_buildPeoplePerson(metrics));
    addCandidate(_buildGlobetrotter(metrics));
    addCandidate(_buildPetParent(metrics));
    addCandidate(_buildMinimalist(metrics));

    if (candidates.isEmpty) {
      final WrappedCard fallbackCard = WrappedCard(
        type: WrappedCardType.badge,
        title: "Ente Rewind ${context.year} is on its way",
        subtitle: "Full story coming soon.",
        meta: <String, Object?>{
          "generatedAt": context.now.toIso8601String(),
          "isStub": true,
        },
      );
      return WrappedBadgeSelection(
        badgeKey: _kBadgeKeyConsistency,
        card: fallbackCard,
        candidatesMeta: const <Map<String, Object?>>[],
      );
    }

    final List<_BadgeCandidate> eligible =
        candidates.where((_BadgeCandidate candidate) {
      if (!candidate.eligible) {
        return false;
      }
      if (candidate.score <= 0) {
        return false;
      }
      return true;
    }).toList(growable: false);

    eligible.sort(_badgeComparator);

    final _BadgeCandidate primary =
        eligible.isNotEmpty ? eligible.first : candidates.last;

    final List<Map<String, Object?>> candidatesMeta =
        candidates.map((_BadgeCandidate candidate) {
      return candidate.toMetaMap();
    }).toList(growable: false)
          ..sort(
            (Map<String, Object?> a, Map<String, Object?> b) {
              final int tierA = a["tier"] as int? ?? 1;
              final int tierB = b["tier"] as int? ?? 1;
              if (tierA != tierB) {
                return tierA.compareTo(tierB);
              }
              final double scoreA = (a["score"] as num?)?.toDouble() ?? 0;
              final double scoreB = (b["score"] as num?)?.toDouble() ?? 0;
              final int scoreCompare = scoreB.compareTo(scoreA);
              if (scoreCompare != 0) {
                return scoreCompare;
              }
              return (a["key"] as String).compareTo(b["key"] as String);
            },
          );

    final WrappedCard badgeCard = WrappedCard(
      type: WrappedCardType.badge,
      title: primary.title,
      subtitle: primary.subtitle,
      media: primary.mediaRefs,
      meta: primary.meta
        ..addAll(<String, Object?>{
          "candidates": candidatesMeta,
          "badgeKey": primary.key,
        }),
    );

    return WrappedBadgeSelection(
      badgeKey: primary.key,
      card: badgeCard,
      candidatesMeta: candidatesMeta,
    );
  }

  static int _badgeComparator(_BadgeCandidate a, _BadgeCandidate b) {
    if (a.tier != b.tier) {
      return a.tier.compareTo(b.tier);
    }
    final int scoreCompare = b.score.compareTo(a.score);
    if (scoreCompare != 0) {
      return scoreCompare;
    }
    final int sampleCompare = b.sampleSize.compareTo(a.sampleSize);
    if (sampleCompare != 0) {
      return sampleCompare;
    }
    final int hashCompare =
        a.deterministicTieBreaker.compareTo(b.deterministicTieBreaker);
    if (hashCompare != 0) {
      return hashCompare;
    }
    return a.key.compareTo(b.key);
  }

  static _BadgeCandidate _buildConsistencyChamp(
    _BadgeComputationContext metrics,
  ) {
    final double streakScore =
        metrics.longestStreakDays <= 0 ? 0 : metrics.longestStreakDays / 14.0;
    final double activeRatio = metrics.elapsedDays <= 0
        ? 0
        : metrics.daysWithCaptures / metrics.elapsedDays;
    final double score = _clamp01(
      0.6 * _clamp01(streakScore) + 0.4 * _clamp01(activeRatio / 0.5),
    );

    final bool eligible = metrics.daysWithCaptures >= 15 &&
        metrics.longestStreakDays >= 3 &&
        metrics.totalCount > 0;

    final String subtitle = metrics.longestStreakDays > 0
        ? "You're the consistency champ—${metrics.longestStreakDays} days without missing a beat."
        : "You're the consistency champ—the lens stayed alive all year.";

    final List<String> chips = <String>[
      "Active days: ${metrics.daysWithCaptures}",
      if (metrics.longestStreakDays > 0)
        "Longest streak: ${metrics.longestStreakDays}",
    ];

    return _BadgeCandidate(
      key: _kBadgeKeyConsistency,
      name: "Consistency Champ",
      title: "Consistency Champ",
      subtitle: subtitle,
      emoji: "🔥",
      gradientStart: "#FF7A18",
      gradientEnd: "#AF002D",
      mediaRefs: metrics.highlightMedia,
      detailChips: chips,
      score: score,
      eligible: eligible,
      sampleSize: metrics.daysWithCaptures,
      tier: 0,
      debugWhy:
          "Streak ${metrics.longestStreakDays}d, active ratio ${metrics.daysWithCaptures}/${metrics.elapsedDays}",
      extras: <String, Object?>{
        "longestStreakDays": metrics.longestStreakDays,
        "daysWithCaptures": metrics.daysWithCaptures,
      },
    );
  }

  static _BadgeCandidate? _buildPortraitPro(
    _BadgeComputationContext metrics,
  ) {
    if (!metrics.peopleStats.hasFaceMoments) {
      return null;
    }
    final int totalFaceMoments = metrics.peopleStats.totalFaceMoments;
    if (totalFaceMoments <= 0) {
      return null;
    }
    final int soloMoments = metrics.peopleStats.soloMoments;
    final double share =
        totalFaceMoments == 0 ? 0 : soloMoments / totalFaceMoments.toDouble();
    final double score = _clamp01(share / 0.60);
    final int soloPercent = _percentOf(share);
    final bool eligible =
        totalFaceMoments >= 20 && soloMoments >= 12 && score >= 0.5;

    final List<String> chips = <String>[
      "Solo portraits: $soloMoments",
      "Share: $soloPercent%",
    ];
    final List<MediaRef> heroMedia = metrics.peopleStats
        .soloSampleFileIDs(3)
        .map(MediaRef.new)
        .toList(growable: false);

    return _BadgeCandidate(
      key: _kBadgeKeyPortraitPro,
      name: "Portrait Pro",
      title: "Portrait Pro",
      subtitle:
          "You're a portrait pro—$soloPercent% one-on-one moments captured.",
      emoji: "🎯",
      gradientStart: "#B721FF",
      gradientEnd: "#21D4FD",
      mediaRefs: heroMedia,
      detailChips: chips,
      score: score,
      eligible: eligible,
      sampleSize: soloMoments,
      tier: 0,
      debugWhy: "Solo share $soloPercent% ($soloMoments/$totalFaceMoments)",
      extras: <String, Object?>{
        "soloMoments": soloMoments,
        "totalFaceMoments": totalFaceMoments,
      },
    );
  }

  static _BadgeCandidate? _buildPeoplePerson(
    _BadgeComputationContext metrics,
  ) {
    if (!metrics.peopleStats.hasFaceMoments || metrics.totalCount <= 0) {
      return null;
    }
    final int totalFaceMoments = metrics.peopleStats.totalFaceMoments;
    if (totalFaceMoments <= 0) {
      return null;
    }
    final double share = totalFaceMoments / metrics.totalCount.toDouble();
    final double score = _clamp01(share / 0.50);
    final int percent = _percentOf(share);

    final bool eligible =
        metrics.totalCount >= 80 && totalFaceMoments >= 16 && score >= 0.45;

    final List<String> chips = <String>[
      "Moments with people: $totalFaceMoments",
    ];

    final List<MediaRef> heroMedia = metrics.peopleStats.topNamedPeople
        .map((_PersonStats stats) => stats.topMediaFileIDs(1))
        .expand((List<int> ids) => ids)
        .where((int id) => id > 0)
        .take(3)
        .map(MediaRef.new)
        .toList(growable: false);

    return _BadgeCandidate(
      key: _kBadgeKeyPeoplePerson,
      name: "People Person",
      title: "People Person",
      subtitle:
          "You're a people person—your crew lit up $percent% of your year.",
      emoji: "🤝",
      gradientStart: "#F857A6",
      gradientEnd: "#FF5858",
      mediaRefs: heroMedia,
      detailChips: chips,
      score: score,
      eligible: eligible,
      sampleSize: totalFaceMoments,
      tier: 0,
      debugWhy:
          "People coverage $percent% ($totalFaceMoments/${metrics.totalCount})",
      extras: <String, Object?>{
        "totalFaceMoments": totalFaceMoments,
        "totalCount": metrics.totalCount,
      },
    );
  }

  static _BadgeCandidate? _buildGlobetrotter(
    _BadgeComputationContext metrics,
  ) {
    if (metrics.placesStats == null || metrics.placesStats!.totalCount <= 0) {
      return null;
    }
    final _BadgePlaceStats placeStats = metrics.placesStats!;
    final int uniqueCities = placeStats.uniqueCities;
    final int uniqueCountries = placeStats.uniqueCountries;
    final int geoCount = placeStats.totalCount;
    if (geoCount <= 0) {
      return null;
    }

    final double score = _clamp01(
      0.6 * _clamp01(uniqueCities / 5.0) +
          0.4 * _clamp01(uniqueCountries / 3.0),
    );
    final bool eligible = geoCount >= 40 &&
        (uniqueCities >= 3 || uniqueCountries >= 2) &&
        score >= 0.45;

    final int geoSharePercent =
        metrics.totalCount == 0 ? 0 : _percentOf(geoCount / metrics.totalCount);

    final List<String> chips = <String>[
      "Cities: $uniqueCities",
      "Countries: $uniqueCountries",
      "Geotagged: $geoSharePercent%",
    ];

    return _BadgeCandidate(
      key: _kBadgeKeyGlobetrotter,
      name: "Globetrotter",
      title: "Globetrotter",
      subtitle:
          "You're a globetrotter—$uniqueCities cities across $uniqueCountries countries this year.",
      emoji: "🌍",
      gradientStart: "#00B09B",
      gradientEnd: "#96C93D",
      mediaRefs: placeStats.heroMedia.map(MediaRef.new).toList(growable: false),
      detailChips: chips,
      score: score,
      eligible: eligible,
      sampleSize: geoCount,
      tier: 0,
      debugWhy:
          "$uniqueCities cities, $uniqueCountries countries, share $geoSharePercent%",
      extras: <String, Object?>{
        "uniqueCities": uniqueCities,
        "uniqueCountries": uniqueCountries,
        "geotaggedCount": geoCount,
      },
    );
  }

  static _BadgeCandidate? _buildPetParent(
    _BadgeComputationContext metrics,
  ) {
    if (!metrics.hasPetEmbedding || metrics.totalCount == 0) {
      return null;
    }

    final int petMatches = metrics.petMatches;
    final double share = metrics.totalCount == 0
        ? 0
        : petMatches / metrics.totalCount.toDouble();
    final double score = _clamp01(share / 0.25);
    final int percent = _percentOf(share);
    final bool eligible = petMatches >= 6 && share >= 0.10;

    if (!eligible) {
      return _BadgeCandidate(
        key: _kBadgeKeyPetParent,
        name: "Pet Parent",
        title: "Pet Parent",
        subtitle:
            "You're a pet parent—$percent% of your shots celebrate your pet.",
        emoji: "🐾",
        gradientStart: "#FAD961",
        gradientEnd: "#F76B1C",
        mediaRefs:
            metrics.petSampleMedia.map(MediaRef.new).toList(growable: false),
        detailChips: <String>[
          "Pet portraits: $petMatches",
        ],
        score: score,
        eligible: false,
        sampleSize: petMatches,
        tier: 0,
        debugWhy: "Pet share $percent% ($petMatches/${metrics.totalCount})",
        extras: <String, Object?>{
          "petMatches": petMatches,
          "petType": metrics.topPetType ?? "pet",
        },
      );
    }

    final String petType = metrics.topPetType ?? "pet";
    final String subtitle =
        "You're a pet parent—$petMatches portraits of your $petType stole the spotlight.";

    return _BadgeCandidate(
      key: _kBadgeKeyPetParent,
      name: "Pet Parent",
      title: "Pet Parent",
      subtitle: subtitle,
      emoji: "🐾",
      gradientStart: "#FAD961",
      gradientEnd: "#F76B1C",
      mediaRefs:
          metrics.petSampleMedia.map(MediaRef.new).toList(growable: false),
      detailChips: <String>[
        "Pets in $percent% of your shots",
      ],
      score: score,
      eligible: eligible,
      sampleSize: petMatches,
      tier: 0,
      debugWhy: "Pet share $percent% ($petMatches/${metrics.totalCount})",
      extras: <String, Object?>{
        "petMatches": petMatches,
        "petType": petType,
      },
    );
  }

  static _BadgeCandidate _buildMinimalist(
    _BadgeComputationContext metrics,
  ) {
    final bool eligible = metrics.totalCount > 0 &&
        metrics.totalCount <= 150 &&
        metrics.daysWithCaptures >= 12;

    final double volumeScore =
        metrics.totalCount <= 0 ? 0 : 150 / metrics.totalCount;
    final double activeRatio = metrics.elapsedDays <= 0
        ? 0
        : metrics.daysWithCaptures / metrics.elapsedDays;
    final double score = _clamp01(
      0.6 * _clamp01(volumeScore) + 0.4 * _clamp01(activeRatio / 0.5),
    );

    final String subtitle =
        "You're a minimalist shooter—${metrics.totalCount} thoughtful frames over fluff.";
    final List<String> chips = <String>[
      "Active days: ${metrics.daysWithCaptures}",
    ];

    return _BadgeCandidate(
      key: _kBadgeKeyMinimalist,
      name: "Minimalist Shooter",
      title: "Minimalist Shooter",
      subtitle: subtitle,
      emoji: "🧘",
      gradientStart: "#304352",
      gradientEnd: "#D7D2CC",
      mediaRefs: metrics.highlightMedia,
      detailChips: chips,
      score: score,
      eligible: eligible,
      sampleSize: metrics.totalCount,
      tier: 0,
      debugWhy:
          "Total ${metrics.totalCount}, active days ${metrics.daysWithCaptures}",
      extras: <String, Object?>{
        "totalCount": metrics.totalCount,
        "daysWithCaptures": metrics.daysWithCaptures,
      },
    );
  }

  static double _clamp01(double value) {
    if (value.isNaN) {
      return 0;
    }
    if (value <= 0) {
      return 0;
    }
    if (value >= 1) {
      return 1;
    }
    return value;
  }

  static int _percentOf(double value) {
    if (value.isNaN || value.isInfinite) {
      return 0;
    }
    return (_clamp01(value) * 100).round();
  }
}

class _BadgeCandidate {
  _BadgeCandidate({
    required this.key,
    required this.name,
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.gradientStart,
    required this.gradientEnd,
    required this.mediaRefs,
    required this.detailChips,
    required this.score,
    required this.eligible,
    required this.sampleSize,
    required this.tier,
    required this.debugWhy,
    Map<String, Object?>? extras,
  })  : meta = <String, Object?>{
          "emoji": emoji,
          "gradient": <String>[gradientStart, gradientEnd],
          "detailChips": detailChips,
          "score": score,
          "tier": tier,
          "uploadedFileIDs": mediaRefs
              .map((MediaRef ref) => ref.uploadedFileID)
              .where((int id) => id > 0)
              .toList(growable: false),
          "extras": extras ?? const <String, Object?>{},
        },
        deterministicTieBreaker = _stableHash(key);

  final String key;
  final String name;
  final String title;
  final String subtitle;
  final String emoji;
  final String gradientStart;
  final String gradientEnd;
  final List<MediaRef> mediaRefs;
  final List<String> detailChips;
  final double score;
  final bool eligible;
  final int sampleSize;
  final int tier;
  final String debugWhy;
  final Map<String, Object?> meta;
  final int deterministicTieBreaker;

  Map<String, Object?> toMetaMap() {
    return <String, Object?>{
      "key": key,
      "name": name,
      "score": score,
      "eligible": eligible,
      "tier": tier,
      "sampleSize": sampleSize,
      "debugWhy": debugWhy,
      "emoji": emoji,
      "gradient": <String>[gradientStart, gradientEnd],
      "detailChips": detailChips,
      "subtitle": subtitle,
      "title": title,
      ...((meta["extras"] as Map<String, Object?>?) ?? const {}),
    };
  }
}

class _BadgeComputationContext {
  _BadgeComputationContext({
    required this.year,
    required this.totalCount,
    required this.daysWithCaptures,
    required this.elapsedDays,
    required this.longestStreakDays,
    required this.peopleStats,
    this.placesStats,
    required this.highlightMedia,
    required this.petMatches,
    required this.petSampleMedia,
    required this.topPetType,
    required this.hasPetEmbedding,
  });

  final int year;
  final int totalCount;
  final int daysWithCaptures;
  final int elapsedDays;
  final int longestStreakDays;
  final _PeopleDataset peopleStats;
  final _BadgePlaceStats? placesStats;
  final List<MediaRef> highlightMedia;
  final int petMatches;
  final List<int> petSampleMedia;
  final String? topPetType;
  final bool hasPetEmbedding;

  static _BadgeComputationContext fromEngineContext({
    required WrappedEngineContext context,
  }) {
    final _StatsSnapshot statsSnapshot = _StatsSnapshot.fromContext(context);
    final _PeopleDataset peopleDataset =
        _PeopleDataset.fromContext(context.people, context.year);
    final _PlacesDataset placesDataset = _PlacesDataset.fromContext(context);

    final int totalCount = statsSnapshot.totalCount;

    final Set<int> highlightIds = _collectUnique(
      <List<int>>[
        statsSnapshot.firstCaptureUploadedIDs,
        statsSnapshot.lastCaptureUploadedIDs,
        statsSnapshot.streakStartUploadedIDs,
        statsSnapshot.busiestDayMediaUploadedIDs,
      ],
    );

    final _BadgePlaceStats? placeStats =
        placesDataset.totalCount > 0 ? _BadgePlaceStats(placesDataset) : null;

    final _PetDetectionResult petDetection =
        _PetDetectionResult.fromContext(context);

    return _BadgeComputationContext(
      year: context.year,
      totalCount: totalCount,
      daysWithCaptures: statsSnapshot.daysWithCaptures,
      elapsedDays: statsSnapshot.elapsedDays,
      longestStreakDays: statsSnapshot.longestStreakDays,
      peopleStats: peopleDataset,
      placesStats: placeStats,
      highlightMedia: highlightIds.map(MediaRef.new).toList(growable: false),
      petMatches: petDetection.matchCount,
      petSampleMedia: petDetection.sampleIds,
      topPetType: petDetection.topPetType,
      hasPetEmbedding: petDetection.hasEmbeddings,
    );
  }

  static Set<int> _collectUnique(List<List<int>> sources) {
    final Set<int> unique = <int>{};
    for (final List<int> source in sources) {
      for (final int id in source) {
        if (id > 0) {
          unique.add(id);
        }
      }
      if (unique.length >= 6) {
        break;
      }
    }
    return unique;
  }
}

class _BadgePlaceStats {
  _BadgePlaceStats(_PlacesDataset dataset)
      : totalCount = dataset.totalCount,
        uniqueCities = dataset.cityClusters.length,
        uniqueCountries = dataset.cityClusters
            .map((_PlaceClusterSummary summary) => summary.label?.country)
            .whereType<String>()
            .toSet()
            .length,
        heroMedia = dataset.cityClusters
            .expand(
              (_PlaceClusterSummary cluster) =>
                  cluster.sampleMediaIds(2, preferDistinctDays: true),
            )
            .take(6)
            .toList(growable: false);

  final int totalCount;
  final int uniqueCities;
  final int uniqueCountries;
  final List<int> heroMedia;
}

class _PetDetectionResult {
  _PetDetectionResult({
    required this.matchCount,
    required this.sampleIds,
    required this.topPetType,
    required this.hasEmbeddings,
  });

  final int matchCount;
  final List<int> sampleIds;
  final String? topPetType;
  final bool hasEmbeddings;

  static _PetDetectionResult fromContext(WrappedEngineContext context) {
    if (context.aesthetics.clipEmbeddings.isEmpty ||
        !context.aesthetics.textEmbeddings.containsKey(
          WrappedBadgeSelector._kPetGenericQuery,
        )) {
      return _PetDetectionResult(
        matchCount: 0,
        sampleIds: const <int>[],
        topPetType: null,
        hasEmbeddings: false,
      );
    }

    final Map<int, List<double>> clipEmbeddings =
        context.aesthetics.clipEmbeddings;
    final Map<String, List<double>> textEmbeddings =
        context.aesthetics.textEmbeddings;

    final _Embedding petEmbedding = _Embedding.fromList(
      textEmbeddings[WrappedBadgeSelector._kPetGenericQuery]!,
    );

    final Map<int, double> scores = <int, double>{};

    clipEmbeddings.forEach((int fileID, List<double> vector) {
      final _Embedding imageEmbedding = _Embedding.fromList(vector);
      if (!imageEmbedding.isValid) {
        return;
      }
      final double similarity = _Embedding.cosine(imageEmbedding, petEmbedding);
      if (similarity >= WrappedBadgeSelector._kPetSimilarityThreshold) {
        scores[fileID] = similarity;
      }
    });

    if (scores.isEmpty) {
      return _PetDetectionResult(
        matchCount: 0,
        sampleIds: const <int>[],
        topPetType: null,
        hasEmbeddings: true,
      );
    }

    final Map<String, int> petTypeCounts = <String, int>{};
    WrappedBadgeSelector._kPetTypeQueries.forEach(
      (String type, String query) {
        final List<double>? embedding = textEmbeddings[query];
        if (embedding == null || embedding.isEmpty) {
          return;
        }
        final _Embedding typeEmbedding = _Embedding.fromList(embedding);
        int count = 0;
        scores.forEach((int fileID, double _) {
          final List<double>? imageVector = clipEmbeddings[fileID];
          if (imageVector == null) {
            return;
          }
          final _Embedding imageEmbedding = _Embedding.fromList(imageVector);
          if (!imageEmbedding.isValid) {
            return;
          }
          final double similarity =
              _Embedding.cosine(imageEmbedding, typeEmbedding);
          if (similarity >= WrappedBadgeSelector._kPetSimilarityThreshold) {
            count += 1;
          }
        });
        petTypeCounts[type] = count;
      },
    );

    String? topPetType;
    if (petTypeCounts.isNotEmpty) {
      topPetType = petTypeCounts.entries
          .reduce(
            (MapEntry<String, int> a, MapEntry<String, int> b) =>
                a.value >= b.value ? a : b,
          )
          .key;
    }

    final List<MapEntry<int, double>> sortedEntries = scores.entries.toList()
      ..sort(
        (MapEntry<int, double> a, MapEntry<int, double> b) =>
            b.value.compareTo(a.value),
      );

    final List<int> sampleIds = sortedEntries
        .map((MapEntry<int, double> entry) => entry.key)
        .take(6)
        .toList(growable: false);

    return _PetDetectionResult(
      matchCount: scores.length,
      sampleIds: sampleIds,
      topPetType: topPetType,
      hasEmbeddings: true,
    );
  }
}

class _Embedding {
  _Embedding(this.vector, this.norm);

  final Float32List vector;
  final double norm;

  bool get isValid => norm > 0 && vector.isNotEmpty;

  factory _Embedding.fromList(List<double> values) {
    final Float32List data = Float32List.fromList(values);
    double sum = 0;
    for (final double value in values) {
      sum += value * value;
    }
    final double norm = sum <= 0 ? 0 : math.sqrt(sum);
    return _Embedding(data, norm);
  }

  static double cosine(_Embedding a, _Embedding b) {
    final int length = math.min(a.vector.length, b.vector.length);
    double dot = 0;
    for (int index = 0; index < length; index += 1) {
      dot += a.vector[index] * b.vector[index];
    }
    final double denom = a.norm * b.norm;
    if (denom <= 0) {
      return 0;
    }
    return dot / denom;
  }
}

int _stableHash(String input) {
  int hash = 17;
  for (int i = 0; i < input.length; i += 1) {
    hash = (hash * 31 + input.codeUnitAt(i)) & 0x7fffffff;
  }
  return hash;
}
