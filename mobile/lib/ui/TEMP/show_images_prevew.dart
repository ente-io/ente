import "dart:ui";

import "package:figma_squircle/figma_squircle.dart";
import "package:flutter/material.dart";
import "package:photos/models/file/file.dart";
import "package:photos/ui/TEMP/captureImage.dart";
import "package:photos/ui/TEMP/widget_to_image.dart";
import "package:photos/ui/viewer/file/thumbnail_widget.dart";

class ShowImagePreviewFromTap extends StatefulWidget {
  const ShowImagePreviewFromTap({
    required this.tempEnteFile,
    super.key,
  });
  final List<EnteFile> tempEnteFile;
  @override
  State<ShowImagePreviewFromTap> createState() =>
      _ShowImagePreviewFromTapState();
}

class _ShowImagePreviewFromTapState extends State<ShowImagePreviewFromTap> {
  // late String tempImagePath;
  // final ValueNotifier<Uint8List?> bytesNotifier =
  //     ValueNotifier<Uint8List?>(null);

  late GlobalKey _widgetImageKey;
  final ValueNotifier<String?> tempImagePath = ValueNotifier<String?>(null);
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      //delay of 1 second before capturing the image
      await Future.delayed(const Duration(milliseconds: 100));

      tempImagePath.value = await Captures().saveImage(_widgetImageKey);

      Navigator.of(context).pop(tempImagePath.value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final int length = widget.tempEnteFile.length;
    Widget placeholderWidget = const SizedBox(
      height: 250,
      width: 250,
    );

    if (length == 1) {
      placeholderWidget = BackDrop(
        backDropImage: widget.tempEnteFile[0],
        children: [
          Padding(
            padding: const EdgeInsets.all(18.0),
            child: ClipSmoothRect(
              radius: SmoothBorderRadius(
                cornerRadius: 7.5,
                cornerSmoothing: 1,
              ),
              child: ThumbnailWidget(
                widget.tempEnteFile[0],
                shouldShowArchiveStatus: false,
                shouldShowSyncStatus: false,
              ),
            ),
          ),
        ],
      );
    } else if (length == 2) {
      placeholderWidget = BackDrop(
        backDropImage: widget.tempEnteFile[0],
        children: [
          Positioned(
            top: 65,
            left: 90,
            child: CustomImage(
              height: 100,
              width: 100,
              collages: widget.tempEnteFile[0],
              zIndex: 0.2,
            ),
          ),
          Positioned(
            top: 20,
            left: 0,
            child: CustomImage(
              height: 100,
              width: 100,
              collages: widget.tempEnteFile[1],
              zIndex: -0.2,
            ),
          ),
        ],
      );
    } else if (length == 3) {
      placeholderWidget = BackDrop(
        backDropImage: widget.tempEnteFile[0],
        children: [
          Positioned(
            top: 30,
            left: 0,
            child: CustomImage(
              height: 80,
              width: 80,
              collages: widget.tempEnteFile[1],
              zIndex: -0.4,
            ),
          ),
          Positioned(
            top: 80,
            left: 110,
            child: CustomImage(
              height: 80,
              width: 80,
              collages: widget.tempEnteFile[2],
              zIndex: 0.4,
            ),
          ),
          Positioned(
            top: 40,
            left: 40,
            child: CustomImage(
              height: 100,
              width: 100,
              collages: widget.tempEnteFile[0],
              zIndex: 0.0,
            ),
          ),
        ],
      );
    } else if (length > 3) {
      placeholderWidget = BackDrop(
        backDropImage: widget.tempEnteFile[0],
        children: [
          Positioned(
            top: 10,
            left: 10,
            child: CustomImage(
              height: 80,
              width: 80,
              collages: widget.tempEnteFile[1],
              zIndex: 0,
            ),
          ),
          Positioned(
            top: 95,
            left: 30,
            child: CustomImage(
              height: 80,
              width: 80,
              collages: widget.tempEnteFile[2],
              zIndex: 0,
            ),
          ),
          Positioned(
            top: 35,
            left: 60,
            child: CustomImage(
              height: 100,
              width: 100,
              collages: widget.tempEnteFile[0],
              zIndex: 0.0,
            ),
          ),
          Positioned(
            top: 15,
            left: 140,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "+" "$length",
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      );
    }
    return Offstage(
      offstage: false,
      child: Center(
        child: Column(
          children: [
            WidgetToImage(
              builder: (key) {
                _widgetImageKey = key;
                return placeholderWidget;
              },
            ),
          ],
        ),
      ),
    );
  }
}

class BackDrop extends StatelessWidget {
  const BackDrop({
    super.key,
    required this.backDropImage,
    required this.children,
  });
  final List<Widget> children;
  final EnteFile backDropImage;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4.0),
      height: 200,
      width: 200,
      child: Stack(
        children: [
          ClipSmoothRect(
            radius: SmoothBorderRadius(
              cornerRadius: 7.5,
              cornerSmoothing: 1,
            ),
            child: ThumbnailWidget(
              backDropImage,
              shouldShowArchiveStatus: false,
              shouldShowSyncStatus: false,
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              color: Colors.transparent,
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class CustomImage extends StatelessWidget {
  const CustomImage({
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
      child: ClipSmoothRect(
        radius: SmoothBorderRadius(
          cornerRadius: 7.5,
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

// import "dart:ui";

// import "package:figma_squircle/figma_squircle.dart";
// import "package:flutter/material.dart";
// import "package:photos/models/file/file.dart";
// import "package:photos/ui/TEMP/captureImage.dart";
// import "package:photos/ui/TEMP/widget_to_image.dart";
// import "package:photos/ui/viewer/file/thumbnail_widget.dart";

// class ShowImagePrev {
//   late GlobalKey _widgetImageKey;
//   final ValueNotifier<String?> tempImagePath = ValueNotifier<String?>(null);
//   Future<String?> imageToWidgetFunction(List<EnteFile> tempEnteFile) async {
//     showImagePreviewFromTap(tempEnteFile);
//     await Future.delayed(const Duration(milliseconds: 100));
//     tempImagePath.value = await Captures().saveImage(_widgetImageKey);

//     print("VALUE IS ==================${tempImagePath.value}");
//     if (tempImagePath.value != null) {
//       return tempImagePath.value;
//     }
//     return null;
//   }

//   Widget showImagePreviewFromTap(List<EnteFile> tempEnteFile) {
//     final int length = tempEnteFile.length;
//     Widget placeholderWidget = const SizedBox(
//       height: 250,
//       width: 250,
//     );

//     if (length == 1) {
//       placeholderWidget = BackDrop(
//         backDropImage: tempEnteFile[0],
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(18.0),
//             child: ClipSmoothRect(
//               radius: SmoothBorderRadius(
//                 cornerRadius: 7.5,
//                 cornerSmoothing: 1,
//               ),
//               child: ThumbnailWidget(
//                 tempEnteFile[0],
//                 shouldShowArchiveStatus: false,
//                 shouldShowSyncStatus: false,
//               ),
//             ),
//           ),
//         ],
//       );
//     } else if (length == 2) {
//       placeholderWidget = BackDrop(
//         backDropImage: tempEnteFile[0],
//         children: [
//           Positioned(
//             top: 65,
//             left: 90,
//             child: CustomImage(
//               height: 100,
//               width: 100,
//               collages: tempEnteFile[0],
//               zIndex: 0.2,
//             ),
//           ),
//           Positioned(
//             top: 20,
//             left: 0,
//             child: CustomImage(
//               height: 100,
//               width: 100,
//               collages: tempEnteFile[1],
//               zIndex: -0.2,
//             ),
//           ),
//         ],
//       );
//     } else if (length == 3) {
//       placeholderWidget = BackDrop(
//         backDropImage: tempEnteFile[0],
//         children: [
//           Positioned(
//             top: 30,
//             left: 0,
//             child: CustomImage(
//               height: 80,
//               width: 80,
//               collages: tempEnteFile[1],
//               zIndex: -0.4,
//             ),
//           ),
//           Positioned(
//             top: 80,
//             left: 110,
//             child: CustomImage(
//               height: 80,
//               width: 80,
//               collages: tempEnteFile[2],
//               zIndex: 0.4,
//             ),
//           ),
//           Positioned(
//             top: 40,
//             left: 40,
//             child: CustomImage(
//               height: 100,
//               width: 100,
//               collages: tempEnteFile[0],
//               zIndex: 0.0,
//             ),
//           ),
//         ],
//       );
//     } else if (length > 3) {
//       placeholderWidget = BackDrop(
//         backDropImage: tempEnteFile[0],
//         children: [
//           Positioned(
//             top: 10,
//             left: 10,
//             child: CustomImage(
//               height: 80,
//               width: 80,
//               collages: tempEnteFile[1],
//               zIndex: 0,
//             ),
//           ),
//           Positioned(
//             top: 95,
//             left: 30,
//             child: CustomImage(
//               height: 80,
//               width: 80,
//               collages: tempEnteFile[2],
//               zIndex: 0,
//             ),
//           ),
//           Positioned(
//             top: 35,
//             left: 60,
//             child: CustomImage(
//               height: 100,
//               width: 100,
//               collages: tempEnteFile[0],
//               zIndex: 0.0,
//             ),
//           ),
//           Positioned(
//             top: 15,
//             left: 140,
//             child: Container(
//               padding: const EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Text(
//                 "+ $length",
//                 style: const TextStyle(
//                   fontWeight: FontWeight.w600,
//                   color: Colors.black,
//                 ),
//               ),
//             ),
//           ),
//         ],
//       );
//     }

//     return Center(
//       child: WidgetToImage(
//         builder: (key) {
//           _widgetImageKey = key;
//           return placeholderWidget;
//         },
//       ),
//     );
//   }
// }

// class BackDrop extends StatelessWidget {
//   const BackDrop({
//     super.key,
//     required this.backDropImage,
//     required this.children,
//   });
//   final List<Widget> children;
//   final EnteFile backDropImage;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(4.0),
//       height: 200,
//       width: 200,
//       child: Stack(
//         children: [
//           ClipSmoothRect(
//             radius: SmoothBorderRadius(
//               cornerRadius: 7.5,
//               cornerSmoothing: 1,
//             ),
//             child: ThumbnailWidget(
//               backDropImage,
//               shouldShowArchiveStatus: false,
//               shouldShowSyncStatus: false,
//             ),
//           ),
//           BackdropFilter(
//             filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
//             child: Container(
//               color: Colors.transparent,
//             ),
//           ),
//           ...children,
//         ],
//       ),
//     );
//   }
// }

// class CustomImage extends StatelessWidget {
//   const CustomImage({
//     required this.width,
//     required this.height,
//     super.key,
//     required this.collages,
//     required this.zIndex,
//   });
//   final EnteFile collages;
//   final double zIndex;
//   final double height;
//   final double width;
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       transform: Matrix4.rotationZ(zIndex),
//       height: height,
//       width: width,
//       child: ClipSmoothRect(
//         radius: SmoothBorderRadius(
//           cornerRadius: 7.5,
//           cornerSmoothing: 1,
//         ),
//         clipBehavior: Clip.antiAliasWithSaveLayer,
//         child: ThumbnailWidget(
//           collages,
//           shouldShowArchiveStatus: false,
//           shouldShowSyncStatus: false,
//         ),
//       ),
//     );
//   }
// }
// import "dart:ui";

// import "package:figma_squircle/figma_squircle.dart";
// import "package:flutter/material.dart";
// import "package:photos/models/file/file.dart";
// import "package:photos/ui/TEMP/captureImage.dart";
// import "package:photos/ui/TEMP/widget_to_image.dart";
// import "package:photos/ui/viewer/file/thumbnail_widget.dart";

// class ShowImagePrev {
//   late GlobalKey _widgetImageKey;
//   final ValueNotifier<String?> tempImagePath = ValueNotifier<String?>(null);

//   ShowImagePrev() {
//     _widgetImageKey = GlobalKey();
//   }

//   Future<String?> imageToWidgetFunction(List<EnteFile> tempEnteFile) async {
//     showImagePreviewFromTap(tempEnteFile);
//     // Build the widget to ensure the GlobalKey is assigned correctly
//     WidgetsBinding.instance.addPostFrameCallback((_) async {
//       await Future.delayed(const Duration(milliseconds: 100));
//       tempImagePath.value = await Captures().saveImage(_widgetImageKey);
//       print("VALUE IS ==================${tempImagePath.value}");
//     });

//     return tempImagePath.value;
//   }

//   Widget showImagePreviewFromTap(List<EnteFile> tempEnteFile) {
//     final int length = tempEnteFile.length;
//     Widget placeholderWidget = const SizedBox(
//       height: 250,
//       width: 250,
//     );

//     if (length == 1) {
//       placeholderWidget = BackDrop(
//         backDropImage: tempEnteFile[0],
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(18.0),
//             child: ClipSmoothRect(
//               radius: SmoothBorderRadius(
//                 cornerRadius: 7.5,
//                 cornerSmoothing: 1,
//               ),
//               child: ThumbnailWidget(
//                 tempEnteFile[0],
//                 shouldShowArchiveStatus: false,
//                 shouldShowSyncStatus: false,
//               ),
//             ),
//           ),
//         ],
//       );
//     } else if (length == 2) {
//       placeholderWidget = BackDrop(
//         backDropImage: tempEnteFile[0],
//         children: [
//           Positioned(
//             top: 65,
//             left: 90,
//             child: CustomImage(
//               height: 100,
//               width: 100,
//               collages: tempEnteFile[0],
//               zIndex: 0.2,
//             ),
//           ),
//           Positioned(
//             top: 20,
//             left: 0,
//             child: CustomImage(
//               height: 100,
//               width: 100,
//               collages: tempEnteFile[1],
//               zIndex: -0.2,
//             ),
//           ),
//         ],
//       );
//     } else if (length == 3) {
//       placeholderWidget = BackDrop(
//         backDropImage: tempEnteFile[0],
//         children: [
//           Positioned(
//             top: 30,
//             left: 0,
//             child: CustomImage(
//               height: 80,
//               width: 80,
//               collages: tempEnteFile[1],
//               zIndex: -0.4,
//             ),
//           ),
//           Positioned(
//             top: 80,
//             left: 110,
//             child: CustomImage(
//               height: 80,
//               width: 80,
//               collages: tempEnteFile[2],
//               zIndex: 0.4,
//             ),
//           ),
//           Positioned(
//             top: 40,
//             left: 40,
//             child: CustomImage(
//               height: 100,
//               width: 100,
//               collages: tempEnteFile[0],
//               zIndex: 0.0,
//             ),
//           ),
//         ],
//       );
//     } else if (length > 3) {
//       placeholderWidget = BackDrop(
//         backDropImage: tempEnteFile[0],
//         children: [
//           Positioned(
//             top: 10,
//             left: 10,
//             child: CustomImage(
//               height: 80,
//               width: 80,
//               collages: tempEnteFile[1],
//               zIndex: 0,
//             ),
//           ),
//           Positioned(
//             top: 95,
//             left: 30,
//             child: CustomImage(
//               height: 80,
//               width: 80,
//               collages: tempEnteFile[2],
//               zIndex: 0,
//             ),
//           ),
//           Positioned(
//             top: 35,
//             left: 60,
//             child: CustomImage(
//               height: 100,
//               width: 100,
//               collages: tempEnteFile[0],
//               zIndex: 0.0,
//             ),
//           ),
//           Positioned(
//             top: 15,
//             left: 140,
//             child: Container(
//               padding: const EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Text(
//                 "+ $length",
//                 style: const TextStyle(
//                   fontWeight: FontWeight.w600,
//                   color: Colors.black,
//                 ),
//               ),
//             ),
//           ),
//         ],
//       );
//     }

//     return Center(
//       child: WidgetToImage(
//         builder: (key) {
//           _widgetImageKey = key;
//           return placeholderWidget;
//         },
//       ),
//     );
//   }
// }

// class BackDrop extends StatelessWidget {
//   const BackDrop({
//     super.key,
//     required this.backDropImage,
//     required this.children,
//   });
//   final List<Widget> children;
//   final EnteFile backDropImage;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(4.0),
//       height: 200,
//       width: 200,
//       child: Stack(
//         children: [
//           ClipSmoothRect(
//             radius: SmoothBorderRadius(
//               cornerRadius: 7.5,
//               cornerSmoothing: 1,
//             ),
//             child: ThumbnailWidget(
//               backDropImage,
//               shouldShowArchiveStatus: false,
//               shouldShowSyncStatus: false,
//             ),
//           ),
//           BackdropFilter(
//             filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
//             child: Container(
//               color: Colors.transparent,
//             ),
//           ),
//           ...children,
//         ],
//       ),
//     );
//   }
// }

// class CustomImage extends StatelessWidget {
//   const CustomImage({
//     required this.width,
//     required this.height,
//     super.key,
//     required this.collages,
//     required this.zIndex,
//   });
//   final EnteFile collages;
//   final double zIndex;
//   final double height;
//   final double width;
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       transform: Matrix4.rotationZ(zIndex),
//       height: height,
//       width: width,
//       child: ClipSmoothRect(
//         radius: SmoothBorderRadius(
//           cornerRadius: 7.5,
//           cornerSmoothing: 1,
//         ),
//         clipBehavior: Clip.antiAliasWithSaveLayer,
//         child: ThumbnailWidget(
//           collages,
//           shouldShowArchiveStatus: false,
//           shouldShowSyncStatus: false,
//         ),
//       ),
//     );
//   }
// }
