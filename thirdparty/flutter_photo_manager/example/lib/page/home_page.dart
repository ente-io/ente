import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_scanner_example/model/photo_provider.dart';
import 'package:image_scanner_example/page/gallery_list_page.dart';
import 'package:image_scanner_example/widget/change_notifier_builder.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';

import 'filter_option_page.dart';

class NewHomePage extends StatefulWidget {
  @override
  _NewHomePageState createState() => _NewHomePageState();
}

class _NewHomePageState extends State<NewHomePage> {
  PhotoProvider get readProvider => context.read<PhotoProvider>();
  PhotoProvider get watchProvider => context.watch<PhotoProvider>();

  @override
  void initState() {
    super.initState();
    PhotoManager.addChangeCallback(onChange);
    PhotoManager.setLog(true);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierBuilder(
      value: watchProvider,
      builder: (_, __) => Scaffold(
        appBar: AppBar(
          title: Text("photo manager example"),
        ),
        body: Column(
          children: <Widget>[
            buildButton("Get all gallery list", _scanGalleryList),
            if (Platform.isIOS)
              buildButton(
                  "Change limited photos with PhotosUI", _changeLimitPhotos),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text("scan type"),
                Container(
                  width: 10,
                ),
              ],
            ),
            _buildTypeChecks(watchProvider),
            _buildHasAllCheck(),
            _buildOnlyAllCheck(),
            _buildContainsEmptyCheck(),
            _buildPathContainsModifiedDateCheck(),
            _buildPngCheck(),
            _buildNotifyCheck(),
            _buildFilterOption(watchProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChecks(PhotoProvider provider) {
    final currentType = provider.type;
    Widget buildType(RequestType type) {
      String typeText;
      if (type.containsImage()) {
        typeText = "image";
      } else if (type.containsVideo()) {
        typeText = "video";
      } else if (type.containsAudio()) {
        typeText = "audio";
      } else {
        typeText = "";
      }

      return Expanded(
        child: CheckboxListTile(
          title: Text(typeText),
          value: currentType.containsType(type),
          onChanged: (bool? value) {
            if (value == true) {
              provider.changeType(currentType + type);
            } else {
              provider.changeType(currentType - type);
            }
          },
        ),
      );
    }

    return Container(
      height: 50,
      child: Row(
        children: <Widget>[
          buildType(RequestType.image),
          buildType(RequestType.video),
          buildType(RequestType.audio),
        ],
      ),
    );
  }

  _scanGalleryList() async {
    await readProvider.refreshGalleryList();

    final page = GalleryListPage();

    Navigator.of(context).push(MaterialPageRoute(
      builder: (ctx) => page,
    ));
  }

  Widget _buildHasAllCheck() {
    return CheckboxListTile(
      value: watchProvider.hasAll,
      onChanged: (value) {
        readProvider.changeHasAll(value);
      },
      title: Text("hasAll"),
    );
  }

  Widget _buildPngCheck() {
    return CheckboxListTile(
      value: watchProvider.thumbFormat == ThumbFormat.png,
      onChanged: (value) {
        readProvider.changeThumbFormat();
      },
      title: Text("thumb png"),
    );
  }

  Widget _buildOnlyAllCheck() {
    return CheckboxListTile(
      value: watchProvider.onlyAll,
      onChanged: (value) {
        readProvider.changeOnlyAll(value);
      },
      title: Text("onlyAll"),
    );
  }

  Widget _buildContainsEmptyCheck() {
    if (!Platform.isIOS) {
      return Container();
    }
    return CheckboxListTile(
      value: watchProvider.containsEmptyAlbum,
      onChanged: (value) {
        readProvider.changeContainsEmptyAlbum(value);
      },
      title: Text("contains empty album(only iOS)"),
    );
  }

  Widget _buildPathContainsModifiedDateCheck() {
    return CheckboxListTile(
      value: watchProvider.containsPathModified,
      onChanged: (value) {
        readProvider.changeContainsPathModified(value);
      },
      title: Text("contains path modified date"),
    );
  }

  Widget _buildNotifyCheck() {
    return CheckboxListTile(
        value: watchProvider.notifying,
        title: Text("onChanged"),
        onChanged: (value) {
          readProvider.notifying = value;
          if (value == true) {
            PhotoManager.startChangeNotify();
          } else {
            PhotoManager.stopChangeNotify();
          }
        });
  }

  void onChange(call) {}

  Widget _buildFilterOption(PhotoProvider provider) {
    return ElevatedButton(
      child: Text("Change filter options."),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (BuildContext context) {
              return FilterOptionPage();
            },
          ),
        );
      },
    );
  }

  Future<void> _changeLimitPhotos() async {
    await PhotoManager.presentLimited();
  }
}

Widget buildButton(String text, VoidCallback function) {
  return ElevatedButton(
    child: Text(text),
    onPressed: function,
  );
}
