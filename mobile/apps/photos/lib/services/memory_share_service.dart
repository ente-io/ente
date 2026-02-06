import 'dart:convert';
import 'dart:typed_data';

import 'package:ente_crypto/ente_crypto.dart';
import 'package:fast_base58/fast_base58.dart';
import 'package:photos/core/network/network.dart';
import 'package:photos/db/memory_shares_db.dart';
import 'package:photos/models/api/entity/type.dart';
import 'package:photos/models/api/memory_share/memory_share.dart';
import 'package:photos/models/file/file.dart';
import 'package:photos/models/memories/memory.dart';
import 'package:photos/service_locator.dart' show entityService;
import 'package:photos/utils/file_key.dart';

class MemoryShareService {
  static final MemoryShareService instance = MemoryShareService._();
  MemoryShareService._();

  final _enteDio = NetworkClient.instance.enteDio;
  final _db = MemorySharesDB.instance;

  /// Creates a memory share and returns the shareable URL with key in fragment.
  Future<String> createMemoryShare({
    required List<EnteFile> files,
    required String title,
    String? memoryId,
  }) async {
    final uploadedFiles = files.where((f) => f.uploadedFileID != null).toList();

    if (uploadedFiles.isEmpty) {
      throw Exception("No uploaded files to share");
    }

    final memoryEntityKey =
        await entityService.getOrCreateEntityKey(EntityType.memory);
    final shareKey = CryptoUtil.generateKey();
    final encryptedShareKey = CryptoUtil.encryptSync(
      shareKey,
      memoryEntityKey,
    );

    final metadataMap = <String, dynamic>{'name': title};
    if (memoryId != null) {
      metadataMap['memoryId'] = memoryId;
    }
    final metadata = jsonEncode(metadataMap);
    final metadataBytes = utf8.encode(metadata);
    final encryptedMetadata = CryptoUtil.encryptSync(
      Uint8List.fromList(metadataBytes),
      shareKey,
    );

    final fileItems = <Map<String, dynamic>>[];
    for (final file in uploadedFiles) {
      final fileKey = getFileKey(file);
      final reEncryptedKey = CryptoUtil.encryptSync(fileKey, shareKey);
      fileItems.add({
        'fileID': file.uploadedFileID,
        'encryptedKey': CryptoUtil.bin2base64(reEncryptedKey.encryptedData!),
        'keyDecryptionNonce': CryptoUtil.bin2base64(reEncryptedKey.nonce!),
      });
    }

    final requestData = {
      'metadataCipher': CryptoUtil.bin2base64(encryptedMetadata.encryptedData!),
      'metadataNonce': CryptoUtil.bin2base64(encryptedMetadata.nonce!),
      'encryptedKey': CryptoUtil.bin2base64(encryptedShareKey.encryptedData!),
      'keyDecryptionNonce': CryptoUtil.bin2base64(encryptedShareKey.nonce!),
      'files': fileItems,
    };

    final response = await _enteDio.post('/memory-share', data: requestData);
    final memoryShare = MemoryShare.fromJson(response.data['memoryShare']);

    await _db.upsert(memoryShare);

    // Key in URL fragment is never sent to server (E2E encryption)
    final keyBase58 = Base58Encode(shareKey);
    final shareUrl = "${memoryShare.url}#$keyBase58";

    return shareUrl;
  }

  Future<List<MemoryShare>> listMemoryShares() async {
    final response = await _enteDio.get('/memory-share');
    final List<dynamic> shares = response.data['memoryShares'] ?? [];
    final result = shares
        .map((s) => MemoryShare.fromJson(s as Map<String, dynamic>))
        .toList();

    for (final share in result) {
      await _db.upsert(share);
    }

    return result;
  }

  Future<List<MemoryShare>> getLocalMemoryShares() async {
    return _db.getAll();
  }

  Future<void> deleteMemoryShare(int id) async {
    await _enteDio.delete('/memory-share/$id');
    await _db.delete(id);
  }

  Future<String> shareMemories({
    required List<Memory> memories,
    required String title,
    String? memoryId,
  }) async {
    final files = Memory.filesFromMemories(memories);
    return createMemoryShare(files: files, title: title, memoryId: memoryId);
  }
}
