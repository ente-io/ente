import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:ente_crypto_api/ente_crypto_api.dart';
import 'package:http/http.dart' as http;

import 'config.dart';
import 'http_util.dart';
import 'models.dart';

/// Service that fetches and decrypts slideshow images.
class SlideshowService {
  final http.Client _client;
  final CastPayload _payload;
  final _random = Random();
  var _files = <CastFile>[];
  var _index = 0;

  /// Creates slideshow service.
  SlideshowService(this._client, this._payload);

  /// Returns next slideshow image bytes.
  Future<Uint8List?> nextImage() async {
    if (_index >= _files.length) await _refreshFiles();
    if (_files.isEmpty) return null;
    final file = _files[_index];
    _index += 1;
    return _downloadImage(file);
  }

  /// Closes HTTP resources.
  void close() => _client.close();

  Future<void> _refreshFiles() async {
    final remoteFiles = await _getRemoteFiles();
    final files = <CastFile>[];
    for (final remoteFile in remoteFiles) {
      final file = await _decryptFile(remoteFile);
      if (file != null && file.isImage) files.add(file);
    }
    _files = files;
    _files.shuffle(_random);
    _index = 0;
  }

  Future<List<Map<String, dynamic>>> _getRemoteFiles() async {
    final filesByID = <int, Map<String, dynamic>>{};
    var sinceTime = 0;
    while (true) {
      final response = await _client.get(
        Uri.parse('$apiOrigin/cast/diff?sinceTime=$sinceTime'),
        headers: {'X-Cast-Access-Token': _payload.castToken},
      );
      ensureOk(response);
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final diff = body['diff'] as List<dynamic>;
      for (final item in diff.cast<Map<String, dynamic>>()) {
        sinceTime = max(sinceTime, item['updationTime'] as int);
        if (item['isDeleted'] == true) {
          filesByID.remove(item['id'] as int);
        } else {
          filesByID[item['id'] as int] = item;
        }
      }
      if (body['hasMore'] != true) return filesByID.values.toList();
    }
  }

  Future<CastFile?> _decryptFile(Map<String, dynamic> item) async {
    final key = CryptoUtil.decryptSync(
      CryptoUtil.base642bin(item['encryptedKey'] as String),
      CryptoUtil.base642bin(_payload.collectionKey),
      CryptoUtil.base642bin(item['keyDecryptionNonce'] as String),
    );
    final metadata = item['metadata'] as Map<String, dynamic>;
    final metadataBytes = await CryptoUtil.decryptData(
      CryptoUtil.base642bin(metadata['encryptedData'] as String),
      key,
      CryptoUtil.base642bin(metadata['decryptionHeader'] as String),
    );
    return CastFile.fromRemote(item, key, metadataBytes);
  }

  Future<Uint8List> _downloadImage(CastFile file) async {
    final response = await _client.get(
      Uri.parse('$castWorkerOrigin/preview/?fileID=${file.id}'),
      headers: {'X-Cast-Access-Token': _payload.castToken},
    );
    ensureOk(response);
    final preview = file.preview;
    return CryptoUtil.decryptData(
      response.bodyBytes,
      file.key,
      CryptoUtil.base642bin(preview['decryptionHeader'] as String),
    );
  }
}
