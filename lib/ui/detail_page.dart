import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:like_button/like_button.dart';
import 'package:photos/core/cache/image_cache.dart';
import 'package:photos/favorite_files_repository.dart';
import 'package:photos/models/file_type.dart';
import 'package:photos/models/file.dart';
import 'package:photos/ui/video_widget.dart';
import 'package:photos/ui/zoomable_image.dart';
import 'package:photos/utils/date_time_util.dart';
import 'package:photos/utils/share_util.dart';
import 'package:logging/logging.dart';

class DetailPage extends StatefulWidget {
  final List<File> files;
  final int selectedIndex;

  DetailPage(this.files, this.selectedIndex, {key}) : super(key: key);

  @override
  _DetailPageState createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  final _logger = Logger("DetailPageState");
  bool _shouldDisableScroll = false;
  List<File> _files;
  int _selectedIndex = 0;

  @override
  void initState() {
    _files = widget.files;
    _selectedIndex = widget.selectedIndex;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _logger.info("Opening " +
        _files[_selectedIndex].toString() +
        ". " +
        _selectedIndex.toString() +
        " / " +
        _files.length.toString() +
        " files .");
    return Scaffold(
      appBar: _buildAppBar(),
      body: Center(
        child: Container(
          child: _buildPageView(),
        ),
      ),
      backgroundColor: Colors.black,
    );
  }

  Widget _buildPageView() {
    return PageView.builder(
      itemBuilder: (context, index) {
        final file = _files[index];
        Widget content;
        if (file.fileType == FileType.image) {
          content = ZoomableImage(
            file,
            shouldDisableScroll: (value) {
              setState(() {
                _shouldDisableScroll = value;
              });
            },
          );
        } else if (file.fileType == FileType.video) {
          content = VideoWidget(file);
        } else {
          content = Icon(Icons.error);
        }
        _preloadFiles(index);
        return content;
      },
      onPageChanged: (index) {
        setState(() {
          _selectedIndex = index;
        });
        _preloadFiles(index);
      },
      physics: _shouldDisableScroll
          ? NeverScrollableScrollPhysics()
          : PageScrollPhysics(),
      controller: PageController(initialPage: _selectedIndex),
      itemCount: _files.length,
    );
  }

  void _preloadFiles(int index) {
    if (index > 0) {
      _preloadFile(_files[index - 1]);
    }
    if (index < _files.length - 1) {
      _preloadFile(_files[index + 1]);
    }
  }

  void _preloadFile(File file) {
    if (file.localId == null) {
      file.getBytes().then((data) {
        BytesLruCache.put(file, data);
      });
    } else {
      final cachedFile = FileLruCache.get(file);
      if (cachedFile == null) {
        file.getAsset().then((asset) {
          asset.file.then((assetFile) {
            FileLruCache.put(file, assetFile);
          });
        });
      }
    }
  }

  AppBar _buildAppBar() {
    final actions = List<Widget>();
    if (_files[_selectedIndex].localId != null) {
      actions.add(_getFavoriteButton());
    }
    actions.add(PopupMenuButton(
      itemBuilder: (context) {
        return [
          PopupMenuItem(
            value: 1,
            child: Row(
              children: [
                Icon(Icons.share),
                Padding(
                  padding: EdgeInsets.all(8),
                ),
                Text("Share"),
              ],
            ),
          ),
          PopupMenuItem(
            value: 2,
            child: Row(
              children: [
                Icon(Icons.info),
                Padding(
                  padding: EdgeInsets.all(8),
                ),
                Text("Info"),
              ],
            ),
          )
        ];
      },
      onSelected: (value) {
        if (value == 1) {
          share(_files[_selectedIndex]);
        } else if (value == 2) {
          _displayInfo(_files[_selectedIndex]);
        }
      },
    ));
    return AppBar(
      actions: actions,
    );
  }

  Widget _getFavoriteButton() {
    final file = _files[_selectedIndex];
    return LikeButton(
      isLiked: FavoriteFilesRepository.instance.isLiked(file),
      onTap: (oldValue) {
        return FavoriteFilesRepository.instance.setLiked(file, !oldValue);
      },
    );
  }

  Future<void> _displayInfo(File file) async {
    final asset = await file.getAsset();
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        var items = <Widget>[
          Row(
            children: [
              Icon(Icons.timer),
              Padding(padding: EdgeInsets.all(4)),
              Text(getFormattedTime(
                  DateTime.fromMicrosecondsSinceEpoch(file.createTimestamp))),
            ],
          ),
          Padding(padding: EdgeInsets.all(4)),
          Row(
            children: [
              Icon(Icons.folder),
              Padding(padding: EdgeInsets.all(4)),
              Text(file.deviceFolder),
            ],
          ),
          Padding(padding: EdgeInsets.all(4)),
        ];
        if (file.fileType == FileType.image) {
          items.add(Row(
            children: [
              Icon(Icons.photo_size_select_actual),
              Padding(padding: EdgeInsets.all(4)),
              Text(asset.width.toString() + " x " + asset.height.toString()),
            ],
          ));
        } else {
          items.add(Row(
            children: [
              Icon(Icons.timer),
              Padding(padding: EdgeInsets.all(4)),
              Text(asset.videoDuration.toString()),
            ],
          ));
        }
        return AlertDialog(
          title: Text(file.title),
          content: SingleChildScrollView(
            child: ListBody(
              children: items,
            ),
          ),
          actions: <Widget>[
            FlatButton(
              child: Text('Ok'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
