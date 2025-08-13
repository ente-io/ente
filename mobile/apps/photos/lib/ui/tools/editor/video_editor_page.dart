import "dart:async";
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
import "package:photos/services/sync/sync_service.dart";
import "package:photos/ui/common/linear_progress_dialog.dart";
import "package:photos/ui/notification/toast.dart";
import "package:photos/ui/tools/editor/export_video_service.dart";
import 'package:photos/ui/tools/editor/video_crop_page.dart';
import "package:photos/ui/tools/editor/video_editor/video_editor_bottom_action.dart";
import "package:photos/ui/tools/editor/video_editor/video_editor_main_actions.dart";
import "package:photos/ui/tools/editor/video_editor/video_editor_navigation_options.dart";
import "package:photos/ui/tools/editor/video_editor/video_editor_player_control.dart";
import "package:photos/ui/tools/editor/video_rotate_page.dart";
import "package:photos/ui/tools/editor/video_trim_page.dart";
import "package:photos/ui/viewer/file/detail_page.dart";
import "package:photos/utils/exif_util.dart";
import "package:photos/utils/navigation_util.dart";
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
  final _isExporting = ValueNotifier<bool>(false);
  final _logger = Logger("VideoEditor");

  /// Some videos have a non-zero 'rotation' property in exif which causes the
  /// video to appear rotated in the video editor preview on Andoird.
  /// This variable is used as a workaround to rotate the video back to its
  /// expected orientation in the viewer.
  int? _quarterTurnsForRotationCorrection;

  VideoEditorController? _controller;

  @override
  void initState() {
    _logger.info("Initializing video editor page");
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
          background: Theme.of(context).colorScheme.editorBackgroundColor,
          positionLineColor:
              Theme.of(context).colorScheme.videoPlayerBorderColor,
          lineColor: Theme.of(context)
              .colorScheme
              .videoPlayerBorderColor
              .withValues(alpha: 0.6),
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

    _doRotationCorrectionIfAndroid();
  }

  @override
  void dispose() async {
    _isExporting.dispose();
    _controller?.dispose().ignore();
    ExportService.dispose().ignore();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _logger.info("Building video editor page");
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          if (_isExporting.value) {
            return;
          } else {
            replacePage(context, DetailPage(widget.detailPageConfig));
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          toolbarHeight: 0,
        ),
        body: _controller != null &&
                _controller!.initialized &&
                _quarterTurnsForRotationCorrection != null
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
                                  child: RotatedBox(
                                    quarterTurns:
                                        _quarterTurnsForRotationCorrection!,
                                    child: CropGridViewer.preview(
                                      controller: _controller!,
                                    ),
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
                                          quarterTurnsForRotationCorrection:
                                              _quarterTurnsForRotationCorrection!,
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
                                          quarterTurnsForRotationCorrection:
                                              _quarterTurnsForRotationCorrection!,
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
                                          quarterTurnsForRotationCorrection:
                                              _quarterTurnsForRotationCorrection!,
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
    _isExporting.value = true;

    final dialogKey = GlobalKey<LinearProgressDialogState>();
    final dialog = LinearProgressDialog(
      S.of(context).savingEdits,
      key: dialogKey,
    );

    unawaited(
      showDialog(
        useRootNavigator: false,
        context: context,
        builder: (context) {
          return dialog;
        },
      ),
    );

    final config = VideoFFmpegVideoEditorConfig(
      _controller!,
      format: VideoExportFormat.mp4,
      commandBuilder: (config, videoPath, outputPath) {
        final List<String> filters = config.getExportFilters();

        final String startTrimCmd = "-ss ${_controller!.startTrim}";
        final String toTrimCmd = "-t ${_controller!.trimmedDuration}";
        return '$startTrimCmd -i $videoPath  $toTrimCmd ${config.filtersCmd(filters)} -c:v libx264 -c:a aac $outputPath';
      },
    );

    try {
      await ExportService.runFFmpegCommand(
        await config.getExecuteConfig(),
        onProgress: (stats) {
          if (dialogKey.currentState != null) {
            dialogKey.currentState!
                .setProgress(config.getFFmpegProgress(stats.getTime().toInt()));
          }
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
            final AssetEntity newAsset =
                await (PhotoManager.editor.saveVideo(result, title: fileName));
            result.deleteSync();
            final newFile = await EnteFile.fromAsset(
              widget.file.deviceFolder ?? '',
              newAsset,
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
            final files = widget.detailPageConfig.files;

            // the index could be -1 if the files fetched doesn't contain the newly
            // edited files
            int selectionIndex = files
                .indexWhere((file) => file.generatedID == newFile.generatedID);
            if (selectionIndex == -1) {
              files.add(newFile);
              selectionIndex = files.length - 1;
            }
            Navigator.of(dialogKey.currentContext!).pop('dialog');

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
            Navigator.of(dialogKey.currentContext!).pop('dialog');
          }
        },
      );
    } catch (_) {
      Navigator.of(dialogKey.currentContext!).pop('dialog');
    } finally {
      await PhotoManager.startChangeNotify();
    }
  }

  void _doRotationCorrectionIfAndroid() {
    if (Platform.isAndroid) {
      getVideoPropsAsync(widget.ioFile).then((props) async {
        if (props?.rotation != null) {
          _quarterTurnsForRotationCorrection = -(props!.rotation! / 90).round();
        } else {
          _quarterTurnsForRotationCorrection = 0;
        }
        setState(() {});
      });
    } else {
      _quarterTurnsForRotationCorrection = 0;
    }
  }
}
