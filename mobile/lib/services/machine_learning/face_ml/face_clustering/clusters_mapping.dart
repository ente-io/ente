import "package:photos/face/model/person.dart";

enum MappingSource {
  local,
  remote,
}

class ClustersMapping {
  final Map<int, Set<int>> fileIDToClusterIDs;
  final Map<int, String> clusterToPersonID;
  // personIDToPerson is a map of personID to PersonEntity, and it's same for
  // both local and remote sources
  final Map<String, PersonEntity> personIDToPerson;
  final MappingSource source;

  ClustersMapping({
    required this.fileIDToClusterIDs,
    required this.clusterToPersonID,
    required this.personIDToPerson,
    required this.source,
  });
}
