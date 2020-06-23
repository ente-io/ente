import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:like_button/like_button.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photos/core/cache/image_cache.dart';
import 'package:photos/db/photo_db.dart';
import 'package:photos/favorite_files_repository.dart';
import 'package:photos/file_repository.dart';
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
  PageController _pageController;
  int _selectedIndex = 0;
  bool _hasPageChanged = false;

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
      extendBodyBehindAppBar: true,
      body: Center(
        child: Container(
          child: _buildPageView(),
        ),
      ),
      backgroundColor: Colors.black,
    );
  }

  Widget _buildPageView() {
    _pageController = PageController(initialPage: _selectedIndex);
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
          content = VideoWidget(
            file,
            autoPlay: !_hasPageChanged, // Autoplay if it was opened directly
          );
        } else {
          content = Icon(Icons.error);
        }
        _preloadFiles(index);
        return content;
      },
      onPageChanged: (index) {
        setState(() {
          _selectedIndex = index;
          _hasPageChanged = true;
        });
        _preloadFiles(index);
      },
      physics: _shouldDisableScroll
          ? NeverScrollableScrollPhysics()
          : PageScrollPhysics(),
      controller: _pageController,
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
    if (file.fileType == FileType.video) {
      return;
    }
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
      actions.add(_getDeleteButton());
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
      backgroundColor: Color(0x00000000),
      elevation: 0,
    );
  }

  Widget _getFavoriteButton() {
    final file = _files[_selectedIndex];
    return LikeButton(
      isLiked: FavoriteFilesRepository.instance.isLiked(file),
      onTap: (oldValue) {
        return FavoriteFilesRepository.instance.setLiked(file, !oldValue);
      },
      likeBuilder: (isLiked) {
        return Icon(
          Icons.favorite_border,
          color: isLiked ? Colors.pinkAccent : Colors.white,
          size: 30,
        );
      },
    );
  }

  Widget _getDeleteButton() {
    return IconButton(
      icon: Icon(Icons.delete_outline),
      iconSize: 30,
      onPressed: () {
        _showDeleteSheet();
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

  void _showDeleteSheet() {
    final action = CupertinoActionSheet(
      actions: <Widget>[
        CupertinoActionSheetAction(
          child: Text("Delete on device"),
          isDestructiveAction: true,
          onPressed: () async {
            await _delete(false);
          },
        ),
        CupertinoActionSheetAction(
          child: Text("Delete everywhere [WiP]"),
          isDestructiveAction: true,
          onPressed: () async {
            await _delete(true);
          },
        )
      ],
      cancelButton: CupertinoActionSheetAction(
        child: Text("Cancel"),
        onPressed: () {
          Navigator.of(context, rootNavigator: true).pop();
        },
      ),
    );
    showCupertinoModalPopup(context: context, builder: (_) => action);
  }

  Future _delete(bool deleteEverywhere) async {
    final file = _files[_selectedIndex];
    final totalFiles = _files.length;
    if (_selectedIndex == totalFiles - 1) {
      // Deleted the last file
      await _pageController.previousPage(
          duration: Duration(milliseconds: 200), curve: Curves.easeInOut);
    } else {
      await _pageController.nextPage(
          duration: Duration(milliseconds: 200), curve: Curves.easeInOut);
      setState(() {
        _files.remove(file);
      });
      Future.delayed(Duration(milliseconds: 200), () {
        _pageController.jumpToPage(_selectedIndex - 1);
      });
    }
    Navigator.of(context, rootNavigator: true).pop(); // Close dialog
    if (_files.length == 0) {
      // Deleted the last file in gallery
      Navigator.of(context, rootNavigator: true).pop(); // Close pageview
      Navigator.of(context, rootNavigator: true).pop(); // Close gallery
    }

    await PhotoManager.editor.deleteWithIds([file.localId]);
    deleteEverywhere
        ? await FileDB.instance.markForDeletion(file)
        : await FileDB.instance.delete(file);

    FileRepository.instance.reloadFiles();
  }
}
