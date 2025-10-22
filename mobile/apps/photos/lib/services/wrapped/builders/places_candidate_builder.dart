part of 'package:photos/services/wrapped/candidate_builders.dart';

class PlacesCandidateBuilder extends WrappedCandidateBuilder {
  const PlacesCandidateBuilder();

  @override
  String get debugLabel => "places";

  @override
  Future<List<WrappedCard>> build(WrappedEngineContext context) async {
    return <WrappedCard>[];
  }
}
