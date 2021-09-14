import 'dart:convert';

class DuplicateFiles {
  final List<Duplicates> duplicates;
  DuplicateFiles(this.duplicates);

  factory DuplicateFiles.fromMap(Map<String, dynamic> map) {
    return DuplicateFiles(
      List<Duplicates>.from(
          map['duplicates']?.map((x) => Duplicates.fromMap(x))),
    );
  }

  factory DuplicateFiles.fromJson(String source) =>
      DuplicateFiles.fromMap(json.decode(source));

  @override
  String toString() => 'DuplicateFiles(duplicates: $duplicates)';
}

class Duplicates {
  final List<int> fileIDs;
  final int size;
  Duplicates(this.fileIDs, this.size);

  factory Duplicates.fromMap(Map<String, dynamic> map) {
    return Duplicates(
      List<int>.from(map['fileIDs']),
      map['size'],
    );
  }

  factory Duplicates.fromJson(String source) =>
      Duplicates.fromMap(json.decode(source));

  @override
  String toString() => 'Duplicates(fileIDs: $fileIDs, size: $size)';
}
