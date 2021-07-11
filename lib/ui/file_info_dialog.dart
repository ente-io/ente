import 'package:exif/exif.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:photos/models/file.dart';
import 'package:photos/models/file_type.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/ui/exif_info_dialog.dart';
import 'package:photos/utils/date_time_util.dart';
import 'package:photos/utils/file_util.dart';
import 'package:photos/utils/toast_util.dart';

class FileInfoWidget extends StatefulWidget {
  final File file;

  const FileInfoWidget(
    this.file, {
    Key key,
  }) : super(key: key);

  @override
  _FileInfoWidgetState createState() => _FileInfoWidgetState();
}

class _FileInfoWidgetState extends State<FileInfoWidget> {
  Map<String, IfdTag> _exif;
  bool _isImage = false;

  @override
  void initState() {
    _isImage = widget.file.fileType == FileType.image;
    if (_isImage) {
      _getExif().then((exif) {
        setState(() {
          _exif = exif;
        });
      });
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var items = <Widget>[
      Row(
        children: [
          Icon(
            Icons.calendar_today_outlined,
            color: Colors.white.withOpacity(0.85),
          ),
          Padding(padding: EdgeInsets.all(4)),
          Text(
            getFormattedTime(
              DateTime.fromMicrosecondsSinceEpoch(widget.file.creationTime),
            ),
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
            ),
          ),
        ],
      ),
      Padding(padding: EdgeInsets.all(6)),
      Row(
        children: [
          Icon(
            Icons.folder_outlined,
            color: Colors.white.withOpacity(0.85),
          ),
          Padding(padding: EdgeInsets.all(4)),
          Text(
            widget.file.deviceFolder ??
                CollectionsService.instance
                    .getCollectionByID(widget.file.collectionID)
                    .name,
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
            ),
          ),
        ],
      ),
      Padding(padding: EdgeInsets.all(6)),
    ];
    items.addAll(
      [
        Row(
          children: [
            Icon(
              Icons.sd_storage_outlined,
              color: Colors.white.withOpacity(0.85),
            ),
            Padding(padding: EdgeInsets.all(4)),
            _getFileSize(),
          ],
        ),
        Padding(padding: EdgeInsets.all(6)),
      ],
    );
    if (widget.file.localID != null && !_isImage) {
      items.addAll(
        [
          Row(
            children: [
              Icon(
                Icons.timer_outlined,
                color: Colors.white.withOpacity(0.85),
              ),
              Padding(padding: EdgeInsets.all(4)),
              FutureBuilder(
                future: widget.file.getAsset(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Text(
                      snapshot.data.videoDuration.toString().split(".")[0],
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                      ),
                    );
                  } else {
                    return Center(
                      child: SizedBox.fromSize(
                        size: Size.square(24),
                        child: CupertinoActivityIndicator(
                          radius: 8,
                        ),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          Padding(padding: EdgeInsets.all(6)),
        ],
      );
    }
    if (_isImage && _exif != null) {
      items.add(_getExifWidgets(_exif));
    }
    if (widget.file.uploadedFileID != null) {
      items.addAll(
        [
          Row(
            children: [
              Icon(
                Icons.cloud_upload_outlined,
                color: Colors.white.withOpacity(0.85),
              ),
              Padding(padding: EdgeInsets.all(4)),
              Text(
                getFormattedTime(DateTime.fromMicrosecondsSinceEpoch(
                    widget.file.updationTime)),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                ),
              ),
            ],
          ),
        ],
      );
    }
    items.add(
      Padding(padding: EdgeInsets.all(12)),
    );
    items.add(
      Row(
        mainAxisAlignment:
            _isImage ? MainAxisAlignment.spaceBetween : MainAxisAlignment.end,
        children: _getActions(),
      ),
    );
    return AlertDialog(
      title: Text(widget.file.title),
      content: SingleChildScrollView(
        child: ListBody(
          children: items,
        ),
      ),
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
                    size: Size.square(24),
                    child: CupertinoActivityIndicator(
                      radius: 8,
                    ),
                  ),
                ),
                Padding(padding: EdgeInsets.all(4)),
                Text(
                  "exif",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                  ),
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
                Icon(
                  Icons.feed_outlined,
                  color: Colors.white.withOpacity(0.85),
                ),
                Padding(padding: EdgeInsets.all(4)),
                Text(
                  "view exif",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                  ),
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
                  color: Colors.white.withOpacity(0.5),
                ),
                Padding(padding: EdgeInsets.all(4)),
                Text(
                  "no exif",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ],
            ),
            onPressed: () {
              showToast("this image has no exif data");
            },
          ),
        );
      }
    }
    actions.add(
      TextButton(
        child: Text(
          "close",
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
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
            Icon(
              Icons.photo_size_select_actual_outlined,
              color: Colors.white.withOpacity(0.85),
            ),
            Padding(padding: EdgeInsets.all(4)),
            Text(
              exif["EXIF ExifImageWidth"].toString() +
                  " x " +
                  exif["EXIF ExifImageLength"].toString(),
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
              ),
            ),
          ],
        ),
        Padding(padding: EdgeInsets.all(6)),
      ]);
    } else if (exif["Image ImageWidth"] != null &&
        exif["Image ImageLength"] != null) {
      children.addAll([
        Row(
          children: [
            Icon(
              Icons.photo_size_select_actual_outlined,
              color: Colors.white.withOpacity(0.85),
            ),
            Padding(padding: EdgeInsets.all(4)),
            Text(
              exif["Image ImageWidth"].toString() +
                  " x " +
                  exif["Image ImageLength"].toString(),
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
              ),
            ),
          ],
        ),
        Padding(padding: EdgeInsets.all(6)),
      ]);
    }
    if (exif["Image Make"] != null && exif["Image Model"] != null) {
      children.addAll(
        [
          Row(
            children: [
              Icon(
                Icons.camera_outlined,
                color: Colors.white.withOpacity(0.85),
              ),
              Padding(padding: EdgeInsets.all(4)),
              Text(
                exif["Image Make"].toString() +
                    " " +
                    exif["Image Model"].toString(),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                ),
              ),
            ],
          ),
          Padding(padding: EdgeInsets.all(6)),
        ],
      );
    }
    if (fNumber != null) {
      children.addAll([
        Row(
          children: [
            Icon(
              CupertinoIcons.f_cursive,
              color: Colors.white.withOpacity(0.85),
            ),
            Padding(padding: EdgeInsets.all(4)),
            Text(
              fNumber.toString(),
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
              ),
            ),
          ],
        ),
        Padding(padding: EdgeInsets.all(6)),
      ]);
    }
    if (focalLength != null) {
      children.addAll([
        Row(
          children: [
            Icon(
              Icons.center_focus_strong_outlined,
              color: Colors.white.withOpacity(0.85),
            ),
            Padding(padding: EdgeInsets.all(4)),
            Text(focalLength.toString() + " mm",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                )),
          ],
        ),
        Padding(padding: EdgeInsets.all(6)),
      ]);
    }
    if (exif["EXIF ExposureTime"] != null) {
      children.addAll([
        Row(
          children: [
            Icon(
              Icons.shutter_speed,
              color: Colors.white.withOpacity(0.85),
            ),
            Padding(padding: EdgeInsets.all(4)),
            Text(
              exif["EXIF ExposureTime"].toString(),
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
              ),
            ),
          ],
        ),
        Padding(padding: EdgeInsets.all(6)),
      ]);
    }
    return Column(
      children: children,
    );
  }

  Widget _getFileSize() {
    return FutureBuilder(
      future: getFile(widget.file).then((f) => f.lengthSync()),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Text(
            (snapshot.data / (1024 * 1024)).toStringAsFixed(2) + " MB",
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
            ),
          );
        } else {
          return Center(
            child: SizedBox.fromSize(
              size: Size.square(24),
              child: CupertinoActivityIndicator(
                radius: 8,
              ),
            ),
          );
        }
      },
    );
  }

  Future<Map<String, IfdTag>> _getExif() async {
    return await readExifFromFile(await getFile(widget.file));
  }
}
