import "dart:async";
import "dart:io";

import "package:dio/dio.dart";
import "package:encrypt/encrypt.dart" as enc;
import "package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit.dart";
import "package:ffmpeg_kit_flutter_full_gpl/return_code.dart";
import "package:flutter/foundation.dart";
// import "package:flutter/wid.dart";
import "package:flutter/widgets.dart";
import "package:flutter_cache_manager/flutter_cache_manager.dart";
import "package:logging/logging.dart";
import "package:path_provider/path_provider.dart";
import "package:photos/core/cache/video_cache_manager.dart";
import "package:photos/core/configuration.dart";
import "package:photos/core/network/network.dart";
import "package:photos/models/base/id.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/file/file_type.dart";
import "package:photos/services/filedata/filedata_service.dart";
import "package:photos/utils/file_key.dart";
import "package:photos/utils/file_util.dart";
import "package:photos/utils/gzip.dart";
import "package:photos/utils/toast_util.dart";
import "package:video_compress/video_compress.dart";

class PreviewVideoStore {
  PreviewVideoStore._privateConstructor();

  static final PreviewVideoStore instance =
      PreviewVideoStore._privateConstructor();

  final _logger = Logger("PreviewVideoStore");
  final cacheManager = DefaultCacheManager();
  final videoCacheManager = VideoCacheManager.instance;
  double _progress = 0;

  final _dio = NetworkClient.instance.enteDio;
  void init() {
    VideoCompress.compressProgress$.subscribe((progress) {
      if (kDebugMode) {
        _progress = progress;
        _logger.info("Compression progress: $progress");
      }
    });
  }

  Future<void> chunkAndUploadVideo(BuildContext ctx, EnteFile enteFile) async {
    if (!enteFile.isUploaded) return;
    final file = await getFile(enteFile, isOrigin: true);
    if (file == null) return;
    try {
      // check if playlist already exist
      await getPlaylist(enteFile);
      final resultUrl = await getPreviewUrl(enteFile);
      if (ctx.mounted) {
        showShortToast(ctx, 'Video preview already exists');
      }
      debugPrint("previewUrl $resultUrl");
      return;
    } catch (e, s) {
      if (e is DioError && e.response?.statusCode == 404) {
        _logger.info("No preview found for $enteFile");
      } else {
        _logger.warning("Failed to get playlist for $enteFile", e, s);
        rethrow;
      }
    }
    if (VideoCompress.isCompressing) {
      showShortToast(
        ctx,
        "Another is being compressed ($_progress %), please wait",
      );
      return;
    }
    final String tempDir = Configuration.instance.getTempDirectory();
    final String prefix =
        "${tempDir}_${enteFile.uploadedFileID}_${newID("pv")}";
    Directory(prefix).createSync();
    _logger.info('Compressing video ${enteFile.displayName}');
    final mediaInfo = await VideoCompress.compressVideo(
      file.path,
      quality: VideoQuality.Res1280x720Quality,
    );
    if (mediaInfo?.path == null) return;
    _logger.info('CompressionDone ${enteFile.displayName}');

    final key = enc.Key.fromLength(16);

    final keyfile = File('$prefix/keyfile.key');
    keyfile.writeAsBytesSync(key.bytes);

    final keyinfo = File('$prefix/mykey.keyinfo');
    keyinfo.writeAsStringSync("data:text/plain;base64,${key.base64}\n"
        "${keyfile.path}\n");
    _logger.info(
      'Generating HLS Playlist ${enteFile.displayName} at $prefix/output.m3u8}',
    );
    final session = await FFmpegKit.execute(
      '-i "${mediaInfo!.path}" '
      '-c copy -f hls -hls_time 10 -hls_flags single_file '
      '-hls_list_size 0 -hls_key_info_file ${keyinfo.path} '
      '$prefix/output.m3u8',
    );

    final returnCode = await session.getReturnCode();

    if (ReturnCode.isSuccess(returnCode)) {
      _logger.info('Playlist Generated ${enteFile.displayName}');
      final playlistFile = File("$prefix/output.m3u8");
      final previewFile = File("$prefix/output.ts");
      final result = await _uploadPreviewVideo(enteFile, previewFile);
      final String objectID = result.$1;
      final objectSize = result.$2;
      await _reportVideoPreview(
        enteFile,
        playlistFile,
        objectID: objectID,
        objectSize: objectSize,
      );
      _logger.info("Video preview uploaded for $enteFile");
    } else if (ReturnCode.isCancel(returnCode)) {
      _logger.warning("FFmpeg command cancelled");
    } else {
      _logger.severe("FFmpeg command failed with return code $returnCode");
      if (kDebugMode) {
        final output = await session.getOutput();
        _logger.severe(output);
      }
    }
  }

  Future<void> _reportVideoPreview(
    EnteFile file,
    File playlist, {
    required String objectID,
    required int objectSize,
  }) async {
    _logger.info("Pushing playlist for ${file.uploadedFileID}");
    try {
      final encryptionKey = getFileKey(file);
      final playlistContent = playlist.readAsStringSync();
      final result = await gzipAndEncryptJson(
        {
          "playlist": playlistContent,
          'type': 'hls_video',
        },
        encryptionKey,
      );
      final _ = await _dio.put(
        "/files/video-data",
        data: {
          "fileID": file.uploadedFileID!,
          "objectID": objectID,
          "objectSize": objectSize,
          "playlist": result.encData,
          "playlistHeader": result.header,
        },
      );
    } catch (e, s) {
      _logger.severe("Failed to report video preview", e, s);
    }
  }

  Future<(String, int)> _uploadPreviewVideo(EnteFile file, File preview) async {
    _logger.info("Pushing preview for $file");
    try {
      final response = await _dio.get(
        "/files/data/preview-upload-url",
        queryParameters: {
          "fileID": file.uploadedFileID!,
          "type": "vid_preview",
        },
      );
      final uploadURL = response.data["url"];
      final String objectID = response.data["objectID"];
      final objectSize = preview.lengthSync();
      final _ = await _dio.put(
        uploadURL,
        data: preview.openRead(),
        options: Options(
          headers: {
            Headers.contentLengthHeader: objectSize,
          },
        ),
      );
      return (objectID, objectSize);
    } catch (e) {
      _logger.warning("failed to upload previewVideo", e);
      rethrow;
    }
  }

  String _getCacheKey(String objectKey) {
    return "video_playlist_$objectKey";
  }

  String _getVideoPreviewKey(String objectKey) {
    return "video_preview_$objectKey";
  }

  Future<File?> getPlaylist(EnteFile file) async {
    return await _getPlaylist(file);
  }

  Future<File?> _getPlaylist(EnteFile file) async {
    _logger.info("Getting playlist for $file");
    try {
      final objectKey =
          FileDataService.instance.previewIds![file.uploadedFileID!]!.objectId;
      final playlistCache =
          await cacheManager.getFileFromCache(_getCacheKey(objectKey));
      String finalPlaylist;
      if (playlistCache != null) {
        finalPlaylist = playlistCache.file.readAsStringSync();
      } else {
        final response = await _dio.get(
          "/files/data/fetch/",
          queryParameters: {
            "fileID": file.uploadedFileID,
            "type": "vid_preview",
          },
        );
        final encryptedData = response.data["data"]["encryptedData"];
        final header = response.data["data"]["decryptionHeader"];
        final encryptionKey = getFileKey(file);
        final playlistData = await decryptAndUnzipJson(
          encryptionKey,
          encryptedData: encryptedData,
          header: header,
        );
        finalPlaylist = playlistData["playlist"];

        unawaited(
          cacheManager.putFile(
            _getCacheKey(objectKey),
            Uint8List.fromList((playlistData["playlist"] as String).codeUnits),
          ),
        );
      }

      final videoFile = (await videoCacheManager
              .getFileFromCache(_getVideoPreviewKey(objectKey)))
          ?.file;
      if (videoFile == null) {
        final response2 = await _dio.get(
          "/files/data/preview",
          queryParameters: {
            "fileID": file.uploadedFileID,
            "type": "vid_preview",
          },
        );
        final previewURL = response2.data["url"];
        unawaited(
          downloadAndCacheVideo(
            previewURL,
            _getVideoPreviewKey(objectKey),
          ),
        );
        finalPlaylist =
            finalPlaylist.replaceAll('\noutput.ts', '\n$previewURL');
      } else {
        finalPlaylist =
            finalPlaylist.replaceAll('\noutput.ts', '\n${videoFile.path}');
      }

      final tempDir = await getTemporaryDirectory();
      final playlistFile = File("${tempDir.path}/${file.uploadedFileID}.m3u8");
      await playlistFile.writeAsString(finalPlaylist);
      _logger.info("Writing playlist to ${playlistFile.path}");

      return playlistFile;
    } catch (_) {
      rethrow;
    }
  }

  Future downloadAndCacheVideo(String url, String key) async {
    final file = await videoCacheManager.downloadFile(url, key: key);
    return file;
  }

  Future<String> getPreviewUrl(EnteFile file) async {
    try {
      final response = await _dio.get(
        "/files/data/preview",
        queryParameters: {
          "fileID": file.uploadedFileID,
          "type":
              file.fileType == FileType.video ? "vid_preview" : "img_preview",
        },
      );
      return response.data["url"];
    } catch (e) {
      _logger.warning("Failed to get preview url", e);
      rethrow;
    }
  }
}
