import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:myapp/core/lru_map.dart';
import 'package:myapp/models/photo.dart';
import 'package:myapp/ui/zoomable_image.dart';
import 'extents_page_view.dart';
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
                widget.photos[index],
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
