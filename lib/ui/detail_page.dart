import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:myapp/core/lru_map.dart';
import 'package:myapp/models/photo.dart';
import 'package:photo_view/photo_view.dart';
import 'extents_page_view.dart';
import 'loading_widget.dart';
import 'package:myapp/utils/share_util.dart';

class DetailPage extends StatefulWidget {
  final List<Photo> photos;
  final int selectedIndex;

  DetailPage(this.photos, this.selectedIndex, {Key key}) : super(key: key);

  @override
  _DetailPageState createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  bool _shouldDisableScroll = false;
  int _selectedIndex = 0;
  final _cachedImages = LRUMap<int, ZoomableImage>(5);

  @override
  Widget build(BuildContext context) {
    _selectedIndex = widget.selectedIndex;

    Logger().i("Loading " + widget.photos[_selectedIndex].toString());
    var pageController = PageController(initialPage: _selectedIndex);
    return Scaffold(
      appBar: _buildAppBar(),
      body: Center(
        child: Container(
          child: ExtentsPageView.extents(
            itemBuilder: (context, index) {
              if (_cachedImages.get(index) != null) {
                return _cachedImages.get(index);
              }
              final image = ZoomableImage(
                photo: widget.photos[index],
                shouldDisableScroll: (value) {
                  setState(() {
                    _shouldDisableScroll = value;
                  });
                },
              );
              _cachedImages.put(index, image);
              return image;
            },
            onPageChanged: (int index) {
              _selectedIndex = index;
            },
            physics: _shouldDisableScroll
                ? NeverScrollableScrollPhysics()
                : PageScrollPhysics(),
            controller: pageController,
            itemCount: widget.photos.length,
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      actions: <Widget>[
        IconButton(
          icon: Icon(Icons.share),
          onPressed: () async {
            share(widget.photos[_selectedIndex]);
          },
        )
      ],
    );
  }
}

class ZoomableImage extends StatelessWidget {
  final Function(bool) shouldDisableScroll;

  const ZoomableImage({
    Key key,
    @required this.photo,
    this.shouldDisableScroll,
  }) : super(key: key);

  final Photo photo;

  @override
  Widget build(BuildContext context) {
    Logger().i("Building " + photo.toString());
    if (ImageLruCache.getData(photo.generatedId) != null) {
      return _buildPhotoView(ImageLruCache.getData(photo.generatedId));
    }
    return FutureBuilder<Uint8List>(
      future: photo.getBytes(),
      builder: (_, snapshot) {
        if (snapshot.hasData) {
          return _buildPhotoView(snapshot.data);
        } else if (snapshot.hasError) {
          return Text(snapshot.error.toString());
        } else {
          return loadWidget;
        }
      },
    );
  }

  Widget _buildPhotoView(Uint8List imageData) {
    ValueChanged<PhotoViewScaleState> scaleStateChangedCallback = (value) {
      if (shouldDisableScroll != null) {
        shouldDisableScroll(value != PhotoViewScaleState.initial);
      }
    };
    return PhotoView(
      imageProvider: Image.memory(imageData).image,
      scaleStateChangedCallback: scaleStateChangedCallback,
      minScale: PhotoViewComputedScale.contained,
    );
  }
}
