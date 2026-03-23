/// Represents a named pet that the user has identified.
///
/// Synced to the remote server via the entity sync service using
/// [EntityType.person] (repurposed — person entities are deprecated in favour
/// of cgroup for [PersonEntity]).
///
/// The ML DB holds a mapping table (`pet_cluster_pet`) that links cluster IDs
/// to pet IDs.
class PetEntity {
  final String remoteID;
  final PetData data;

  const PetEntity(this.remoteID, this.data);

  PetEntity copyWith({PetData? data}) {
    return PetEntity(remoteID, data ?? this.data);
  }
}

class PetData {
  final String name;
  final int species;

  const PetData({
    required this.name,
    required this.species,
  });

  PetData copyWith({String? name, int? species}) {
    return PetData(
      name: name ?? this.name,
      species: species ?? this.species,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'species': species,
      };

  factory PetData.fromJson(Map<String, dynamic> json) {
    return PetData(
      name: json['name'] as String? ?? '',
      species: json['species'] as int? ?? -1,
    );
  }
}
