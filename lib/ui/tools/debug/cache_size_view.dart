// @dart=2.9

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photos/core/cache/video_cache_manager.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/ui/tools/debug/path_storage_viewer.dart';

class CacheSizeViewer extends StatefulWidget {
  const CacheSizeViewer({Key key}) : super(key: key);

  @override
  State<CacheSizeViewer> createState() => _CacheSizeViewerState();
}

class _CacheSizeViewerState extends State<CacheSizeViewer> {
  final List<PathStorageItem> paths = [];

  @override
  void initState() {
    addPath();
    super.initState();
  }

  void addPath() async {
    final appDocumentsDirectory = (await getApplicationDocumentsDirectory());
    final appSupportDirectory = (await getApplicationSupportDirectory());
    final appTemporaryDirectory = (await getTemporaryDirectory());
    final iOSOnlyTempDirectory = "${appDocumentsDirectory.parent.path}/tmp/";
    final logsDirectory = appSupportDirectory.path + "/logs";

    String tempDownload = Configuration.instance.getTempDirectory();
    String cacheDirectory = Configuration.instance.getThumbnailCacheDirectory();
    final imageCachePath =
        appTemporaryDirectory.path + "/" + DefaultCacheManager.key;
    final videoCachePath =
        appTemporaryDirectory.path + "/" + VideoCacheManager.key;
    paths.addAll([
      PathStorageItem.name(imageCachePath, "Remote images"),
      PathStorageItem.name(videoCachePath, "Remote videos"),
      PathStorageItem.name(cacheDirectory, "Remote thumbnails"),
      PathStorageItem.name(tempDownload, "Pending sync"),
      PathStorageItem.name(logsDirectory, "Application logs"),
      PathStorageItem.name(
          iOSOnlyTempDirectory + "flutter-images", "Local Gallery"),
      PathStorageItem.name(appDocumentsDirectory.path, "App Documents"),
      PathStorageItem.name(appSupportDirectory.path, "App Support"),
      PathStorageItem.name(appTemporaryDirectory.path, "App Temporary"),
    ]);
    appTemporaryDirectory.list().forEach((element) {
      paths.add(
        PathStorageItem.name(
          element.path,
          "App Temp " + element.path.substring(element.path.length - 10),
        ),
      );
    });
    if (mounted) {
      setState(() => {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text("Storage view"),
      ),
      body: _getBody(),
    );
  }

  Widget _getBody() {
    return Container(
      padding: const EdgeInsets.only(left: 12, top: 8, right: 12),
      child: SingleChildScrollView(
        child: ListView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(6, 0, 6, 0),
          physics: const ScrollPhysics(),
          // to disable GridView's scrolling
          itemBuilder: (context, index) {
            final path = paths[index];
            return PathStorageViewer(path);
          },
          itemCount: paths.length,
        ),
      ),
    );
  }
}
