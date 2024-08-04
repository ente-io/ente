import "dart:async";
import "dart:convert";
import "dart:io";
import "dart:typed_data";

import "package:dio/dio.dart";
import "package:encrypt/encrypt.dart";
import "package:ffmpeg_kit_flutter_min/ffmpeg_kit.dart";
import "package:ffmpeg_kit_flutter_min/return_code.dart";
import "package:logging/logging.dart";
import "package:path_provider/path_provider.dart";
import "package:photos/core/network/network.dart";
import "package:photos/models/file/file.dart";
import "package:photos/utils/crypto_util.dart";
import "package:photos/utils/file_download_util.dart";
import "package:photos/utils/file_util.dart";
import "package:video_compress/video_compress.dart";

class PreviewVideoStore {
  PreviewVideoStore._privateConstructor();

  static final PreviewVideoStore instance =
      PreviewVideoStore._privateConstructor();

  final _logger = Logger("PreviewVideoStore");
  final _dio = NetworkClient.instance.enteDio;

  Future<void> chunkAndUploadVideo(EnteFile enteFile) async {
    if (!enteFile.isUploaded) return;

    final file = await getFileFromServer(enteFile);
    if (file == null) return;
    final tmpDirectory = await getTemporaryDirectory();
    final prefix = "${tmpDirectory.path}/${enteFile.generatedID}";
    Directory(prefix).createSync();
    final mediaInfo = await VideoCompress.compressVideo(
      file.path,
      quality: VideoQuality.Res1280x720Quality,
      deleteOrigin: true,
    );
    if (mediaInfo?.path == null) return;

    final key = Key.fromLength(16);
    final iv = IV.fromLength(16);

    final keyfile = File('$prefix/keyfile.key');
    keyfile.writeAsBytesSync(key.bytes);

    final keyinfo = File('$prefix/mykey.keyinfo');
    keyinfo.writeAsStringSync(
      "data:text/plain;base64,${key.base64}\n"
      "${keyfile.path}\n"
      "${iv.base64}",
    );

    await FFmpegKit.execute(
      """
      -i "${mediaInfo!.path}"
      -c copy -f hls -hls_time 10 -hls_flags single_file
      -hls_list_size 0 -hls_key_info_file ${keyinfo.path}
      $prefix/video.m3u8""",
    ).then((session) async {
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        final playlistFile = File("$prefix/output.m3u8");
        final previewFile = File("$prefix/segment000.ts");
        await _reportPreview(enteFile, previewFile);
        await _reportPlaylist(enteFile, playlistFile);
      } else if (ReturnCode.isCancel(returnCode)) {
        _logger.warning("FFmpeg command cancelled");
      } else {
        _logger.severe("FFmpeg command failed with return code $returnCode");
      }
    });
  }

  Future<void> _reportPlaylist(EnteFile file, File playlist) async {
    _logger.info("Pushing playlist for $file");
    final encryptionKey = getFileKey(file);
    final playlistContent = playlist.readAsStringSync();
    final encryptedPlaylist = await CryptoUtil.encryptChaCha(
      utf8.encode(playlistContent) as Uint8List,
      encryptionKey,
    );
    final encryptedData =
        CryptoUtil.bin2base64(encryptedPlaylist.encryptedData!);
    final header = CryptoUtil.bin2base64(encryptedPlaylist.header!);
    try {
      final _ = await _dio.put(
        "/files/file-data/playlist",
        data: {
          "fileID": file.generatedID,
          "model": "hls_video",
          "encryptedEmbedding": encryptedData,
          "decryptionHeader": header,
        },
      );
    } catch (e, s) {
      _logger.severe(e, s);
    }
  }

  Future<void> _reportPreview(EnteFile file, File preview) async {
    _logger.info("Pushing preview for $file");
    try {
      final response = await _dio.get(
        "/files/file-data/preview/upload-url/${file.generatedID}",
      );
      final uploadURL = response.data["uploadURL"];
      final _ = await _dio.put(
        uploadURL,
        data: await preview.readAsBytes(),
        options: Options(
          contentType: "application/octet-stream",
        ),
      );
    } catch (e, s) {
      _logger.severe(e, s);
      rethrow;
    }
  }

  Future<File?> getPlaylist(EnteFile file) async {
    return await _getPlaylist(file);
  }

  Future<File?> _getPlaylist(EnteFile file) async {
    _logger.info("Getting playlist for $file");
    try {
      final response = await _dio.get(
        "/files/file-data/playlist/${file.generatedID}",
      );
      final encryptedData = response.data["encryptedEmbedding"];
      final header = response.data["decryptionHeader"];
      final encryptionKey = getFileKey(file);
      final playlistData = await CryptoUtil.decryptChaCha(
        CryptoUtil.base642bin(encryptedData),
        encryptionKey,
        CryptoUtil.base642bin(header),
      );
      final response2 = await _dio.get(
        "/files/file-data/preview/${file.generatedID}",
      );
      final previewURL = response2.data["previewURL"];
      final finalPlaylist =
          utf8.decode(playlistData).replaceAll('\nvideo.ts', '\n$previewURL');
      final tempDir = await getTemporaryDirectory();
      final playlistFile = File("${tempDir.path}/${file.generatedID}.m3u8");
      await playlistFile.writeAsString(finalPlaylist);
      return playlistFile;
    } catch (e, s) {
      _logger.severe(e, s);
      return null;
    }
  }
}
