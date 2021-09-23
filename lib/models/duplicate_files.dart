import 'dart:convert';

import 'package:photos/models/file.dart';

class DuplicateFilesResponse {
  final List<DuplicateItems> duplicates;
  DuplicateFilesResponse(this.duplicates);

  factory DuplicateFilesResponse.fromMap(Map<String, dynamic> map) {
    return DuplicateFilesResponse(
      List<DuplicateItems>.from(
          map['duplicates']?.map((x) => DuplicateItems.fromMap(x))),
    );
  }

  factory DuplicateFilesResponse.fromJson(String source) =>
      DuplicateFilesResponse.fromMap(json.decode(source));

  @override
  String toString() => 'DuplicateFiles(duplicates: $duplicates)';
}

class DuplicateItems {
  final List<int> fileIDs;
  final int size;
  DuplicateItems(this.fileIDs, this.size);

  factory DuplicateItems.fromMap(Map<String, dynamic> map) {
    return DuplicateItems(
      List<int>.from(map['fileIDs']),
      map['size'],
    );
  }

  factory DuplicateItems.fromJson(String source) =>
      DuplicateItems.fromMap(json.decode(source));

  @override
  String toString() => 'Duplicates(fileIDs: $fileIDs, size: $size)';
}

class DuplicateFiles {
  final List<File> files;
  final int size;

  DuplicateFiles(this.files, this.size);

  @override
  String toString() => 'DuplicateFiles(files: $files, size: $size)';
}
