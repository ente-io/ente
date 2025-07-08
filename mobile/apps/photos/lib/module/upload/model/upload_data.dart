import "dart:io";
import "dart:typed_data";

import "package:exif_reader/exif_reader.dart";

class UploadMetadaData {
  final Map<String, dynamic> defaultMetadata;
  final Map<String, dynamic>? publicMetadata;

  UploadMetadaData({
    required this.defaultMetadata,
    required this.publicMetadata,
  });
}

class MediaUploadData {
  final File sourceFile;
  final Uint8List? thumbnail;
  final bool isDeleted;
  final Hash hash;
  final int? height;
  final int? width;

  // For android motion photos, the startIndex is the index of the first frame
  // For iOS, this value will be always null.
  final int? motionPhotoStartIndex;

  final Map<String, IfdTag>? exifData;

  bool? isPanorama;

  MediaUploadData(
    this.sourceFile,
    this.thumbnail,
    this.isDeleted,
    this.hash, {
    this.height,
    this.width,
    this.motionPhotoStartIndex,
    this.isPanorama,
    this.exifData,
  });
}

class Hash {
  // For livePhotos, the fileHash value will be imageHash:videoHash
  final String data;

  // zipHash is used to take care of existing live photo uploads from older
  // mobile clients
  String? zipHash;

  Hash(this.data, {this.zipHash});
}
