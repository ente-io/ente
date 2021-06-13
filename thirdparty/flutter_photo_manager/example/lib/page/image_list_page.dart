import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_scanner_example/develop/upload_to_dev_serve.dart';
import 'package:image_scanner_example/model/photo_provider.dart';
import 'package:image_scanner_example/page/detail_page.dart';
import 'package:image_scanner_example/util/common_util.dart';
import 'package:image_scanner_example/widget/change_notifier_builder.dart';
import 'package:image_scanner_example/widget/dialog/list_dialog.dart';
import 'package:image_scanner_example/widget/image_item_widget.dart';
import 'package:image_scanner_example/widget/loading_widget.dart';

import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';

import 'copy_to_another_gallery_example.dart';
import 'move_to_another_gallery_example.dart';
import 'dart:ui' as ui;

class GalleryContentListPage extends StatefulWidget {
  const GalleryContentListPage({
    Key? key,
    required this.path,
  }) : super(key: key);

  final AssetPathEntity path;

  @override
  _GalleryContentListPageState createState() => _GalleryContentListPageState();
}

class _GalleryContentListPageState extends State<GalleryContentListPage> {
  AssetPathEntity get path => widget.path;

  PhotoProvider get photoProvider => Provider.of<PhotoProvider>(context);

  AssetPathProvider get provider =>
      context.read<PhotoProvider>().getOrCreatePathProvider(path);

  List<AssetEntity> checked = [];

  @override
  void initState() {
    super.initState();
    path.getAssetListRange(start: 0, end: path.assetCount).then((value) {
      if (value.isEmpty) {
        return;
      }
      if (mounted) {
        return;
      }
      PhotoCachingManager().requestCacheAssets(
        assets: value,
        option: thumbOption,
      );
    });
  }

  @override
  void dispose() {
    PhotoCachingManager().cancelCacheRequest();
    super.dispose();
  }

  ThumbOption get thumbOption => ThumbOption(
        width: 130,
        height: 130,
        format: photoProvider.thumbFormat,
      );

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierBuilder(
      value: provider,
      builder: (_, __) {
        var length = path.assetCount;
        return Scaffold(
          appBar: AppBar(
            title: Text("${path.name}"),
            actions: <Widget>[
              IconButton(
                icon: Icon(
                  Icons.delete,
                ),
                tooltip: 'Delete selected ',
                onPressed: () {
                  provider.deleteSelectedAssets(checked);
                },
              ),
              AnimatedBuilder(
                animation: photoProvider,
                builder: (_, __) {
                  final formatType =
                      photoProvider.thumbFormat == ThumbFormat.jpeg
                          ? ThumbFormat.png
                          : ThumbFormat.jpeg;
                  return IconButton(
                    icon: Icon(Icons.swap_horiz),
                    iconSize: 22,
                    tooltip: "Use another format.",
                    onPressed: () {
                      photoProvider.thumbFormat = formatType;
                    },
                  );
                },
              ),
              Tooltip(
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Icon(
                    Icons.info_outline,
                    size: 22,
                  ),
                ),
                message: "Long tap to delete item.",
              ),
            ],
          ),
          body: buildRefreshIndicator(length),
        );
      },
    );
  }

  Widget buildRefreshIndicator(int length) {
    if (!provider.isInit) {
      provider.onRefresh();
      return Center(
        child: Text("loading"),
      );
    }
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: Scrollbar(
        child: GridView.builder(
          itemBuilder: _buildItem,
          itemCount: provider.showItemCount,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
          ),
        ),
      ),
    );
  }

  Widget _buildItem(BuildContext context, int index) {
    final list = provider.list;
    if (list.length == index) {
      onLoadMore();
      return loadWidget;
    }

    if (index > list.length) {
      return Container();
    }

    final entity = list[index];

    Widget previewOriginBytesWidget;

    if (entity.type != AssetType.image) {
      previewOriginBytesWidget = Container();
    } else {
      previewOriginBytesWidget = ElevatedButton(
        child: Text("Show origin bytes image in dialog"),
        onPressed: () => showOriginBytes(entity),
      );
    }

    return GestureDetector(
      onTap: () async {
        showDialog(
          context: context,
          builder: (_) => ListDialog(
            children: <Widget>[
              previewOriginBytesWidget,
              ElevatedButton(
                child: Text("Show detail page"),
                onPressed: () => routeToDetailPage(entity),
              ),
              ElevatedButton(
                child: Text("Show info dialog"),
                onPressed: () => CommonUtil.showInfoDialog(context, entity),
              ),
              ElevatedButton(
                child: Text("show 500 size thumb "),
                onPressed: () => showThumb(entity, 500),
              ),
              ElevatedButton(
                child: Text("Delete item"),
                onPressed: () => _deleteCurrent(entity),
              ),
              ElevatedButton(
                child: Text("Upload to my test server."),
                onPressed: () => UploadToDevServer.upload(entity),
              ),
              ElevatedButton(
                child: Text("Copy to another path"),
                onPressed: () => copyToAnotherPath(entity),
              ),
              _buildMoveAnotherPath(entity),
              _buildRemoveInAlbumWidget(entity),
              ElevatedButton(
                child: Text("Test progress"),
                onPressed: () => testProgressHandler(entity),
              ),
              ElevatedButton(
                child: Text("Test thumb size"),
                onPressed: () =>
                    testThumbSize(entity, [500, 600, 700, 1000, 1500, 2000]),
              ),
            ],
          ),
        );
      },
      onLongPress: () {
        if (checked.contains(entity)) {
          checked.remove(entity);
        } else {
          checked.add(entity);
        }
        setState(() {});
      },
      child: Stack(
        children: [
          ImageItemWidget(
            key: ValueKey(entity),
            entity: entity,
            option: thumbOption,
          ),
          Align(
            alignment: Alignment.topRight,
            child: Checkbox(
              value: checked.contains(entity),
              onChanged: (value) {
                if (checked.contains(entity)) {
                  checked.remove(entity);
                } else {
                  checked.add(entity);
                }
                setState(() {});
              },
            ),
          ),
        ],
      ),
    );
  }

  void routeToDetailPage(AssetEntity entity) async {
    final mediaUrl = await entity.getMediaUrl();
    final page = DetailPage(
      entity: entity,
      mediaUrl: mediaUrl,
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) {
          return page;
        },
      ),
    );
  }

  Future<void> onLoadMore() async {
    if (!mounted) {
      return;
    }
    await provider.onLoadMore();
  }

  Future<void> _onRefresh() async {
    if (!mounted) {
      return;
    }
    await provider.onRefresh();
  }

  void _deleteCurrent(AssetEntity entity) async {
    if (Platform.isAndroid) {
      final dialog = AlertDialog(
        title: Text("Delete the asset"),
        actions: <Widget>[
          TextButton(
            child: Text(
              "delete",
              style: const TextStyle(color: Colors.red),
            ),
            onPressed: () async {
              provider.delete(entity);
              Navigator.pop(context);
            },
          ),
          TextButton(
            child: Text("cancel"),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      );
      showDialog(context: context, builder: (_) => dialog);
    } else {
      provider.delete(entity);
    }
  }

  Future<void> showOriginBytes(AssetEntity entity) async {
    final String title;
    if (entity.title?.isEmpty != false) {
      title = await entity.titleAsync;
    } else {
      title = entity.title!;
    }
    print("entity.title = $title");
    showDialog(
        context: context,
        builder: (_) {
          return FutureBuilder<Uint8List?>(
            future: entity.originBytes,
            builder: (BuildContext context, snapshot) {
              Widget w;
              if (snapshot.hasError) {
                return ErrorWidget(snapshot.error!);
              } else if (snapshot.hasData) {
                w = Image.memory(snapshot.data!);
              } else {
                w = Center(
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              return GestureDetector(
                child: w,
                onTap: () => Navigator.pop(context),
              );
            },
          );
        });
  }

  void copyToAnotherPath(AssetEntity entity) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CopyToAnotherGalleryPage(assetEntity: entity),
      ),
    );
  }

  Widget _buildRemoveInAlbumWidget(AssetEntity entity) {
    if (!(Platform.isIOS || Platform.isMacOS)) {
      return Container();
    }

    return ElevatedButton(
      child: Text("Remove in album"),
      onPressed: () => deleteAssetInAlbum(entity),
    );
  }

  void deleteAssetInAlbum(entity) {
    provider.removeInAlbum(entity);
  }

  Widget _buildMoveAnotherPath(AssetEntity entity) {
    if (!Platform.isAndroid) {
      return Container();
    }
    return ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (BuildContext context) {
            return MoveToAnotherExample(entity: entity);
          }),
        );
      },
      child: Text("Move to another gallery."),
    );
  }

  showThumb(AssetEntity entity, int size) async {
    final String title;
    if (entity.title?.isEmpty != false) {
      title = await entity.titleAsync;
    } else {
      title = entity.title!;
    }
    print("entity.title = $title");
    showDialog(
      context: context,
      builder: (_) {
        return FutureBuilder<Uint8List?>(
          future: entity.thumbDataWithOption(
            ThumbOption.ios(
              width: 500,
              height: 500,
              deliveryMode: DeliveryMode.opportunistic,
              resizeMode: ResizeMode.fast,
              resizeContentMode: ResizeContentMode.fit,
              // resizeContentMode: ResizeContentMode.fill,
            ),
          ),
          builder: (BuildContext context, snapshot) {
            Widget w;
            if (snapshot.hasError) {
              return ErrorWidget(snapshot.error!);
            } else if (snapshot.hasData) {
              final data = snapshot.data!;
              ui.decodeImageFromList(data, (result) {
                print('result size: ${result.width}x${result.height}');
                // for 4288x2848
              });
              w = Image.memory(data);
            } else {
              w = Center(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            return GestureDetector(
              child: w,
              onTap: () => Navigator.pop(context),
            );
          },
        );
      },
    );
  }

  Future<void> testProgressHandler(AssetEntity entity) async {
    final progressHandler = PMProgressHandler();
    progressHandler.stream.listen((event) {
      final progress = event.progress;
      print('progress state onChange: ${event.state}, progress: $progress');
    });
    // final file = await entity.loadFile(progressHandler: progressHandler);
    // print('file = $file');

    // final thumb = await entity.thumbDataWithSize(
    //   300,
    //   300,
    //   progressHandler: progressHandler,
    // );

    // print('thumb length = ${thumb.length}');

    final file = await entity.loadFile(
      progressHandler: progressHandler,
      isOrigin: true,
    );
    print('file = $file');
  }

  testThumbSize(AssetEntity entity, List<int> list) async {
    for (final size in list) {
      // final data = await entity.thumbDataWithOption(ThumbOption.ios(
      //   width: size,
      //   height: size,
      //   resizeMode: ResizeMode.exact,
      // ));
      final data = await entity.thumbDataWithSize(size, size);

      if (data == null) {
        return;
      }
      ui.decodeImageFromList(data, (result) {
        print(
            'size:$size length:${data.length}, size: ${result.width}x${result.height}');
      });
    }
  }
}
