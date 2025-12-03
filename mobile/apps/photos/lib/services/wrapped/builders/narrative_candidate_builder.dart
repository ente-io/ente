part of 'package:photos/services/wrapped/candidate_builders.dart';

class NarrativeCandidateBuilder extends WrappedCandidateBuilder {
  const NarrativeCandidateBuilder();

  @override
  String get debugLabel => "narrative";

  @override
  Future<List<WrappedCard>> build(WrappedEngineContext context) async {
    return <WrappedCard>[];
  }
}
