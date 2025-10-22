import "dart:math" as math;

import "package:flutter/foundation.dart" show immutable;
import "package:intl/intl.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/file/file_type.dart";
import "package:photos/services/wrapped/models.dart";
import "package:photos/utils/standalone/data.dart";

part "builders/stats_candidate_builder.dart";
part "builders/people_candidate_builder.dart";
part "builders/places_candidate_builder.dart";
part "builders/aesthetics_candidate_builder.dart";
part "builders/curation_candidate_builder.dart";
part "builders/narrative_candidate_builder.dart";

/// Provides basic context details for candidate builders.
@immutable
class WrappedEngineContext {
  WrappedEngineContext({
    required this.year,
    required this.now,
    required List<EnteFile> files,
  }) : files = List<EnteFile>.unmodifiable(files);

  final int year;
  final DateTime now;
  final List<EnteFile> files;
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
