import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/network/network.dart';
import 'package:photos/generated/l10n.dart';
import 'package:photos/models/file/file.dart';
import "package:photos/models/file/remote/asset.dart";
import "package:photos/models/file/remote/collection_file.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/services/remote/fetch/files_diff.dart";
import "package:photos/utils/dialog_util.dart";

Future<List<EnteFile>> getPublicFiles(
  BuildContext context,
  int collectionID,
  bool sortAsc,
) async {
  try {
    final collectionFilService =
        RemoteFileDiffService(NetworkClient.instance.enteDio);
    bool hasMore = false;
    final sharedFiles = <EnteFile>[];
    final headers =
        CollectionsService.instance.publicCollectionHeaders(collectionID);
    int sinceTime = 0;
    final collectionKey =
        CollectionsService.instance.getCollectionKey(collectionID);
    do {
      final diffResult = await collectionFilService.getPublicCollectionDiff(
        collectionID,
        sinceTime,
        collectionKey,
        headers,
      );
      for (final item in diffResult.updatedItems) {
        final cf = CollectionFile(
          collectionID: item.collectionID,
          fileID: item.fileID,
          encFileKey: item.encFileKey!,
          encFileKeyNonce: item.encFileKeyNonce!,
          updatedAt: item.updatedAt,
          createdAt: item.createdAt ?? 0,
        );
        final rAsset = RemoteAsset.fromMetadata(
          id: item.fileItem.fileID,
          ownerID: item.fileItem.ownerID,
          fileHeader: item.fileItem.fileDecryptionHeader!,
          thumbHeader: item.fileItem.thumnailDecryptionHeader!,
          metadata: item.fileItem.metadata!,
          publicMetadata: item.fileItem.pubMagicMetadata,
          privateMetadata: item.fileItem.privMagicMetadata,
          info: item.fileItem.info,
        );
        sharedFiles.add(EnteFile.fromRemoteAsset(rAsset, cf));
      }
      sinceTime = diffResult.maxUpdatedAtTime;
      hasMore = diffResult.hasMore;
    } while (hasMore);
    if (sortAsc) {
      sharedFiles.sort((a, b) => a.creationTime!.compareTo(b.creationTime!));
    }
    return sharedFiles;
  } catch (e, s) {
    Logger("getPublicFiles").severe("Failed to decrypt collection ", e, s);
    await showErrorDialog(
      context,
      S.of(context).somethingWentWrong,
      e.toString(),
    );
    rethrow;
  }
}
