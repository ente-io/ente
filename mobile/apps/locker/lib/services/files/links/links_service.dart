import "package:fast_base58/fast_base58.dart";
import "package:locker/services/collections/collections_service.dart";
import "package:locker/services/files/links/links_client.dart";
import "package:locker/services/files/links/models/shareable_link.dart";
import "package:locker/services/files/sync/models/file.dart";

class LinksService {
  LinksService._();

  static final LinksService instance = LinksService._();

  late final LinksClient _client;

  Future<void> init() async {
    _client = LinksClient.instance;
  }

  Future<ShareableLink> getOrCreateLink(EnteFile file) async {
    final link = await _client.getOrCreateLink(file.uploadedFileID!);
    link.fullURL = link.url +
        "#" +
        Base58Encode(await CollectionService.instance.getFileKey(file));
    return link;
  }

  Future<void> deleteLink(int fileID) async {
    await _client.deleteLink(fileID);
  }
}
