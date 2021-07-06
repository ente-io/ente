import 'dart:io';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:like_button/like_button.dart';
import 'package:logging/logging.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/events/local_photos_updated_event.dart';

import 'package:photos/models/file.dart';
import 'package:photos/models/file_type.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/services/favorites_service.dart';
import 'package:photos/services/local_sync_service.dart';
import 'package:photos/ui/custom_app_bar.dart';
import 'package:photos/ui/gallery.dart';
import 'package:photos/ui/image_editor_page.dart';
import 'package:photos/ui/set_wallpaper_dialog.dart';
import 'package:photos/ui/video_widget.dart';
import 'package:photos/ui/zoomable_image.dart';
import 'package:photos/utils/date_time_util.dart';
import 'package:photos/utils/delete_file_util.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/file_util.dart';
import 'package:photos/utils/navigation_util.dart';
import 'package:photos/utils/share_util.dart';
import 'package:photos/utils/toast_util.dart';

class DetailPageConfiguration {
  final List<File> files;
  final GalleryLoader asyncLoader;
  final int selectedIndex;
  final String tagPrefix;

  DetailPageConfiguration(
    this.files,
    this.asyncLoader,
    this.selectedIndex,
    this.tagPrefix,
  );

  DetailPageConfiguration copyWith({
    List<File> files,
    GalleryLoader asyncLoader,
    int selectedIndex,
    String tagPrefix,
  }) {
    return DetailPageConfiguration(
      files ?? this.files,
      asyncLoader ?? this.asyncLoader,
      selectedIndex ?? this.selectedIndex,
      tagPrefix ?? this.tagPrefix,
    );
  }
}

class DetailPage extends StatefulWidget {
  final DetailPageConfiguration config;

  DetailPage(this.config, {key}) : super(key: key);

  @override
  _DetailPageState createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  static const kLoadLimit = 100;
  final _logger = Logger("DetailPageState");
  bool _shouldDisableScroll = false;
  List<File> _files;
  PageController _pageController;
  int _selectedIndex = 0;
  bool _hasPageChanged = false;
  bool _hasLoadedTillStart = false;
  bool _hasLoadedTillEnd = false;
  bool _shouldHideAppBar = false;

  @override
  void initState() {
    _files = widget.config.files;
    _selectedIndex = widget.config.selectedIndex;
    _preloadEntries(_selectedIndex);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Future.delayed(Duration.zero, () {
      SystemChrome.setEnabledSystemUIOverlays(
        _shouldHideAppBar ? [] : SystemUiOverlay.values,
      );
    });
    _logger.info("Opening " +
        _files[_selectedIndex].toString() +
        ". " +
        (_selectedIndex + 1).toString() +
        " / " +
        _files.length.toString() +
        " files .");
    return Scaffold(
      appBar: _getAppBar(),
      extendBodyBehindAppBar: true,
      body: Center(
        child: Container(
          child: Stack(
            children: [
              _buildPageView(),
              _getBottomBar(),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.black,
    );
  }

  PreferredSizeWidget _getAppBar() {
    return CustomAppBar(
      AnimatedOpacity(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.64),
                Colors.black.withOpacity(0.5),
                Colors.transparent,
              ],
              stops: [0, 0.2, 1],
            ),
          ),
          child: _buildAppBar(),
        ),
        opacity: _shouldHideAppBar ? 0 : 1,
        duration: Duration(milliseconds: 150),
      ),
      height: 100,
    );
  }

  Widget _getBottomBar() {
    List<Widget> children = [];
    children.add(
      Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 12),
        child: IconButton(
          icon: Icon(
              Platform.isAndroid ? Icons.info_outline : CupertinoIcons.info),
          onPressed: () {
            _displayInfo(_files[_selectedIndex]);
          },
        ),
      ),
    );
    if (_files[_selectedIndex].fileType == FileType.image) {
      children.add(
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 12),
          child: IconButton(
            icon: Icon(Icons.tune_outlined),
            onPressed: () {
              _editFile(_files[_selectedIndex]);
            },
          ),
        ),
      );
    }
    children.add(
      Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 12),
        child: IconButton(
          icon: Icon(
              Platform.isAndroid ? Icons.share_outlined : CupertinoIcons.share),
          onPressed: () {
            share(context, [_files[_selectedIndex]]);
          },
        ),
      ),
    );
    return AnimatedOpacity(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.5),
                Colors.black.withOpacity(0.64),
              ],
              stops: [0, 0.8, 1],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: children,
            ),
          ),
        ),
      ),
      opacity: _shouldHideAppBar ? 0 : 1,
      duration: Duration(milliseconds: 150),
    );
  }

  Widget _buildPageView() {
    _logger.info("Building with " + _selectedIndex.toString());
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
            tagPrefix: widget.config.tagPrefix,
          );
        } else if (file.fileType == FileType.video) {
          content = VideoWidget(
            file,
            autoPlay: !_hasPageChanged, // Autoplay if it was opened directly
            tagPrefix: widget.config.tagPrefix,
          );
        } else {
          content = Icon(Icons.error);
        }
        _preloadFiles(index);
        return GestureDetector(
          onTap: () {
            setState(() {
              _shouldHideAppBar = !_shouldHideAppBar;
            });
          },
          child: content,
        );
      },
      onPageChanged: (index) {
        setState(() {
          _selectedIndex = index;
          _hasPageChanged = true;
        });
        _preloadEntries(index);
        _preloadFiles(index);
      },
      physics: _shouldDisableScroll
          ? NeverScrollableScrollPhysics()
          : PageScrollPhysics(),
      controller: _pageController,
      itemCount: _files.length,
    );
  }

  void _preloadEntries(int index) async {
    if (index == 0 && !_hasLoadedTillStart) {
      final result = await widget.config.asyncLoader(
          _files[index].creationTime + 1, DateTime.now().microsecondsSinceEpoch,
          limit: kLoadLimit, asc: true);
      setState(() {
        final files = result.files.reversed.toList();
        if (!result.hasMore) {
          _hasLoadedTillStart = true;
        }
        final length = files.length;
        files.addAll(_files);
        _files = files;
        _pageController.jumpToPage(length);
        _selectedIndex = length;
      });
    }
    if (index == _files.length - 1 && !_hasLoadedTillEnd) {
      final result = await widget.config
          .asyncLoader(0, _files[index].creationTime - 1, limit: kLoadLimit);
      setState(() {
        if (!result.hasMore) {
          _hasLoadedTillEnd = true;
        }
        _files.addAll(result.files);
      });
    }
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
    final List<Widget> actions = [];
    actions.add(_getFavoriteButton());
    actions.add(PopupMenuButton(
      itemBuilder: (context) {
        final List<PopupMenuItem> items = [];
        if (_files[_selectedIndex].localID == null) {
          items.add(
            PopupMenuItem(
              value: 1,
              child: Row(
                children: [
                  Icon(Platform.isAndroid
                      ? Icons.download
                      : CupertinoIcons.cloud_download),
                  Padding(
                    padding: EdgeInsets.all(8),
                  ),
                  Text("download"),
                ],
              ),
            ),
          );
        }
        items.add(
          PopupMenuItem(
            value: 2,
            child: Row(
              children: [
                Icon(Platform.isAndroid
                    ? Icons.delete_outline
                    : CupertinoIcons.delete),
                Padding(
                  padding: EdgeInsets.all(8),
                ),
                Text("delete"),
              ],
            ),
          ),
        );
        if (Platform.isAndroid) {
          items.add(
            PopupMenuItem(
              value: 3,
              child: Row(
                children: [
                  Icon(Icons.wallpaper_outlined),
                  Padding(
                    padding: EdgeInsets.all(8),
                  ),
                  Text("set wallpaper"),
                ],
              ),
            ),
          );
        }
        return items;
      },
      onSelected: (value) {
        final file = _files[_selectedIndex];
        if (value == 1) {
          _download(file);
        } else if (value == 2) {
          _showDeleteSheet();
        } else if (value == 3) {
          _setWallpaper(file);
        }
      },
    ));
    return AppBar(
      title: Text(
        getDayTitle(_files[_selectedIndex].creationTime),
        style: TextStyle(
          fontSize: 14,
        ),
      ),
      actions: actions,
      backgroundColor: Color(0x00000000),
      elevation: 0,
    );
  }

  Future<void> _editFile(File file) async {
    final dialog = createProgressDialog(context, "please wait...");
    await dialog.show();
    final imageProvider =
        ExtendedFileImageProvider(await getFile(file), cacheRawData: true);
    await precacheImage(imageProvider, context);
    await dialog.hide();
    replacePage(
      context,
      ImageEditorPage(
        imageProvider,
        file,
        widget.config.copyWith(
          files: _files,
          selectedIndex: _selectedIndex,
        ),
      ),
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
          final shouldBlockUser = file.uploadedFileID == null;
          var dialog;
          if (shouldBlockUser) {
            dialog = createProgressDialog(context, "adding to favorites...");
            await dialog.show();
          }
          try {
            await FavoritesService.instance.addToFavorites(file);
          } catch (e, s) {
            _logger.severe(e, s);
            hasError = true;
            showToast("sorry, could not add this to favorites!");
          } finally {
            if (shouldBlockUser) {
              await dialog.hide();
            }
          }
        } else {
          try {
            await FavoritesService.instance.removeFromFavorites(file);
          } catch (e, s) {
            _logger.severe(e, s);
            hasError = true;
            showToast("sorry, could not remove this from favorites!");
          }
        }
        return hasError ? oldValue : isLiked;
      },
      likeBuilder: (isLiked) {
        return Icon(
          Icons.favorite_border,
          color: isLiked ? Colors.pinkAccent : Colors.white,
          size: 24,
        );
      },
    );
  }

  Future<void> _displayInfo(File file) async {
    AssetEntity asset;
    int fileSize;
    final isLocalFile = file.localID != null;
    if (isLocalFile) {
      asset = await file.getAsset();
      fileSize = await (await asset.originFile).length();
    }
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        var items = <Widget>[
          Row(
            children: [
              Icon(Icons.calendar_today_outlined),
              Padding(padding: EdgeInsets.all(4)),
              Text(getFormattedTime(
                  DateTime.fromMicrosecondsSinceEpoch(file.creationTime))),
            ],
          ),
          Padding(padding: EdgeInsets.all(4)),
          Row(
            children: [
              Icon(Icons.folder_outlined),
              Padding(padding: EdgeInsets.all(4)),
              Text(file.deviceFolder ??
                  CollectionsService.instance
                      .getCollectionByID(file.collectionID)
                      .name),
            ],
          ),
          Padding(padding: EdgeInsets.all(4)),
        ];
        if (isLocalFile) {
          items.add(Row(
            children: [
              Icon(Icons.sd_storage_outlined),
              Padding(padding: EdgeInsets.all(4)),
              Text((fileSize / (1024 * 1024)).toStringAsFixed(2) + " MB"),
            ],
          ));
          items.add(
            Padding(padding: EdgeInsets.all(4)),
          );
          if (file.fileType == FileType.image) {
            items.add(Row(
              children: [
                Icon(Icons.photo_size_select_actual_outlined),
                Padding(padding: EdgeInsets.all(4)),
                Text(asset.width.toString() + " x " + asset.height.toString()),
              ],
            ));
          } else {
            items.add(Row(
              children: [
                Icon(Icons.timer_outlined),
                Padding(padding: EdgeInsets.all(4)),
                Text(asset.videoDuration.toString().split(".")[0]),
              ],
            ));
          }
          items.add(
            Padding(padding: EdgeInsets.all(4)),
          );
        }
        if (file.uploadedFileID != null) {
          items.add(Row(
            children: [
              Icon(Icons.cloud_upload_outlined),
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
              child: Text('ok'),
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop('dialog');
              },
            ),
          ],
        );
      },
    );
  }

  void _showDeleteSheet() {
    final fileToBeDeleted = _files[_selectedIndex];
    final actions = List<Widget>();
    if (fileToBeDeleted.uploadedFileID == null) {
      actions.add(CupertinoActionSheetAction(
        child: Text("everywhere"),
        isDestructiveAction: true,
        onPressed: () async {
          await deleteFilesFromEverywhere(context, [fileToBeDeleted]);
          _onFileDeleted();
        },
      ));
    } else {
      if (fileToBeDeleted.localID != null) {
        actions.add(CupertinoActionSheetAction(
          child: Text("on this device"),
          isDestructiveAction: true,
          onPressed: () async {
            await deleteFilesOnDeviceOnly(context, [fileToBeDeleted]);
            showToast("file deleted from device");
            Navigator.of(context, rootNavigator: true).pop();
          },
        ));
      }
      actions.add(CupertinoActionSheetAction(
        child: Text("everywhere"),
        isDestructiveAction: true,
        onPressed: () async {
          await deleteFilesFromEverywhere(context, [fileToBeDeleted]);
          _onFileDeleted();
        },
      ));
    }
    final action = CupertinoActionSheet(
      title: Text("delete file?"),
      actions: actions,
      cancelButton: CupertinoActionSheetAction(
        child: Text("cancel"),
        onPressed: () {
          Navigator.of(context, rootNavigator: true).pop();
        },
      ),
    );
    showCupertinoModalPopup(context: context, builder: (_) => action);
  }

  Future _onFileDeleted() async {
    final file = _files[_selectedIndex];
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

  Future<void> _download(File file) async {
    final dialog = createProgressDialog(context, "downloading...");
    await dialog.show();
    final savedAsset = await PhotoManager.editor.saveImageWithPath(
      (await getFile(file)).path,
      title: file.title,
    );
    file.localID = savedAsset.id;
    await FilesDB.instance.insert(file);
    await LocalSyncService.instance.trackDownloadedFile(file);
    Bus.instance.fire(LocalPhotosUpdatedEvent([file]));
    await dialog.hide();
    showToast("file saved to gallery");
  }

  Future<void> _setWallpaper(File file) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SetWallpaperDialog(file);
      },
      barrierColor: Colors.black87,
    );
  }
}
