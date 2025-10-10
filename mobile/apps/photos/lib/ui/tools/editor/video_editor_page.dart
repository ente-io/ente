import "dart:async";
import 'dart:io';
import "dart:math";

import 'package:flutter/material.dart';
import "package:logging/logging.dart";
import 'package:native_video_editor/native_video_editor.dart';
import 'package:path/path.dart' as path;
import "package:photo_manager/photo_manager.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/db/files_db.dart";
import "package:photos/ente_theme_data.dart";
import "package:photos/events/local_photos_updated_event.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/location/location.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/sync/sync_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/common/linear_progress_dialog.dart";
import "package:photos/ui/notification/toast.dart";
import "package:photos/ui/tools/editor/export_video_service.dart";
import "package:photos/ui/tools/editor/native_video_export_service.dart";
import 'package:photos/ui/tools/editor/video_crop_page.dart';
import "package:photos/ui/tools/editor/video_crop_util.dart";
import "package:photos/ui/tools/editor/video_editor/video_editor_app_bar.dart";
import "package:photos/ui/tools/editor/video_editor/video_editor_bottom_action.dart";
import "package:photos/ui/tools/editor/video_editor/video_editor_main_actions.dart";
import "package:photos/ui/tools/editor/video_editor/video_editor_player_control.dart";
import "package:photos/ui/tools/editor/video_rotate_page.dart";
import "package:photos/ui/tools/editor/video_trim_page.dart";
import "package:photos/ui/viewer/file/detail_page.dart";
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

  /// Toggle state for internal users to switch between native and FFmpeg export
  /// Initially set to the flag service value
  late bool _useNativeExport;
  bool _dryRunMode = false;

  @override
  void initState() {
    super.initState();

    // Initialize toggle with flagService value
    _useNativeExport = flagService.useNativeVideoEditor;

    // First determine rotation correction for Android
    _doRotationCorrectionIfAndroid().then((_) {
      // Then initialize the controller
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
          positionLineColor: Theme.of(
            context,
          ).colorScheme.videoPlayerBorderColor,
          lineColor: Theme.of(
            context,
          ).colorScheme.videoPlayerBorderColor.withValues(alpha: 0.6),
        ),
      );

      _controller!.initialize().then((_) {
        // Apply metadata rotation to the video player
        if (_quarterTurnsForRotationCorrection != null &&
            _quarterTurnsForRotationCorrection! != 0) {
          final rotationDegrees = _quarterTurnsForRotationCorrection! * 90;
          _controller!.video.value = _controller!.video.value.copyWith(
            rotationCorrection: rotationDegrees,
          );
          _logger.fine(
            'Applied rotation correction: $rotationDegrees degrees to video player',
          );
        }
        setState(() {});
      }).catchError(
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
    _isExporting.dispose();
    _controller?.dispose().ignore();
    ExportService.dispose().ignore();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_isExporting.value) {
          return;
        }
        replacePage(context, DetailPage(widget.detailPageConfig));
      },
      child: ValueListenableBuilder<bool>(
        valueListenable: _isExporting,
        builder: (context, isExporting, _) {
          final isReady = _controller != null &&
              _controller!.initialized &&
              _quarterTurnsForRotationCorrection != null;

          return Scaffold(
            backgroundColor: colorScheme.backgroundBase,
            appBar: VideoEditorAppBar(
              onCancel: () {
                if (isExporting) return;
                replacePage(context, DetailPage(widget.detailPageConfig));
              },
              primaryActionLabel: AppLocalizations.of(context).saveCopy,
              onPrimaryAction: exportVideo,
              isPrimaryEnabled: isReady && !isExporting,
            ),
            body: isReady
                ? SafeArea(
                    top: false,
                    bottom: true,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Positioned.fill(
                                    child: Hero(
                                      tag: "video-editor-preview",
                                      child: CropGridViewer.preview(
                                        controller: _controller!,
                                      ),
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.bottomCenter,
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 24,
                                      ),
                                      child: VideoEditorPlayerControl(
                                        controller: _controller!,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (flagService.internalUser)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Native (i)",
                                    style: getEnteTextTheme(context)
                                        .mini
                                        .copyWith(color: colorScheme.textMuted),
                                  ),
                                  const SizedBox(width: 4),
                                  Transform.scale(
                                    scale: 0.8,
                                    child: Switch(
                                      value: _useNativeExport,
                                      onChanged: (value) {
                                        setState(() {
                                          _useNativeExport = value;
                                        });
                                      },
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (flagService.internalUser)
                            const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _dryRunMode = !_dryRunMode;
                                      });
                                    },
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Dry run (debug)',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium,
                                        ),
                                        Transform.scale(
                                          scale: 0.8,
                                          child: Switch(
                                            value: _dryRunMode,
                                            onChanged: (value) {
                                              setState(() {
                                                _dryRunMode = value;
                                              });
                                            },
                                            materialTapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          VideoEditorMainActions(
                            children: [
                              VideoEditorBottomAction(
                                label: AppLocalizations.of(context).trim,
                                svgPath:
                                    "assets/video-editor/video-editor-trim-action.svg",
                                onPressed: () => _openSubEditor(
                                  VideoTrimPage(
                                    controller: _controller!,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 24),
                              VideoEditorBottomAction(
                                label: AppLocalizations.of(context).crop,
                                svgPath:
                                    "assets/video-editor/video-editor-crop-action.svg",
                                onPressed: () => _openSubEditor(
                                  VideoCropPage(
                                    controller: _controller!,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 24),
                              VideoEditorBottomAction(
                                label: AppLocalizations.of(context).rotate,
                                svgPath:
                                    "assets/video-editor/video-editor-rotate-action.svg",
                                onPressed: () => _openSubEditor(
                                  VideoRotatePage(
                                    controller: _controller!,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  )
                : const Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }

  void exportVideo() async {
    final shouldUseNative = flagService.internalUser
        ? _useNativeExport
        : flagService.useNativeVideoEditor;

    // Always log dry run info for debugging, regardless of toggle
    final debugInfo = await NativeVideoExportService.buildDebugSummary(
      controller: _controller!,
    );
    _logger.info(
      'DRY_RUN pipeline=${shouldUseNative ? "native" : "ffmpeg"} videoSize=${debugInfo.videoSize.width.toInt()}x${debugInfo.videoSize.height.toInt()} trimStart=${debugInfo.trimStart} trimEnd=${debugInfo.trimEnd} nativeRotate=${debugInfo.nativeRotateDegrees ?? 0} nativeDisplayCrop=${_formatRect(debugInfo.nativeDisplayCrop)} nativeFileCrop=${_formatCrop(debugInfo.nativeFileCrop)} nativeOutputSize=${_formatSize(debugInfo.nativeOutputSize)} ffmpegFileCrop=${_formatCrop(debugInfo.ffmpegFileCrop)} ffmpegCropFilter=${debugInfo.ffmpegCropFilter ?? "-"}',
    );

    if (_dryRunMode) {
      await _showDryRunDialog(debugInfo, shouldUseNative);
      return;
    }

    _isExporting.value = true;

    final dialogKey = GlobalKey<LinearProgressDialogState>();
    final dialog = LinearProgressDialog(
      AppLocalizations.of(context).savingEdits,
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

    try {
      final result = await _performExport(
        shouldUseNative: shouldUseNative,
        dialogKey: dialogKey,
      );
      await _handleExportCompletion(result, dialogKey);
    } catch (e, s) {
      _logger.severe("Unexpected error in export process", e, s);
      _isExporting.value = false;

      if (dialogKey.currentState != null && dialogKey.currentState!.mounted) {
        Navigator.of(dialogKey.currentContext!).pop();
      }

      showShortToast(context, AppLocalizations.of(context).somethingWentWrong);
    }
  }

  Future<File> _performExport({
    required bool shouldUseNative,
    required GlobalKey<LinearProgressDialogState> dialogKey,
  }) async {
    if (shouldUseNative) {
      final tempDir = Directory.systemTemp.createTempSync(
        'ente_video_export',
      );
      final outputPath = path.join(
        tempDir.path,
        'export_${DateTime.now().millisecondsSinceEpoch}.mp4',
      );

      try {
        return await NativeVideoExportService.exportVideo(
          controller: _controller!,
          outputPath: outputPath,
          onProgress: (progress) {
            if (dialogKey.currentState != null) {
              dialogKey.currentState!.setProgress(progress);
            }
          },
          onError: (e, s) {
            _logger.severe("Error exporting video with native", e, s);
          },
        );
      } catch (nativeError, _) {
        _logger.warning(
          "Native export failed, attempting FFmpeg fallback",
          nativeError,
        );

        if (flagService.internalUser && mounted) {
          showShortToast(context, "(i) Switching to FFmpeg fallback");
        }

        if (dialogKey.currentState != null) {
          dialogKey.currentState!.setProgress(0.0);
        }

        return await _runFfmpegExport(
          dialogKey: dialogKey,
        );
      }
    }

    return await _runFfmpegExport(
      dialogKey: dialogKey,
    );
  }

  Future<File> _runFfmpegExport({
    required GlobalKey<LinearProgressDialogState> dialogKey,
  }) async {
    final config = VideoFFmpegVideoEditorConfig(
      _controller!,
      format: VideoExportFormat.mp4,
      commandBuilder: (config, videoPath, outputPath) {
        final List<String> filters = config.getExportFilters();

        final String startTrimCmd = "-ss ${_controller!.startTrim}";
        final String toTrimCmd = "-t ${_controller!.trimmedDuration}";
        final command =
            '$startTrimCmd -i $videoPath  $toTrimCmd ${config.filtersCmd(filters)} -c:v libx264 -c:a aac $outputPath';
        return command;
      },
    );

    final executeConfig = await config.getExecuteConfig();
    final completer = Completer<File>();

    await ExportService.runFFmpegCommand(
      executeConfig,
      onProgress: (stats) {
        final progress = config.getFFmpegProgress(stats.getTime().toInt());
        if (dialogKey.currentState != null) {
          dialogKey.currentState!.setProgress(progress);
        }
      },
      onError: (e, s) {
        _logger.severe("Error exporting video with FFmpeg", e, s);
        if (!completer.isCompleted) {
          completer.completeError(e, s);
        }
      },
      onCompleted: (file) {
        if (!completer.isCompleted) {
          completer.complete(file);
        }
      },
    );

    return completer.future;
  }

  Future<void> _showDryRunDialog(
    DebugExportSummary info,
    bool shouldUseNative,
  ) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Dry Run (Debug)'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  shouldUseNative
                      ? 'Native pipeline will be used'
                      : 'FFmpeg pipeline will be used (native disabled)',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  'Native export',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'Video size: ${info.videoSize.width.toInt()} x ${info.videoSize.height.toInt()}',
                ),
                Text('Trim: ${info.trimStart ?? "-"} → ${info.trimEnd ?? "-"}'),
                Text('Rotate degrees: ${info.nativeRotateDegrees ?? 0}'),
                Text('Display crop: ${_formatRect(info.nativeDisplayCrop)}'),
                Text('File crop: ${_formatCrop(info.nativeFileCrop)}'),
                Text(
                  'Output dimensions: ${_formatSize(info.nativeOutputSize)}',
                ),
                const SizedBox(height: 12),
                Text(
                  'FFmpeg fallback',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text('File crop: ${_formatCrop(info.ffmpegFileCrop)}'),
                Text('Crop filter: ${info.ffmpegCropFilter ?? '-'}'),
                if (info.ffmpegCommand != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Command:',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  SelectableText(
                    info.ffmpegCommand!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                        ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  String _formatRect(Rect? rect) {
    if (rect == null) return '-';
    return '(${rect.left.toStringAsFixed(1)}, ${rect.top.toStringAsFixed(1)}) → '
        '(${rect.right.toStringAsFixed(1)}, ${rect.bottom.toStringAsFixed(1)}) '
        '[${rect.width.toStringAsFixed(1)} x ${rect.height.toStringAsFixed(1)}]';
  }

  String _formatCrop(CropCalculation? crop) {
    if (crop == null) return '-';
    return 'x=${crop.x}, y=${crop.y}, w=${crop.width}, h=${crop.height}';
  }

  String _formatSize(Size? size) {
    if (size == null) return '-';
    return '${size.width.toStringAsFixed(1)} x ${size.height.toStringAsFixed(1)}';
  }

  Future<void> _handleExportCompletion(
    File result,
    GlobalKey<LinearProgressDialogState> dialogKey,
  ) async {
    try {
      _isExporting.value = false;
      if (!mounted) {
        return;
      }

      final fileName = path.basenameWithoutExtension(widget.file.title!) +
          "_edited_" +
          DateTime.now().microsecondsSinceEpoch.toString() +
          ".mp4";

      //Disabling notifications for assets changing to insert the file into
      //files db before triggering a sync.
      await PhotoManager.stopChangeNotify();

      try {
        final AssetEntity newAsset = await (PhotoManager.editor.saveVideo(
          result,
          title: fileName,
        ));

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

        newFile.generatedID = await FilesDB.instance.insertAndGetId(newFile);

        Bus.instance.fire(
          LocalPhotosUpdatedEvent([newFile], source: "editSave"),
        );

        SyncService.instance.sync().ignore();

        showShortToast(context, AppLocalizations.of(context).editsSaved);
        final files = widget.detailPageConfig.files;

        // the index could be -1 if the files fetched doesn't contain the newly
        // edited files
        int selectionIndex = files.indexWhere(
          (file) => file.generatedID == newFile.generatedID,
        );
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
      } catch (e, s) {
        _logger.severe("Error in post-processing", e, s);
        Navigator.of(dialogKey.currentContext!).pop('dialog');
      }
    } finally {
      await PhotoManager.startChangeNotify();
    }
  }

  Future<void> _openSubEditor(Widget child) {
    return Navigator.of(context).push(_VideoEditorSubPageRoute(child));
  }

  Future<void> _doRotationCorrectionIfAndroid() async {
    if (Platform.isAndroid) {
      try {
        // Use native method to get video info more efficiently
        final videoInfo = await NativeVideoEditor.getVideoInfo(
          widget.ioFile.path,
        );
        final rotation = videoInfo['rotation'] as int? ?? 0;
        final width = videoInfo['width'] as int? ?? 0;
        final height = videoInfo['height'] as int? ?? 0;

        _logger.fine('Video info: ${width}x$height, rotation=$rotation');

        if (rotation != 0) {
          _quarterTurnsForRotationCorrection = (rotation / 90).round();
          _logger.fine(
            'Applying rotation correction: $rotation° → $_quarterTurnsForRotationCorrection quarter turns',
          );
        } else {
          _quarterTurnsForRotationCorrection = 0;
        }
        setState(() {});
      } catch (e) {
        _logger.warning('Failed to get video info, using fallback', e);
        _quarterTurnsForRotationCorrection = 0;
        setState(() {});
      }
    } else {
      _quarterTurnsForRotationCorrection = 0;
      setState(() {});
    }
  }
}

class _VideoEditorSubPageRoute extends PageRouteBuilder<void> {
  _VideoEditorSubPageRoute(this.child)
      : super(
          fullscreenDialog: true,
          transitionDuration: const Duration(milliseconds: 220),
          reverseTransitionDuration: const Duration(milliseconds: 180),
          pageBuilder: (_, __, ___) => child,
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
                reverseCurve: Curves.easeInCubic,
              ),
              child: child,
            );
          },
        );

  final Widget child;
}
