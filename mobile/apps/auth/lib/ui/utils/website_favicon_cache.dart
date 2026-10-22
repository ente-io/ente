import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:image/image.dart' as image;
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WebsiteFaviconCache {
  WebsiteFaviconCache._();

  static final WebsiteFaviconCache instance = WebsiteFaviconCache._();
  static const Duration _cacheDuration = Duration(days: 1);
  static const String _resolutionPrefix = 'auth_favicon_resolution_v1_';

  final CacheManager _cache = CacheManager(
    Config(
      'auth-website-favicons-v1',
      stalePeriod: _cacheDuration,
      maxNrOfCacheObjects: 500,
    ),
  );
  final Map<String, Future<CachedFavicon?>> _pending = {};
  final Logger _logger = Logger('WebsiteFaviconCache');

  Future<CachedFavicon?> getFavicon(String websiteUrl) {
    final website = Uri.tryParse(websiteUrl);
    if (website == null ||
        (website.scheme != 'http' && website.scheme != 'https') ||
        website.host.isEmpty ||
        website.userInfo.isNotEmpty) {
      return Future.value(null);
    }

    // Strip query and fragment data; neither is needed to identify the site's
    // favicon and should be sent in the page request.
    final pageUri = Uri(
      scheme: website.scheme,
      host: website.host,
      port: website.hasPort ? website.port : null,
      path: website.path.isEmpty ? '/' : website.path,
    );
    final key = pageUri.toString();
    final pending = _pending[key];
    if (pending != null) return pending;
    final future = _resolveFavicon(pageUri).whenComplete(() {
      _pending.remove(key);
    });
    _pending[key] = future;
    return future;
  }

  Future<CachedFavicon?> _resolveFavicon(Uri pageUri) async {
    final prefs = await SharedPreferences.getInstance();
    final preferenceKey =
        '$_resolutionPrefix${base64Url.encode(utf8.encode(pageUri.toString()))}';
    final cachedResolution = _readResolution(prefs.getString(preferenceKey));
    final now = DateTime.now();

    if (cachedResolution != null &&
        now.difference(cachedResolution.checkedAt) < _cacheDuration) {
      final iconUrl = cachedResolution.iconUrl;
      if (iconUrl == null) return null;
      final cachedFile = await _cache.getFileFromCache(iconUrl);
      final cachedIcon = cachedFile == null
          ? null
          : await _decodeFile(cachedFile.file);
      if (cachedIcon != null) return cachedIcon;
      // Do not retry a missing or invalid icon until the 24-hour lookup period
      // expires. This also avoids hammering sites that temporarily fail.
      return null;
    }

    final candidates = <Uri>[];
    final pageFile = await _tryGetFile(pageUri.toString());
    if (pageFile != null) {
      candidates.addAll(await _extractIconLinks(pageUri, pageFile));
    }

    final origin = Uri(
      scheme: pageUri.scheme,
      host: pageUri.host,
      port: pageUri.hasPort ? pageUri.port : null,
    );
    final path = pageUri.path.toLowerCase();
    if (path.endsWith('.ico') ||
        path.endsWith('.png') ||
        path.endsWith('.svg') ||
        path.endsWith('.jpg') ||
        path.endsWith('.jpeg') ||
        path.endsWith('.webp')) {
      candidates.add(pageUri);
    }
    candidates.add(origin.resolve('/favicon.ico'));

    final seen = <String>{};
    for (final candidate in candidates) {
      if (!_isSafeWebUri(candidate) || !seen.add(candidate.toString())) {
        continue;
      }
      final favicon = await _downloadAndDecode(candidate.toString());
      if (favicon != null) {
        await _storeResolution(prefs, preferenceKey, candidate.toString());
        return favicon;
      }
    }

    await _storeResolution(prefs, preferenceKey, null);
    return null;
  }

  Future<File?> _tryGetFile(String url) async {
    try {
      return await _cache.getSingleFile(url);
    } catch (error, stackTrace) {
      _logger.fine('Could not load favicon page $url', error, stackTrace);
      return null;
    }
  }

  Future<List<Uri>> _extractIconLinks(Uri pageUri, File pageFile) async {
    try {
      final bytes = await pageFile.readAsBytes();
      if (bytes.length > 2 * 1024 * 1024) return const [];
      final document = html_parser.parse(
        utf8.decode(bytes, allowMalformed: true),
      );
      final candidates = <Uri>[];
      for (final link in document.querySelectorAll('link[href][rel]')) {
        final rel = (link.attributes['rel'] ?? '').toLowerCase();
        if (!rel.contains('icon')) continue;
        final href = link.attributes['href']?.trim();
        if (href == null || href.isEmpty) continue;
        final uri = Uri.tryParse(href);
        if (uri == null) continue;
        final resolved = pageUri.resolveUri(uri);
        if (_isSafeWebUri(resolved)) candidates.add(resolved);
      }
      return candidates;
    } catch (error, stackTrace) {
      _logger.fine(
        'Could not parse favicon links for $pageUri',
        error,
        stackTrace,
      );
      return const [];
    }
  }

  Future<CachedFavicon?> _downloadAndDecode(String url) async {
    try {
      final file = await _cache.getSingleFile(url);
      return await _decodeFile(file);
    } catch (error, stackTrace) {
      _logger.fine('Could not load website favicon $url', error, stackTrace);
      return null;
    }
  }

  Future<CachedFavicon?> _decodeFile(File file) async {
    try {
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty || bytes.length > 5 * 1024 * 1024) return null;

      final prefix = utf8.decode(
        bytes.take(512).toList(),
        allowMalformed: true,
      );
      if (prefix.contains('<svg')) {
        return CachedFavicon(file: file, isSvg: true);
      }

      final decoded = image.decodeImage(bytes);
      if (decoded == null || decoded.width > 1024 || decoded.height > 1024) {
        return null;
      }

      final isIco =
          bytes.length >= 4 &&
          bytes[0] == 0 &&
          bytes[1] == 0 &&
          bytes[2] == 1 &&
          bytes[3] == 0;
      return isIco
          ? CachedFavicon(bytes: Uint8List.fromList(image.encodePng(decoded)))
          : CachedFavicon(file: file);
    } catch (error, stackTrace) {
      _logger.fine(
        'Could not decode website favicon ${file.path}',
        error,
        stackTrace,
      );
      return null;
    }
  }

  bool _isSafeWebUri(Uri uri) =>
      (uri.scheme == 'http' || uri.scheme == 'https') &&
      uri.host.isNotEmpty &&
      uri.userInfo.isEmpty;

  _CachedResolution? _readResolution(String? value) {
    if (value == null) return null;
    try {
      final json = jsonDecode(value) as Map<String, dynamic>;
      return _CachedResolution(
        checkedAt: DateTime.fromMillisecondsSinceEpoch(
          json['checkedAt'] as int,
        ),
        iconUrl: json['iconUrl'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _storeResolution(
    SharedPreferences prefs,
    String key,
    String? iconUrl,
  ) async {
    try {
      await prefs.setString(
        key,
        jsonEncode({
          'checkedAt': DateTime.now().millisecondsSinceEpoch,
          'iconUrl': iconUrl,
        }),
      );
    } catch (error, stackTrace) {
      _logger.fine('Could not cache favicon resolution', error, stackTrace);
    }
  }
}

class CachedFavicon {
  final File? file;
  final Uint8List? bytes;
  final bool isSvg;

  const CachedFavicon({this.file, this.bytes, this.isSvg = false});
}

class _CachedResolution {
  final DateTime checkedAt;
  final String? iconUrl;

  const _CachedResolution({required this.checkedAt, required this.iconUrl});
}
