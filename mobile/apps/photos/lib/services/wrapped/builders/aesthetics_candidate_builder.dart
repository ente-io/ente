part of 'package:photos/services/wrapped/candidate_builders.dart';

class AestheticsCandidateBuilder extends WrappedCandidateBuilder {
  const AestheticsCandidateBuilder();

  @override
  String get debugLabel => "aesthetics";

  @override
  Future<List<WrappedCard>> build(WrappedEngineContext context) async {
    return <WrappedCard>[];
  }
}
