import 'dart:io';

import 'package:exif/exif.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/models/file.dart';
import 'package:photos/models/file_type.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/ui/viewer/file/exif_info_dialog.dart';
import 'package:photos/utils/date_time_util.dart';
import 'package:photos/utils/exif_util.dart';
import 'package:photos/utils/file_util.dart';
import 'package:photos/utils/magic_util.dart';
import 'package:photos/utils/toast_util.dart';

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
  bool _isImage = false;
  Color infoColor;

  @override
  void initState() {
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
    infoColor = Theme.of(context).colorScheme.onSurface.withOpacity(0.85);
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
          style: Theme.of(context)
              .textTheme
              .bodyText2
              .copyWith(color: Colors.black.withOpacity(0.5)),
        ),
        trailing: (widget.file.ownerID == null ||
                    widget.file.ownerID ==
                        Configuration.instance.getUserID()) &&
                widget.file.uploadedFileID != null
            ? IconButton(
                onPressed: () {
                  PopupMenuItem(
                    value: 2,
                    child: Row(
                      children: [
                        Icon(
                          Platform.isAndroid
                              ? Icons.access_time_rounded
                              : CupertinoIcons.time,
                          color: Theme.of(context).iconTheme.color,
                        ),
                        const Padding(
                          padding: EdgeInsets.all(8),
                        ),
                        const Text("Edit time"),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.edit),
              )
            : const SizedBox.shrink(),
      ),
      const DividerWithPadding(),
      ListTile(
        leading: const Padding(
          padding: EdgeInsets.only(top: 8, left: 6),
          child: Icon(
            Icons.image,
          ),
        ),
        title: Text(
          file.getDisplayName(),
        ),
        subtitle: Text(
          getTimeIn12hrFormat(dateTime) + "  " + dateTime.timeZoneName,
          style: Theme.of(context)
              .textTheme
              .bodyText2
              .copyWith(color: Colors.black.withOpacity(0.5)),
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
      )
    ];

    var items = <Widget>[
      Row(
        children: [
          Icon(Icons.calendar_today_outlined, color: infoColor),
          const SizedBox(height: 8),
          Text(
            getFormattedTime(
              DateTime.fromMicrosecondsSinceEpoch(file.creationTime),
            ),
            style: TextStyle(color: infoColor),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Icon(Icons.folder_outlined, color: infoColor),
          const Padding(padding: EdgeInsets.all(4)),
          Text(
            file.deviceFolder ??
                CollectionsService.instance
                    .getCollectionByID(file.collectionID)
                    .name,
            style: TextStyle(color: infoColor),
          ),
        ],
      ),
      const SizedBox(height: 12),
    ];
    items.addAll(
      [
        Row(
          children: [
            Icon(Icons.sd_storage_outlined, color: infoColor),
            const Padding(padding: EdgeInsets.all(4)),
            _getFileSize(),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
    if (file.localID != null && !_isImage) {
      items.addAll(
        [
          Row(
            children: [
              Icon(Icons.timer_outlined, color: infoColor),
              const Padding(padding: EdgeInsets.all(4)),
              FutureBuilder(
                future: file.getAsset(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Text(
                      snapshot.data.videoDuration.toString().split(".")[0],
                      style: TextStyle(color: infoColor),
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
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      );
    }
    if (_isImage && _exif != null) {
      items.add(_getExifWidgets(_exif));
    }
    if (file.uploadedFileID != null && file.updationTime != null) {
      items.addAll(
        [
          Row(
            children: [
              Icon(Icons.cloud_upload_outlined, color: infoColor),
              const Padding(padding: EdgeInsets.all(4)),
              Text(
                getFormattedTime(
                  DateTime.fromMicrosecondsSinceEpoch(file.updationTime),
                ),
                style: TextStyle(color: infoColor),
              ),
            ],
          ),
        ],
      );
    }
    items.add(
      const SizedBox(height: 12),
    );
    items.add(
      Row(
        mainAxisAlignment:
            _isImage ? MainAxisAlignment.spaceBetween : MainAxisAlignment.end,
        children: _getActions(),
      ),
    );

    Widget titleContent;
    if (file.uploadedFileID == null ||
        file.ownerID != Configuration.instance.getUserID()) {
      titleContent = Text(file.getDisplayName());
    } else {
      titleContent = InkWell(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                file.getDisplayName(),
                style: Theme.of(context).textTheme.headline5,
              ),
            ),
            const SizedBox(width: 16),
            Icon(Icons.edit, color: infoColor),
          ],
        ),
        onTap: () async {
          await editFilename(context, file);
          setState(() {});
        },
      );
    }

    // return AlertDialog(
    //   title: titleContent,
    //   content: SingleChildScrollView(
    //     child: ListBody(
    //       children: items,
    //     ),
    //   ),
    // );
    return Column(
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
                  'Details',
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

  List<Widget> _getActions() {
    final List<Widget> actions = [];
    if (_isImage) {
      if (_exif == null) {
        actions.add(
          TextButton(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Center(
                  child: SizedBox.fromSize(
                    size: const Size.square(24),
                    child: const CupertinoActivityIndicator(
                      radius: 8,
                    ),
                  ),
                ),
                const Padding(padding: EdgeInsets.all(4)),
                Text(
                  "EXIF",
                  style: TextStyle(color: infoColor),
                ),
              ],
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return ExifInfoDialog(widget.file);
                },
                barrierColor: Colors.black87,
              );
            },
          ),
        );
      } else if (_exif.isNotEmpty) {
        actions.add(
          TextButton(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Icon(Icons.feed_outlined, color: infoColor),
                const Padding(padding: EdgeInsets.all(4)),
                Text(
                  "View raw EXIF",
                  style: TextStyle(color: infoColor),
                ),
              ],
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return ExifInfoDialog(widget.file);
                },
                barrierColor: Colors.black87,
              );
            },
          ),
        );
      } else {
        actions.add(
          TextButton(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Icon(
                  Icons.feed_outlined,
                  color: Theme.of(context)
                      .colorScheme
                      .defaultTextColor
                      .withOpacity(0.5),
                ),
                const Padding(padding: EdgeInsets.all(4)),
                Text(
                  "No exif",
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .defaultTextColor
                        .withOpacity(0.5),
                  ),
                ),
              ],
            ),
            onPressed: () {
              showShortToast(context, "This image has no exif data");
            },
          ),
        );
      }
    }
    actions.add(
      TextButton(
        child: Text(
          "Close",
          style: TextStyle(
            color: infoColor,
          ),
        ),
        onPressed: () {
          Navigator.of(context, rootNavigator: true).pop('dialog');
        },
      ),
    );
    return actions;
  }

  Widget _getExifWidgets(Map<String, IfdTag> exif) {
    final focalLength = exif["EXIF FocalLength"] != null
        ? (exif["EXIF FocalLength"].values.toList()[0] as Ratio).numerator /
            (exif["EXIF FocalLength"].values.toList()[0] as Ratio).denominator
        : null;
    final fNumber = exif["EXIF FNumber"] != null
        ? (exif["EXIF FNumber"].values.toList()[0] as Ratio).numerator /
            (exif["EXIF FNumber"].values.toList()[0] as Ratio).denominator
        : null;
    final List<Widget> children = [];
    if (exif["EXIF ExifImageWidth"] != null &&
        exif["EXIF ExifImageLength"] != null) {
      children.addAll([
        Row(
          children: [
            Icon(Icons.photo_size_select_actual_outlined, color: infoColor),
            const Padding(padding: EdgeInsets.all(4)),
            Text(
              exif["EXIF ExifImageWidth"].toString() +
                  " x " +
                  exif["EXIF ExifImageLength"].toString(),
              style: TextStyle(color: infoColor),
            ),
          ],
        ),
        const Padding(padding: EdgeInsets.all(6)),
      ]);
    } else if (exif["Image ImageWidth"] != null &&
        exif["Image ImageLength"] != null) {
      children.addAll([
        Row(
          children: [
            Icon(Icons.photo_size_select_actual_outlined, color: infoColor),
            const Padding(padding: EdgeInsets.all(4)),
            Text(
              exif["Image ImageWidth"].toString() +
                  " x " +
                  exif["Image ImageLength"].toString(),
              style: TextStyle(color: infoColor),
            ),
          ],
        ),
        const Padding(padding: EdgeInsets.all(6)),
      ]);
    }
    if (exif["Image Make"] != null && exif["Image Model"] != null) {
      children.addAll(
        [
          Row(
            children: [
              Icon(Icons.camera_outlined, color: infoColor),
              const Padding(padding: EdgeInsets.all(4)),
              Flexible(
                child: Text(
                  exif["Image Make"].toString() +
                      " " +
                      exif["Image Model"].toString(),
                  style: TextStyle(color: infoColor),
                  overflow: TextOverflow.clip,
                ),
              ),
            ],
          ),
          const Padding(padding: EdgeInsets.all(6)),
        ],
      );
    }
    if (fNumber != null) {
      children.addAll([
        Row(
          children: [
            Icon(CupertinoIcons.f_cursive, color: infoColor),
            const Padding(padding: EdgeInsets.all(4)),
            Text(
              fNumber.toString(),
              style: TextStyle(color: infoColor),
            ),
          ],
        ),
        const Padding(padding: EdgeInsets.all(6)),
      ]);
    }
    if (focalLength != null) {
      children.addAll([
        Row(
          children: [
            Icon(Icons.center_focus_strong_outlined, color: infoColor),
            const Padding(padding: EdgeInsets.all(4)),
            Text(
              focalLength.toString() + " mm",
              style: TextStyle(color: infoColor),
            ),
          ],
        ),
        const Padding(padding: EdgeInsets.all(6)),
      ]);
    }
    if (exif["EXIF ExposureTime"] != null) {
      children.addAll([
        Row(
          children: [
            Icon(Icons.shutter_speed, color: infoColor),
            const Padding(padding: EdgeInsets.all(4)),
            Text(
              exif["EXIF ExposureTime"].toString(),
              style: TextStyle(color: infoColor),
            ),
          ],
        ),
        const Padding(padding: EdgeInsets.all(6)),
      ]);
    }
    return Column(
      children: children,
    );
  }

  Widget _getFileSize() {
    return FutureBuilder(
      future: getFile(widget.file).then((f) => f.length()),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Text(
            (snapshot.data / (1024 * 1024)).toStringAsFixed(2) + " MB",
            style: TextStyle(color: infoColor),
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
}

class DividerWithPadding extends StatelessWidget {
  const DividerWithPadding({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(70, 0, 20, 0),
      child: Divider(
        thickness: 0.5,
      ),
    );
  }
}
