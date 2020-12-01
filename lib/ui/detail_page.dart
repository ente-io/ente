import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:like_button/like_button.dart';
import 'package:photos/services/favorites_service.dart';
import 'package:photos/models/file_type.dart';
import 'package:photos/models/file.dart';
import 'package:photos/ui/video_widget.dart';
import 'package:photos/ui/zoomable_image.dart';
import 'package:photos/utils/date_time_util.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/file_util.dart';
import 'package:photos/utils/share_util.dart';
import 'package:logging/logging.dart';
import 'package:photos/utils/toast_util.dart';

class DetailPage extends StatefulWidget {
  final List<File> files;
  final int selectedIndex;
  final String tagPrefix;

  DetailPage(this.files, this.selectedIndex, this.tagPrefix, {key})
      : super(key: key);

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
            tagPrefix: widget.tagPrefix,
          );
        } else if (file.fileType == FileType.video) {
          content = VideoWidget(
            file,
            autoPlay: !_hasPageChanged, // Autoplay if it was opened directly
            tagPrefix: widget.tagPrefix,
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
      preloadFile(_files[index - 1]);
    }
    if (index < _files.length - 1) {
      preloadFile(_files[index + 1]);
    }
  }

  AppBar _buildAppBar() {
    final actions = List<Widget>();
    actions.add(_getFavoriteButton());
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
          ),
          PopupMenuItem(
            value: 3,
            child: Row(
              children: [
                Icon(Icons.delete),
                Padding(
                  padding: EdgeInsets.all(8),
                ),
                Text("Delete"),
              ],
            ),
          )
        ];
      },
      onSelected: (value) {
        if (value == 1) {
          share(context, _files[_selectedIndex]);
        } else if (value == 2) {
          _displayInfo(_files[_selectedIndex]);
        } else if (value == 3) {
          _showDeleteSheet();
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

    return FutureBuilder(
      future: FavoritesService.instance.isFavorite(file),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return _getLikeButton(file, snapshot.data);
        } else {
          return _getLikeButton(file, false);
        }
      },
    );
  }

  Widget _getLikeButton(File file, bool isLiked) {
    return LikeButton(
      isLiked: isLiked,
      onTap: (oldValue) async {
        final isLiked = !oldValue;
        bool hasError = false;
        if (isLiked) {
          final dialog =
              createProgressDialog(context, "Adding to favorites...");
          await dialog.show();
          try {
            await FavoritesService.instance.addToFavorites(file);
            showToast("Added to favorites.");
          } catch (e, s) {
            _logger.severe(e, s);
            await dialog.hide();
            hasError = true;
            showGenericErrorDialog(context);
          } finally {
            await dialog.hide();
          }
        } else {
          final dialog =
              createProgressDialog(context, "Removing from favorites...");
          await dialog.show();
          try {
            await FavoritesService.instance.removeFromFavorites(file);
            showToast("Removed from favorites.");
          } catch (e, s) {
            _logger.severe(e, s);
            await dialog.hide();
            hasError = true;
            showGenericErrorDialog(context);
          } finally {
            await dialog.hide();
          }
        }
        return hasError ? oldValue : isLiked;
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

  Future<void> _displayInfo(File file) async {
    var asset;
    final isLocalFile = file.localID != null;
    if (isLocalFile) {
      asset = await file.getAsset();
    }
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        var items = <Widget>[
          Row(
            children: [
              Icon(Icons.timer),
              Padding(padding: EdgeInsets.all(4)),
              Text(getFormattedTime(
                  DateTime.fromMicrosecondsSinceEpoch(file.creationTime))),
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
        if (isLocalFile) {
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
        }
        if (file.uploadedFileID != null) {
          items.add(
            Padding(padding: EdgeInsets.all(4)),
          );
          items.add(Row(
            children: [
              Icon(Icons.cloud_upload),
              Padding(padding: EdgeInsets.all(4)),
              Text(getFormattedTime(
                  DateTime.fromMicrosecondsSinceEpoch(file.updationTime))),
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
      title: Text("Delete file?"),
      actions: <Widget>[
        CupertinoActionSheetAction(
          child: Text("Delete"),
          isDestructiveAction: true,
          onPressed: () async {
            await _delete();
          },
        ),
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

  Future _delete() async {
    final file = _files[_selectedIndex];
    await deleteFilesFromEverywhere([file]);
    final totalFiles = _files.length;
    if (totalFiles == 1) {
      // Deleted the only file
      Navigator.of(context, rootNavigator: true).pop(); // Close pageview
      Navigator.of(context, rootNavigator: true).pop(); // Close gallery
      return;
    }
    if (_selectedIndex == totalFiles - 1) {
      // Deleted the last file
      await _pageController.previousPage(
          duration: Duration(milliseconds: 200), curve: Curves.easeInOut);
      setState(() {
        _files.remove(file);
      });
    } else {
      await _pageController.nextPage(
          duration: Duration(milliseconds: 200), curve: Curves.easeInOut);
      setState(() {
        _selectedIndex--;
        _files.remove(file);
      });
    }
    Navigator.of(context, rootNavigator: true).pop(); // Close dialog
  }
}
