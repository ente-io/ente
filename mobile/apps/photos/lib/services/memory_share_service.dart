import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:ente_crypto/ente_crypto.dart';
import "package:flutter/foundation.dart" show kDebugMode;
import "package:logging/logging.dart";
import 'package:photos/core/network/network.dart';
import "package:photos/db/files_db.dart";
import 'package:photos/db/memory_shares_db.dart';
import "package:photos/gateways/entity/models/type.dart";
import 'package:photos/models/api/memory_share/memory_share.dart';
import 'package:photos/models/file/file.dart';
import 'package:photos/models/memories/memory.dart';
import "package:photos/models/metadata/file_magic.dart";
import 'package:photos/service_locator.dart' show entityService;
import 'package:photos/utils/file_key.dart';

class MemoryShareService {
  MemoryShareService._();

  static final MemoryShareService instance = MemoryShareService._();

  final Logger _logger = Logger("MemoryShareService");

  static const int _shortFragmentSecretLength = 12;
  static final RegExp _base62SecretPattern = RegExp(r'^[0-9A-Za-z]{12}$');

  late final Dio _enteDio;
  late final MemorySharesDB _db;

  Future<void> init() async {
    _enteDio = NetworkClient.instance.enteDio;
    _db = MemorySharesDB.instance;
  }

  /// Creates a memory share and returns the shareable URL with key in fragment.
  Future<String> createMemoryShare({
    required List<EnteFile> files,
    required String title,
    String? memoryId,
  }) async {
    List<EnteFile> uploadedFiles = const [];
    try {
      uploadedFiles = files.where((f) => f.uploadedFileID != null).toList();

      if (uploadedFiles.isEmpty) {
        throw Exception("No uploaded files to share");
      }

      final secretPayload = await _prepareShareSecret();
      final shareKey = secretPayload.shareKey;

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
        'metadataCipher':
            CryptoUtil.bin2base64(encryptedMetadata.encryptedData!),
        'metadataNonce': CryptoUtil.bin2base64(encryptedMetadata.nonce!),
        ...secretPayload.metadata(),
        'files': fileItems,
      };

      final response = await _enteDio.post('/memory-share', data: requestData);
      final memoryShare = MemoryShare.fromJson(response.data['memoryShare']);

      final shareUrl = "${memoryShare.url}#${secretPayload.secret}";
      await _db.upsert(
        MemoryShare(
          id: memoryShare.id,
          type: memoryShare.type,
          metadataCipher: memoryShare.metadataCipher,
          metadataNonce: memoryShare.metadataNonce,
          encryptedKey: memoryShare.encryptedKey,
          keyDecryptionNonce: memoryShare.keyDecryptionNonce,
          accessToken: memoryShare.accessToken,
          isDeleted: memoryShare.isDeleted,
          createdAt: memoryShare.createdAt,
          updatedAt: memoryShare.updatedAt,
          url: shareUrl,
          previewUploadedFileID: uploadedFiles.first.uploadedFileID,
          fileCount: uploadedFiles.length,
        ),
      );

      return shareUrl;
    } catch (e, s) {
      if (e is DioException) {
        final ownerIDs = uploadedFiles.map((f) => f.ownerID).toSet().toList();
        final sampleFileIDs = uploadedFiles
            .map((f) => f.uploadedFileID)
            .whereType<int>()
            .take(10)
            .toList();
        final distinctFileIDCount = uploadedFiles
            .map((f) => f.uploadedFileID)
            .whereType<int>()
            .toSet()
            .length;
        _logger.severe(
          "Failed to create memory share "
          "(status: ${e.response?.statusCode}, data: ${e.response?.data}, "
          "uploadedFiles: ${uploadedFiles.length}, ownerIDs: $ownerIDs, "
          "distinctFileIDs: $distinctFileIDCount, sampleFileIDs: $sampleFileIDs)",
          e,
          s,
        );
      } else {
        _logger.severe("Failed to create memory share", e, s);
      }
      rethrow;
    }
  }

  Future<List<MemoryShare>> listMemoryShares() async {
    try {
      final response = await _enteDio.get('/memory-share');
      final List<dynamic> shares = response.data['memoryShares'] ?? [];
      Uint8List? memoryEntityKey;
      try {
        memoryEntityKey = await entityService.getOrCreateEntityKey(
          EntityType.memory,
        );
      } catch (e, s) {
        _logger.severe(
          "Failed to get memory entity key while listing memory shares",
          e,
          s,
        );
        memoryEntityKey = null;
      }
      final result = shares.map((s) {
        var share = MemoryShare.fromJson(s as Map<String, dynamic>);
        final entityKey = memoryEntityKey;
        if (entityKey != null) {
          final fragment = Uri.parse(share.url).fragment;
          if (fragment.isEmpty) {
            final resolvedFragment = _resolveFragmentSecret(share, entityKey);
            if (resolvedFragment != null && resolvedFragment.isNotEmpty) {
              share = share.copyWith(url: "${share.url}#$resolvedFragment");
            }
          }
        }
        return share;
      }).toList();

      for (final share in result) {
        final localShare = await _db.getById(share.id);
        await _db.upsert(
          share.copyWith(
            previewUploadedFileID: localShare?.previewUploadedFileID,
            fileCount: localShare?.fileCount,
          ),
        );
      }

      return result;
    } catch (e, s) {
      _logger.severe("Failed to list memory shares", e, s);
      rethrow;
    }
  }

  Future<List<MemoryShare>> getLocalMemoryShares() async {
    return _db.getAll();
  }

  Future<List<EnteFile>> getPublicMemoryFiles(String shareUrl) async {
    try {
      final uri = Uri.parse(shareUrl);
      final accessToken = _extractAccessToken(uri);
      final shareKey = _resolveShareKeyFromUrlFragment(uri.fragment);
      final response = await _enteDio.get(
        '/public-memory/files',
        options: Options(
          headers: {'X-Auth-Access-Token': accessToken},
        ),
      );
      final rawFiles = response.data['files'] as List<dynamic>? ?? const [];
      final files = <EnteFile>[];
      for (final rawFile in rawFiles) {
        final localFile = await _resolveLocalFileFromShareItem(rawFile);
        if (localFile != null) {
          files.add(localFile);
          continue;
        }
        final file = await _parsePublicMemoryFile(rawFile, shareKey);
        if (file != null) {
          files.add(file);
        }
      }
      if (files.isEmpty && kDebugMode) {
        _logger.info(
          "Public memory files response was empty, using debug dummy files",
        );
        return _buildDebugDummyMemoryFiles();
      }
      return files;
    } catch (e, s) {
      _logger.severe("Failed to fetch public memory files", e, s);
      if (kDebugMode) {
        _logger.info("Using debug dummy files after fetch failure");
        return _buildDebugDummyMemoryFiles();
      }
      rethrow;
    }
  }

  Future<EnteFile?> _resolveLocalFileFromShareItem(dynamic rawFile) async {
    final item = _toMap(rawFile);
    final remoteFile = _toMap(item?['file']);
    if (remoteFile == null) {
      return null;
    }
    final fileID = _toInt(remoteFile['id']);
    if (fileID == null) {
      return null;
    }
    return FilesDB.instance.getAnyUploadedFile(fileID);
  }

  String? getMemoryShareTitle(MemoryShare share) {
    try {
      final metadataCipher = share.metadataCipher;
      final metadataNonce = share.metadataNonce;
      if (metadataCipher == null || metadataNonce == null) {
        return null;
      }
      final fragment = Uri.parse(share.url).fragment;
      if (fragment.isEmpty) {
        return null;
      }
      final shareKey = _resolveShareKeyFromUrlFragment(fragment);
      final decryptedMetadata = CryptoUtil.decryptSync(
        CryptoUtil.base642bin(metadataCipher),
        shareKey,
        CryptoUtil.base642bin(metadataNonce),
      );
      final parsed = jsonDecode(utf8.decode(decryptedMetadata));
      if (parsed is! Map<String, dynamic>) {
        return null;
      }
      final name = parsed["name"];
      if (name is String && name.trim().isNotEmpty) {
        return name;
      }
      return null;
    } catch (e, s) {
      _logger.severe(
        "Failed to read memory share title for share ${share.id}",
        e,
        s,
      );
      return null;
    }
  }

  Future<void> deleteMemoryShare(int id) async {
    try {
      await _enteDio.delete('/memory-share/$id');
      await _db.delete(id);
    } catch (e, s) {
      _logger.severe("Failed to delete memory share $id", e, s);
      rethrow;
    }
  }

  Future<EnteFile?> _parsePublicMemoryFile(
    dynamic rawFile,
    Uint8List shareKey,
  ) async {
    final item = _toMap(rawFile);
    final remoteFile = _toMap(item?['file']);
    if (item == null || remoteFile == null) {
      return null;
    }
    try {
      final file = EnteFile();
      file.uploadedFileID = _toInt(remoteFile['id']);
      file.collectionID = _toInt(remoteFile['collectionID']);
      file.ownerID = _toInt(remoteFile['ownerID']);
      // /public-memory/files returns per-share re-encrypted key material at the
      // top level. Fall back to nested fields for compatibility.
      file.encryptedKey = item['encryptedKey'] as String? ??
          remoteFile['encryptedKey'] as String?;
      file.keyDecryptionNonce = item['keyDecryptionNonce'] as String? ??
          remoteFile['keyDecryptionNonce'] as String?;
      final collectionAddedAt = _toInt(remoteFile['collectionAddedAt']);
      if (collectionAddedAt != null) {
        file.addedTime = collectionAddedAt;
      }

      final fileData = _toMap(remoteFile['file']);
      final thumbnailData = _toMap(remoteFile['thumbnail']);
      final metadataData = _toMap(remoteFile['metadata']);
      if (fileData == null || thumbnailData == null || metadataData == null) {
        return null;
      }

      file.fileDecryptionHeader = fileData['decryptionHeader'] as String?;
      file.thumbnailDecryptionHeader =
          thumbnailData['decryptionHeader'] as String?;
      file.metadataDecryptionHeader =
          metadataData['decryptionHeader'] as String?;

      final info = _toMap(remoteFile['info']);
      if (info != null) {
        file.fileSize = _toInt(info['fileSize']);
      }

      if (file.encryptedKey == null ||
          file.keyDecryptionNonce == null ||
          file.metadataDecryptionHeader == null) {
        return null;
      }

      final encryptedMetadata = metadataData['encryptedData'] as String?;
      if (encryptedMetadata == null) {
        return null;
      }

      final fileKey = CryptoUtil.decryptSync(
        CryptoUtil.base642bin(file.encryptedKey!),
        shareKey,
        CryptoUtil.base642bin(file.keyDecryptionNonce!),
      );
      final encodedMetadata = await CryptoUtil.decryptChaCha(
        CryptoUtil.base642bin(encryptedMetadata),
        fileKey,
        CryptoUtil.base642bin(file.metadataDecryptionHeader!),
      );
      final decodedMetadata = jsonDecode(utf8.decode(encodedMetadata));
      if (decodedMetadata is! Map) {
        return null;
      }
      file.applyMetadata(Map<String, dynamic>.from(decodedMetadata));

      final pubMagicMetadata = _toMap(remoteFile['pubMagicMetadata']);
      if (pubMagicMetadata != null) {
        final data = pubMagicMetadata['data'] as String?;
        final header = pubMagicMetadata['header'] as String?;
        if (data != null && header != null) {
          final utfEncodedMmd = await CryptoUtil.decryptChaCha(
            CryptoUtil.base642bin(data),
            fileKey,
            CryptoUtil.base642bin(header),
          );
          file.pubMmdEncodedJson = utf8.decode(utfEncodedMmd);
          file.pubMmdVersion = _toInt(pubMagicMetadata['version']) ?? 0;
          file.pubMagicMetadata =
              PubMagicMetadata.fromEncodedJson(file.pubMmdEncodedJson!);
        }
      }

      file.localID = null;
      if ((file.collectionID ?? 0) <= 0) {
        return null;
      }
      return file;
    } catch (e, s) {
      _logger.warning("Failed to parse public memory file", e, s);
      return null;
    }
  }

  Future<_MemoryShareSecretPayload> _prepareShareSecret() async {
    try {
      final memoryEntityKey =
          await entityService.getOrCreateEntityKey(EntityType.memory);
      final secret = _generateBase62Secret(_shortFragmentSecretLength);
      final shareKey = _deriveShareKeyFromSecret(secret);
      final encryptedSecret = CryptoUtil.encryptSync(
        Uint8List.fromList(utf8.encode(secret)),
        memoryEntityKey,
      );
      return _MemoryShareSecretPayload(
        secret: secret,
        shareKey: shareKey,
        encryptedShareSecret:
            CryptoUtil.bin2base64(encryptedSecret.encryptedData!),
        encryptedShareSecretNonce:
            CryptoUtil.bin2base64(encryptedSecret.nonce!),
      );
    } catch (e, s) {
      _logger.severe("Failed to prepare memory share secret", e, s);
      rethrow;
    }
  }

  String? _resolveFragmentSecret(
    MemoryShare share,
    Uint8List memoryEntityKey,
  ) {
    try {
      final decrypted = CryptoUtil.decryptSync(
        CryptoUtil.base642bin(share.encryptedKey),
        memoryEntityKey,
        CryptoUtil.base642bin(share.keyDecryptionNonce),
      );
      return _tryDecodeShortFragmentSecret(decrypted);
    } catch (e, s) {
      _logger.severe(
        "Failed to resolve memory share fragment secret for share ${share.id}",
        e,
        s,
      );
      return null;
    }
  }

  String? _tryDecodeShortFragmentSecret(Uint8List value) {
    if (value.length != _shortFragmentSecretLength) {
      return null;
    }
    try {
      final secret = utf8.decode(value);
      if (_base62SecretPattern.hasMatch(secret)) {
        return secret;
      }
    } catch (e, s) {
      _logger.severe("Failed to decode memory share fragment secret", e, s);
      return null;
    }
    return null;
  }

  Uint8List _resolveShareKeyFromUrlFragment(String fragment) {
    if (!_base62SecretPattern.hasMatch(fragment)) {
      throw const FormatException("Invalid memory share fragment");
    }
    return _deriveShareKeyFromSecret(fragment);
  }

  Uint8List _deriveShareKeyFromSecret(String secret) {
    final digest = sha256.convert(utf8.encode(secret));
    return Uint8List.fromList(digest.bytes);
  }

  String _generateBase62Secret(int length) {
    const charset =
        "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
    final random = Random.secure();
    final buffer = StringBuffer();
    for (var i = 0; i < length; i++) {
      buffer.write(charset[random.nextInt(charset.length)]);
    }
    return buffer.toString();
  }

  String _extractAccessToken(Uri uri) {
    final tokenFromQuery = uri.queryParameters["t"];
    if (tokenFromQuery != null && tokenFromQuery.isNotEmpty) {
      return tokenFromQuery;
    }
    for (final segment in uri.pathSegments) {
      if (segment.isNotEmpty && segment != "memory") {
        return segment;
      }
    }
    throw const FormatException("Invalid memory share URL");
  }

  Map<String, dynamic>? _toMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  int? _toInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  Future<List<EnteFile>> _buildDebugDummyMemoryFiles({
    int limit = 12,
  }) async {
    try {
      final localFiles = await FilesDB.instance.getAllFilesFromDB(
        const {},
      );
      if (localFiles.isEmpty) {
        return [];
      }
      final usableFiles = localFiles
          .where(
            (file) =>
                file.generatedID != null &&
                file.creationTime != null &&
                file.creationTime! > 0,
          )
          .take(limit)
          .toList();
      if (usableFiles.isEmpty) {
        return [];
      }
      return List<EnteFile>.generate(
        usableFiles.length,
        (index) => usableFiles[index].copyWith(
          title: "Dummy Memory File ${index + 1}",
        ),
      );
    } catch (e, s) {
      _logger.warning("Failed to build debug dummy memory files", e, s);
      return [];
    }
  }

  Future<(String, int?)> createMemoryShareLinkData({
    required List<Memory> memories,
    required String title,
    String? memoryId,
  }) async {
    try {
      final shareUrl = await shareMemories(
        memories: memories,
        title: title,
        memoryId: memoryId,
      );
      var memoryShare = await findMemoryShareByUrl(shareUrl);
      if (memoryShare == null) {
        await listMemoryShares();
        memoryShare = await findMemoryShareByUrl(shareUrl);
      }
      return (shareUrl, memoryShare?.id);
    } catch (e, s) {
      _logger.severe("Failed to create memory share link data", e, s);
      rethrow;
    }
  }

  Future<MemoryShare?> findMemoryShareByUrl(String shareUrl) async {
    try {
      final shares = await getLocalMemoryShares();
      final shareUri = Uri.parse(shareUrl);
      final linkWithoutFragment = shareUri.replace(fragment: "").toString();
      for (final share in shares) {
        if (share.url == shareUrl) {
          return share;
        }
        final shareUriWithoutFragment =
            Uri.parse(share.url).replace(fragment: "").toString();
        if (shareUriWithoutFragment == linkWithoutFragment) {
          return share;
        }
      }
      return null;
    } catch (e, s) {
      _logger.severe("Failed to find memory share by URL", e, s);
      rethrow;
    }
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

class _MemoryShareSecretPayload {
  final String secret;
  final Uint8List shareKey;
  final String encryptedShareSecret;
  final String encryptedShareSecretNonce;

  const _MemoryShareSecretPayload({
    required this.secret,
    required this.shareKey,
    required this.encryptedShareSecret,
    required this.encryptedShareSecretNonce,
  });

  Map<String, dynamic> metadata() {
    return {
      'encryptedKey': encryptedShareSecret,
      'keyDecryptionNonce': encryptedShareSecretNonce,
    };
  }
}
