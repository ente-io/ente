import "package:exif/exif.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:logging/logging.dart";
import "package:photos/core/configuration.dart";
import 'package:photos/db/files_db.dart';
import "package:photos/ente_theme_data.dart";
import "package:photos/models/collection.dart";
import "package:photos/models/collection_items.dart";
import "package:photos/models/file.dart";
import "package:photos/models/file_type.dart";
import "package:photos/models/gallery_type.dart";
import 'package:photos/services/collections_service.dart';
import "package:photos/services/feature_flag_service.dart";
import 'package:photos/theme/ente_theme.dart';
import "package:photos/ui/components/buttons/chip_button_widget.dart";
import 'package:photos/ui/components/buttons/icon_button_widget.dart';
import 'package:photos/ui/components/divider_widget.dart';
import "package:photos/ui/components/info_item_widget.dart";
import 'package:photos/ui/components/title_bar_widget.dart';
import 'package:photos/ui/viewer/file/file_caption_widget.dart';
import "package:photos/ui/viewer/file_details/backed_up_date_item_widget.dart";
import "package:photos/ui/viewer/file_details/creation_time_item_widget.dart";
import "package:photos/ui/viewer/file_details/exif_item_widget.dart";
import "package:photos/ui/viewer/file_details/file_properties_item_widget.dart";
import "package:photos/ui/viewer/file_details/objects_item_widget.dart";
import "package:photos/ui/viewer/gallery/collection_page.dart";
import "package:photos/utils/exif_util.dart";
import "package:photos/utils/navigation_util.dart";

class FileDetailsWidget extends StatefulWidget {
  final File file;
  const FileDetailsWidget(
    this.file, {
    Key? key,
  }) : super(key: key);

  @override
  State<FileDetailsWidget> createState() => _FileDetailsWidgetState();
}

class _FileDetailsWidgetState extends State<FileDetailsWidget> {
  Map<String, IfdTag>? _exif;
  final Map<String, dynamic> _exifData = {
    "focalLength": null,
    "fNumber": null,
    "resolution": null,
    "takenOnDevice": null,
    "exposureTime": null,
    "ISO": null,
    "megaPixels": null
  };

  bool _isImage = false;
  late int _currentUserID;

  @override
  void initState() {
    debugPrint('file_details_sheet initState');
    _currentUserID = Configuration.instance.getUserID()!;
    _isImage = widget.file.fileType == FileType.image ||
        widget.file.fileType == FileType.livePhoto;
    if (_isImage) {
      getExif(widget.file).then((exif) {
        if (mounted) {
          setState(() {
            _exif = exif;
          });
        }
      });
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final subtitleTextTheme = getEnteTextTheme(context).smallMuted;
    final file = widget.file;
    final fileIsBackedup = file.uploadedFileID == null ? false : true;
    final bool isFileOwner =
        file.ownerID == null || file.ownerID == _currentUserID;
    late Future<Set<int>> allCollectionIDsOfFile;
    //Typing this as Future<Set<T>> as it would be easier to implement showing multiple device folders for a file in the future
    final Future<Set<String>> allDeviceFoldersOfFile =
        Future.sync(() => {file.deviceFolder ?? ''});
    if (fileIsBackedup) {
      allCollectionIDsOfFile = FilesDB.instance.getAllCollectionIDsOfFile(
        file.uploadedFileID!,
      );
    }

    if (_isImage && _exif != null) {
      _generateExifForDetails(_exif!);
    }
    final bool showExifListTile = _exifData["focalLength"] != null ||
        _exifData["fNumber"] != null ||
        _exifData["takenOnDevice"] != null ||
        _exifData["exposureTime"] != null ||
        _exifData["ISO"] != null;
    final fileDetailsTiles = <Widget?>[
      !widget.file.isUploaded ||
              (!isFileOwner && (widget.file.caption?.isEmpty ?? true))
          ? const SizedBox(height: 16)
          : Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              child: isFileOwner
                  ? FileCaptionWidget(file: widget.file)
                  : FileCaptionReadyOnly(caption: widget.file.caption!),
            ),
      CreationTimeItem(file, _currentUserID),
      FilePropertiesWidget(file, _isImage, _exifData, _currentUserID),
      showExifListTile ? BasicExifItemWidget(_exifData) : null,
      _isImage ? AllExifItemWidget(file, _exif) : null,
      FeatureFlagService.instance.isInternalUserOrDebugBuild()
          ? ObjectsItemWidget(file)
          : null,
      (file.uploadedFileID != null && file.updationTime != null)
          ? BackedUpDateItemWidget(file)
          : null,
      InfoItemWidget(
        key: const ValueKey("Albums"),
        leadingIcon: Icons.folder_outlined,
        title: "Albums",
        subtitleSection: fileIsBackedup
            ? _collectionsListOfFile(allCollectionIDsOfFile, _currentUserID!)
            : _deviceFoldersListOfFile(allDeviceFoldersOfFile),
        hasChipButtons: true,
      ),
    ];

    fileDetailsTiles.removeWhere(
      (element) => element == null,
    );

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
                title: "Details",
                isOnTopOfScreen: false,
                backgroundColor: getEnteColorScheme(context).backgroundElevated,
                leading: IconButtonWidget(
                  icon: Icons.expand_more_outlined,
                  iconButtonType: IconButtonType.primary,
                  onTap: () => Navigator.pop(context),
                ),
              ),
              SliverToBoxAdapter(child: addedBy(widget.file)),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    //Dividers occupy odd indexes
                    if (index.isOdd) {
                      return index == 1
                          ? const SizedBox.shrink()
                          : const Padding(
                              padding: EdgeInsets.symmetric(vertical: 15.5),
                              child: DividerWidget(
                                dividerType: DividerType.menu,
                                divColorHasBlur: false,
                              ),
                            );
                    } else {
                      return fileDetailsTiles[index ~/ 2];
                    }
                  },
                  childCount: (fileDetailsTiles.length * 2) - 1,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<List<ChipButtonWidget>> _deviceFoldersListOfFile(
    Future<Set<String>> allDeviceFoldersOfFile,
  ) async {
    try {
      final chipButtons = <ChipButtonWidget>[];
      final List<String> deviceFolders =
          (await allDeviceFoldersOfFile).toList();
      for (var deviceFolder in deviceFolders) {
        chipButtons.add(
          ChipButtonWidget(
            deviceFolder,
          ),
        );
      }
      return chipButtons;
    } catch (e, s) {
      Logger("FileInfoWidget").info(e, s);
      return [];
    }
  }

  Future<List<ChipButtonWidget>> _collectionsListOfFile(
    Future<Set<int>> allCollectionIDsOfFile,
    int currentUserID,
  ) async {
    try {
      final chipButtons = <ChipButtonWidget>[];
      final Set<int> collectionIDs = await allCollectionIDsOfFile;
      final collections = <Collection>[];
      for (var collectionID in collectionIDs) {
        final c = CollectionsService.instance.getCollectionByID(collectionID);
        collections.add(c!);
        chipButtons.add(
          ChipButtonWidget(
            c.isHidden() ? "Hidden" : c.name,
            onTap: () {
              if (c.isHidden()) {
                return;
              }
              routeToPage(
                context,
                CollectionPage(
                  CollectionWithThumbnail(c, null),
                  appBarType: c.isOwner(currentUserID)
                      ? GalleryType.ownedCollection
                      : GalleryType.sharedCollection,
                ),
              );
            },
          ),
        );
      }
      return chipButtons;
    } catch (e, s) {
      Logger("FileInfoWidget").info(e, s);
      return [];
    }
  }

  Widget addedBy(File file) {
    if (file.uploadedFileID == null) {
      return const SizedBox.shrink();
    }
    String? addedBy;
    if (file.ownerID == _currentUserID) {
      if (file.pubMagicMetadata!.uploaderName != null) {
        addedBy = file.pubMagicMetadata!.uploaderName;
      }
    } else {
      final fileOwner = CollectionsService.instance
          .getFileOwner(file.ownerID!, file.collectionID);
      addedBy = fileOwner.email;
    }
    if (addedBy == null || addedBy.isEmpty) {
      return const SizedBox.shrink();
    }
    final enteTheme = Theme.of(context).colorScheme.enteTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 4.0, bottom: 4.0, left: 16),
      child: Text(
        "Added by $addedBy",
        style: enteTheme.textTheme.mini
            .copyWith(color: enteTheme.colorScheme.textMuted),
      ),
    );
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
      _exifData['megaPixels'] =
          ((imageWidth.values.firstAsInt() * imageLength.values.firstAsInt()) /
                  1000000)
              .toStringAsFixed(1);
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
