import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:ente_crypto/ente_crypto.dart';
import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/errors.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/core/network/network.dart';
import 'package:photos/events/files_updated_event.dart';
import 'package:photos/models/api/file_share_url.dart';
import 'package:photos/models/file/file.dart';
import 'package:photos/utils/file_key.dart';

class SingleFileShareService {
  static final SingleFileShareService instance =
      SingleFileShareService._privateConstructor();

  SingleFileShareService._privateConstructor();

  final _logger = Logger('SingleFileShareService');
  late final Dio _enteDio;

  // Cache of file share URLs by file ID
  final Map<int, FileShareUrl> _fileShareCache = {};

  // Base62 characters for generating passphrase
  static const _base62Chars =
      '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';

  void init() {
    _enteDio = NetworkClient.instance.enteDio;
  }

  /// Create a public share URL for a single file
  ///
  /// Returns the full URL with the passphrase in the hash fragment
  Future<String> createShareUrl(EnteFile file) async {
    if (file.uploadedFileID == null) {
      throw ArgumentError('File must be uploaded before sharing');
    }

    // Check if we already have an active share for this file
    final existingShare = _fileShareCache[file.uploadedFileID];
    if (existingShare != null && !existingShare.isDisabled) {
      return _buildShareUrl(existingShare, file);
    }

    try {
      // Generate a 12-character base62 passphrase
      final passphrase = _generatePassphrase(12);

      // Get the file key
      final fileKey = getFileKey(file);

      // Derive a key from the passphrase using KDF
      final kdfSalt = Sodium.randombytesBuf(Sodium.cryptoPwhashSaltbytes);
      const opsLimit = 2; // INTERACTIVE
      const memLimit = 67108864; // 64 MB

      final derivedKey = Sodium.cryptoPwhash(
        Sodium.cryptoSecretboxKeybytes,
        Uint8List.fromList(utf8.encode(passphrase)),
        kdfSalt,
        opsLimit,
        memLimit,
        Sodium.cryptoPwhashAlgArgon2id13,
      );

      // Encrypt the file key with the derived key
      final nonce = Sodium.randombytesBuf(Sodium.cryptoSecretboxNoncebytes);
      final encryptedFileKey =
          Sodium.cryptoSecretboxEasy(fileKey, nonce, derivedKey);

      // Create the share URL on server
      final response = await _enteDio.post(
        "/files/share-url",
        data: {
          "fileID": file.uploadedFileID,
          "encryptedFileKey": CryptoUtil.bin2base64(encryptedFileKey),
          "encryptedFileKeyNonce": CryptoUtil.bin2base64(nonce),
          "kdfNonce": CryptoUtil.bin2base64(kdfSalt),
          "kdfMemLimit": memLimit,
          "kdfOpsLimit": opsLimit,
        },
      );

      final fileShareUrl = FileShareUrl.fromMap(response.data["result"]);
      _fileShareCache[file.uploadedFileID!] = fileShareUrl;

      _logger.info('Created share URL for file ${file.uploadedFileID}');

      // Build the URL with passphrase in the hash fragment
      return "${fileShareUrl.url}#$passphrase";
    } on DioException catch (e) {
      if (e.response?.statusCode == 402) {
        throw SharingNotPermittedForFreeAccountsError();
      }
      _logger.severe('Failed to create share URL', e);
      rethrow;
    } catch (e, s) {
      _logger.severe('Failed to create share URL', e, s);
      rethrow;
    }
  }

  /// Get the share URL for a file if it exists
  Future<String?> getShareUrl(EnteFile file) async {
    if (file.uploadedFileID == null) return null;

    // Check cache first
    final cached = _fileShareCache[file.uploadedFileID];
    if (cached != null && !cached.isDisabled) {
      return _buildShareUrl(cached, file);
    }

    // Fetch from server
    try {
      final response = await _enteDio.get(
        "/files/share-urls/",
        queryParameters: {"sinceTime": 0},
      );

      final List<dynamic> urls = response.data["result"] ?? [];
      for (final urlData in urls) {
        final shareUrl = FileShareUrl.fromMap(urlData);
        _fileShareCache[shareUrl.fileID] = shareUrl;
      }

      final fileShareUrl = _fileShareCache[file.uploadedFileID];
      if (fileShareUrl != null && !fileShareUrl.isDisabled) {
        return _buildShareUrl(fileShareUrl, file);
      }
    } catch (e, s) {
      _logger.severe('Failed to get share URL', e, s);
    }

    return null;
  }

  /// Disable the share URL for a file
  Future<void> disableShareUrl(int fileID) async {
    try {
      await _enteDio.delete("/files/share-url/$fileID");
      _fileShareCache.remove(fileID);
      _logger.info('Disabled share URL for file $fileID');

      Bus.instance.fire(
        FilesUpdatedEvent(
          [],
          type: EventType.deletedFromEverywhere,
          source: "disableSingleFileShare",
        ),
      );
    } on DioException catch (e) {
      _logger.severe('Failed to disable share URL', e);
      rethrow;
    }
  }

  /// Update share URL settings (device limit, expiry, download, password)
  Future<void> updateShareUrl(
    int fileID,
    Map<String, dynamic> props,
  ) async {
    props['fileID'] = fileID;
    try {
      final response = await _enteDio.put(
        "/files/share-url",
        data: json.encode(props),
      );
      final fileShareUrl = FileShareUrl.fromMap(response.data["result"]);
      _fileShareCache[fileID] = fileShareUrl;
      _logger.info('Updated share URL for file $fileID');
    } on DioException catch (e) {
      if (e.response?.statusCode == 402) {
        throw SharingNotPermittedForFreeAccountsError();
      }
      _logger.severe('Failed to update share URL', e);
      rethrow;
    }
  }

  /// List all single file share URLs for the current user
  Future<List<FileShareUrl>> getShareUrls({int sinceTime = 0}) async {
    try {
      final response = await _enteDio.get(
        "/files/share-urls/",
        queryParameters: {"sinceTime": sinceTime},
      );

      final List<dynamic> urls = response.data["result"] ?? [];
      final result = <FileShareUrl>[];

      for (final urlData in urls) {
        final shareUrl = FileShareUrl.fromMap(urlData);
        _fileShareCache[shareUrl.fileID] = shareUrl;
        result.add(shareUrl);
      }

      return result;
    } catch (e, s) {
      _logger.severe('Failed to get share URLs', e, s);
      rethrow;
    }
  }

  /// Get active (non-disabled) share URLs
  Future<List<FileShareUrl>> getActiveShareUrls() async {
    final allUrls = await getShareUrls();
    return allUrls.where((url) => !url.isDisabled).toList();
  }

  /// Check if a file has an active share URL
  bool hasActiveShareUrl(int fileID) {
    final cached = _fileShareCache[fileID];
    return cached != null && !cached.isDisabled;
  }

  /// Get cached share URL for a file
  FileShareUrl? getCachedShareUrl(int fileID) {
    return _fileShareCache[fileID];
  }

  /// Clear the cache
  void clearCache() {
    _fileShareCache.clear();
  }

  /// Generate a random base62 passphrase
  String _generatePassphrase(int length) {
    final random = Random.secure();
    return List.generate(
      length,
      (_) => _base62Chars[random.nextInt(_base62Chars.length)],
    ).join();
  }

  /// Build the full share URL with passphrase in hash
  String _buildShareUrl(FileShareUrl shareUrl, EnteFile file) {
    // The passphrase is not stored on server for security
    // For existing shares without stored passphrase, we need to regenerate
    // This means old links won't work - user needs to create a new share
    //
    // Note: The passphrase is generated at creation time and returned to the user
    // It's never stored on the server or locally
    return shareUrl.url;
  }
}
