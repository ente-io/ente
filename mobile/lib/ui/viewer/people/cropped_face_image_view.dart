import 'dart:developer' show log;
import "dart:io" show File;

import 'package:flutter/material.dart';
import "package:photos/face/model/face.dart";
import "package:photos/models/file/file.dart";
import "package:photos/ui/viewer/file/thumbnail_widget.dart";
import "package:photos/utils/file_util.dart";

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

class CroppedFaceImageView extends StatelessWidget {
  final EnteFile enteFile;
  final Face face;

  const CroppedFaceImageView({
    Key? key,
    required this.enteFile,
    required this.face,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: getImage(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final Image image = snapshot.data!;

              final double viewWidth = constraints.maxWidth;
              final double viewHeight = constraints.maxHeight;

              final faceBox = face.detection.box;

              final double relativeFaceCenterX =
                  faceBox.xMin + faceBox.width / 2;
              final double relativeFaceCenterY =
                  faceBox.yMin + faceBox.height / 2;

              const double desiredFaceHeightRelativeToWidget = 7 / 10;
              final double scale =
                  (1 / faceBox.height) * desiredFaceHeightRelativeToWidget;

              final double widgetCenterX = viewWidth / 2;
              final double widgetCenterY = viewHeight / 2;

              final double imageAspectRatio = enteFile.width / enteFile.height;
              final double widgetAspectRatio = viewWidth / viewHeight;
              final double imageToWidgetRatio =
                  imageAspectRatio / widgetAspectRatio;

              double offsetX =
                  (widgetCenterX - relativeFaceCenterX * viewWidth) * scale;
              double offsetY =
                  (widgetCenterY - relativeFaceCenterY * viewHeight) * scale;

              if (imageAspectRatio > widgetAspectRatio) {
                // Landscape Image: Adjust offsetX more conservatively
                offsetX = offsetX * imageToWidgetRatio;
              } else {
                // Portrait Image: Adjust offsetY more conservatively
                offsetY = offsetY / imageToWidgetRatio;
              }

              return ClipRect(
                clipBehavior: Clip.antiAlias,
                child: Transform.translate(
                  offset: Offset(
                    offsetX,
                    offsetY,
                  ),
                  child: Transform.scale(
                    scale: scale,
                    child: image,
                  ),
                ),
              );
            },
          );
        } else {
          if (snapshot.hasError) {
            log('Error getting cover face for person: ${snapshot.error}');
          }
          return ThumbnailWidget(
            enteFile,
          );
        }
      },
    );
  }

  Future<Image?> getImage() async {
    final File? ioFile = await getFile(enteFile);
    if (ioFile == null) {
      return null;
    }

    final imageData = await ioFile.readAsBytes();
    final image = Image.memory(imageData, fit: BoxFit.cover);

    return image;
  }
}
