import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:myapp/core/lru_map.dart';
import 'package:myapp/models/photo.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_view/photo_view.dart';
import 'package:share_extend/share_extend.dart';
import 'extents_page_view.dart';
import 'loading_widget.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_image_compress/flutter_image_compress.dart';

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
  void initState() {
    super.initState();
  }

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
          onPressed: () {
            ShareExtend.share(widget.photos[_selectedIndex].localPath, "image");
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
    Logger().i("Building " + photo.generatedId.toString());
    if (ImageLruCache.getData(photo.generatedId) != null) {
      return _buildPhotoView(ImageLruCache.getData(photo.generatedId));
    }
    var future;
    if (path.extension(photo.localPath) == '.HEIC') {
      Logger().i("Decoding HEIC");
      future = photo.getAsset().originBytes.then((bytes) =>
          FlutterImageCompress.compressWithList(bytes)
              .then((result) => Uint8List.fromList(result)));
    } else {
      future = AssetEntity(id: photo.localId).originBytes;
    }
    return FutureBuilder<Uint8List>(
      future: future,
      builder: (_, snapshot) {
        if (snapshot.hasData) {
          return _buildPhotoView(snapshot.data);
        } else if (snapshot.hasError) {
          return Text(snapshot.error);
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
