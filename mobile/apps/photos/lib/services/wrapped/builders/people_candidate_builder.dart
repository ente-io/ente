part of 'package:photos/services/wrapped/candidate_builders.dart';

class PeopleCandidateBuilder extends WrappedCandidateBuilder {
  const PeopleCandidateBuilder();

  @override
  String get debugLabel => "people";

  @override
  Future<List<WrappedCard>> build(WrappedEngineContext context) async {
    return <WrappedCard>[];
  }
}
