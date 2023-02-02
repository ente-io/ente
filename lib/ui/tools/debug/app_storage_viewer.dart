import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photos/core/cache/video_cache_manager.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/services/feature_flag_service.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/components/captioned_text_widget.dart';
import 'package:photos/ui/components/icon_button_widget.dart';
import 'package:photos/ui/components/menu_item_widget.dart';
import 'package:photos/ui/components/menu_section_title.dart';
import 'package:photos/ui/components/title_bar_title_widget.dart';
import 'package:photos/ui/components/title_bar_widget.dart';
import 'package:photos/ui/tools/debug/path_storage_viewer.dart';
import 'package:photos/utils/directory_content.dart';

class AppStorageViewer extends StatefulWidget {
  const AppStorageViewer({Key? key}) : super(key: key);

  @override
  State<AppStorageViewer> createState() => _AppStorageViewerState();
}

class _AppStorageViewerState extends State<AppStorageViewer> {
  final List<PathStorageItem> paths = [];
  late String iosTempDirectoryPath;
  late bool internalUser;
  int _refreshCounterKey = 0;

  @override
  void initState() {
    internalUser = FeatureFlagService.instance.isInternalUserOrDebugBuild();
    addPath();
    super.initState();
  }

  void addPath() async {
    final appDocumentsDirectory = (await getApplicationDocumentsDirectory());
    final appSupportDirectory = (await getApplicationSupportDirectory());
    final appTemporaryDirectory = (await getTemporaryDirectory());
    iosTempDirectoryPath = "${appDocumentsDirectory.parent.path}/tmp/";
    final iOSPhotoManagerInAppCacheDirectory =
        iosTempDirectoryPath + "flutter-images";
    final androidGlideCacheDirectory =
        "${appTemporaryDirectory.path}/image_manager_disk_cache/";

    final String tempDownload = Configuration.instance.getTempDirectory();
    final String cacheDirectory =
        Configuration.instance.getThumbnailCacheDirectory();
    final imageCachePath =
        appTemporaryDirectory.path + "/" + DefaultCacheManager.key;
    final videoCachePath =
        appTemporaryDirectory.path + "/" + VideoCacheManager.key;
    paths.addAll([
      PathStorageItem.name(
        imageCachePath,
        "Remote images",
        allowCacheClear: true,
      ),
      PathStorageItem.name(
        videoCachePath,
        "Remote videos",
        allowCacheClear: true,
      ),
      PathStorageItem.name(
        cacheDirectory,
        "Remote thumbnails",
        allowCacheClear: true,
      ),
      PathStorageItem.name(tempDownload, "Pending sync"),
      PathStorageItem.name(
        Platform.isAndroid
            ? androidGlideCacheDirectory
            : iOSPhotoManagerInAppCacheDirectory,
        "Local gallery",
        allowCacheClear: true,
      ),
    ]);
    if (internalUser) {
      paths.addAll([
        PathStorageItem.name(appDocumentsDirectory.path, "App Documents Dir"),
        PathStorageItem.name(appSupportDirectory.path, "App Support Dir"),
        PathStorageItem.name(appTemporaryDirectory.path, "App Temp Dir"),
      ]);
      if (!Platform.isAndroid) {
        paths.add(PathStorageItem.name(iosTempDirectoryPath, "/tmp directory"));
      }
    }
    if (mounted) {
      setState(() => {});
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("$runtimeType building");

    return Scaffold(
      body: CustomScrollView(
        primary: false,
        slivers: <Widget>[
          TitleBarWidget(
            flexibleSpaceTitle: const TitleBarTitleWidget(
              title: "Manage device storage",
            ),
            actionIcons: [
              IconButtonWidget(
                icon: Icons.close_outlined,
                iconButtonType: IconButtonType.secondary,
                onTap: () {
                  Navigator.pop(context);
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        children: [
                          const MenuSectionTitle(
                            title: 'Cached data',
                          ),
                          ListView.builder(
                            shrinkWrap: true,
                            padding: const EdgeInsets.all(0),
                            physics: const ScrollPhysics(),
                            // to disable GridView's scrolling
                            itemBuilder: (context, index) {
                              final path = paths[index];
                              return PathStorageViewer(
                                path,
                                removeTopRadius: index > 0,
                                removeBottomRadius: index < paths.length - 1,
                                enableDoubleTapClear: internalUser,
                                key: ValueKey("$index-$_refreshCounterKey"),
                              );
                            },
                            itemCount: paths.length,
                          ),
                          const SizedBox(
                            height: 24,
                          ),
                          MenuItemWidget(
                            leadingIcon: Icons.delete_sweep_outlined,
                            captionedTextWidget: const CaptionedTextWidget(
                              title: "Clear caches",
                            ),
                            menuItemColor:
                                getEnteColorScheme(context).fillFaint,
                            singleBorderRadius: 8,
                            onTap: () async {
                              for (var pathItem in paths) {
                                if (pathItem.allowCacheClear) {
                                  await deleteDirectoryContents(
                                    pathItem.path,
                                  );
                                }
                              }
                              if (!Platform.isAndroid) {
                                await deleteDirectoryContents(
                                  iosTempDirectoryPath,
                                );
                              }
                              _refreshCounterKey++;
                              if (mounted) {
                                setState(() => {});
                              }
                            },
                          ),
                          const SizedBox(
                            height: 24,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
              childCount: 1,
            ),
          ),
        ],
      ),
    );
  }
}
