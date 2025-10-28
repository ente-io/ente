import "dart:math" as math;
import "dart:typed_data";

import "package:flutter/foundation.dart" show immutable;
import "package:intl/intl.dart";
import "package:ml_linalg/dtype.dart";
import "package:ml_linalg/vector.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/file/file_type.dart";
import "package:photos/models/location/location.dart";
import "package:photos/models/metadata/common_keys.dart";
import "package:photos/services/machine_learning/face_ml/face_filtering/face_filtering_constants.dart";
import "package:photos/services/wrapped/models.dart";
import "package:photos/utils/standalone/data.dart";

part "builders/stats_candidate_builder.dart";
part "builders/people_candidate_builder.dart";
part "builders/places_candidate_builder.dart";
part "builders/aesthetics_candidate_builder.dart";
part "builders/curation_candidate_builder.dart";
part "builders/narrative_candidate_builder.dart";
part "builders/badge_selector.dart";
part "builders/media_selector.dart";

/// Provides basic context details for candidate builders.
@immutable
class WrappedEngineContext {
  WrappedEngineContext({
    required this.year,
    required this.now,
    required List<EnteFile> files,
    WrappedPeopleContext? people,
    WrappedAestheticsContext? aesthetics,
    List<WrappedCity>? cities,
    Set<int>? favoriteUploadedFileIDs,
    Set<int>? archivedCollectionIDs,
  })  : files = List<EnteFile>.unmodifiable(files),
        people = people ?? WrappedPeopleContext.empty(),
        aesthetics = aesthetics ?? WrappedAestheticsContext.empty(),
        cities = List<WrappedCity>.unmodifiable(
          cities ?? const <WrappedCity>[],
        ),
        favoriteUploadedFileIDs = Set<int>.unmodifiable(
          favoriteUploadedFileIDs ?? const <int>{},
        ),
        archivedCollectionIDs = Set<int>.unmodifiable(
          archivedCollectionIDs ?? const <int>{},
        );

  final int year;
  final DateTime now;
  final List<EnteFile> files;
  final WrappedPeopleContext people;
  final WrappedAestheticsContext aesthetics;
  final List<WrappedCity> cities;
  final Set<int> favoriteUploadedFileIDs;
  final Set<int> archivedCollectionIDs;
}

/// Contract for producing Wrapped candidate cards for a specific domain.
abstract class WrappedCandidateBuilder {
  const WrappedCandidateBuilder();

  String get debugLabel;

  Future<List<WrappedCard>> build(WrappedEngineContext context);
}

/// Registry of all candidate builders invoked by the engine.
const List<WrappedCandidateBuilder> wrappedCandidateBuilders =
    <WrappedCandidateBuilder>[
  StatsCandidateBuilder(),
  PeopleCandidateBuilder(),
  PlacesCandidateBuilder(),
  AestheticsCandidateBuilder(),
  CurationCandidateBuilder(),
  NarrativeCandidateBuilder(),
];
