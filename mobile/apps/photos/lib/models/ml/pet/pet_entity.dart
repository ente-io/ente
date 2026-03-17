/// Represents a named pet that the user has identified.
///
/// Stored in a standalone [PetDB] database, separate from the ML data DB.
/// The ML DB holds a mapping table (`pet_cluster_pet`) that links cluster IDs
/// to pet IDs.
class PetEntity {
  final String id;
  final String name;
  final int species;

  const PetEntity({
    required this.id,
    required this.name,
    required this.species,
  });

  PetEntity copyWith({String? name, int? species}) {
    return PetEntity(
      id: id,
      name: name ?? this.name,
      species: species ?? this.species,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'species': species,
      };

  factory PetEntity.fromMap(Map<String, dynamic> map) {
    return PetEntity(
      id: map['id'] as String,
      name: map['name'] as String,
      species: map['species'] as int,
    );
  }
}
