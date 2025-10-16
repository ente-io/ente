import "package:flutter/foundation.dart" show immutable;

import "models.dart";

/// Provides basic context details for candidate builders.
@immutable
class WrappedEngineContext {
  const WrappedEngineContext({
    required this.year,
    required this.now,
  });

  final int year;
  final DateTime now;
}

/// Contract for producing Wrapped candidate cards for a specific domain.
abstract class WrappedCandidateBuilder {
  const WrappedCandidateBuilder();

  String get debugLabel;

  Future<List<WrappedCard>> build(WrappedEngineContext context);
}

class StatsCandidateBuilder extends WrappedCandidateBuilder {
  const StatsCandidateBuilder();

  @override
  String get debugLabel => "stats";

  @override
  Future<List<WrappedCard>> build(WrappedEngineContext context) async {
    return <WrappedCard>[];
  }
}

class PeopleCandidateBuilder extends WrappedCandidateBuilder {
  const PeopleCandidateBuilder();

  @override
  String get debugLabel => "people";

  @override
  Future<List<WrappedCard>> build(WrappedEngineContext context) async {
    return <WrappedCard>[];
  }
}

class PlacesCandidateBuilder extends WrappedCandidateBuilder {
  const PlacesCandidateBuilder();

  @override
  String get debugLabel => "places";

  @override
  Future<List<WrappedCard>> build(WrappedEngineContext context) async {
    return <WrappedCard>[];
  }
}

class AestheticsCandidateBuilder extends WrappedCandidateBuilder {
  const AestheticsCandidateBuilder();

  @override
  String get debugLabel => "aesthetics";

  @override
  Future<List<WrappedCard>> build(WrappedEngineContext context) async {
    return <WrappedCard>[];
  }
}

class CurationCandidateBuilder extends WrappedCandidateBuilder {
  const CurationCandidateBuilder();

  @override
  String get debugLabel => "curation";

  @override
  Future<List<WrappedCard>> build(WrappedEngineContext context) async {
    return <WrappedCard>[];
  }
}

class NarrativeCandidateBuilder extends WrappedCandidateBuilder {
  const NarrativeCandidateBuilder();

  @override
  String get debugLabel => "narrative";

  @override
  Future<List<WrappedCard>> build(WrappedEngineContext context) async {
    return <WrappedCard>[];
  }
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
