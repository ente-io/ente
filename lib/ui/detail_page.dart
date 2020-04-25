import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:myapp/core/lru_map.dart';
import 'package:myapp/db/db_helper.dart';
import 'package:myapp/models/photo.dart';
import 'package:myapp/photo_loader.dart';
import 'package:myapp/ui/zoomable_image.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';
import 'package:myapp/utils/share_util.dart';

class DetailPage extends StatefulWidget {
  final List<Photo> photos;
  final int selectedIndex;
  final Function(Photo) onPhotoDeleted;

  DetailPage(this.photos, this.selectedIndex, {this.onPhotoDeleted, key})
      : super(key: key);

  @override
  _DetailPageState createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  PhotoLoader get photoLoader => Provider.of<PhotoLoader>(context);
  bool _shouldDisableScroll = false;
  List<Photo> _photos;
  int _selectedIndex = 0;
  PageController _pageController;
  LRUMap<int, ZoomableImage> _cachedImages;

  @override
  void initState() {
    Logger().i("initState");
    _photos = widget.photos;
    _selectedIndex = widget.selectedIndex;
    _cachedImages = LRUMap<int, ZoomableImage>(5);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Logger().i("Opening " +
        _selectedIndex.toString() +
        " / " +
        _photos.length.toString() +
        "photos .");
    return Scaffold(
      appBar: _buildAppBar(),
      body: Center(
        child: Container(
          child: _buildPageView(),
        ),
      ),
    );
  }

  PageView _buildPageView() {
    _pageController = PageController(initialPage: _selectedIndex);
    return PageView.builder(
      itemBuilder: (context, index) {
        final photo = _photos[index];
        if (_cachedImages.get(photo.generatedId) != null) {
          return _cachedImages.get(photo.generatedId);
        }
        final image = ZoomableImage(
          photo,
          shouldDisableScroll: (value) {
            setState(() {
              _shouldDisableScroll = value;
            });
          },
        );
        _cachedImages.put(photo.generatedId, image);
        return image;
      },
      onPageChanged: (int index) {
        Logger().i("onPageChanged to " + index.toString());
        _selectedIndex = index;
      },
      physics: _shouldDisableScroll
          ? NeverScrollableScrollPhysics()
          : PageScrollPhysics(),
      controller: _pageController,
      itemCount: _photos.length,
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      actions: <Widget>[
        IconButton(
          icon: Icon(Icons.delete),
          onPressed: () {
            _showDeletePhotosSheet(context, _photos[_selectedIndex]);
          },
        ),
        IconButton(
          icon: Icon(Icons.share),
          onPressed: () async {
            share(_photos[_selectedIndex]);
          },
        )
      ],
    );
  }

  void _showDeletePhotosSheet(BuildContext context, Photo photo) {
    final action = CupertinoActionSheet(
      actions: <Widget>[
        CupertinoActionSheetAction(
          child: Text("Delete on device"),
          isDestructiveAction: true,
          onPressed: () async {
            await _deletePhoto(context, photo, false);
          },
        ),
        CupertinoActionSheetAction(
          child: Text("Delete everywhere [WiP]"),
          isDestructiveAction: true,
          onPressed: () async {
            await _deletePhoto(context, photo, true);
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

  Future _deletePhoto(
      BuildContext context, Photo photo, bool deleteEverywhere) async {
    await PhotoManager.editor.deleteWithIds([photo.localId]);

    deleteEverywhere
        ? await DatabaseHelper.instance.markPhotoForDeletion(photo)
        : await DatabaseHelper.instance.deletePhoto(photo);

    Navigator.of(context, rootNavigator: true).pop();

    _pageController
        .nextPage(duration: Duration(milliseconds: 250), curve: Curves.ease)
        .then((value) {
      if (widget.onPhotoDeleted != null) {
        widget.onPhotoDeleted(photo);
      }
      _pageController.previousPage(
          duration: Duration(milliseconds: 1), curve: Curves.linear); // h4ck
    });

    photoLoader.reloadPhotos();
  }
}
