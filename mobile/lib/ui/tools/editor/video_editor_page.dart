import 'dart:io';
import "dart:math";

import 'package:flutter/material.dart';
import "package:logging/logging.dart";
import 'package:path/path.dart' as path;
import "package:photo_manager/photo_manager.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/db/files_db.dart";
import "package:photos/ente_theme_data.dart";
import "package:photos/events/local_photos_updated_event.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/location/location.dart";
import "package:photos/services/sync_service.dart";
import "package:photos/ui/tools/editor/export_video_service.dart";
import 'package:photos/ui/tools/editor/video_crop_page.dart';
import "package:photos/ui/tools/editor/video_editor/video_editor_bottom_action.dart";
import "package:photos/ui/tools/editor/video_editor/video_editor_main_actions.dart";
import "package:photos/ui/tools/editor/video_editor/video_editor_navigation_options.dart";
import "package:photos/ui/tools/editor/video_editor/video_editor_player_control.dart";
import "package:photos/ui/tools/editor/video_rotate_page.dart";
import "package:photos/ui/tools/editor/video_trim_page.dart";
import "package:photos/ui/viewer/file/detail_page.dart";
import "package:photos/utils/dialog_util.dart";
import "package:photos/utils/navigation_util.dart";
import "package:photos/utils/toast_util.dart";
import "package:video_editor/video_editor.dart";

class VideoEditorPage extends StatefulWidget {
  const VideoEditorPage({
    super.key,
    required this.file,
    required this.ioFile,
    required this.detailPageConfig,
  });

  final EnteFile file;
  final File ioFile;
  final DetailPageConfiguration detailPageConfig;

  @override
  State<VideoEditorPage> createState() => _VideoEditorPageState();
}

class _VideoEditorPageState extends State<VideoEditorPage> {
  final _exportingProgress = ValueNotifier<double>(0.0);
  final _isExporting = ValueNotifier<bool>(false);
  final _logger = Logger("VideoEditor");

  VideoEditorController? _controller;

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      _controller = VideoEditorController.file(
        widget.ioFile,
        minDuration: const Duration(seconds: 1),
        cropStyle: CropGridStyle(
          background: Theme.of(context).colorScheme.surface,
          selectedBoundariesColor:
              const ColorScheme.dark().videoPlayerPrimaryColor,
        ),
        trimStyle: TrimSliderStyle(
          onTrimmedColor: const ColorScheme.dark().videoPlayerPrimaryColor,
          onTrimmingColor: const ColorScheme.dark().videoPlayerPrimaryColor,
          background: Theme.of(context).colorScheme.videoPlayerBackgroundColor,
          positionLineColor:
              Theme.of(context).colorScheme.videoPlayerBorderColor,
          lineColor: Theme.of(context)
              .colorScheme
              .videoPlayerBorderColor
              .withOpacity(0.6),
        ),
      );

      _controller!.initialize().then((_) => setState(() {})).catchError(
        (error) {
          // handle minumum duration bigger than video duration error
          Navigator.pop(context);
        },
        test: (e) => e is VideoMinDurationError,
      );
    });
  }

  @override
  void dispose() async {
    _exportingProgress.dispose();
    _isExporting.dispose();
    _controller?.dispose().ignore();
    ExportService.dispose().ignore();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          toolbarHeight: 0,
        ),
        body: _controller != null && _controller!.initialized
            ? SafeArea(
                child: Stack(
                  children: [
                    Column(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Expanded(
                                child: Hero(
                                  tag: "video-editor-preview",
                                  child: CropGridViewer.preview(
                                    controller: _controller!,
                                  ),
                                ),
                              ),
                              VideoEditorPlayerControl(
                                controller: _controller!,
                              ),
                              VideoEditorMainActions(
                                children: [
                                  VideoEditorBottomAction(
                                    label: S.of(context).trim,
                                    svgPath:
                                        "assets/video-editor/video-editor-trim-action.svg",
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute<void>(
                                        builder: (context) => VideoTrimPage(
                                          controller: _controller!,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 40),
                                  VideoEditorBottomAction(
                                    label: S.of(context).crop,
                                    svgPath:
                                        "assets/video-editor/video-editor-crop-action.svg",
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute<void>(
                                        builder: (context) => VideoCropPage(
                                          controller: _controller!,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 40),
                                  VideoEditorBottomAction(
                                    label: S.of(context).rotate,
                                    svgPath:
                                        "assets/video-editor/video-editor-rotate-action.svg",
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute<void>(
                                        builder: (context) => VideoRotatePage(
                                          controller: _controller!,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 40),
                              VideoEditorNavigationOptions(
                                color: Theme.of(context)
                                    .colorScheme
                                    .videoPlayerPrimaryColor,
                                secondaryText: S.of(context).saveCopy,
                                onSecondaryPressed: () {
                                  exportVideo();
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  void exportVideo() async {
    _exportingProgress.value = 0;
    _isExporting.value = true;
    final dialog = createProgressDialog(context, S.of(context).savingEdits);
    await dialog.show();

    final config = VideoFFmpegVideoEditorConfig(
      _controller!,
      format: VideoExportFormat.mp4,
      // commandBuilder: (config, videoPath, outputPath) {
      //   final List<String> filters = config.getExportFilters();
      //   filters.add('hflip'); // add horizontal flip

      //   return '-i $videoPath ${config.filtersCmd(filters)} -preset ultrafast $outputPath';
      // },
    );

    try {
      await ExportService.runFFmpegCommand(
        await config.getExecuteConfig(),
        onProgress: (stats) {
          _exportingProgress.value =
              config.getFFmpegProgress(stats.getTime().toInt());
        },
        onError: (e, s) => _logger.severe("Error exporting video", e, s),
        onCompleted: (result) async {
          _isExporting.value = false;
          if (!mounted) return;

          final fileName = path.basenameWithoutExtension(widget.file.title!) +
              "_edited_" +
              DateTime.now().microsecondsSinceEpoch.toString() +
              ".mp4";
          //Disabling notifications for assets changing to insert the file into
          //files db before triggering a sync.
          await PhotoManager.stopChangeNotify();

          try {
            final AssetEntity? newAsset =
                await (PhotoManager.editor.saveVideo(result, title: fileName));
            result.deleteSync();
            final newFile = await EnteFile.fromAsset(
              widget.file.deviceFolder ?? '',
              newAsset!,
            );

            newFile.creationTime = widget.file.creationTime;
            newFile.collectionID = widget.file.collectionID;
            newFile.location = widget.file.location;
            if (!newFile.hasLocation && widget.file.localID != null) {
              final assetEntity = await widget.file.getAsset;
              if (assetEntity != null) {
                final latLong = await assetEntity.latlngAsync();
                newFile.location = Location(
                  latitude: latLong.latitude,
                  longitude: latLong.longitude,
                );
              }
            }

            newFile.generatedID =
                await FilesDB.instance.insertAndGetId(newFile);
            Bus.instance
                .fire(LocalPhotosUpdatedEvent([newFile], source: "editSave"));
            SyncService.instance.sync().ignore();
            showShortToast(context, S.of(context).editsSaved);
            _logger.info("Original file " + widget.file.toString());
            _logger.info("Saved edits to file " + newFile.toString());
            final existingFiles = widget.detailPageConfig.files;
            final files = (await widget.detailPageConfig.asyncLoader!(
              existingFiles[existingFiles.length - 1].creationTime!,
              existingFiles[0].creationTime!,
            ))
                .files;
            // the index could be -1 if the files fetched doesn't contain the newly
            // edited files
            int selectionIndex = files
                .indexWhere((file) => file.generatedID == newFile.generatedID);
            if (selectionIndex == -1) {
              files.add(newFile);
              selectionIndex = files.length - 1;
            }
            await dialog.hide();

            replacePage(
              context,
              DetailPage(
                widget.detailPageConfig.copyWith(
                  files: files,
                  selectedIndex: min(selectionIndex, files.length - 1),
                ),
              ),
            );
          } catch (_) {
            await dialog.hide();
          }
        },
      );
    } catch (_) {
      await dialog.hide();
    }
  }
}
