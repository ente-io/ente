import "dart:async";
import "dart:collection";
import "dart:convert";
import "dart:io";

import "package:collection/collection.dart";
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
import 'package:photos/db/files_db.dart';
import "package:photos/db/upload_locks_db.dart";
import "package:photos/events/preview_updated_event.dart";
import "package:photos/events/video_streaming_changed.dart";
import "package:photos/models/base/id.dart";
import "package:photos/models/ffmpeg/ffprobe_props.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/file/file_type.dart";
import "package:photos/models/preview/playlist_data.dart";
import "package:photos/models/preview/preview_item.dart";
import "package:photos/models/preview/preview_item_status.dart";
import "package:photos/services/filedata/filedata_service.dart";
import "package:photos/ui/notification/toast.dart";
import "package:photos/utils/exif_util.dart";
import "package:photos/utils/file_key.dart";
import "package:photos/utils/file_util.dart";
import "package:photos/utils/gzip.dart";
import "package:photos/utils/network_util.dart";
import "package:shared_preferences/shared_preferences.dart";

const _maxRetryCount = 3;

class PreviewVideoStore {
  final LinkedHashMap<int, PreviewItem> _items = LinkedHashMap();
  LinkedHashMap<int, PreviewItem> get previews => _items;
  Set<int>? _failureFiles;

  bool _initSuccess = false;

  PreviewVideoStore._privateConstructor();

  static final PreviewVideoStore instance =
      PreviewVideoStore._privateConstructor();

  final _logger = Logger("PreviewVideoStore");
  final cacheManager = DefaultCacheManager();
  final videoCacheManager = VideoCacheManager.instance;

  LinkedHashSet<EnteFile> fileQueue = LinkedHashSet();
  int uploadingFileId = -1;

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
    _prefs.setBool(_videoStreamingEnabled, value).ignore();
    _prefs
        .setInt(
          _videoStreamingCutoff,
          oneMonthBack.millisecondsSinceEpoch,
        )
        .ignore();
    Bus.instance.fire(VideoStreamingChanged());

    if (isVideoStreamingEnabled) {
      await FileDataService.instance.syncFDStatus();
      _putFilesForPreviewCreation().ignore();
    } else {
      clearQueue();
    }
  }

  void clearQueue() {
    fileQueue.clear();
    _items.clear();
    Bus.instance.fire(PreviewUpdatedEvent(_items));
  }

  DateTime? get videoStreamingCutoff {
    final milliseconds = _prefs.getInt(_videoStreamingCutoff);
    if (milliseconds == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(milliseconds);
  }

  Future<void> chunkAndUploadVideo(
    BuildContext? ctx,
    EnteFile enteFile, [
    bool forceUpload = false,
  ]) async {
    if (!isVideoStreamingEnabled) {
      clearQueue();
      return;
    }

    Object? error;
    bool removeFile = false;
    try {
      if (!enteFile.isUploaded) {
        removeFile = true;
        return;
      }

      try {
        // check if playlist already exist
        await getPlaylist(enteFile);
        final _ = await getPreviewUrl(enteFile);

        if (ctx != null && ctx.mounted) {
          showShortToast(ctx, 'Video preview already exists');
        }
        removeFile = true;
        return;
      } catch (e, s) {
        if (e is DioException && e.response?.statusCode == 404) {
          _logger.info("No preview found for $enteFile");
        } else {
          _logger.warning("Failed to get playlist for $enteFile", e, s);
          error = e;
          return;
        }
      }

      // elimination case for <=10 MB with H.264
      var (props, result, file) = await _checkFileForPreviewCreation(enteFile);
      if (result) {
        removeFile = true;
        return;
      }

      // check if there is already a preview in processing
      if (uploadingFileId >= 0) {
        if (uploadingFileId == enteFile.uploadedFileID) return;

        _items[enteFile.uploadedFileID!] = PreviewItem(
          status: PreviewItemStatus.inQueue,
          file: enteFile,
          retryCount: forceUpload
              ? 0
              : _items[enteFile.uploadedFileID!]?.retryCount ?? 0,
          collectionID: enteFile.collectionID ?? 0,
        );
        Bus.instance.fire(PreviewUpdatedEvent(_items));
        fileQueue.add(enteFile);
        return;
      }

      // everything is fine, let's process
      uploadingFileId = enteFile.uploadedFileID!;
      _items[enteFile.uploadedFileID!] = PreviewItem(
        status: PreviewItemStatus.compressing,
        file: enteFile,
        retryCount:
            forceUpload ? 0 : _items[enteFile.uploadedFileID!]?.retryCount ?? 0,
        collectionID: enteFile.collectionID ?? 0,
      );
      Bus.instance.fire(PreviewUpdatedEvent(_items));

      // get file
      file ??= await getFile(enteFile, isOrigin: true);
      if (file == null) {
        error = "Unable to fetch file";
        return;
      }

      // check metadata for bitrate, codec, color space
      props ??= await getVideoPropsAsync(file);
      final fileSize = enteFile.fileSize ?? file.lengthSync();

      final videoData = List.from(props?.propData?["streams"] ?? [])
          .firstWhereOrNull((e) => e["type"] == "video");

      final codec = videoData["codec_name"]?.toString().toLowerCase();
      final codecIsH264 = codec?.contains("h264") ?? false;

      final bitrate = props?.duration?.inSeconds != null
          ? (fileSize * 8) / props!.duration!.inSeconds
          : null;

      final colorSpace = videoData["color_space"]?.toString().toLowerCase();
      final isColorGood = colorSpace == "bt709";

      // create temp file & directory for preview generation
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

      // case 1, if it's already a good stream
      if (bitrate != null && bitrate <= 4000 * 1000 && codecIsH264) {
        session = await FFmpegKit.execute(
          '-i "${file.path}" '
          '-c:v copy -c:a copy '
          '-f hls -hls_time 2 -hls_flags single_file '
          '-hls_list_size 0 -hls_key_info_file ${keyinfo.path} '
          '$prefix/output.m3u8',
        );
      } // case 2, if it's bitrate is good, but codec is not
      else if (bitrate != null &&
          codec != null &&
          bitrate <= 2000 * 1000 &&
          !codecIsH264) {
        session = await FFmpegKit.execute(
          '-i "${file.path}" '
          '-vf "format=yuv420p10le,zscale=transfer=linear,tonemap=tonemap=hable:desat=0:peak=10,zscale=transfer=bt709:matrix=bt709:primaries=bt709,format=yuv420p" '
          '-color_primaries bt709 -color_trc bt709 -colorspace bt709 '
          '-c:v libx264 -crf 23 -preset medium '
          '-c:a copy '
          '-f hls -hls_time 2 -hls_flags single_file '
          '-hls_list_size 0 -hls_key_info_file ${keyinfo.path} '
          '$prefix/output.m3u8',
        );
      } // case 3, if it's color space is good
      else if (colorSpace != null && isColorGood) {
        session = await FFmpegKit.execute(
          '-i "${file.path}" '
          '-vf "scale=-2:720,fps=30" '
          '-c:v libx264 -b:v 2000k -crf 23 -preset medium '
          '-c:a aac -b:a 128k -f hls -hls_time 2 -hls_flags single_file '
          '-hls_list_size 0 -hls_key_info_file ${keyinfo.path} '
          '$prefix/output.m3u8',
        );
      } // case 4, make it compatible
      else {
        session = await FFmpegKit.execute(
          '-i "${file.path}" '
          '-vf "scale=-2:720,fps=30,format=yuv420p10le,zscale=transfer=linear,tonemap=tonemap=hable:desat=0:peak=10,zscale=transfer=bt709:matrix=bt709:primaries=bt709,format=yuv420p" '
          '-color_primaries bt709 -color_trc bt709 -colorspace bt709 '
          '-x264-params "colorprim=bt709:transfer=bt709:colormatrix=bt709" '
          '-c:v libx264 -b:v 2000k -crf 23 -preset medium '
          '-c:a aac -b:a 128k -f hls -hls_time 2 -hls_flags single_file '
          '-hls_list_size 0 -hls_key_info_file ${keyinfo.path} '
          '$prefix/output.m3u8',
        );
      }

      final returnCode = await session.getReturnCode();

      String? objectId;
      int? objectSize;

      if (ReturnCode.isSuccess(returnCode)) {
        try {
          _items[enteFile.uploadedFileID!] = PreviewItem(
            status: PreviewItemStatus.uploading,
            file: enteFile,
            collectionID: enteFile.collectionID ?? 0,
            retryCount: _items[enteFile.uploadedFileID!]?.retryCount ?? 0,
          );
          Bus.instance.fire(PreviewUpdatedEvent(_items));

          _logger.info('Playlist Generated ${enteFile.displayName}');

          final playlistFile = File("$prefix/output.m3u8");
          final previewFile = File("$prefix/output.ts");
          final result = await _uploadPreviewVideo(enteFile, previewFile);

          objectId = result.$1;
          objectSize = result.$2;

          // Fetch resolution of generated stream by decrypting a single frame
          final FFmpegSession session2 = await FFmpegKit.execute(
            '-allowed_extensions ALL -i "$prefix/output.m3u8" -frames:v 1 -c copy "$prefix/frame.ts"',
          );
          final returnCode2 = await session2.getReturnCode();
          int? width, height;
          try {
            if (ReturnCode.isSuccess(returnCode2)) {
              FFProbeProps? props2;
              final file2 = File("$prefix/frame.ts");

              props2 = await getVideoPropsAsync(file2);
              width = props2?.width;
              height = props2?.height;
            }
          } catch (err, sT) {
            _logger.warning("Failed to fetch resolution of stream", err, sT);
          }

          await _reportVideoPreview(
            enteFile,
            playlistFile,
            objectId: objectId,
            objectSize: objectSize,
            width: width,
            height: height,
          );

          _logger.info("Video preview uploaded for $enteFile");
        } catch (err, sT) {
          error = "Failed to upload video preview\nError: $err";
          _logger.shout("Something went wrong with preview upload", err, sT);
        }
      } else if (ReturnCode.isCancel(returnCode)) {
        _logger.warning("FFmpeg command cancelled");
        error = "FFmpeg command cancelled";
      } else {
        final output = await session.getOutput();
        _logger.shout(
          "FFmpeg command failed with return code $returnCode",
          output ?? "Error not found",
        );
        error = "Failed to generate video preview\nError: $output";
      }

      if (error == null) {
        // update previewIds
        FileDataService.instance.appendPreview(
          enteFile.uploadedFileID!,
          objectId!,
          objectSize!,
        );

        _items[enteFile.uploadedFileID!] = PreviewItem(
          status: PreviewItemStatus.uploaded,
          file: enteFile,
          retryCount: _items[enteFile.uploadedFileID!]!.retryCount,
          collectionID: enteFile.collectionID ?? 0,
        );
        _removeFromLocks(enteFile).ignore();
        Bus.instance.fire(PreviewUpdatedEvent(_items));
      }
    } finally {
      if (error != null) {
        _retryFile(enteFile, error);
        Bus.instance.fire(PreviewUpdatedEvent(_items));
      } else if (removeFile) {
        _removeFile(enteFile);
        _removeFromLocks(enteFile).ignore();
        Bus.instance.fire(PreviewUpdatedEvent(_items));
      }
      // reset uploading status if this was getting processed
      if (uploadingFileId == enteFile.uploadedFileID!) {
        uploadingFileId = -1;
      }
      _logger.info("[chunk] Processing ${_items.length} items for streaming");
      // process next file
      if (fileQueue.isNotEmpty) {
        final file = fileQueue.first;
        fileQueue.remove(file);
        await chunkAndUploadVideo(ctx, file);
      }
    }
  }

  Future<void> _removeFromLocks(EnteFile enteFile) async {
    final bool isFailurePresent =
        _failureFiles?.contains(enteFile.uploadedFileID!) ?? false;

    if (isFailurePresent) {
      await UploadLocksDB.instance
          .deleteStreamUploadErrorEntry(enteFile.uploadedFileID!);
      _failureFiles?.remove(enteFile.uploadedFileID!);
    }
  }

  void _removeFile(EnteFile enteFile) {
    _items.remove(enteFile.uploadedFileID!);
  }

  void _retryFile(EnteFile enteFile, Object error) {
    if (_items[enteFile.uploadedFileID!]!.retryCount < _maxRetryCount) {
      _items[enteFile.uploadedFileID!] = PreviewItem(
        status: PreviewItemStatus.retry,
        file: enteFile,
        retryCount: _items[enteFile.uploadedFileID!]!.retryCount + 1,
        collectionID: enteFile.collectionID ?? 0,
      );
      fileQueue.add(enteFile);
    } else {
      _items[enteFile.uploadedFileID!] = PreviewItem(
        status: PreviewItemStatus.failed,
        file: enteFile,
        retryCount: _items[enteFile.uploadedFileID!]!.retryCount,
        collectionID: enteFile.collectionID ?? 0,
        error: error,
      );

      final bool isFailurePresent =
          _failureFiles?.contains(enteFile.uploadedFileID!) ?? false;

      if (isFailurePresent) {
        UploadLocksDB.instance.appendStreamEntry(
          enteFile.uploadedFileID!,
          error.toString(),
        );
      } else {
        UploadLocksDB.instance.appendStreamEntry(
          enteFile.uploadedFileID!,
          error.toString(),
        );
        _failureFiles?.add(enteFile.uploadedFileID!);
      }
    }
  }

  Future<void> _reportVideoPreview(
    EnteFile file,
    File playlist, {
    required String objectId,
    required int objectSize,
    required int? width,
    required int? height,
  }) async {
    _logger.info("Pushing playlist for ${file.uploadedFileID}");
    try {
      final encryptionKey = getFileKey(file);
      final playlistContent = playlist.readAsStringSync();
      final result = await gzipAndEncryptJson(
        {
          "playlist": playlistContent,
          'type': 'hls_video',
          'width': width,
          'height': height,
          'size': objectSize,
        },
        encryptionKey,
      );
      final _ = await _dio.put(
        "/files/video-data",
        data: {
          "fileID": file.uploadedFileID!,
          "objectID": objectId,
          "objectSize": objectSize,
          "playlist": result.encData,
          "playlistHeader": result.header,
        },
      );
    } catch (e, s) {
      _logger.severe("Failed to report video preview", e, s);
      rethrow;
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

  String _getDetailsCacheKey(String objectKey) {
    return "video_playlist_details_$objectKey";
  }

  String _getVideoPreviewKey(String objectKey) {
    return "video_preview_$objectKey";
  }

  Future<PlaylistData?> getPlaylist(EnteFile file) async {
    return await _getPlaylist(file);
  }

  Future<PlaylistData?> _getPlaylist(EnteFile file) async {
    _logger.info("Getting playlist for $file");
    int? width, height, size;
    try {
      final objectKey =
          FileDataService.instance.previewIds?[file.uploadedFileID!]?.objectId;
      final FileInfo? playlistCache = (objectKey == null)
          ? null
          : await cacheManager.getFileFromCache(_getCacheKey(objectKey));
      final detailsCache = (objectKey == null)
          ? null
          : await cacheManager.getFileFromCache(
              _getDetailsCacheKey(objectKey),
            );
      String finalPlaylist;
      if (playlistCache != null) {
        finalPlaylist = playlistCache.file.readAsStringSync();
        if (detailsCache != null) {
          final details = json.decode(detailsCache.file.readAsStringSync());
          width = details["width"];
          height = details["height"];
          size = details["size"];
        }
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

        width = playlistData["width"];
        height = playlistData["height"];
        size = playlistData["size"];

        if (objectKey != null) {
          unawaited(
            cacheManager.putFile(
              _getCacheKey(objectKey),
              Uint8List.fromList(
                (playlistData["playlist"] as String).codeUnits,
              ),
            ),
          );
          final details = {
            "width": width,
            "height": height,
            "size": size,
          };
          unawaited(
            cacheManager.putFile(
              _getDetailsCacheKey(objectKey),
              Uint8List.fromList(
                json.encode(details).codeUnits,
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
            _downloadAndCacheVideo(
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
      final data = PlaylistData(
        preview: playlistFile,
        width: width,
        height: height,
        size: size,
      );
      return data;
    } catch (_) {
      rethrow;
    }
  }

  Future _downloadAndCacheVideo(String url, String key) async {
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

  Future<(FFProbeProps?, bool, File?)> _checkFileForPreviewCreation(
    EnteFile enteFile,
  ) async {
    final fileSize = enteFile.fileSize;
    FFProbeProps? props;
    File? file;
    bool result = false;

    try {
      final isFileUnder10MB = fileSize != null && fileSize <= 10 * 1024 * 1024;
      if (isFileUnder10MB) {
        file = await getFile(enteFile, isOrigin: true);
        if (file != null) {
          props = await getVideoPropsAsync(file);
          final videoData = List.from(props?.propData?["streams"] ?? [])
              .firstWhereOrNull((e) => e["type"] == "video");

          final codec = videoData["codec_name"]?.toString().toLowerCase();
          result = codec?.contains("h264") ?? false;
        }
      }
    } catch (e, sT) {
      _logger.warning("Failed to check props", e, sT);
    }
    return (props, result, file);
  }

  // generate stream for all files after cutoff date
  Future<void> _putFilesForPreviewCreation([bool updateInit = false]) async {
    if (!isVideoStreamingEnabled || !await canUseHighBandwidth()) return;

    final cutoff = videoStreamingCutoff;
    if (cutoff == null) return;
    if (updateInit) _initSuccess = true;

    Map<int, String> failureFiles = {};
    try {
      failureFiles = await UploadLocksDB.instance.getStreamUploadError();
      _failureFiles = {...failureFiles.keys};

      // handle case when failures are already previewed
      for (final failure in _failureFiles!) {
        if (previews.containsKey(failure)) {
          UploadLocksDB.instance.deleteStreamUploadErrorEntry(failure).ignore();
        }
      }
    } catch (_) {}

    final files = await FilesDB.instance.getAllFilesAfterDate(
      fileType: FileType.video,
      beginDate: cutoff,
      userID: Configuration.instance.getUserID()!,
    );

    final previewIds = FileDataService.instance.previewIds;
    final allFiles = files
        .where((file) => previewIds?[file.uploadedFileID] == null)
        .sorted((a, b) {
      // put higher duration videos last along with remote files
      final first = (a.localID == null ? 2 : 0) +
          (a.duration == null || a.duration! >= 10 * 60 ? 1 : 0);
      final second = (b.localID == null ? 2 : 0) +
          (b.duration == null || b.duration! >= 10 * 60 ? 1 : 0);
      return first.compareTo(second);
    }).toList();

    // set all video status to in queue
    var n = allFiles.length, i = 0;
    while (i < n) {
      final enteFile = allFiles[i];
      // elimination case for <=10 MB with H.264
      final (_, result, _) = await _checkFileForPreviewCreation(enteFile);
      final isFailure =
          _failureFiles?.contains(enteFile.uploadedFileID!) ?? false;

      if (isFailure) {
        _items[enteFile.uploadedFileID!] = PreviewItem(
          status: PreviewItemStatus.failed,
          file: enteFile,
          collectionID: enteFile.collectionID ?? 0,
          retryCount: _maxRetryCount,
          error: failureFiles[enteFile.uploadedFileID!],
        );
      }
      if (result || isFailure) {
        allFiles.removeAt(i);
        n--;
        continue;
      }

      _items[enteFile.uploadedFileID!] = PreviewItem(
        status: PreviewItemStatus.inQueue,
        file: enteFile,
        collectionID: enteFile.collectionID ?? 0,
      );

      i++;
    }

    Bus.instance.fire(PreviewUpdatedEvent(_items));
    if (allFiles.isEmpty) {
      _logger.info("[init] No preview to cache");
      return;
    }

    _logger.info("[init] Processing ${allFiles.length} items for streaming");

    // take first file and put it for stream generation
    final file = allFiles.removeAt(0);
    fileQueue.addAll(allFiles);
    chunkAndUploadVideo(null, file).ignore();
  }

  void queueFiles() {
    if (!_initSuccess) {
      _putFilesForPreviewCreation(true).catchError((_) {
        _initSuccess = false;
      });
    }
  }
}
