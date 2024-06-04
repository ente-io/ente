import "dart:async" show StreamSubscription;

import "package:exif/exif.dart";
import "package:flutter/material.dart";
import "package:logging/logging.dart";
import "package:photos/core/configuration.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/events/people_changed_event.dart";
import "package:photos/generated/l10n.dart";
import 'package:photos/models/file/file.dart';
import 'package:photos/models/file/file_type.dart';
import "package:photos/models/metadata/file_magic.dart";
import "package:photos/services/file_magic_service.dart";
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/components/buttons/icon_button_widget.dart';
import "package:photos/ui/components/divider_widget.dart";
import 'package:photos/ui/components/title_bar_widget.dart';
import 'package:photos/ui/viewer/file/file_caption_widget.dart';
import "package:photos/ui/viewer/file_details/added_by_widget.dart";
import "package:photos/ui/viewer/file_details/albums_item_widget.dart";
import 'package:photos/ui/viewer/file_details/backed_up_time_item_widget.dart';
import "package:photos/ui/viewer/file_details/creation_time_item_widget.dart";
import 'package:photos/ui/viewer/file_details/exif_item_widgets.dart';
import "package:photos/ui/viewer/file_details/faces_item_widget.dart";
import "package:photos/ui/viewer/file_details/file_properties_item_widget.dart";
import "package:photos/ui/viewer/file_details/location_tags_widget.dart";
import "package:photos/utils/exif_util.dart";
import "package:photos/utils/local_settings.dart";

class FileDetailsWidget extends StatefulWidget {
  final EnteFile file;

  const FileDetailsWidget(
    this.file, {
    Key? key,
  }) : super(key: key);

  @override
  State<FileDetailsWidget> createState() => _FileDetailsWidgetState();
}

class _FileDetailsWidgetState extends State<FileDetailsWidget> {
  final ValueNotifier<Map<String, IfdTag>?> _exifNotifier = ValueNotifier(null);
  final Map<String, dynamic> _exifData = {
    "focalLength": null,
    "fNumber": null,
    "resolution": null,
    "takenOnDevice": null,
    "exposureTime": null,
    "ISO": null,
    "megaPixels": null,
    "lat": null,
    "long": null,
    "latRef": null,
    "longRef": null,
  };

  late final StreamSubscription<PeopleChangedEvent> _peopleChangedEvent;

  bool _isImage = false;
  late int _currentUserID;
  bool showExifListTile = false;
  final ValueNotifier<bool> hasLocationData = ValueNotifier(false);
  final Logger _logger = Logger("_FileDetailsWidgetState");

  @override
  void initState() {
    debugPrint('file_details_sheet initState');
    _currentUserID = Configuration.instance.getUserID()!;
    hasLocationData.value = widget.file.hasLocation;
    _isImage = widget.file.fileType == FileType.image ||
        widget.file.fileType == FileType.livePhoto;

    _peopleChangedEvent = Bus.instance.on<PeopleChangedEvent>().listen((event) {
      setState(() {});
    });

    _exifNotifier.addListener(() {
      if (_exifNotifier.value != null && !widget.file.hasLocation) {
        _updateLocationFromExif(_exifNotifier.value!).ignore();
      }
    });

    if (_isImage) {
      _exifNotifier.addListener(() {
        if (_exifNotifier.value != null) {
          _generateExifForDetails(_exifNotifier.value!);
        }
        showExifListTile = _exifData["focalLength"] != null ||
            _exifData["fNumber"] != null ||
            _exifData["takenOnDevice"] != null ||
            _exifData["exposureTime"] != null ||
            _exifData["ISO"] != null;
      });
    }
    getExif(widget.file).then((exif) {
      _exifNotifier.value = exif;
    });

    super.initState();
  }

  @override
  void dispose() {
    _exifNotifier.dispose();
    _peopleChangedEvent.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final file = widget.file;
    final bool isFileOwner =
        file.ownerID == null || file.ownerID == _currentUserID;

    //Make sure the bottom most tile is always the same one, that is it should
    //not be rendered only if a condition is met.
    final fileDetailsTiles = <Widget>[];
    fileDetailsTiles.add(
      !widget.file.isUploaded ||
              (!isFileOwner && (widget.file.caption?.isEmpty ?? true))
          ? const SizedBox(height: 16)
          : Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              child: isFileOwner
                  ? FileCaptionWidget(file: widget.file)
                  : FileCaptionReadyOnly(caption: widget.file.caption!),
            ),
    );
    fileDetailsTiles.addAll([
      CreationTimeItem(file, _currentUserID),
      const FileDetailsDivider(),
      ValueListenableBuilder(
        valueListenable: _exifNotifier,
        builder: (context, _, __) => FilePropertiesItemWidget(
          file,
          _isImage,
          _exifData,
          _currentUserID,
        ),
      ),
      const FileDetailsDivider(),
    ]);
    fileDetailsTiles.add(
      ValueListenableBuilder(
        valueListenable: _exifNotifier,
        builder: (context, value, _) {
          return showExifListTile
              ? Column(
                  children: [
                    BasicExifItemWidget(_exifData),
                    const FileDetailsDivider(),
                  ],
                )
              : const SizedBox.shrink();
        },
      ),
    );

    fileDetailsTiles.addAll([
      ValueListenableBuilder(
        valueListenable: hasLocationData,
        builder: (context, bool value, __) {
          return value
              ? Column(
                  children: [
                    LocationTagsWidget(
                      widget.file,
                    ),
                    const FileDetailsDivider(),
                  ],
                )
              : const SizedBox.shrink();

          ///To be used when state issues are fixed when location is updated.
          //
          //  file.fileType != FileType.video &&
          //         file.ownerID == _currentUserID
          //     ? Column(
          //         children: [
          //           InfoItemWidget(
          //             leadingIcon: Icons.pin_drop_outlined,
          //             title: "No location data",
          //             subtitleSection: Future.value(
          //               [
          //                 Text(
          //                   "Add location data",
          //                   style: getEnteTextTheme(context).miniBoldMuted,
          //                 ),
          //               ],
          //             ),
          //             hasChipButtons: false,
          //             onTap: () async {
          //               await showBarModalBottomSheet(
          //                 shape: const RoundedRectangleBorder(
          //                   borderRadius: BorderRadius.vertical(
          //                     top: Radius.circular(5),
          //                   ),
          //                 ),
          //                 backgroundColor: getEnteColorScheme(context)
          //                     .backgroundElevated,
          //                 barrierColor: backdropFaintDark,
          //                 context: context,
          //                 builder: (context) {
          //                   return UpdateLocationDataWidget([file]);
          //                 },
          //               );
          //             },
          //           ),
          //           const FileDetailsDivider(),
          //         ],
          //       )
          //     : const SizedBox.shrink();
        },
      ),
    ]);
    if (_isImage) {
      fileDetailsTiles.addAll([
        ValueListenableBuilder(
          valueListenable: _exifNotifier,
          builder: (context, value, _) {
            return Column(
              children: [
                AllExifItemWidget(file, _exifNotifier.value),
                const FileDetailsDivider(),
              ],
            );
          },
        ),
      ]);
    }

    if (LocalSettings.instance.isFaceIndexingEnabled) {
      fileDetailsTiles.addAll([
        FacesItemWidget(file),
        const FileDetailsDivider(),
      ]);
    }

    if (file.uploadedFileID != null && file.updationTime != null) {
      fileDetailsTiles.addAll(
        [
          BackedUpTimeItemWidget(file),
          const FileDetailsDivider(),
        ],
      );
    }
    fileDetailsTiles.add(AlbumsItemWidget(file, _currentUserID));

    return SafeArea(
      top: false,
      child: Scrollbar(
        thickness: 4,
        radius: const Radius.circular(2),
        thumbVisibility: true,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CustomScrollView(
            physics: const ClampingScrollPhysics(),
            shrinkWrap: true,
            slivers: <Widget>[
              TitleBarWidget(
                isFlexibleSpaceDisabled: true,
                title: S.of(context).details,
                isOnTopOfScreen: false,
                backgroundColor: getEnteColorScheme(context).backgroundElevated,
                leading: IconButtonWidget(
                  icon: Icons.expand_more_outlined,
                  iconButtonType: IconButtonType.primary,
                  onTap: () => Navigator.pop(context),
                ),
              ),
              SliverToBoxAdapter(child: AddedByWidget(widget.file)),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return fileDetailsTiles[index];
                  },
                  childCount: fileDetailsTiles.length,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //This code is for updating the location of files in which location data is
  //missing and the EXIF has location data. This is only happens for a
  //certain specific minority of devices.
  Future<void> _updateLocationFromExif(Map<String, IfdTag> exif) async {
    // If the file is not uploaded or the file is not owned by the current user
    // then we don't need to update the location.
    if (!widget.file.isUploaded || widget.file.ownerID! != _currentUserID) {
      return;
    }
    try {
      final locationDataFromExif = locationFromExif(exif);
      if (locationDataFromExif?.latitude != null &&
          locationDataFromExif?.longitude != null) {
        widget.file.location = locationDataFromExif;
        await FileMagicService.instance.updatePublicMagicMetadata([
          widget.file,
        ], {
          latKey: locationDataFromExif!.latitude,
          longKey: locationDataFromExif.longitude,
        });
        hasLocationData.value = true;
      }
    } catch (e, s) {
      _logger.severe("Error while updating location from EXIF", e, s);
    }
  }

  _generateExifForDetails(Map<String, IfdTag> exif) {
    if (exif["EXIF FocalLength"] != null) {
      _exifData["focalLength"] =
          (exif["EXIF FocalLength"]!.values.toList()[0] as Ratio).numerator /
              (exif["EXIF FocalLength"]!.values.toList()[0] as Ratio)
                  .denominator;
    }

    if (exif["EXIF FNumber"] != null) {
      _exifData["fNumber"] =
          (exif["EXIF FNumber"]!.values.toList()[0] as Ratio).numerator /
              (exif["EXIF FNumber"]!.values.toList()[0] as Ratio).denominator;
    }
    final imageWidth = exif["EXIF ExifImageWidth"] ?? exif["Image ImageWidth"];
    final imageLength = exif["EXIF ExifImageLength"] ??
        exif["Image "
            "ImageLength"];
    if (imageWidth != null && imageLength != null) {
      _exifData["resolution"] = '$imageWidth x $imageLength';
      final double megaPixels =
          (imageWidth.values.firstAsInt() * imageLength.values.firstAsInt()) /
              1000000;
      final double roundedMegaPixels = (megaPixels * 10).round() / 10.0;
      _exifData['megaPixels'] = roundedMegaPixels..toStringAsFixed(1);
    } else {
      debugPrint("No image width/height");
    }
    if (exif["Image Make"] != null && exif["Image Model"] != null) {
      _exifData["takenOnDevice"] =
          exif["Image Make"].toString() + " " + exif["Image Model"].toString();
    }

    if (exif["EXIF ExposureTime"] != null) {
      _exifData["exposureTime"] = exif["EXIF ExposureTime"].toString();
    }
    if (exif["EXIF ISOSpeedRatings"] != null) {
      _exifData['ISO'] = exif["EXIF ISOSpeedRatings"].toString();
    }
  }
}

class FileDetailsDivider extends StatelessWidget {
  const FileDetailsDivider({super.key});

  @override
  Widget build(BuildContext context) {
    const dividerPadding = EdgeInsets.symmetric(vertical: 9.5);
    return const DividerWidget(
      dividerType: DividerType.menu,
      divColorHasBlur: false,
      padding: dividerPadding,
    );
  }
}
