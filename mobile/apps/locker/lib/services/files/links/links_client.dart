import "package:ente_network/network.dart";
import "package:locker/services/files/links/models/shareable_link.dart";
import "package:logging/logging.dart";

class LinksClient {
  LinksClient._();

  static final LinksClient instance = LinksClient._();

  final _logger = Logger("LinksClient");
  final _enteDio = Network.instance.enteDio;

  Future<void> init() async {}

  Future<ShareableLink> getOrCreateLink(int fileID) async {
    try {
      final response = await _enteDio.post(
        '/files/share-url',
        data: {
          'fileID': fileID,
          'app': 'locker',
        },
      );
      return ShareableLink.fromJson(response.data as Map<String, dynamic>);
    } catch (e, s) {
      _logger.severe('Failed to get or create link for file ID: $fileID', e, s);
      rethrow;
    }
  }

  Future<void> deleteLink(int linkID) async {
    try {
      await _enteDio.delete('/files/share-url/$linkID');
    } catch (e, s) {
      _logger.severe('Failed to delete link with ID: $linkID', e, s);
      rethrow;
    }
  }
}
