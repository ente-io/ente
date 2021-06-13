import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_scanner_example/page/image_list_page.dart';
import 'package:image_scanner_example/page/sub_gallery_page.dart';
import 'package:oktoast/oktoast.dart';
import 'package:photo_manager/photo_manager.dart';

import 'dialog/list_dialog.dart';

class GalleryItemWidget extends StatelessWidget {
  const GalleryItemWidget({
    Key? key,
    required this.path,
    required this.setState,
  }) : super(key: key);

  final AssetPathEntity path;
  final ValueSetter<VoidCallback> setState;

  @override
  Widget build(BuildContext context) {
    return buildGalleryItemWidget(path, context);
  }

  Widget buildGalleryItemWidget(AssetPathEntity item, BuildContext context) {
    return GestureDetector(
      child: ListTile(
        title: Text(item.name),
        subtitle: Text("count : ${item.assetCount}"),
        trailing: _buildSubButton(item),
      ),
      onTap: () {
        if (item.assetCount == 0) {
          showToast("The asset count is 0.");
          return;
        }
        if (item.albumType == 2) {
          showToast("The folder can't get asset");
          return;
        }

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => GalleryContentListPage(
              path: item,
            ),
          ),
        );
      },
      onLongPress: () async {
        showDialog(
          context: context,
          builder: (_) {
            return ListDialog(
              children: [
                ElevatedButton(
                  child: Text("refresh properties"),
                  onPressed: () async {
                    await item.refreshPathProperties();
                    setState(() {});
                  },
                ),
                ElevatedButton(
                  child: Text("Delete self (${item.name})"),
                  onPressed: () async {
                    if (!(Platform.isIOS || Platform.isMacOS)) {
                      showToast("The function only support iOS.");
                      return;
                    }
                    PhotoManager.editor.iOS.deletePath(path);
                  },
                ),
                ElevatedButton(
                  child: Text("Show modified date"),
                  onPressed: () async {
                    showToast('modified date = ${item.lastModified}');
                  },
                ),
              ],
            );
          },
        );
      },
      // onDoubleTap: () async {
      //   final list =
      //       await item.getAssetListRange(start: 0, end: item.assetCount);
      //   for (var i = 0; i < list.length; i++) {
      //     final asset = list[i];
      //     debugPrint("$i : ${asset.id}");
      //   }
      // },
    );
  }

  Widget _buildSubButton(AssetPathEntity item) {
    if (item.isAll || item.albumType == 2) {
      return Builder(
        builder: (ctx) => ElevatedButton(
          onPressed: () async {
            final sub = await item.getSubPathList();
            Navigator.push(ctx, MaterialPageRoute(builder: (_) {
              return SubFolderPage(
                title: item.name,
                pathList: sub,
              );
            }));
          },
          child: Text("folder"),
        ),
      );
    } else {
      return Container(
        width: 0,
        height: 0,
      );
    }
  }
}
