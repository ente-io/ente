import "package:dio/dio.dart";
import "package:photos/gateways/collections/models/metadata.dart";

/// Gateway for file magic metadata API endpoints.
///
/// Magic metadata is encrypted key-value data attached to files.
/// Private magic metadata is only visible to the file owner.
/// Public magic metadata is visible to anyone the file is shared with.
class FileMagicGateway {
  final Dio _enteDio;

  FileMagicGateway(this._enteDio);

  /// Updates private magic metadata for one or more files.
  ///
  /// PUT /files/magic-metadata
  ///
  /// [metadataList] contains the encrypted metadata for each file to update.
  /// Throws [DioException] with status 409 if there's a version conflict.
  Future<void> updateMagicMetadata(
    List<UpdateMagicMetadataRequest> metadataList,
  ) async {
    await _enteDio.put(
      "/files/magic-metadata",
      data: {"metadataList": metadataList},
    );
  }

  /// Updates public magic metadata for one or more files.
  ///
  /// PUT /files/public-magic-metadata
  ///
  /// [metadataList] contains the encrypted metadata for each file to update.
  /// Public metadata is visible to users the file is shared with.
  /// Throws [DioException] with status 409 if there's a version conflict.
  Future<void> updatePublicMagicMetadata(
    List<UpdateMagicMetadataRequest> metadataList,
  ) async {
    await _enteDio.put(
      "/files/public-magic-metadata",
      data: {"metadataList": metadataList},
    );
  }
}
