part of 'package:photos/services/wrapped/candidate_builders.dart';

class CurationCandidateBuilder extends WrappedCandidateBuilder {
  const CurationCandidateBuilder();

  @override
  String get debugLabel => "curation";

  @override
  Future<List<WrappedCard>> build(WrappedEngineContext context) async {
    return <WrappedCard>[];
  }
}
