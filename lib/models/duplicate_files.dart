import 'dart:convert';

import 'package:photos/models/file/file.dart';
import 'package:photos/services/collections_service.dart';

class DuplicateFilesResponse {
  final List<FileWithSameSize> sameSizeFiles;
  DuplicateFilesResponse(this.sameSizeFiles);

  factory DuplicateFilesResponse.fromMap(Map<String, dynamic> map) {
    return DuplicateFilesResponse(
      List<FileWithSameSize>.from(
        map['duplicates']?.map((x) => FileWithSameSize.fromMap(x)),
      ),
    );
  }

  Map<int, int> toUploadIDToSize() {
    final Map<int, int> result = {};
    for (final filesWithSameSize in sameSizeFiles) {
      for (final uploadID in filesWithSameSize.fileIDs) {
        result[uploadID] = filesWithSameSize.size;
      }
    }
    return result;
  }

  factory DuplicateFilesResponse.fromJson(String source) =>
      DuplicateFilesResponse.fromMap(json.decode(source));

  @override
  String toString() => 'DuplicateFiles(sameSizeFiles: $sameSizeFiles)';
}

class FileWithSameSize {
  final List<int> fileIDs;
  final int size;
  FileWithSameSize(this.fileIDs, this.size);

  factory FileWithSameSize.fromMap(Map<String, dynamic> map) {
    return FileWithSameSize(
      List<int>.from(map['fileIDs']),
      map['size'],
    );
  }

  factory FileWithSameSize.fromJson(String source) =>
      FileWithSameSize.fromMap(json.decode(source));

  @override
  String toString() => 'Duplicates(fileIDs: $fileIDs, size: $size)';
}

class DuplicateFiles {
  final List<EnteFile> files;
  final int size;
  static final collectionsService = CollectionsService.instance;

  DuplicateFiles(this.files, this.size) {
    sortByCollectionName();
  }

  @override
  String toString() => 'DuplicateFiles(files: $files, size: $size)';

  sortByCollectionName() {
    files.sort((first, second) {
      final firstName = collectionsService
          .getCollectionByID(first.collectionID!)!
          .displayName;
      final secondName = collectionsService
          .getCollectionByID(second.collectionID!)!
          .displayName;
      return firstName.compareTo(secondName);
    });
  }
}
