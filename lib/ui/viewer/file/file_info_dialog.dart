import "package:exif/exif.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import "package:photos/core/configuration.dart";
import "package:photos/ente_theme_data.dart";
import "package:photos/models/file.dart";
import "package:photos/models/file_type.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/ui/viewer/file/exif_info_dialog.dart";
import "package:photos/utils/date_time_util.dart";
import "package:photos/utils/exif_util.dart";
import "package:photos/utils/file_util.dart";
import "package:photos/utils/magic_util.dart";
import "package:photos/utils/toast_util.dart";

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
        setState(() {
          _exif = exif;
        });
      });
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final file = widget.file;
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
    var listTiles = <Widget>[
      ListTile(
        leading: const Padding(
          padding: EdgeInsets.only(top: 8, left: 6),
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
      const DividerWithPadding(),
      ListTile(
        leading: _isImage
            ? const Padding(
                padding: EdgeInsets.only(top: 8, left: 6),
                child: Icon(
                  Icons.image,
                ),
              )
            : const Padding(
                padding: EdgeInsets.only(top: 8, left: 6),
                child: Icon(
                  Icons.video_camera_back,
                  size: 27,
                ),
              ),
        title: Text(
          file.getDisplayName(),
        ),
        subtitle: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: _getFileSize(),
            ),
            !_isImage ? _getVideoDuration() : const SizedBox.shrink(),
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
      const DividerWithPadding(),
      showExifListTile
          ? ListTile(
              leading: const Padding(
                padding: EdgeInsets.only(left: 6),
                child: Icon(Icons.camera_rounded),
              ),
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
          : const SizedBox.shrink(),
      showExifListTile ? const DividerWithPadding() : const SizedBox.shrink(),
      ListTile(
        leading: const Padding(
          padding: EdgeInsets.only(left: 6),
          child: Icon(Icons.folder_outlined),
        ),
        title: Text(
          file.deviceFolder ??
              CollectionsService.instance
                  .getCollectionByID(file.collectionID)
                  .name,
        ),
      ),
      const DividerWithPadding(),
      (file.uploadedFileID != null && file.updationTime != null)
          ? ListTile(
              leading: const Padding(
                padding: EdgeInsets.only(top: 8, left: 6),
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
          : const SizedBox.shrink(),
      _isImage
          ? Padding(
              padding: const EdgeInsets.fromLTRB(0, 24, 0, 16),
              child: SafeArea(
                child: RawExifButton(_exif, widget.file),
              ),
            )
          : const SizedBox(
              height: 12,
            )
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(
                  Icons.close,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  "Details",
                  style: Theme.of(context).textTheme.bodyText1,
                ),
              ),
            ],
          ),
        ),
        ...listTiles
      ],
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

    if (exif["EXIF ExifImageWidth"] != null &&
        exif["EXIF ExifImageLength"] != null) {
      _exifData["resolution"] = exif["EXIF ExifImageWidth"].toString() +
          " x " +
          exif["EXIF ExifImageLength"].toString();

      _exifData['megaPixels'] = ((exif["Image ImageWidth"].values.firstAsInt() *
                  exif["Image ImageLength"].values.firstAsInt()) /
              1000000)
          .toStringAsFixed(1);
    } else if (exif["Image ImageWidth"] != null &&
        exif["Image ImageLength"] != null) {
      _exifData["resolution"] = exif["Image ImageWidth"].toString() +
          " x " +
          exif["Image ImageLength"].toString();
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
    return FutureBuilder(
      future: getFile(widget.file).then((f) => f.length()),
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
      future: widget.file.getAsset(),
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

class DividerWithPadding extends StatelessWidget {
  const DividerWithPadding({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(70, 0, 20, 0),
      child: Divider(
        thickness: 0.5,
      ),
    );
  }
}

enum Status {
  loading,
  exifIsAvailable,
  noExif,
}

class RawExifButton extends StatelessWidget {
  final File file;
  final Map<String, IfdTag> exif;
  const RawExifButton(this.exif, this.file, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Status exifStatus = Status.loading;
    if (exif == null) {
      exifStatus = Status.loading;
    } else if (exif.isNotEmpty) {
      exifStatus = Status.exifIsAvailable;
    } else {
      exifStatus = Status.noExif;
    }
    return GestureDetector(
      onTap:
          exifStatus == Status.loading || exifStatus == Status.exifIsAvailable
              ? () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return ExifInfoDialog(file);
                    },
                    barrierColor: Colors.black87,
                  );
                }
              : exifStatus == Status.noExif
                  ? () {
                      showShortToast(context, "This image has no exif data");
                    }
                  : null,
      child: Container(
        height: 40,
        width: 140,
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .inverseBackgroundColor
              .withOpacity(0.12),
          borderRadius: const BorderRadius.all(
            Radius.circular(20),
          ),
        ),
        child: Center(
          child: exifStatus == Status.loading
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    CupertinoActivityIndicator(
                      radius: 8,
                    ),
                    SizedBox(
                      width: 8,
                    ),
                    Text('EXIF')
                  ],
                )
              : exifStatus == Status.exifIsAvailable
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.feed_outlined),
                        SizedBox(
                          width: 8,
                        ),
                        Text('Raw EXIF'),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.feed_outlined),
                        SizedBox(
                          width: 8,
                        ),
                        Text('No EXIF'),
                      ],
                    ),
        ),
      ),
    );
  }
}
