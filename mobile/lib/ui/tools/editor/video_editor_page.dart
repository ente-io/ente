import 'dart:io';
import "dart:math";

import 'package:flutter/material.dart';
import "package:flutter_svg/flutter_svg.dart";
import "package:logging/logging.dart";
import 'package:path/path.dart' as path;
import "package:pedantic/pedantic.dart";
import "package:photo_manager/photo_manager.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/db/files_db.dart";
import "package:photos/ente_theme_data.dart";
import "package:photos/events/local_photos_updated_event.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/file/file.dart";
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

  late final VideoEditorController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoEditorController.file(
      widget.ioFile,
      minDuration: const Duration(seconds: 1),
      cropStyle: CropGridStyle(
        selectedBoundariesColor:
            const ColorScheme.dark().videoPlayerPrimaryColor,
      ),
      trimStyle: TrimSliderStyle(
        onTrimmedColor: const ColorScheme.dark().videoPlayerPrimaryColor,
        onTrimmingColor: const ColorScheme.dark().videoPlayerPrimaryColor,
      ),
    );
    _controller.initialize().then((_) => setState(() {})).catchError(
      (error) {
        // handle minumum duration bigger than video duration error
        Navigator.pop(context);
      },
      test: (e) => e is VideoMinDurationError,
    );
  }

  @override
  void dispose() async {
    _exportingProgress.dispose();
    _isExporting.dispose();
    _controller.dispose().ignore();
    ExportService.dispose().ignore();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: _controller.initialized
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
                                    controller: _controller,
                                  ),
                                ),
                              ),
                              VideoEditorPlayerControl(
                                controller: _controller,
                              ),
                              VideoEditorMainActions(
                                children: [
                                  VideoEditorBottomAction(
                                    label: "Trim",
                                    child: SvgPicture.asset(
                                      "assets/video-editor/video-editor-trim-action.svg",
                                    ),
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute<void>(
                                        builder: (context) => VideoTrimPage(
                                          controller: _controller,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 40),
                                  VideoEditorBottomAction(
                                    label: "Crop",
                                    child: SvgPicture.asset(
                                      "assets/video-editor/video-editor-crop-action.svg",
                                    ),
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute<void>(
                                        builder: (context) => VideoCropPage(
                                          controller: _controller,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 40),
                                  VideoEditorBottomAction(
                                    label: "Rotate",
                                    child: SvgPicture.asset(
                                      "assets/video-editor/video-editor-rotate-action.svg",
                                    ),
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute<void>(
                                        builder: (context) => VideoRotatePage(
                                          controller: _controller,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 40),
                              VideoEditorNavigationOptions(
                                secondaryText: "Save copy",
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

    final config = VideoFFmpegVideoEditorConfig(
      _controller,
      format: VideoExportFormat.mp4,
      // commandBuilder: (config, videoPath, outputPath) {
      //   final List<String> filters = config.getExportFilters();
      //   filters.add('hflip'); // add horizontal flip

      //   return '-i $videoPath ${config.filtersCmd(filters)} -preset ultrafast $outputPath';
      // },
    );

    await ExportService.runFFmpegCommand(
      await config.getExecuteConfig(),
      onProgress: (stats) {
        _exportingProgress.value =
            config.getFFmpegProgress(stats.getTime().toInt());
      },
      onError: (e, s) => _logger.severe("Error exporting video", e, s),
      onCompleted: (result) async {
        _isExporting.value = false;
        final dialog = createProgressDialog(context, S.of(context).savingEdits);
        await dialog.show();
        if (!mounted) return;

        final fileName = path.basenameWithoutExtension(widget.file.title!) +
            "_edited_" +
            DateTime.now().microsecondsSinceEpoch.toString() +
            ".mp4";
        //Disabling notifications for assets changing to insert the file into
        //files db before triggering a sync.
        await PhotoManager.stopChangeNotify();
        final AssetEntity? newAsset =
            await (PhotoManager.editor.saveVideo(result, title: fileName));
        result.deleteSync();
        final newFile = await EnteFile.fromAsset(
          widget.file.deviceFolder ?? '',
          newAsset!,
        );

        newFile.generatedID =
            await FilesDB.instance.insertAndGetId(widget.file);
        Bus.instance
            .fire(LocalPhotosUpdatedEvent([newFile], source: "editSave"));
        unawaited(SyncService.instance.sync());
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
        int selectionIndex =
            files.indexWhere((file) => file.generatedID == newFile.generatedID);
        if (selectionIndex == -1) {
          files.add(newFile);
          selectionIndex = files.length - 1;
        }
        replacePage(
          context,
          DetailPage(
            widget.detailPageConfig.copyWith(
              files: files,
              selectedIndex: min(selectionIndex, files.length - 1),
            ),
          ),
        );
        await dialog.hide();
      },
    );
  }
}
