import "package:exif/exif.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:path/path.dart' as path;
import 'package:photo_manager/photo_manager.dart';
import "package:photos/core/configuration.dart";
import 'package:photos/db/files_db.dart';
import "package:photos/ente_theme_data.dart";
import "package:photos/models/file.dart";
import "package:photos/models/file_type.dart";
import 'package:photos/services/collections_service.dart';
import "package:photos/services/feature_flag_service.dart";
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/components/buttons/icon_button_widget.dart';
import 'package:photos/ui/components/divider_widget.dart';
import "package:photos/ui/components/info_item_widget.dart";
import 'package:photos/ui/components/title_bar_widget.dart';
import 'package:photos/ui/viewer/file/collections_list_of_file_widget.dart';
import 'package:photos/ui/viewer/file/device_folders_list_of_file_widget.dart';
import 'package:photos/ui/viewer/file/file_caption_widget.dart';
import "package:photos/ui/viewer/file/object_tags_widget.dart";
import 'package:photos/ui/viewer/file/raw_exif_list_tile_widget.dart';
import "package:photos/utils/date_time_util.dart";
import "package:photos/utils/exif_util.dart";
import "package:photos/utils/file_util.dart";
import "package:photos/utils/magic_util.dart";

class FileInfoWidget extends StatefulWidget {
  final File file;
  const FileInfoWidget(
    this.file, {
    Key? key,
  }) : super(key: key);

  @override
  State<FileInfoWidget> createState() => _FileInfoWidgetState();
}

class _FileInfoWidgetState extends State<FileInfoWidget> {
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
  int? _currentUserID;

  @override
  void initState() {
    debugPrint('file_info_dialog initState');
    _currentUserID = Configuration.instance.getUserID();
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
    final dateTime = DateTime.fromMicrosecondsSinceEpoch(file.creationTime!);
    final dateTimeForUpdationTime =
        DateTime.fromMicrosecondsSinceEpoch(file.updationTime!);

    if (_isImage && _exif != null) {
      _generateExifForDetails(_exif!);
    }
    final bool showExifListTile = _exifData["focalLength"] != null ||
        _exifData["fNumber"] != null ||
        _exifData["takenOnDevice"] != null ||
        _exifData["exposureTime"] != null ||
        _exifData["ISO"] != null;
    final bool showDimension =
        _exifData["resolution"] != null && _exifData["megaPixels"] != null;
    final listTiles = <Widget?>[
      !widget.file.isUploaded ||
              (!isFileOwner && (widget.file.caption?.isEmpty ?? true))
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: isFileOwner
                  ? FileCaptionWidget(file: widget.file)
                  : FileCaptionReadyOnly(caption: widget.file.caption!),
            ),
      InfoItemWidget(
        leadingIcon: Icons.calendar_today_outlined,
        title: getFullDate(
          DateTime.fromMicrosecondsSinceEpoch(file.creationTime!),
        ),
        subtitle: [
          Text(
            getTimeIn12hrFormat(dateTime) + "  " + dateTime.timeZoneName,
            style: subtitleTextTheme,
          ),
        ],
        editOnTap: ((widget.file.ownerID == null ||
                    widget.file.ownerID == _currentUserID) &&
                widget.file.uploadedFileID != null)
            ? () {
                _showDateTimePicker(widget.file);
              }
            : null,
      ),
      InfoItemWidget(
        leadingIcon:
            _isImage ? Icons.photo_outlined : Icons.video_camera_back_outlined,
        title: path.basenameWithoutExtension(file.displayName) +
            path.extension(file.displayName).toUpperCase(),
        subtitle: [
          showDimension
              ? Text(
                  "${_exifData["megaPixels"]}MP  "
                  "${_exifData["resolution"]}  ",
                  style: subtitleTextTheme,
                )
              : const SizedBox.shrink(),
          _getFileSize(),
          (file.fileType == FileType.video) &&
                  (file.localID != null || file.duration != 0)
              ? _getVideoDuration()
              : const SizedBox.shrink(),
        ],
        editOnTap: file.uploadedFileID == null || file.ownerID != _currentUserID
            ? null
            : () async {
                await editFilename(context, file);
                setState(() {});
              },
      ),
      showExifListTile
          ? InfoItemWidget(
              leadingIcon: Icons.camera_outlined,
              title: _exifData["takenOnDevice"] ?? "--",
              subtitle: [
                _exifData["fNumber"] != null
                    ? Text(
                        'ƒ/' + _exifData["fNumber"].toString(),
                        style: subtitleTextTheme,
                      )
                    : const SizedBox.shrink(),
                _exifData["exposureTime"] != null
                    ? Text(
                        _exifData["exposureTime"],
                        style: subtitleTextTheme,
                      )
                    : const SizedBox.shrink(),
                _exifData["focalLength"] != null
                    ? Text(
                        _exifData["focalLength"].toString() + "mm",
                        style: subtitleTextTheme,
                      )
                    : const SizedBox.shrink(),
                _exifData["ISO"] != null
                    ? Text(
                        "ISO" + _exifData["ISO"].toString(),
                        style: subtitleTextTheme,
                      )
                    : const SizedBox.shrink(),
              ],
            )
          : null,
      SizedBox(
        height: 62,
        child: ListTile(
          horizontalTitleGap: 0,
          leading: const Icon(Icons.folder_outlined),
          title: fileIsBackedup
              ? CollectionsListOfFileWidget(
                  allCollectionIDsOfFile,
                  _currentUserID!,
                )
              : DeviceFoldersListOfFileWidget(allDeviceFoldersOfFile),
        ),
      ),
      FeatureFlagService.instance.isInternalUserOrDebugBuild()
          ? SizedBox(
              height: 62,
              child: ListTile(
                horizontalTitleGap: 0,
                leading: const Icon(Icons.image_search),
                title: ObjectTagsWidget(file),
              ),
            )
          : null,
      (file.uploadedFileID != null && file.updationTime != null)
          ? InfoItemWidget(
              leadingIcon: Icons.backup_outlined,
              title: getFullDate(
                DateTime.fromMicrosecondsSinceEpoch(file.updationTime!),
              ),
              subtitle: [
                Text(
                  getTimeIn12hrFormat(dateTimeForUpdationTime) +
                      "  " +
                      dateTimeForUpdationTime.timeZoneName,
                  style: subtitleTextTheme,
                ),
              ],
            )
          : null,
      _isImage ? RawExifListTileWidget(_exif, widget.file) : null,
    ];

    listTiles.removeWhere(
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
                          : const DividerWidget(
                              dividerType: DividerType.menu,
                            );
                    } else {
                      return listTiles[index ~/ 2];
                    }
                  },
                  childCount: (listTiles.length * 2) - 1,
                ),
              )
            ],
          ),
        ),
      ),
    );
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

  Widget _getFileSize() {
    Future<int> fileSizeFuture;
    if (widget.file.fileSize != null) {
      fileSizeFuture = Future.value(widget.file.fileSize);
    } else {
      fileSizeFuture = getFile(widget.file).then((f) => f!.length());
    }
    return FutureBuilder<int>(
      future: fileSizeFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Text(
            (snapshot.data! / (1024 * 1024)).toStringAsFixed(2) + " MB",
            style: getEnteTextTheme(context).smallMuted,
          );
        } else {
          return Center(
            child: SizedBox.fromSize(
              size: const Size.square(24),
              child: const CupertinoActivityIndicator(
                radius: 8,
              ),
            ),
          );
        }
      },
    );
  }

  Widget _getVideoDuration() {
    if (widget.file.duration != 0) {
      return Text(
        secondsToHHMMSS(widget.file.duration!),
        style: getEnteTextTheme(context).smallMuted,
      );
    }
    return FutureBuilder<AssetEntity?>(
      future: widget.file.getAsset,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Text(
            snapshot.data!.videoDuration.toString().split(".")[0],
            style: getEnteTextTheme(context).smallMuted,
          );
        } else {
          return Center(
            child: SizedBox.fromSize(
              size: const Size.square(24),
              child: const CupertinoActivityIndicator(
                radius: 8,
              ),
            ),
          );
        }
      },
    );
  }

  void _showDateTimePicker(File file) async {
    final dateResult = await DatePicker.showDatePicker(
      context,
      minTime: DateTime(1800, 1, 1),
      maxTime: DateTime.now(),
      currentTime: DateTime.fromMicrosecondsSinceEpoch(file.creationTime!),
      locale: LocaleType.en,
      theme: Theme.of(context).colorScheme.dateTimePickertheme,
    );
    if (dateResult == null) {
      return;
    }
    final dateWithTimeResult = await DatePicker.showTime12hPicker(
      context,
      showTitleActions: true,
      currentTime: dateResult,
      locale: LocaleType.en,
      theme: Theme.of(context).colorScheme.dateTimePickertheme,
    );
    if (dateWithTimeResult != null) {
      if (await editTime(
        context,
        List.of([widget.file]),
        dateWithTimeResult.microsecondsSinceEpoch,
      )) {
        widget.file.creationTime = dateWithTimeResult.microsecondsSinceEpoch;
        setState(() {});
      }
    }
  }
}
