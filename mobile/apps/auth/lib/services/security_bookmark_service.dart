import 'dart:io';

import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

/// Service for managing iOS security-scoped bookmarks.
///
/// On iOS, when a user picks a directory outside the app sandbox,
/// the app receives temporary security-scoped access. To persist
/// this access across app launches, we must create a bookmark.
class SecurityBookmarkService {
  SecurityBookmarkService._();

  static final SecurityBookmarkService instance = SecurityBookmarkService._();
  static const _channel = MethodChannel('io.ente.auth/security_bookmark');
  final _logger = Logger('SecurityBookmarkService');

  /// Opens native iOS directory picker and creates a bookmark immediately.
  ///
  /// Returns a [DirectoryPickResult] with both path and bookmark, or null if cancelled.
  /// This is the preferred method on iOS as it creates the bookmark while we still
  /// have the security-scoped URL from the picker.
  Future<DirectoryPickResult?> pickDirectoryAndCreateBookmark() async {
    if (!Platform.isIOS) return null;

    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'pickDirectoryAndCreateBookmark',
      );
      if (result == null) {
        _logger.info('Directory picker cancelled');
        return null;
      }

      final path = result['path'] as String?;
      final bookmark = result['bookmark'] as String?;

      if (path == null || bookmark == null) {
        _logger.severe('Invalid result from directory picker');
        return null;
      }

      _logger
          .info('Picked directory: $path, bookmark length: ${bookmark.length}');
      return DirectoryPickResult(path: path, bookmark: bookmark);
    } on PlatformException catch (e) {
      _logger.severe('Failed to pick directory: ${e.message}');
      return null;
    }
  }

  /// Creates a security-scoped bookmark for the given directory path.
  ///
  /// NOTE: This typically doesn't work on iOS because the path from FilePicker
  /// doesn't have security-scoped access. Use [pickDirectoryAndCreateBookmark] instead.
  ///
  /// Returns the bookmark as a base64-encoded string, or null on failure.
  Future<String?> createBookmark(String directoryPath) async {
    if (!Platform.isIOS) return null;

    try {
      final result = await _channel.invokeMethod<String>(
        'createBookmark',
        {'path': directoryPath},
      );
      _logger.info('Created bookmark for: $directoryPath');
      return result;
    } on PlatformException catch (e) {
      _logger.severe('Failed to create bookmark: ${e.message}');
      return null;
    }
  }

  /// Resolves a bookmark to get the directory path.
  ///
  /// Returns a [BookmarkResolveResult] with the path and stale status.
  /// If the bookmark is stale (directory was moved/renamed), you should
  /// prompt the user to re-select the directory.
  Future<BookmarkResolveResult?> resolveBookmark(String bookmark) async {
    if (!Platform.isIOS) return null;

    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'resolveBookmark',
        {'bookmark': bookmark},
      );
      if (result == null) return null;

      return BookmarkResolveResult(
        path: result['path'] as String,
        isStale: result['isStale'] as bool,
      );
    } on PlatformException catch (e) {
      _logger.severe('Failed to resolve bookmark: ${e.message}');
      return null;
    }
  }

  /// Starts accessing a security-scoped resource using a stored bookmark.
  ///
  /// Returns a [BookmarkAccessResult] containing the success status,
  /// resolved path, and whether the bookmark is stale.
  ///
  /// You MUST call [stopAccessingBookmark] when done to balance the call.
  Future<BookmarkAccessResult?> startAccessingBookmark(String bookmark) async {
    if (!Platform.isIOS) return null;

    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'startAccessingBookmark',
        {'bookmark': bookmark},
      );
      if (result == null) return null;

      final accessResult = BookmarkAccessResult(
        success: result['success'] as bool,
        path: result['path'] as String,
        isStale: result['isStale'] as bool,
      );
      _logger.info(
        'Start accessing bookmark: success=${accessResult.success}, '
        'path=${accessResult.path}, isStale=${accessResult.isStale}',
      );
      return accessResult;
    } on PlatformException catch (e) {
      _logger.severe('Failed to start accessing bookmark: ${e.message}');
      return null;
    }
  }

  /// Stops accessing a security-scoped resource.
  ///
  /// Always call this after you're done with file operations to
  /// balance the [startAccessingBookmark] call.
  Future<bool> stopAccessingBookmark(String bookmark) async {
    if (!Platform.isIOS) return true;

    try {
      final result = await _channel.invokeMethod<bool>(
        'stopAccessingBookmark',
        {'bookmark': bookmark},
      );
      _logger.info('Stopped accessing bookmark');
      return result ?? false;
    } on PlatformException catch (e) {
      _logger.severe('Failed to stop accessing bookmark: ${e.message}');
      return false;
    }
  }
}

class DirectoryPickResult {
  const DirectoryPickResult({
    required this.path,
    required this.bookmark,
  });

  final String path;
  final String bookmark;
}

class BookmarkResolveResult {
  const BookmarkResolveResult({
    required this.path,
    required this.isStale,
  });

  final String path;
  final bool isStale;
}

class BookmarkAccessResult {
  const BookmarkAccessResult({
    required this.success,
    required this.path,
    required this.isStale,
  });

  final bool success;
  final String path;
  final bool isStale;
}
