import "dart:typed_data";

import "package:ente_crypto/ente_crypto.dart";
import "package:photos/models/api/diff/diff.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/file/remote/asset.dart";
import "package:photos/models/file/remote/collection_file.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/utils/file_key.dart";

extension CollectionsServiceMapper on CollectionsService {
  EnteFile moveOrAddEntry(EnteFile file, int destCollectionID) {
    if (file.rAsset == null || file.cf == null) {
      throw ArgumentError(
        "File must have remoteAsset and fileEntry to be mapped.",
      );
    }
    final fileKey = getFileKey(file);
    final encResult =
        CryptoUtil.encryptSync(fileKey, getCollectionKey(destCollectionID));
    final remoteAsset = file.rAsset!;
    final oldCF = file.cf!;
    final newCF = CollectionFile(
      collectionID: destCollectionID,
      fileID: oldCF.fileID,
      encFileKey: encResult.encryptedData!,
      encFileKeyNonce: encResult.nonce!,
      updatedAt: DateTime.now().microsecondsSinceEpoch,
      createdAt: DateTime.now().microsecondsSinceEpoch,
    );
    return EnteFile.fromRemoteAsset(
      remoteAsset,
      newCF,
      lAsset: file.lAsset,
    );
  }

  EnteFile copyEntry(
    RemoteAsset rAsset,
    (Uint8List, Uint8List) keyAndntNonce, {
    required int newID,
    required int dstCollectionID,
    required int ownerID,
  }) {
    if (rAsset.ownerID == ownerID) {
      throw ArgumentError("copying file to same owner is not allowed.");
    }
    final newCF = CollectionFile(
      collectionID: dstCollectionID,
      fileID: rAsset.id,
      encFileKey: keyAndntNonce.$1,
      encFileKeyNonce: keyAndntNonce.$2,
      updatedAt: DateTime.now().microsecondsSinceEpoch,
      createdAt: DateTime.now().microsecondsSinceEpoch,
    );
    final newRAsset = RemoteAsset(
      id: newID,
      ownerID: ownerID,
      thumbHeader: rAsset.thumbHeader,
      fileHeader: rAsset.fileHeader,
      metadata: rAsset.metadata,
      publicMetadata: rAsset.publicMetadata,
      privateMetadata: null,
      info: rAsset.info,
    );
    return EnteFile.fromRemoteAsset(newRAsset, newCF);
  }

  DiffItem buildDiffItem(EnteFile file, int dstCollectionID) {
    if (file.rAsset == null || file.cf == null) {
      throw ArgumentError("must have remoteAsset and fileEntry");
    }
    if (file.cf!.collectionID != dstCollectionID) {
      throw ArgumentError(
        "File collection ID does not match destination collection ID.",
      );
    }
    if (file.rAsset!.id != file.cf!.fileID) {
      throw ArgumentError("File ID in remote asset does not match file entry.");
    }
    final remoteAsset = file.rAsset!;
    final cf = file.cf!;
    if (remoteAsset.id != cf.fileID) {
      throw ArgumentError("File ID in remote asset does not match file entry.");
    }

    return DiffItem(
      collectionID: cf.collectionID,
      isDeleted: false,
      updatedAt: cf.updatedAt,
      createdAt: cf.createdAt,
      encFileKey: cf.encFileKey,
      encFileKeyNonce: cf.encFileKeyNonce,
      fileItem: ApiFileItem(
        fileID: remoteAsset.id,
        ownerID: remoteAsset.ownerID,
        thumnailDecryptionHeader: remoteAsset.thumbHeader,
        fileDecryptionHeader: remoteAsset.fileHeader,
        metadata: remoteAsset.metadata,
        privMagicMetadata: remoteAsset.privateMetadata,
        pubMagicMetadata: remoteAsset.publicMetadata,
        info: remoteAsset.info,
      ),
    );
  }
}
