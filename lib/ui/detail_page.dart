import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:like_button/like_button.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/photo_opened_event.dart';
import 'package:photos/favorite_photos_repository.dart';
import 'package:photos/models/photo.dart';
import 'package:photos/ui/extents_page_view.dart';
import 'package:photos/ui/zoomable_image.dart';
import 'package:photos/utils/date_time_util.dart';
import 'package:photos/utils/share_util.dart';
import 'package:logging/logging.dart';

class DetailPage extends StatefulWidget {
  final List<Photo> photos;
  final int selectedIndex;

  DetailPage(this.photos, this.selectedIndex, {key}) : super(key: key);

  @override
  _DetailPageState createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  final _logger = Logger("DetailPageState");
  bool _shouldDisableScroll = false;
  List<Photo> _photos;
  int _selectedIndex = 0;

  @override
  void initState() {
    _photos = widget.photos;
    _selectedIndex = widget.selectedIndex;
    super.initState();
  }

  @override
  void dispose() {
    Bus.instance.fire(PhotoOpenedEvent(null));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _logger.info("Opening " +
        _photos[_selectedIndex].toString() +
        ". " +
        _selectedIndex.toString() +
        " / " +
        _photos.length.toString() +
        " photos .");
    return Scaffold(
      appBar: _buildAppBar(),
      body: Center(
        child: Container(
          child: _buildPageView(),
        ),
      ),
    );
  }

  Widget _buildPageView() {
    return ExtentsPageView.extents(
      itemBuilder: (context, index) {
        final photo = _photos[index];
        final image = ZoomableImage(
          photo,
          shouldDisableScroll: (value) {
            setState(() {
              _shouldDisableScroll = value;
            });
          },
        );
        if (index == _selectedIndex) {
          Bus.instance.fire(PhotoOpenedEvent(photo));
        }
        return image;
      },
      onPageChanged: (int index) {
        _selectedIndex = index;
        Bus.instance.fire(PhotoOpenedEvent(widget.photos[index]));
      },
      physics: _shouldDisableScroll
          ? NeverScrollableScrollPhysics()
          : PageScrollPhysics(),
      controller: PageController(initialPage: _selectedIndex),
      itemCount: _photos.length,
      extents: 1,
    );
  }

  AppBar _buildAppBar() {
    final actions = List<Widget>();
    if (_photos[_selectedIndex].localId != null) {
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
          share(_photos[_selectedIndex]);
        } else if (value == 2) {
          _displayInfo(_photos[_selectedIndex]);
        }
      },
    ));
    return AppBar(
      actions: actions,
    );
  }

  Widget _getFavoriteButton() {
    final photo = _photos[_selectedIndex];
    return LikeButton(
      isLiked: FavoritePhotosRepository.instance.isLiked(photo),
      onTap: (oldValue) {
        return FavoritePhotosRepository.instance.setLiked(photo, !oldValue);
      },
    );
  }

  Future<void> _displayInfo(Photo photo) async {
    final asset = await photo.getAsset();
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(photo.title),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Row(
                  children: [
                    Icon(Icons.timer),
                    Padding(padding: EdgeInsets.all(4)),
                    Text(getFormattedTime(DateTime.fromMicrosecondsSinceEpoch(
                        photo.createTimestamp))),
                  ],
                ),
                Padding(padding: EdgeInsets.all(4)),
                Row(
                  children: [
                    Icon(Icons.folder),
                    Padding(padding: EdgeInsets.all(4)),
                    Text(photo.deviceFolder),
                  ],
                ),
                Padding(padding: EdgeInsets.all(4)),
                Row(
                  children: [
                    Icon(Icons.photo_size_select_actual),
                    Padding(padding: EdgeInsets.all(4)),
                    Text(asset.width.toString() +
                        " x " +
                        asset.height.toString()),
                  ],
                ),
              ],
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
