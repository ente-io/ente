import "dart:ui";

import "package:figma_squircle/figma_squircle.dart";
import "package:flutter/material.dart";
import "package:photos/models/file/file.dart";
import "package:photos/ui/viewer/file/thumbnail_widget.dart";

class LinkPlaceholder extends StatelessWidget {
  const LinkPlaceholder({
    required this.files,
    super.key,
  });

  final List<EnteFile> files;

  @override
  Widget build(BuildContext context) {
    final int length = files.length;
    Widget placeholderWidget = const SizedBox(
      height: 300,
      width: 300,
    );

    if (length == 1) {
      placeholderWidget = AspectRatio(
        aspectRatio: 1,
        child: _BackDrop(
          backDropImage: files[0],
          children: [
            Padding(
              padding: const EdgeInsets.all(18.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      spreadRadius: 1,
                      blurRadius: 1,
                      offset: const Offset(1, 1),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      spreadRadius: 1,
                      blurRadius: 1,
                      offset: const Offset(-1, -1),
                    ),
                  ],
                ),
                child: ClipSmoothRect(
                  radius: SmoothBorderRadius(
                    cornerRadius: 15,
                    cornerSmoothing: 1,
                  ),
                  child: ThumbnailWidget(
                    files[0],
                    shouldShowArchiveStatus: false,
                    shouldShowSyncStatus: false,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else if (length == 2) {
      placeholderWidget = AspectRatio(
        aspectRatio: 1,
        child: _BackDrop(
          backDropImage: files[0],
          children: [
            Positioned(
              right: 20,
              bottom: 50,
              child: _CustomImage(
                height: 190,
                width: 190,
                collages: files[1],
                zIndex: 0.2,
              ),
            ),
            Positioned(
              top: 50,
              left: 20,
              child: _CustomImage(
                height: 190,
                width: 190,
                collages: files[0],
                zIndex: -0.2,
              ),
            ),
          ],
        ),
      );
    } else if (length == 3) {
      placeholderWidget = AspectRatio(
        aspectRatio: 1,
        child: _BackDrop(
          backDropImage: files[0],
          children: [
            Positioned(
              top: 55,
              left: 10,
              child: _CustomImage(
                height: 160,
                width: 160,
                collages: files[1],
                zIndex: -0.3,
              ),
            ),
            Positioned(
              right: 10,
              bottom: 50,
              child: _CustomImage(
                height: 160,
                width: 160,
                collages: files[2],
                zIndex: 0.3,
              ),
            ),
            Positioned(
              top: 100,
              left: 100,
              child: _CustomImage(
                height: 175,
                width: 175,
                collages: files[0],
                zIndex: 0.0,
              ),
            ),
          ],
        ),
      );
    } else if (length > 3) {
      placeholderWidget = Padding(
        padding: const EdgeInsets.all(8.0),
        child: AspectRatio(
          aspectRatio: 1,
          child: _BackDrop(
            backDropImage: files[0],
            children: [
              Positioned(
                top: 20,
                left: 20,
                child: _CustomImage(
                  height: 160,
                  width: 160,
                  collages: files[1],
                  zIndex: 0,
                ),
              ),
              Positioned(
                bottom: 15,
                left: 40,
                child: _CustomImage(
                  height: 160,
                  width: 160,
                  collages: files[2],
                  zIndex: 0,
                ),
              ),
              Positioned(
                top: 75,
                right: 30,
                child: _CustomImage(
                  height: 175,
                  width: 175,
                  collages: files[0],
                  zIndex: 0.0,
                ),
              ),
              Positioned(
                bottom: 30,
                right: 40,
                child: ClipSmoothRect(
                  radius: SmoothBorderRadius(
                    cornerRadius: 7.5,
                    cornerSmoothing: 1,
                  ),
                  child: Container(
                    color: Colors.white,
                    height: 50,
                    width: 50,
                    child: Center(
                      child: Text(
                        "+" "$length",
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 24,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return placeholderWidget;
  }
}

class _BackDrop extends StatelessWidget {
  const _BackDrop({
    super.key,
    required this.backDropImage,
    required this.children,
  });

  final List<Widget> children;
  final EnteFile backDropImage;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ThumbnailWidget(
          backDropImage,
          shouldShowArchiveStatus: false,
          shouldShowSyncStatus: false,
        ),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            color: Colors.transparent,
          ),
        ),
        ...children,
      ],
    );
  }
}

class _CustomImage extends StatelessWidget {
  const _CustomImage({
    required this.width,
    required this.height,
    super.key,
    required this.collages,
    required this.zIndex,
  });

  final EnteFile collages;
  final double zIndex;
  final double height;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      transform: Matrix4.rotationZ(zIndex),
      height: height,
      width: width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            spreadRadius: 1,
            blurRadius: 1,
            offset: const Offset(1, 1),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            spreadRadius: 1,
            blurRadius: 1,
            offset: const Offset(-1, -1),
          ),
        ],
      ),
      child: ClipSmoothRect(
        radius: SmoothBorderRadius(
          cornerRadius: 20.0,
          cornerSmoothing: 1,
        ),
        clipBehavior: Clip.antiAliasWithSaveLayer,
        child: ThumbnailWidget(
          collages,
          shouldShowArchiveStatus: false,
          shouldShowSyncStatus: false,
        ),
      ),
    );
  }
}
