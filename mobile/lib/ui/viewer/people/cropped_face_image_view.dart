import "dart:io" show File;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import "package:image/image.dart" as img;
import "package:logging/logging.dart";
import "package:photos/face/model/face.dart";
import "package:photos/models/file/file.dart";
import "package:photos/ui/viewer/file/thumbnail_widget.dart";
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

class CroppedFaceImageView extends StatefulWidget {
  final EnteFile enteFile;
  final Face face;

  const CroppedFaceImageView({
    Key? key,
    required this.enteFile,
    required this.face,
  }) : super(key: key);

  @override
  CroppedFaceImageViewState createState() => CroppedFaceImageViewState();
}

class CroppedFaceImageViewState extends State<CroppedFaceImageView> {
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

      final image = await img.decodeImageFile(ioFile.path);

      if (image == null) {
        throw Exception("Failed decoding image file ${widget.enteFile.title}}");
      }

      final croppedImage = img.copyCrop(
        image,
        x: (image.width * faceBox.xMin).round(),
        y: (image.height * faceBox.yMin).round(),
        width: (image.width * faceBox.width).round(),
        height: (image.height * faceBox.height).round(),
        antialias: false,
      );

      return convertImageToFlutterUi(croppedImage);
    } catch (e, s) {
      _logger.severe("Error getting image", e, s);
      return null;
    }
  }
}
