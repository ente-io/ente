import "dart:io" show File;
import "dart:typed_data";
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import "package:flutter/widgets.dart";
import "package:logging/logging.dart";
import "package:photos/face/model/face.dart";
import "package:photos/models/file/file.dart";
import "package:photos/ui/viewer/file/thumbnail_widget.dart";
import "package:photos/utils/face/face_util.dart";
import "package:photos/utils/file_util.dart";
import "package:photos/utils/image_util.dart";

class CroppedFaceInfo {
  final Image image;
  final double scale;
  final double offsetX;
  final double offsetY;

  const CroppedFaceInfo({
    required this.image,
    required this.scale,
    required this.offsetX,
    required this.offsetY,
  });
}

class CroppedFaceImgImageView extends StatefulWidget {
  final EnteFile enteFile;
  final Face face;

  const CroppedFaceImgImageView({
    Key? key,
    required this.enteFile,
    required this.face,
  }) : super(key: key);

  @override
  CroppedFaceImgImageViewState createState() => CroppedFaceImgImageViewState();
}

class CroppedFaceImgImageViewState extends State<CroppedFaceImgImageView> {
  ui.Image? _image;
  final _logger = Logger("CroppedFaceImageView");

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void dispose() {
    super.dispose();
    _image?.dispose();
  }

  Future<void> _loadImage() async {
    final image = await getImage();
    if (mounted) {
      setState(() {
        _image = image;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _image != null
        ? LayoutBuilder(
            builder: (context, constraints) {
              return RawImage(
                image: _image!,
              );
            },
          )
        : ThumbnailWidget(widget.enteFile);
  }

  Future<ui.Image?> getImage() async {
    try {
      final faceBox = widget.face.detection.box;

      final File? ioFile = await getFile(widget.enteFile);
      if (ioFile == null) {
        return null;
      }

      final image = await generateImgFaceThumbnails(ioFile.path, [faceBox]);

      return convertImageToFlutterUi(image.first);
    } catch (e, s) {
      _logger.severe("Error getting image", e, s);
      return null;
    }
  }
}

class CroppedFaceJpgImageView extends StatefulWidget {
  final EnteFile enteFile;
  final Face face;

  const CroppedFaceJpgImageView({
    Key? key,
    required this.enteFile,
    required this.face,
  }) : super(key: key);

  @override
  CroppedFaceJpgImageViewState createState() => CroppedFaceJpgImageViewState();
}

class CroppedFaceJpgImageViewState extends State<CroppedFaceJpgImageView> {
  Uint8List? _image;
  final _logger = Logger("CroppedFaceImageView");

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadImage() async {
    final image = await getImage();
    if (mounted) {
      setState(() {
        _image = image;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _image != null
        ? LayoutBuilder(
            builder: (context, constraints) {
              return Image.memory(
                _image!,
              );
            },
          )
        : ThumbnailWidget(widget.enteFile);
  }

  Future<Uint8List?> getImage() async {
    try {
      final faceBox = widget.face.detection.box;

      final File? ioFile = await getFile(widget.enteFile);
      if (ioFile == null) {
        return null;
      }

      final image = await generateJpgFaceThumbnails(ioFile.path, [faceBox]);

      return image.first;
    } catch (e, s) {
      _logger.severe("Error getting image", e, s);
      return null;
    }
  }
}
