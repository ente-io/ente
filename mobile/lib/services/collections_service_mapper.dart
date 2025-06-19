import "package:ente_crypto/ente_crypto.dart";
import "package:photos/models/api/diff/diff.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/file/remote/asset.dart";
import "package:photos/models/file/remote/file_entry.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/utils/file_key.dart";

extension CollectionsServiceMapper on CollectionsService {
  EnteFile moveOrAddEntry(EnteFile file, int destCollectionID) {
    if (file.remoteAsset == null || file.fileEntry == null) {
      throw ArgumentError(
        "File must have remoteAsset and fileEntry to be mapped.",
      );
    }
    final fileKey = getFileKey(file);
    final encResult =
        CryptoUtil.encryptSync(fileKey, getCollectionKey(destCollectionID));
    final remoteAsset = file.remoteAsset!;
    final oldCF = file.fileEntry!;
    final newCF = CollectionFileEntry(
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
      asset: file.asset,
    );
  }

  DiffFileItem mapDiffItem(EnteFile file) {
    if (file.remoteAsset == null || file.fileEntry == null) {
      throw ArgumentError(
        "File must have remoteAsset and fileEntry to be mapped.",
      );
    }
    final remoteAsset = file.remoteAsset!;
    final cf = file.fileEntry!;
    if (remoteAsset.id != cf.fileID) {
      throw ArgumentError(
        "File ID in remote asset does not match file entry.",
      );
    }

    return DiffFileItem(
      collectionID: cf.collectionID,
      isDeleted: false,
      updatedAt: cf.updatedAt,
      createdAt: cf.createdAt,
      encFileKey: cf.encFileKey,
      encFileKeyNonce: cf.encFileKeyNonce,
      fileItem: FileItem(
        fileID: remoteAsset.id,
        ownerID: remoteAsset.ownerID,
        thumnailDecryptionHeader: remoteAsset.thumbHeader,
        fileDecryotionHeader: remoteAsset.fileHeader,
        metadata: remoteAsset.metadata,
        magicMetadata: remoteAsset.privateMetadata,
        pubMagicMetadata: remoteAsset.publicMetadata,
        info: remoteAsset.info,
      ),
    );
  }
}
