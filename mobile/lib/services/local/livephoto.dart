import "dart:io";

import "package:archive/archive_io.dart";
import "package:computer/computer.dart";
import "package:ente_crypto/ente_crypto.dart";
import "package:logging/logging.dart";
import "package:motionphoto/motionphoto.dart";
import "package:path/path.dart";
import "package:photos/core/configuration.dart";
import "package:photos/core/errors.dart";
import "package:uuid/uuid.dart";

class LivePhotoService {
  static final _logger = Logger("LivePhotoService");
  static Future<(File, String)> liveVideoAndHash(String id) async {
    final liveVideo = await Motionphoto.getLivePhotoFile(id);
    if (liveVideo == null || !liveVideo.existsSync()) {
      final String errMsg = "missing livePhoto video for id $id";
      _logger.severe(errMsg);
      throw InvalidFileError(errMsg, InvalidReason.livePhotoVideoMissing);
    }
    final videoHash = await CryptoUtil.getHash(liveVideo);
    return (liveVideo, videoHash);
  }

  static Future<String> zip({
    required String id,
    required String imagePath,
    required String videoPath,
  }) {
    final tempPath = Configuration.instance.getTempDirectory();
    final uniqueId = const Uuid().v4().toString();
    final zipPath = "$tempPath${uniqueId}_$id.elp";
    _logger.info("Creating zip for live photo from " + basename(zipPath));
    return Computer.shared().compute<Map<String, dynamic>, String>(
      (Map<String, dynamic> args) async {
        final encoder = ZipFileEncoder();
        encoder.create(args['zipPath']);
        await encoder.addFile(
          File(args['imagePath']),
          "image${extension(args['imagePath'])}",
        );
        await encoder.addFile(
          File(args['videoPath']),
          "video${extension(args['videoPath'])}",
        );
        await encoder.close();
        return args['zipPath'];
      },
      param: {
        'zipPath': zipPath,
        'imagePath': imagePath,
        'videoPath': videoPath,
      },
      taskName: 'zip',
    );
  }
}
