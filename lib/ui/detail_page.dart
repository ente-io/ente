import 'dart:io';

import 'package:flutter/material.dart';
import 'package:myapp/core/lru_map.dart';
import 'package:myapp/models/photo.dart';
import 'package:photo_view/photo_view.dart';
import 'package:share_extend/share_extend.dart';
import 'extents_page_view.dart';

class DetailPage extends StatefulWidget {
  final List<Photo> photos;
  int selectedIndex;

  DetailPage(this.photos, this.selectedIndex, {Key key}) : super(key: key);

  @override
  _DetailPageState createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  bool _shouldDisableScroll = false;

  @override
  Widget build(BuildContext context) {
    var pageController = PageController(initialPage: widget.selectedIndex);

    return Scaffold(
      appBar: AppBar(
        actions: <Widget>[
          // action button
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () {
              ShareExtend.share(
                  widget.photos[widget.selectedIndex].localPath, "image");
            },
          )
        ],
      ),
      body: Center(
        child: Container(
          child: ExtentsPageView.extents(
            itemBuilder: (context, index) {
              return _buildItem(context, widget.photos[index]);
            },
            onPageChanged: (int index) {
              widget.selectedIndex = index;
            },
            physics: _shouldDisableScroll
                ? NeverScrollableScrollPhysics()
                : PageScrollPhysics(),
            controller: pageController,
          ),
        ),
      ),
    );
  }

  Widget _buildItem(BuildContext context, Photo photo) {
    var image = ImageLruCache.getData(photo.localPath) == null
        ? Image.file(
            File(photo.localPath),
            filterQuality: FilterQuality.low,
          )
        : ImageLruCache.getData(photo.localPath);
    ValueChanged<PhotoViewScaleState> scaleStateChangedCallback = (value) {
      var shouldDisableScroll;
      if (value == PhotoViewScaleState.initial) {
        shouldDisableScroll = false;
      } else {
        shouldDisableScroll = true;
      }
      if (shouldDisableScroll != _shouldDisableScroll) {
        setState(() {
          _shouldDisableScroll = shouldDisableScroll;
        });
      }
    };
    return PhotoView(
      imageProvider: image.image,
      scaleStateChangedCallback: scaleStateChangedCallback,
    );
  }
}
