import "package:ente_crypto/ente_crypto.dart";
import "package:photos/models/api/diff/diff.dart";
import "package:photos/models/file/file.dart";
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

  DiffFileItem buildDiffItem(EnteFile file) {
    if (file.rAsset == null || file.cf == null) {
      throw ArgumentError("must have remoteAsset and fileEntry");
    }
    final remoteAsset = file.rAsset!;
    final cf = file.cf!;
    if (remoteAsset.id != cf.fileID) {
      throw ArgumentError("File ID in remote asset does not match file entry.");
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
