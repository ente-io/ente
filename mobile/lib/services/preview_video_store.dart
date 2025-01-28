import "dart:async";
import "dart:io";

import "package:dio/dio.dart";
import "package:encrypt/encrypt.dart" as enc;
import "package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit.dart";
import "package:ffmpeg_kit_flutter_full_gpl/ffmpeg_session.dart";
import "package:ffmpeg_kit_flutter_full_gpl/return_code.dart";
import "package:flutter/foundation.dart";
// import "package:flutter/wid.dart";
import "package:flutter/widgets.dart";
import "package:flutter_cache_manager/flutter_cache_manager.dart";
import "package:logging/logging.dart";
import "package:path_provider/path_provider.dart";
import "package:photos/core/cache/video_cache_manager.dart";
import "package:photos/core/configuration.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/core/network/network.dart";
import "package:photos/events/video_streaming_changed.dart";
import "package:photos/models/base/id.dart";
import "package:photos/models/ffmpeg/ffprobe_props.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/file/file_type.dart";
import "package:photos/services/filedata/filedata_service.dart";
import "package:photos/utils/exif_util.dart";
import "package:photos/utils/file_key.dart";
import "package:photos/utils/file_util.dart";
import "package:photos/utils/gzip.dart";
import "package:photos/utils/toast_util.dart";
import "package:shared_preferences/shared_preferences.dart";

class PreviewVideoStore {
  PreviewVideoStore._privateConstructor();

  static final PreviewVideoStore instance =
      PreviewVideoStore._privateConstructor();

  final _logger = Logger("PreviewVideoStore");
  final cacheManager = DefaultCacheManager();
  final videoCacheManager = VideoCacheManager.instance;

  final files = <EnteFile>{};
  bool isUploading = false;

  final _dio = NetworkClient.instance.enteDio;

  void init(SharedPreferences prefs) {
    _prefs = prefs;
  }

  late final SharedPreferences _prefs;
  static const String _videoStreamingEnabled = "videoStreamingEnabled";
  static const String _videoStreamingCutoff = "videoStreamingCutoff";

  bool get isVideoStreamingEnabled {
    return _prefs.getBool(_videoStreamingEnabled) ?? false;
  }

  Future<void> setIsVideoStreamingEnabled(bool value) async {
    final oneMonthBack = DateTime.now().subtract(const Duration(days: 30));
    await _prefs.setBool(_videoStreamingEnabled, value);
    await _prefs.setInt(
      _videoStreamingCutoff,
      oneMonthBack.millisecondsSinceEpoch,
    );
    Bus.instance.fire(VideoStreamingChanged());
  }

  Future<DateTime?> get videoStreamingCutoff async {
    final milliseconds = _prefs.getInt(_videoStreamingCutoff);
    if (milliseconds == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(milliseconds);
  }

  Future<void> chunkAndUploadVideo(BuildContext? ctx, EnteFile enteFile) async {
    if (!enteFile.isUploaded || !isVideoStreamingEnabled) return;
    final file = await getFile(enteFile, isOrigin: true);
    if (file == null) return;

    try {
      // check if playlist already exist
      await getPlaylist(enteFile);
      final resultUrl = await getPreviewUrl(enteFile);
      if (ctx != null && ctx.mounted) {
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

    final fileSize = file.lengthSync();
    FFProbeProps? props;

    if (fileSize <= 10 * 1024 * 1024) {
      props = await getVideoPropsAsync(file);
      final codec = props?.propData?["codec"].toString().toLowerCase();
      if (codec == "h264") {
        return;
      }
    }
    if (isUploading) {
      files.add(enteFile);
      return;
    }

    props ??= await getVideoPropsAsync(file);

    final codec = props?.propData?["codec"]?.toString().toLowerCase();
    final bitrate = int.tryParse(props?.bitrate ?? "");

    final String tempDir = Configuration.instance.getTempDirectory();
    final String prefix =
        "${tempDir}_${enteFile.uploadedFileID}_${newID("pv")}";
    Directory(prefix).createSync();
    _logger.info('Compressing video ${enteFile.displayName}');
    final key = enc.Key.fromLength(16);

    final keyfile = File('$prefix/keyfile.key');
    keyfile.writeAsBytesSync(key.bytes);

    final keyinfo = File('$prefix/mykey.keyinfo');
    keyinfo.writeAsStringSync("data:text/plain;base64,${key.base64}\n"
        "${keyfile.path}\n");
    _logger.info(
      'Generating HLS Playlist ${enteFile.displayName} at $prefix/output.m3u8}',
    );

    FFmpegSession? session;
    if (bitrate != null && bitrate <= 4000 * 1000 && codec == "h264") {
      // create playlist without compression, as is
      session = await FFmpegKit.execute(
        '-i "${file.path}" '
        '-metadata:s:v:0 rotate=0 ' // Adjust metadata if needed
        '-c:v copy ' // Copy the original video codec
        '-c:a copy ' // Copy the original audio codec
        '-f hls -hls_time 10 -hls_flags single_file '
        '-hls_list_size 0 -hls_key_info_file ${keyinfo.path} '
        '$prefix/output.m3u8',
      );
    } else if (bitrate != null &&
        codec != null &&
        bitrate <= 2000 * 1000 &&
        codec != "h264") {
      // compress video with crf=21, h264 no change in resolution or frame rate,
      // just change color scheme
      session = await FFmpegKit.execute(
        '-i "${file.path}" '
        '-metadata:s:v:0 rotate=0 ' // Keep rotation metadata
        '-vf "format=yuv420p10le,zscale=transfer=linear,tonemap=tonemap=hable:desat=0:peak=10,zscale=transfer=bt709:matrix=bt709:primaries=bt709,format=yuv420p" ' // Adjust color scheme
        '-color_primaries bt709 -color_trc bt709 -colorspace bt709 ' // Set color profile to BT.709
        '-c:v libx264 -crf 21 -preset medium ' // Compress with CRF=21 using H.264
        '-c:a copy ' // Keep original audio
        '-f hls -hls_time 10 -hls_flags single_file '
        '-hls_list_size 0 -hls_key_info_file ${keyinfo.path} '
        '$prefix/output.m3u8',
      );
    }

    session ??= await FFmpegKit.execute(
      '-i "${file.path}" '
      '-metadata:s:v:0 rotate=0 '
      '-vf "scale=-2:720,fps=30,format=yuv420p10le,zscale=transfer=linear,tonemap=tonemap=hable:desat=0:peak=10,zscale=transfer=bt709:matrix=bt709:primaries=bt709,format=yuv420p" '
      '-color_primaries bt709 -color_trc bt709 -colorspace bt709 '
      '-x264-params "colorprim=bt709:transfer=bt709:colormatrix=bt709" '
      '-c:v libx264 -b:v 2000k -preset medium '
      '-c:a aac -b:a 128k -f hls -hls_time 10 -hls_flags single_file '
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

    isUploading = false;
    if (files.isNotEmpty) {
      final file = files.first;
      files.remove(file);
      await chunkAndUploadVideo(ctx, file);
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
          FileDataService.instance.previewIds![file.uploadedFileID!]?.objectId;
      final FileInfo? playlistCache = (objectKey == null)
          ? null
          : await cacheManager.getFileFromCache(_getCacheKey(objectKey));
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
        if (objectKey != null) {
          unawaited(
            cacheManager.putFile(
              _getCacheKey(objectKey),
              Uint8List.fromList(
                (playlistData["playlist"] as String).codeUnits,
              ),
            ),
          );
        }
      }

      final videoFile = objectKey == null
          ? null
          : (await videoCacheManager
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
        if (objectKey != null) {
          unawaited(
            downloadAndCacheVideo(
              previewURL,
              _getVideoPreviewKey(objectKey),
            ),
          );
        }
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
