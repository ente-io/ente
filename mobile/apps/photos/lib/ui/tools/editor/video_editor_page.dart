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
  bool _useNativeExport = true;

  @override
  void initState() {
    super.initState();

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
          positionLineColor:
              Theme.of(context).colorScheme.videoPlayerBorderColor,
          lineColor: Theme.of(context)
              .colorScheme
              .videoPlayerBorderColor
              .withValues(alpha: 0.6),
        ),
      );

      _controller!.initialize().then((_) {
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
                                      child: Builder(
                                        builder: (context) {
                                          // For videos with metadata rotation, we need to swap dimensions
                                          final shouldSwap =
                                              _quarterTurnsForRotationCorrection! %
                                                      2 ==
                                                  1;
                                          final width = _controller!
                                              .video.value.size.width;
                                          final height = _controller!
                                              .video.value.size.height;

                                          return RotatedBox(
                                            quarterTurns:
                                                _quarterTurnsForRotationCorrection!,
                                            child: CropGridViewer.preview(
                                              controller: _controller!,
                                              overrideWidth:
                                                  shouldSwap ? height : width,
                                              overrideHeight:
                                                  shouldSwap ? width : height,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.bottomCenter,
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 24),
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
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Native (i)",
                                    style:
                                        getEnteTextTheme(context).mini.copyWith(
                                              color: colorScheme.textMuted,
                                            ),
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
                          VideoEditorMainActions(
                            children: [
                              VideoEditorBottomAction(
                                label: AppLocalizations.of(context).trim,
                                svgPath:
                                    "assets/video-editor/video-editor-trim-action.svg",
                                onPressed: () => _openSubEditor(
                                  VideoTrimPage(
                                    controller: _controller!,
                                    quarterTurnsForRotationCorrection:
                                        _quarterTurnsForRotationCorrection!,
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
                                    quarterTurnsForRotationCorrection:
                                        _quarterTurnsForRotationCorrection!,
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
                                    quarterTurnsForRotationCorrection:
                                        _quarterTurnsForRotationCorrection!,
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
      File result;

      if (flagService.useNativeVideoEditor && _useNativeExport) {
        // Use native export
        final tempDir =
            Directory.systemTemp.createTempSync('ente_video_export');
        final outputPath = path.join(
          tempDir.path,
          'export_${DateTime.now().millisecondsSinceEpoch}.mp4',
        );

        try {
          result = await NativeVideoExportService.exportVideo(
            controller: _controller!,
            outputPath: outputPath,
            metadataRotation: _quarterTurnsForRotationCorrection! * 90,
            onProgress: (progress) {
              if (dialogKey.currentState != null) {
                dialogKey.currentState!.setProgress(progress);
              }
            },
            onError: (e, s) {
              _logger.severe("Error exporting video with native", e, s);
              // Don't handle error here, let it propagate
            },
          );
        } catch (nativeError, _) {
          _logger.warning(
            "Native export failed, attempting FFmpeg fallback",
            nativeError,
          );

          // Show toast for internal users
          if (flagService.internalUser && mounted) {
            showShortToast(context, "(i) Switching to FFmpeg fallback");
          }

          // Reset progress for FFmpeg
          if (dialogKey.currentState != null) {
            dialogKey.currentState!.setProgress(0.0);
          }

          // Fallback to FFmpeg
          try {
            result = await ExportService.exportVideo(
              controller: _controller!,
              outputPath: outputPath,
              onProgress: (progress) {
                if (dialogKey.currentState != null) {
                  dialogKey.currentState!.setProgress(progress);
                }
              },
              onError: (e, s) {
                _logger.severe("FFmpeg fallback also failed", e, s);
                // Don't handle error here, let it propagate
              },
            );
            _logger.info("FFmpeg fallback succeeded");
          } catch (ffmpegError, _) {
            _logger.severe(
              "Both native and FFmpeg exports failed",
              ffmpegError,
            );
            rethrow; // This will be caught by the outer try-catch
          }
        }
      } else {
        // Use FFmpeg export
        final config = VideoFFmpegVideoEditorConfig(
          _controller!,
          format: VideoExportFormat.mp4,
          commandBuilder: (config, videoPath, outputPath) {
            List<String> filters = config.getExportFilters();

            // For Android with metadata rotation, adjust crop filter
            if (Platform.isAndroid &&
                _quarterTurnsForRotationCorrection != null &&
                _quarterTurnsForRotationCorrection! != 0 &&
                _quarterTurnsForRotationCorrection! % 2 == 1) {
              final metadataRotation = _quarterTurnsForRotationCorrection! * 90;
              _logger.info(
                '[FFmpeg] Android with $metadataRotation° rotation - adjusting crop filter',
              );

              // Find and replace crop filter with corrected values
              filters = _adjustCropFilterForAndroid(filters, metadataRotation);
            }

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

        result = await completer.future;
      }

      // Common post-export handling
      await _handleExportCompletion(result, dialogKey);
    } catch (e, s) {
      _logger.severe("Unexpected error in export process", e, s);
      _isExporting.value = false;

      // Close the progress dialog if it's still showing
      if (dialogKey.currentContext != null && mounted) {
        try {
          Navigator.of(dialogKey.currentContext!, rootNavigator: false).pop();
        } catch (navError) {
          _logger.warning("Failed to close dialog", navError);
        }
      }

      // Show error to user
      if (mounted) {
        showToast(context, AppLocalizations.of(context).oopsCouldNotSaveEdits);
      }
    } finally {
      await PhotoManager.startChangeNotify();
    }
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

        newFile.generatedID = await FilesDB.instance.insertAndGetId(
          newFile,
        );

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

  /// Adjust crop filter for Android with metadata rotation
  /// On Android, RotatedBox shows the video in corrected orientation, but FFmpeg
  /// doesn't know about this, so we need to recalculate crop for 90°/270° rotations
  List<String> _adjustCropFilterForAndroid(
    List<String> filters,
    int metadataRotation,
  ) {
    final adjustedFilters = <String>[];
    final controller = _controller!;
    final videoSize = controller.video.value.size;

    final needsCrop = controller.minCrop != Offset.zero ||
        controller.maxCrop != const Offset(1.0, 1.0);

    if (!needsCrop) {
      return filters; // No crop needed, return original filters
    }

    for (final filter in filters) {
      if (filter.startsWith('crop=')) {
        // Recalculate crop using the same logic as native export
        final metadataQuarterTurns = (metadataRotation / 90).round();

        // For Android: RotatedBox shows corrected orientation, so display dimensions
        // match the visual orientation (no swap needed)
        final displayWidth = videoSize.width;
        final displayHeight = videoSize.height;

        // Get normalized crop coordinates in display space
        double minXNorm = controller.minCrop.dx;
        double minYNorm = controller.minCrop.dy;
        double maxXNorm = controller.maxCrop.dx;
        double maxYNorm = controller.maxCrop.dy;

        // For 90°/270° rotations: swap axes
        // Display X maps to Original Y, Display Y maps to Original X
        if (metadataQuarterTurns % 2 == 1) {
          final tempMinX = minXNorm;
          final tempMaxX = maxXNorm;
          minXNorm = minYNorm;
          maxXNorm = maxYNorm;
          minYNorm = tempMinX;
          maxYNorm = tempMaxX;
        }

        // Apply to original video dimensions
        // After axis swap, X coordinates apply to height, Y coordinates apply to width
        final minX = (minXNorm *
                (metadataQuarterTurns % 2 == 1
                    ? videoSize.height
                    : videoSize.width))
            .round();
        final maxX = (maxXNorm *
                (metadataQuarterTurns % 2 == 1
                    ? videoSize.height
                    : videoSize.width))
            .round();
        final minY = (minYNorm *
                (metadataQuarterTurns % 2 == 1
                    ? videoSize.width
                    : videoSize.height))
            .round();
        final maxY = (maxYNorm *
                (metadataQuarterTurns % 2 == 1
                    ? videoSize.width
                    : videoSize.height))
            .round();

        final w = maxX - minX;
        final h = maxY - minY;

        final newFilter = 'crop=$w:$h:$minX:$minY';
        _logger.info(
          '[FFmpeg] Recalculated crop for Android: $filter -> $newFilter',
        );
        _logger.info('[FFmpeg]   Display: ${displayWidth}x$displayHeight');
        _logger.info(
          '[FFmpeg]   Controller crop: (${controller.minCrop.dx}, ${controller.minCrop.dy}) to (${controller.maxCrop.dx}, ${controller.maxCrop.dy})',
        );
        _logger.info('[FFmpeg]   Final crop: x=$minX, y=$minY, w=$w, h=$h');
        adjustedFilters.add(newFilter);
        continue;
      }
      adjustedFilters.add(filter);
    }

    return adjustedFilters;
  }

  Future<void> _openSubEditor(Widget child) {
    return Navigator.of(context).push(_VideoEditorSubPageRoute(child));
  }

  Future<void> _doRotationCorrectionIfAndroid() async {
    if (Platform.isAndroid) {
      try {
        // Use native method to get video info more efficiently
        final videoInfo =
            await NativeVideoEditor.getVideoInfo(widget.ioFile.path);
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
