import "dart:async";
import "dart:collection";
import "dart:convert";
import "dart:io";

import "package:collection/collection.dart";
import "package:dio/dio.dart";
import "package:encrypt/encrypt.dart" as enc;
import "package:ffmpeg_kit_flutter/return_code.dart";
import "package:flutter/foundation.dart";
import "package:flutter/widgets.dart";
import "package:flutter_cache_manager/flutter_cache_manager.dart";
import "package:logging/logging.dart";
import "package:path_provider/path_provider.dart";
import "package:photos/core/cache/video_cache_manager.dart";
import "package:photos/core/configuration.dart";
import "package:photos/core/event_bus.dart";
import 'package:photos/db/files_db.dart';
import "package:photos/db/upload_locks_db.dart";
import "package:photos/events/video_preview_state_changed_event.dart";
import "package:photos/events/video_streaming_changed.dart";
import 'package:photos/generated/intl/app_localizations.dart';
import "package:photos/models/base/id.dart";
import "package:photos/models/ffmpeg/ffprobe_props.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/file/file_type.dart";
import "package:photos/models/metadata/file_magic.dart";
import "package:photos/models/preview/playlist_data.dart";
import "package:photos/models/preview/preview_item.dart";
import "package:photos/models/preview/preview_item_status.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/file_magic_service.dart";
import "package:photos/services/filedata/model/file_data.dart";
import "package:photos/services/isolated_ffmpeg_service.dart";
import "package:photos/services/machine_learning/compute_controller.dart";
import "package:photos/ui/notification/toast.dart";
import "package:photos/utils/exif_util.dart";
import "package:photos/utils/file_key.dart";
import "package:photos/utils/file_util.dart";
import "package:photos/utils/gzip.dart";
import "package:photos/utils/network_util.dart";

const _maxRetryCount = 3;

class VideoPreviewService {
  final _logger = Logger("VideoPreviewService");
  final LinkedHashMap<int, PreviewItem> _items = LinkedHashMap();
  LinkedHashMap<int, EnteFile> fileQueue = LinkedHashMap();
  final int _maxPreviewSizeLimitForCache = 50 * 1024 * 1024; // 50 MB
  Set<int>? _failureFiles;

  bool get _hasQueuedFile => fileQueue.isNotEmpty;

  VideoPreviewService._privateConstructor()
      : serviceLocator = ServiceLocator.instance,
        filesDB = FilesDB.instance,
        uploadLocksDB = UploadLocksDB.instance,
        ffmpegService = IsolatedFfmpegService.instance,
        fileMagicService = FileMagicService.instance,
        cacheManager = DefaultCacheManager(),
        videoCacheManager = VideoCacheManager.instance,
        config = Configuration.instance;

  VideoPreviewService(
    this.config,
    this.serviceLocator,
    this.filesDB,
    this.uploadLocksDB,
    this.fileMagicService,
    this.ffmpegService,
    this.cacheManager,
    this.videoCacheManager,
  );

  static final VideoPreviewService instance =
      VideoPreviewService._privateConstructor();

  int uploadingFileId = -1;

  final Configuration config;
  final ServiceLocator serviceLocator;
  final FilesDB filesDB;
  final UploadLocksDB uploadLocksDB;
  final FileMagicService fileMagicService;
  final IsolatedFfmpegService ffmpegService;
  final DefaultCacheManager cacheManager;
  final CacheManager videoCacheManager;

  static const String _videoStreamingEnabled = "videoStreamingEnabled";

  bool get isVideoStreamingEnabled {
    return serviceLocator.prefs.getBool(_videoStreamingEnabled) ?? false;
  }

  Future<void> setIsVideoStreamingEnabled(bool value) async {
    serviceLocator.prefs.setBool(_videoStreamingEnabled, value).ignore();
    Bus.instance.fire(VideoStreamingChanged());

    if (isVideoStreamingEnabled) {
      queueFiles(duration: Duration.zero);
    } else {
      clearQueue();
    }
  }

  void clearQueue() {
    // Fire events for all items being cleared
    for (final entry in _items.entries) {
      _fireVideoPreviewStateChange(entry.key, PreviewItemStatus.uploaded);
    }
    fileQueue.clear();
    _items.clear();
  }

  void _fireVideoPreviewStateChange(int fileId, PreviewItemStatus status) {
    Bus.instance.fire(VideoPreviewStateChangedEvent(fileId, status));
  }

  // Return value indicates file was successfully added to queue or not
  Future<bool> addToManualQueue(EnteFile file, String queueType) async {
    if (file.uploadedFileID == null) return false;

    // Check if already in queue
    final bool alreadyInQueue = await uploadLocksDB.isInStreamQueue(
      file.uploadedFileID!,
    );
    if (alreadyInQueue) {
      // File is already queued, but trigger processing in case it was stalled
      if (uploadingFileId < 0) {
        queueFiles(duration: Duration.zero, isManual: true, forceProcess: true);
      }
      return false; // Indicates file was already in queue
    }

    // Add to persistent database queue
    await uploadLocksDB.addToStreamQueue(file.uploadedFileID!, queueType);

    // Start processing if not already processing
    if (uploadingFileId < 0) {
      queueFiles(duration: Duration.zero, isManual: true);
    } else {
      _items[file.uploadedFileID!] = PreviewItem(
        status: PreviewItemStatus.inQueue,
        file: file,
        retryCount: 0,
        collectionID: file.collectionID ?? 0,
      );
      _fireVideoPreviewStateChange(
        file.uploadedFileID!,
        PreviewItemStatus.inQueue,
      );
      fileQueue[file.uploadedFileID!] = file;
    }

    return true;
  }

  bool isCurrentlyProcessing(int? uploadedFileID) {
    if (uploadedFileID == null) return false;

    // Also check if file is in queue or other processing states
    final item = _items[uploadedFileID];
    if (item != null) {
      switch (item.status) {
        case PreviewItemStatus.inQueue:
        case PreviewItemStatus.compressing:
        case PreviewItemStatus.uploading:
          return true;
        default:
          return false;
      }
    }

    return false;
  }

  PreviewItemStatus? getProcessingStatus(int uploadedFileID) {
    return _items[uploadedFileID]?.status;
  }

  Future<bool> _isRecreateOperation(EnteFile file) async {
    if (file.uploadedFileID == null) return false;

    try {
      // Check database directly instead of relying on in-memory _manualQueueFiles
      // which might not be populated yet
      final manualQueueFiles = await uploadLocksDB.getStreamQueue();
      final queueType = manualQueueFiles[file.uploadedFileID!];
      return queueType == 'recreate';
    } catch (_) {
      return false;
    }
  }

  Future<void> _ensurePreviewIdsInitialized() async {
    // Ensure fileDataService previewIds is initialized before using it
    if (fileDataService.previewIds.isEmpty) {
      await fileDataService.syncFDStatus();
    }
  }

  Future<bool> isSharedFileStreamble(EnteFile file) async {
    try {
      await _ensurePreviewIdsInitialized();
      if (fileDataService.previewIds.containsKey(file.uploadedFileID)) {
        return true;
      }
      await _getPreviewUrl(file);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<EnteFile>> _getFiles({
    DateTime? beginDate,
    bool onlyFilesWithLocalId = true,
  }) async {
    return await filesDB.getStreamingEligibleVideoFiles(
      beginDate: beginDate,
      userID: config.getUserID()!,
      onlyFilesWithLocalId: onlyFilesWithLocalId,
    );
  }

  Future<double> calcStatus(
    List<EnteFile> files,
    Map<int, PreviewInfo> previewIds,
  ) async {
    // This is the total video files that have streams
    final Set<int> processed = previewIds.keys.toSet();
    // Total: Total Remote video files owned - skipped video files
    //         + processed videos (any platform)
    final Set<int> total = {...processed};

    for (final file in files) {
      // skipped -> don't add
      if (file.pubMagicMetadata?.sv == 1) {
        continue;
      }
      // Include the file to total set
      total.add(file.uploadedFileID!);
    }

    // If total is empty then mark all as processed else compute the ratio
    // of processed files and total remote video files
    // netProcessedItems = processed / total
    final double netProcessedItems =
        total.isEmpty ? 1 : (processed.length / total.length).clamp(0, 1);

    // Store the data and return it
    final status = netProcessedItems;
    return status;
  }

  Future<double> getStatus() async {
    try {
      await _ensurePreviewIdsInitialized();

      // This will get us all the video files that are present on remote
      // and also that could be / have been skipped due to device
      // limitations
      final files = await _getFiles(
        beginDate: null,
        onlyFilesWithLocalId: false,
      );

      return calcStatus(files, fileDataService.previewIds);
    } catch (e, s) {
      _logger.severe('Error getting Streaming status', e, s);
      rethrow;
    }
  }

  Future<void> chunkAndUploadVideo(
    BuildContext? ctx,
    EnteFile enteFile, {
    /// Indicates this function is an continuation of a chunking thread
    bool continuation = false,
    // not used currently
    bool forceUpload = false,
  }) async {
    final bool isManual =
        await uploadLocksDB.isInStreamQueue(enteFile.uploadedFileID!);
    final canStream = _isPermissionGranted();
    if (!canStream) {
      _logger.info(
        "Pause preview due to disabledSteaming($isVideoStreamingEnabled) or computeController permission) - isManual: $isManual",
      );
      computeController.releaseCompute(stream: true);
      if (isVideoStreamingEnabled) _logger.info("No permission to run compute");
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
        // check if playlist already exist, but skip this check for 'recreate' operations
        final isRecreateOperation = await _isRecreateOperation(enteFile);
        if (!isRecreateOperation && await getPlaylist(enteFile) != null) {
          if (ctx != null && ctx.mounted) {
            showShortToast(
              ctx,
              AppLocalizations.of(ctx).videoPreviewAlreadyExists,
            );
          }
          removeFile = true;
          return;
        }
      } catch (e, s) {
        if (e is DioException && e.response?.statusCode == 404) {
          // 404 is expected when checking if preview exists
          _logger.fine(
            "No preview found for ${enteFile.displayName}, will create one",
          );
        } else {
          _logger.warning("Failed to get playlist for $enteFile", e, s);
          error = e;
          return;
        }
      }
      _logger.info(
        "Starting video preview generation for ${enteFile.displayName}",
      );
      // elimination case for <=10 MB with H.264
      var (props, result, file) =
          await _checkFileForPreviewCreation(enteFile, isManual);
      if (result) {
        removeFile = true;
        return;
      }

      // check if there is already a preview in processing
      if (!continuation && uploadingFileId >= 0) {
        if (uploadingFileId == enteFile.uploadedFileID) return;

        _items[enteFile.uploadedFileID!] = PreviewItem(
          status: PreviewItemStatus.inQueue,
          file: enteFile,
          retryCount: forceUpload
              ? 0
              : _items[enteFile.uploadedFileID!]?.retryCount ?? 0,
          collectionID: enteFile.collectionID ?? 0,
        );
        _fireVideoPreviewStateChange(
          enteFile.uploadedFileID!,
          PreviewItemStatus.inQueue,
        );
        fileQueue[enteFile.uploadedFileID!] = enteFile;
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
      _fireVideoPreviewStateChange(
        enteFile.uploadedFileID!,
        PreviewItemStatus.compressing,
      );

      // get file
      file ??= await getFile(enteFile, isOrigin: true);
      if (file == null) {
        error = "Unable to fetch file";
        return;
      }

      // check metadata for bitrate, codec, color space
      props ??= await getVideoPropsAsync(file);
      final fileSize = enteFile.fileSize ?? file.lengthSync();

      final videoData = List.from(
        props?.propData?["streams"] ?? [],
      ).firstWhereOrNull((e) => e["type"] == "video");

      final codec = videoData["codec_name"]?.toString().toLowerCase();
      final isH264 = codec?.contains("h264") ?? false;

      final bitrate = props?.duration?.inSeconds != null
          ? (fileSize * 8) / props!.duration!.inSeconds
          : null;

      final colorTransfer =
          videoData["color_transfer"]?.toString().toLowerCase();
      final isHDR = colorTransfer != null &&
          (colorTransfer == "smpte2084" || colorTransfer == "arib-std-b67");

      // create temp file & directory for preview generation
      final String tempDir = config.getTempDirectory();
      final String prefix =
          "${tempDir}_${enteFile.uploadedFileID}_${newID("pv")}";
      Directory(prefix).createSync();
      _logger.info('Compressing video ${enteFile.displayName}');
      final key = enc.Key.fromLength(16);

      final keyfile = File('$prefix/keyfile.key');
      keyfile.writeAsBytesSync(key.bytes);

      final keyinfo = File('$prefix/mykey.keyinfo');
      keyinfo.writeAsStringSync(
        "data:text/plain;base64,${key.base64}\n"
        "${keyfile.path}\n",
      );

      _logger.info(
        'Generating HLS Playlist ${enteFile.displayName} at $prefix/output.m3u8',
      );

      final reencodeVideo =
          !(isH264 && bitrate != null && bitrate <= 4000 * 1000);
      final rescaleVideo = !(bitrate != null && bitrate <= 2000 * 1000);
      final needsTonemap = isHDR;
      final applyFPS = (double.tryParse(props?.fps ?? "") ?? 100) > 30;

      String filters = "";

      if (reencodeVideo) {
        final videoFilters = <String>[];

        if (rescaleVideo || needsTonemap) {
          // scale video to 720p or keep original height if less than 720p
          videoFilters.add("scale=-2:'min(720,ih)'");

          // reduce fps to 30 if it is more than 30
          if (applyFPS) videoFilters.add("fps=30");
        }

        if (needsTonemap) {
          // apply tonemapping for HDR videos
          videoFilters.addAll([
            'zscale=transfer=linear',
            'tonemap=tonemap=hable:desat=0',
            'zscale=primaries=709:transfer=709:matrix=709',
          ]);
        }

        videoFilters.add("format=yuv420p");

        filters = '-vf "${videoFilters.join(",")}" ';
      }

      final command =
          // scaling, fps, tonemapping
          '$filters'
          // video encoding
          '${reencodeVideo ? '-c:v libx264 -crf 23 -preset medium ' : '-c:v copy '}'
          // audio encoding
          '-c:a aac -b:a 128k '
          // hls options
          '-f hls -hls_flags single_file '
          '-hls_list_size 0 -hls_key_info_file ${keyinfo.path} ';

      _logger.info(command);

      final playlistGenResult = await ffmpegService
          .runFfmpeg(
        // input file path
        '-i "${file.path}" ' +
            // main params for streaming
            command +
            // output file path
            '$prefix/output.m3u8',
      )
          .onError((error, stackTrace) {
        _logger.warning("FFmpeg command failed", error, stackTrace);
        return {};
      });

      final playlistGenReturnCode = playlistGenResult["returnCode"] as int?;

      String? objectId;
      int? objectSize;

      if (ReturnCode.success == playlistGenReturnCode) {
        try {
          _items[enteFile.uploadedFileID!] = PreviewItem(
            status: PreviewItemStatus.uploading,
            file: enteFile,
            collectionID: enteFile.collectionID ?? 0,
            retryCount: _items[enteFile.uploadedFileID!]?.retryCount ?? 0,
          );
          _fireVideoPreviewStateChange(
            enteFile.uploadedFileID!,
            PreviewItemStatus.uploading,
          );

          _logger.info('Playlist Generated ${enteFile.displayName}');

          final playlistFile = File("$prefix/output.m3u8");
          final previewFile = File("$prefix/output.ts");
          final result = await _uploadPreviewVideo(enteFile, previewFile);

          objectId = result.$1;
          objectSize = result.$2;

          // Fetch resolution of generated stream by decrypting a single frame
          final playlistFrameResult = await ffmpegService
              .runFfmpeg(
            '-allowed_extensions ALL -i "$prefix/output.m3u8" -frames:v 1 -c copy "$prefix/frame.ts"',
          )
              .onError((error, stackTrace) {
            _logger.warning(
              "FFmpeg command failed for frame",
              error,
              stackTrace,
            );
            return {};
          });
          final playlistFrameReturnCode =
              playlistFrameResult["returnCode"] as int?;
          int? width, height;
          try {
            if (ReturnCode.success == playlistFrameReturnCode) {
              FFProbeProps? playlistFrameProps;
              final file2 = File("$prefix/frame.ts");

              playlistFrameProps = await getVideoPropsAsync(file2);
              width = playlistFrameProps?.width;
              height = playlistFrameProps?.height;
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
      } else if (ReturnCode.cancel == playlistGenReturnCode) {
        _logger.warning("FFmpeg command cancelled");
        error = "FFmpeg command cancelled";
      } else {
        final output = playlistGenResult["output"] as String?;
        _logger.shout(
          "FFmpeg command failed with return code $playlistGenReturnCode",
          output ?? "Error not found",
        );
        error = "Failed to generate video preview\nError: $output";
      }

      if (error == null) {
        // update previewIds
        fileDataService.appendPreview(
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
        _fireVideoPreviewStateChange(
          enteFile.uploadedFileID!,
          PreviewItemStatus.uploaded,
        );
        _removeFromLocks(enteFile).ignore();
        Directory(prefix).delete(recursive: true).ignore();
      }
    } finally {
      if (error != null) {
        _retryFile(enteFile, error);
      } else if (removeFile) {
        _removeFile(enteFile);
        _removeFromLocks(enteFile).ignore();
      }
      // Check if we should stop processing due to network errors
      final bool shouldStopProcessing = _isNetworkError(error);

      if (fileQueue.isNotEmpty && !shouldStopProcessing) {
        // If there was an error, add a delay before processing next file
        if (error != null) {
          _logger.info(
            "[chunk] Error occurred, waiting before processing next item. Queue size: ${fileQueue.length}",
          );
          // Add a small delay before processing next file after an error
          await Future.delayed(const Duration(seconds: 2));
        }

        // process next file
        _logger.info(
          "[chunk] Processing ${_items.length} items for streaming",
        );
        final entry = fileQueue.entries.first;
        final file = entry.value;
        fileQueue.remove(entry.key);
        await chunkAndUploadVideo(
          ctx,
          file,
          continuation: true,
        );
      } else {
        // Release compute when queue is empty or network is unavailable
        if (shouldStopProcessing) {
          _logger.warning(
            "[chunk] Network error detected, stopping queue processing. ${fileQueue.length} items pending",
          );
        } else {
          _logger.info(
            "[chunk] Nothing to process, releasing compute",
          );
        }
        computeController.releaseCompute(stream: true);
        uploadingFileId = -1;
      }
    }
  }

  Future<void> _removeFromLocks(EnteFile enteFile) async {
    final bool isFailurePresent =
        _failureFiles?.contains(enteFile.uploadedFileID!) ?? false;
    final bool isInManualQueue = await uploadLocksDB.isInStreamQueue(
      enteFile.uploadedFileID!,
    );

    if (isFailurePresent) {
      await uploadLocksDB.deleteStreamUploadErrorEntry(
        enteFile.uploadedFileID!,
      );
      _failureFiles?.remove(enteFile.uploadedFileID!);
    }

    if (isInManualQueue) {
      await uploadLocksDB.removeFromStreamQueue(enteFile.uploadedFileID!);
    }
  }

  void _removeFile(EnteFile enteFile) {
    final fileId = enteFile.uploadedFileID!;
    _items.remove(fileId);
    // Note: Using 'uploaded' status as there's no 'removed' status in PreviewItemStatus
    // This indicates the item has been successfully processed and removed from queue
    _fireVideoPreviewStateChange(fileId, PreviewItemStatus.uploaded);
  }

  bool _isNetworkError(Object? error) {
    if (error is DioException) {
      // Check for any network-related error
      return error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.unknown ||
          (error.error != null &&
              error.error.toString().contains('ERR_NAME_NOT_RESOLVED'));
    }
    return false;
  }

  void _retryFile(EnteFile enteFile, Object error) {
    // Check if it's a network error that should not be retried immediately
    bool shouldRetry = true;
    if (_isNetworkError(error)) {
      _logger.fine(
        "Network error detected, marking file as failed instead of retrying",
      );
      shouldRetry = false;
    }

    if (shouldRetry &&
        _items[enteFile.uploadedFileID!]!.retryCount < _maxRetryCount) {
      _items[enteFile.uploadedFileID!] = PreviewItem(
        status: PreviewItemStatus.retry,
        file: enteFile,
        retryCount: _items[enteFile.uploadedFileID!]!.retryCount + 1,
        collectionID: enteFile.collectionID ?? 0,
      );
      _fireVideoPreviewStateChange(
        enteFile.uploadedFileID!,
        PreviewItemStatus.retry,
      );
      fileQueue[enteFile.uploadedFileID!] = enteFile;
    } else {
      _items[enteFile.uploadedFileID!] = PreviewItem(
        status: PreviewItemStatus.failed,
        file: enteFile,
        retryCount: _items[enteFile.uploadedFileID!]!.retryCount,
        collectionID: enteFile.collectionID ?? 0,
        error: error,
      );
      _fireVideoPreviewStateChange(
        enteFile.uploadedFileID!,
        PreviewItemStatus.failed,
      );

      final bool isFailurePresent =
          _failureFiles?.contains(enteFile.uploadedFileID!) ?? false;

      if (isFailurePresent) {
        uploadLocksDB.appendStreamEntry(
          enteFile.uploadedFileID!,
          error.toString(),
        );
      } else {
        uploadLocksDB.appendStreamEntry(
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
    _logger.fine("Pushing playlist for ${file.uploadedFileID}");
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
      final _ = await serviceLocator.enteDio.put(
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
    _logger.fine("Pushing preview for $file");
    try {
      final response = await serviceLocator.enteDio.get(
        "/files/data/preview-upload-url",
        queryParameters: {
          "fileID": file.uploadedFileID!,
          "type": "vid_preview",
        },
      );
      final uploadURL = response.data["url"];
      final String objectID = response.data["objectID"];
      final objectSize = preview.lengthSync();
      final _ = await serviceLocator.enteDio.put(
        uploadURL,
        data: preview.openRead(),
        options: Options(headers: {Headers.contentLengthHeader: objectSize}),
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
    _logger.fine("Getting playlist for $file");
    int? width, height, size;

    try {
      late final String objectID;
      final PreviewInfo? previewInfo =
          fileDataService.previewIds[file.uploadedFileID!];
      bool shouldAppendPreview = false;
      (String, String)? previewURLResult;
      if (previewInfo == null) {
        shouldAppendPreview = true;
        previewURLResult = await _getPreviewUrl(file);
        _logger.fine("parsed objectID: ${previewURLResult.$2}");
        objectID = previewURLResult.$2;
      } else {
        objectID = previewInfo.objectId;
      }

      final FileInfo? playlistCache = await cacheManager.getFileFromCache(
        _getCacheKey(objectID),
      );
      final detailsCache = await cacheManager.getFileFromCache(
        _getDetailsCacheKey(objectID),
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
        final Map<String, dynamic> playlistData = await _getPlaylistData(file);
        finalPlaylist = playlistData["playlist"];
        width = playlistData["width"];
        height = playlistData["height"];
        size = playlistData["size"];
        unawaited(
          cacheManager.putFile(
            _getCacheKey(objectID),
            Uint8List.fromList((playlistData["playlist"] as String).codeUnits),
          ),
        );
        unawaited(
          cacheManager.putFile(
            _getDetailsCacheKey(objectID),
            Uint8List.fromList(
              json.encode({
                "width": width,
                "height": height,
                "size": size,
              }).codeUnits,
            ),
          ),
        );
      }
      final videoFile = (await videoCacheManager.getFileFromCache(
        _getVideoPreviewKey(objectID),
      ))
          ?.file;
      if (videoFile == null) {
        previewURLResult = previewURLResult ?? await _getPreviewUrl(file);
        if (size != null && size < _maxPreviewSizeLimitForCache) {
          unawaited(
            videoCacheManager.downloadFile(
              previewURLResult.$1,
              key: _getVideoPreviewKey(objectID),
            ),
          );
        }
        finalPlaylist = finalPlaylist.replaceAll(
          '\noutput.ts',
          '\n${previewURLResult.$1}',
        );
      } else {
        finalPlaylist = finalPlaylist.replaceAll(
          '\noutput.ts',
          '\n${videoFile.path}',
        );
      }
      final tempDir = await getTemporaryDirectory();
      final playlistFile = File("${tempDir.path}/${file.uploadedFileID}.m3u8");
      await playlistFile.writeAsString(finalPlaylist);
      final String log = (
        StringBuffer()
          ..write("[CACHE-STATUS] ")
          ..write("Video: ${videoFile != null ? '✓' : '✗'} | ")
          ..write("Details: ${detailsCache != null ? '✓' : '✗'} | ")
          ..write("Playlist: ${playlistCache != null ? '✓' : '✗'}"),
      ).toString();
      _logger.fine("Mapped playlist to ${playlistFile.path}, $log");
      final data = PlaylistData(
        preview: playlistFile,
        width: width,
        height: height,
        size: size,
        durationInSeconds: parseDurationFromHLS(finalPlaylist),
      );
      if (shouldAppendPreview) {
        fileDataService.appendPreview(file.uploadedFileID!, objectID, size!);
      }
      return data;
    } catch (_) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _getPlaylistData(EnteFile file) async {
    late Response<dynamic> response;
    if (collectionsService.isSharedPublicLink(file.collectionID!)) {
      response = await serviceLocator.nonEnteDio.get(
        "${config.getHttpEndpoint()}/public-collection/files/data/fetch/",
        queryParameters: {"fileID": file.uploadedFileID, "type": "vid_preview"},
        options: Options(
          headers: collectionsService.publicCollectionHeaders(
            file.collectionID!,
          ),
        ),
      );
    } else {
      response = await serviceLocator.enteDio.get(
        "/files/data/fetch/",
        queryParameters: {"fileID": file.uploadedFileID, "type": "vid_preview"},
      );
    }
    final encryptedData = response.data["data"]["encryptedData"];
    final header = response.data["data"]["decryptionHeader"];
    final encryptionKey = getFileKey(file);
    final playlistData = await decryptAndUnzipJson(
      encryptionKey,
      encryptedData: encryptedData,
      header: header,
    );
    return playlistData;
  }

  int? parseDurationFromHLS(String playlist) {
    final lines = playlist.split("\n");
    double totalDuration = 0.0;
    for (final line in lines) {
      if (line.startsWith("#EXTINF:")) {
        // Extract duration value (e.g., "#EXTINF:2.400000," → "2.400000")
        final durationStr = line.substring(8, line.length - 1);
        final duration = double.tryParse(durationStr);
        if (duration != null) {
          totalDuration += duration;
        }
      }
    }
    return totalDuration > 0 ? totalDuration.round() : null;
  }

  Future<(String, String)> _getPreviewUrl(EnteFile file) async {
    try {
      late String url;
      if (collectionsService.isSharedPublicLink(file.collectionID!)) {
        final response = await serviceLocator.nonEnteDio.get(
          "${config.getHttpEndpoint()}/public-collection/files/data/preview",
          queryParameters: {
            "fileID": file.uploadedFileID,
            "type":
                file.fileType == FileType.video ? "vid_preview" : "img_preview",
          },
          options: Options(
            headers: collectionsService.publicCollectionHeaders(
              file.collectionID!,
            ),
          ),
        );
        url = (response.data["url"] as String);
      } else {
        final response = await serviceLocator.enteDio.get(
          "/files/data/preview",
          queryParameters: {
            "fileID": file.uploadedFileID,
            "type":
                file.fileType == FileType.video ? "vid_preview" : "img_preview",
          },
        );
        url = (response.data["url"] as String);
      }
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      if (segments.isEmpty) throw Exception("Invalid URL");
      final String objectID = segments.last;
      return (url, objectID);
    } catch (e) {
      _logger.warning("Failed to get preview url", e);
      rethrow;
    }
  }

  Future<(FFProbeProps?, bool, File?)> _checkFileForPreviewCreation(
    EnteFile enteFile, [
    bool isManual = false,
  ]) async {
    if ((enteFile.pubMagicMetadata?.sv ?? 0) == 1) {
      _logger.info("Skip Preview due to sv=1 for  ${enteFile.displayName}");
      return (null, true, null);
    }
    if (!isManual) {
      if (enteFile.fileSize == null || enteFile.duration == null) {
        _logger.warning(
          "Skip Preview due to misisng size/duration for ${enteFile.displayName}",
        );
        return (null, true, null);
      }
      final int size = enteFile.fileSize!;
      final int duration = enteFile.duration!;
      if (size >= 500 * 1024 * 1024 || duration > 60) {
        _logger.info("Skip Preview due to size: $size or duration: $duration");
        return (null, true, null);
      }
    }
    FFProbeProps? props;
    File? file;
    bool skipFile = false;
    if (enteFile.fileSize == null && isManual) {
      return (props, skipFile, file);
    }

    final size = enteFile.fileSize ?? 0;
    try {
      final isFileUnder10MB = size <= 10 * 1024 * 1024;
      if (isFileUnder10MB) {
        file = await getFile(enteFile, isOrigin: true);
        if (file != null) {
          props = await getVideoPropsAsync(file);
          final videoData = List.from(
            props?.propData?["streams"] ?? [],
          ).firstWhereOrNull((e) => e["type"] == "video");
          final codec = videoData["codec_name"]?.toString().toLowerCase();
          skipFile = codec?.contains("h264") ?? false;

          if (skipFile) {
            _logger.info(
              "[init] Ignoring file ${enteFile.displayName} for preview due to codec",
            );
            await fileMagicService.updatePublicMagicMetadata(
              [enteFile],
              {streamVersionKey: 1},
            );
            return (props, skipFile, file);
          }
        }
      }
    } catch (e, sT) {
      _logger.warning("Failed to check props", e, sT);
    }
    return (props, skipFile, file);
  }

  // generate stream for all files after cutoff date
  // returns false if it fails to launch chuncking function
  Future<bool> _putFilesForPreviewCreation() async {
    if (!isVideoStreamingEnabled || !await canUseHighBandwidth()) return false;

    Map<int, String> failureFiles = {};
    Map<int, String> manualQueueFiles = {};
    try {
      failureFiles = await uploadLocksDB.getStreamUploadError();
      _failureFiles = {...failureFiles.keys};

      manualQueueFiles = await uploadLocksDB.getStreamQueue();

      // handle case when failures are already previewed
      for (final failure in _failureFiles!) {
        if (_items.containsKey(failure)) {
          uploadLocksDB.deleteStreamUploadErrorEntry(failure).ignore();
        }
      }

      // handle case when manual queue items are already previewed (for 'create' type only)
      for (final queueItem in manualQueueFiles.keys) {
        final queueType = manualQueueFiles[queueItem];
        final hasPreview = fileDataService.previewIds[queueItem] != null;
        if (hasPreview && queueType == 'create') {
          // Remove from queue only if it's a 'create' type and preview exists
          await uploadLocksDB.removeFromStreamQueue(queueItem);
        }
      }

      // Refresh manual queue after cleanup
      manualQueueFiles = await uploadLocksDB.getStreamQueue();
    } catch (_) {}

    final files = await _getFiles(
      beginDate: DateTime.now().subtract(const Duration(days: 60)),
      onlyFilesWithLocalId: true,
    );
    final previewIds = fileDataService.previewIds;

    _logger.info(
      "[init] Found ${files.length} files in last 60 days, ${manualQueueFiles.length} manual queue files: ${manualQueueFiles.keys.toList()}",
    );

    // Add manual queue files first (they have priority)
    for (final queueFileId in manualQueueFiles.keys) {
      final queueType = manualQueueFiles[queueFileId] ?? 'create';
      final hasPreview = previewIds[queueFileId] != null;

      // For create, only add if no preview exists
      if (queueType == 'create' && hasPreview) {
        _logger.info(
          "[manual-queue] Skipping file $queueFileId (type=$queueType, hasPreview=$hasPreview)",
        );
        continue;
      }

      // First try to find the file in the 60-day list
      var queueFile = files.firstWhereOrNull(
        (f) => f.uploadedFileID == queueFileId,
      );

      // If not found in 60-day list, fetch it individually
      queueFile ??=
          await filesDB.getAnyUploadedFile(queueFileId).catchError((e) => null);

      if (queueFile == null) {
        await uploadLocksDB
            .removeFromStreamQueue(queueFileId)
            .catchError((e) {});
        continue;
      }

      _items[queueFile.uploadedFileID!] = PreviewItem(
        status: PreviewItemStatus.inQueue,
        file: queueFile,
        collectionID: queueFile.collectionID ?? 0,
      );
      _fireVideoPreviewStateChange(
        queueFile.uploadedFileID!,
        PreviewItemStatus.inQueue,
      );
      fileQueue[queueFile.uploadedFileID!] = queueFile;
    }

    // Then add regular files that need processing
    final allFiles = files
        .where(
          (file) =>
              previewIds[file.uploadedFileID] == null &&
              !manualQueueFiles.containsKey(file.uploadedFileID),
        )
        .toList();

    // set all video status to in queue
    var n = allFiles.length, i = 0;
    while (i < n) {
      final enteFile = allFiles[i];
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
        _fireVideoPreviewStateChange(
          enteFile.uploadedFileID!,
          PreviewItemStatus.failed,
        );
      }
      if (isFailure) {
        _logger.info(
          "[init] Ignoring file ${enteFile.displayName} for preview",
        );
        allFiles.removeAt(i);
        n--;
        continue;
      }

      _items[enteFile.uploadedFileID!] = PreviewItem(
        status: PreviewItemStatus.inQueue,
        file: enteFile,
        collectionID: enteFile.collectionID ?? 0,
      );
      _fireVideoPreviewStateChange(
        enteFile.uploadedFileID!,
        PreviewItemStatus.inQueue,
      );
      fileQueue[enteFile.uploadedFileID!] = enteFile;

      i++;
    }

    final totalFiles = fileQueue.length;
    if (totalFiles == 0) {
      _logger.fine("[init] No preview to cache");
      return false;
    }

    _logger.info(
      "[init] Processing $totalFiles items for streaming (${manualQueueFiles.length} manual requested, ${fileQueue.length} queued, ${allFiles.length} regular)",
    );

    // take first file and put it for stream generation
    final entry = fileQueue.entries.first;
    final file = entry.value;
    fileQueue.remove(entry.key);
    chunkAndUploadVideo(null, file).ignore();
    return true;
  }

  bool _allowStream() {
    return isVideoStreamingEnabled &&
        computeController.requestCompute(stream: true);
  }

  bool _allowManualStream() {
    return isVideoStreamingEnabled &&
        computeController.requestCompute(
          stream: true,
          bypassInteractionCheck: true,
          bypassMLWaiting: true,
        );
  }

  /// To check if it's enabled, device is healthy and running streaming
  bool _isPermissionGranted() {
    return isVideoStreamingEnabled &&
        computeController.computeState == ComputeRunState.generatingStream &&
        computeController.isDeviceHealthy;
  }

  void queueFiles({
    Duration duration = const Duration(seconds: 5),
    bool isManual = false,
    bool forceProcess = false,
  }) {
    Future.delayed(duration, () async {
      if (_hasQueuedFile && !forceProcess) return;

      final isStreamAllowed = isManual ? _allowManualStream() : _allowStream();
      if (!isStreamAllowed) return;

      await _ensurePreviewIdsInitialized();
      final result = await _putFilesForPreviewCreation();
      // Cannot proceed to stream generation, would have to release compute ASAP
      if (!result) {
        computeController.releaseCompute(stream: true);
      }
    });
  }
}
