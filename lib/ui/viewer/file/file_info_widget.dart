// @dart=2.9

import "package:exif/exif.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import "package:photos/core/configuration.dart";
import 'package:photos/db/files_db.dart';
import "package:photos/ente_theme_data.dart";
import "package:photos/models/file.dart";
import "package:photos/models/file_type.dart";
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/components/divider_widget.dart';
import 'package:photos/ui/components/icon_button_widget.dart';
import 'package:photos/ui/components/title_bar_widget.dart';
import 'package:photos/ui/viewer/file/collections_list_of_file_widget.dart';
import 'package:photos/ui/viewer/file/device_folders_list_of_file_widget.dart';
import 'package:photos/ui/viewer/file/file_caption_widget.dart';
import 'package:photos/ui/viewer/file/raw_exif_list_tile_widget.dart';
import "package:photos/utils/date_time_util.dart";
import "package:photos/utils/exif_util.dart";
import "package:photos/utils/file_util.dart";
import "package:photos/utils/magic_util.dart";

class FileInfoWidget extends StatefulWidget {
  final File file;

  const FileInfoWidget(
    this.file, {
    Key key,
  }) : super(key: key);

  @override
  State<FileInfoWidget> createState() => _FileInfoWidgetState();
}

class _FileInfoWidgetState extends State<FileInfoWidget> {
  Map<String, IfdTag> _exif;
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

  @override
  void initState() {
    debugPrint('file_info_dialog initState');
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
    final file = widget.file;
    final fileIsBackedup = file.uploadedFileID == null ? false : true;
    Future<Set<int>> allCollectionIDsOfFile;
    Future<Set<String>>
        allDeviceFoldersOfFile; //Typing this as Future<Set<T>> as it would be easier to implement showing multiple device folders for a file in the future
    if (fileIsBackedup) {
      allCollectionIDsOfFile = FilesDB.instance.getAllCollectionIDsOfFile(
        file.uploadedFileID,
      );
    } else {
      allDeviceFoldersOfFile = Future.sync(() => {file.deviceFolder});
    }
    final dateTime = DateTime.fromMicrosecondsSinceEpoch(file.creationTime);
    final dateTimeForUpdationTime =
        DateTime.fromMicrosecondsSinceEpoch(file.updationTime);

    if (_isImage && _exif != null) {
      _generateExifForDetails(_exif);
    }
    final bool showExifListTile = _exifData["focalLength"] != null ||
        _exifData["fNumber"] != null ||
        _exifData["takenOnDevice"] != null ||
        _exifData["exposureTime"] != null ||
        _exifData["ISO"] != null;
    final bool showDimension =
        _exifData["resolution"] != null && _exifData["megaPixels"] != null;
    final listTiles = <Widget>[
      widget.file.uploadedFileID == null ||
              Configuration.instance.getUserID() != file.ownerID
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: FileCaptionWidget(file: widget.file),
            ),
      ListTile(
        horizontalTitleGap: 2,
        leading: const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Icon(Icons.calendar_today_rounded),
        ),
        title: Text(
          getFullDate(
            DateTime.fromMicrosecondsSinceEpoch(file.creationTime),
          ),
        ),
        subtitle: Text(
          getTimeIn12hrFormat(dateTime) + "  " + dateTime.timeZoneName,
          style: Theme.of(context).textTheme.bodyText2.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .defaultTextColor
                    .withOpacity(0.5),
              ),
        ),
        trailing: (widget.file.ownerID == null ||
                    widget.file.ownerID ==
                        Configuration.instance.getUserID()) &&
                widget.file.uploadedFileID != null
            ? IconButton(
                onPressed: () {
                  _showDateTimePicker(widget.file);
                },
                icon: const Icon(Icons.edit),
              )
            : const SizedBox.shrink(),
      ),
      ListTile(
        horizontalTitleGap: 2,
        leading: _isImage
            ? const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Icon(
                  Icons.image,
                ),
              )
            : const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Icon(
                  Icons.video_camera_back,
                  size: 27,
                ),
              ),
        title: Text(
          file.displayName,
        ),
        subtitle: Row(
          children: [
            showDimension
                ? Text(
                    "${_exifData["megaPixels"]}MP  "
                    "${_exifData["resolution"]}  ",
                  )
                : const SizedBox.shrink(),
            _getFileSize(),
            (file.fileType == FileType.video) &&
                    (file.localID != null || file.duration != 0)
                ? Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: _getVideoDuration(),
                  )
                : const SizedBox.shrink(),
          ],
        ),
        trailing: file.uploadedFileID == null ||
                file.ownerID != Configuration.instance.getUserID()
            ? const SizedBox.shrink()
            : IconButton(
                onPressed: () async {
                  await editFilename(context, file);
                  setState(() {});
                },
                icon: const Icon(Icons.edit),
              ),
      ),
      showExifListTile
          ? ListTile(
              horizontalTitleGap: 2,
              leading: const Icon(Icons.camera_rounded),
              title: Text(_exifData["takenOnDevice"] ?? "--"),
              subtitle: Row(
                children: [
                  _exifData["fNumber"] != null
                      ? Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: Text('ƒ/' + _exifData["fNumber"].toString()),
                        )
                      : const SizedBox.shrink(),
                  _exifData["exposureTime"] != null
                      ? Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: Text(_exifData["exposureTime"]),
                        )
                      : const SizedBox.shrink(),
                  _exifData["focalLength"] != null
                      ? Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child:
                              Text(_exifData["focalLength"].toString() + "mm"),
                        )
                      : const SizedBox.shrink(),
                  _exifData["ISO"] != null
                      ? Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: Text("ISO" + _exifData["ISO"].toString()),
                        )
                      : const SizedBox.shrink(),
                ],
              ),
            )
          : null,
      SizedBox(
        height: 62,
        child: ListTile(
          horizontalTitleGap: 0,
          leading: const Icon(Icons.folder_outlined),
          title: fileIsBackedup
              ? CollectionsListOfFileWidget(allCollectionIDsOfFile)
              : DeviceFoldersListOfFileWidget(allDeviceFoldersOfFile),
        ),
      ),
      (file.uploadedFileID != null && file.updationTime != null)
          ? ListTile(
              horizontalTitleGap: 2,
              leading: const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Icon(Icons.cloud_upload_outlined),
              ),
              title: Text(
                getFullDate(
                  DateTime.fromMicrosecondsSinceEpoch(file.updationTime),
                ),
              ),
              subtitle: Text(
                getTimeIn12hrFormat(dateTimeForUpdationTime) +
                    "  " +
                    dateTimeForUpdationTime.timeZoneName,
                style: Theme.of(context).textTheme.bodyText2.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .defaultTextColor
                          .withOpacity(0.5),
                    ),
              ),
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
                  icon: Icons.close_outlined,
                  iconButtonType: IconButtonType.primary,
                  onTap: () => Navigator.pop(context),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
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

  _generateExifForDetails(Map<String, IfdTag> exif) {
    if (exif["EXIF FocalLength"] != null) {
      _exifData["focalLength"] =
          (exif["EXIF FocalLength"].values.toList()[0] as Ratio).numerator /
              (exif["EXIF FocalLength"].values.toList()[0] as Ratio)
                  .denominator;
    }

    if (exif["EXIF FNumber"] != null) {
      _exifData["fNumber"] =
          (exif["EXIF FNumber"].values.toList()[0] as Ratio).numerator /
              (exif["EXIF FNumber"].values.toList()[0] as Ratio).denominator;
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
      fileSizeFuture = getFile(widget.file).then((f) => f.length());
    }
    return FutureBuilder(
      future: fileSizeFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Text(
            (snapshot.data / (1024 * 1024)).toStringAsFixed(2) + " MB",
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
        secondsToHHMMSS(widget.file.duration),
      );
    }
    return FutureBuilder(
      future: widget.file.getAsset,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Text(
            snapshot.data.videoDuration.toString().split(".")[0],
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
      currentTime: DateTime.fromMicrosecondsSinceEpoch(file.creationTime),
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
