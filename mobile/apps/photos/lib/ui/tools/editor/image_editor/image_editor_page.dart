import "dart:async";
import "dart:io";
import "dart:math";
import "dart:ui" as ui;

import "package:ente_pure_utils/ente_pure_utils.dart";
import 'package:flutter/material.dart';
import "package:flutter/services.dart";
import "package:flutter_svg/svg.dart";
import "package:logging/logging.dart";
import 'package:path/path.dart' as path;
import "package:photo_manager/photo_manager.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/db/files_db.dart";
import "package:photos/ente_theme_data.dart";
import "package:photos/events/local_photos_updated_event.dart";
import "package:photos/generated/l10n.dart";
import 'package:photos/models/file/file.dart' as ente;
import "package:photos/models/location/location.dart";
import "package:photos/services/sync/sync_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/action_sheet_widget.dart";
import "package:photos/ui/components/buttons/button_widget.dart";
import "package:photos/ui/components/models/button_type.dart";
import "package:photos/ui/notification/toast.dart";
import "package:photos/ui/tools/editor/image_editor/image_editor_app_bar.dart";
import "package:photos/ui/tools/editor/image_editor/image_editor_constants.dart";
import "package:photos/ui/tools/editor/image_editor/image_editor_crop_rotate.dart";
import "package:photos/ui/tools/editor/image_editor/image_editor_filter_bar.dart";
import "package:photos/ui/tools/editor/image_editor/image_editor_main_bottom_bar.dart";
import "package:photos/ui/tools/editor/image_editor/image_editor_paint_bar.dart";
import "package:photos/ui/tools/editor/image_editor/image_editor_text_bar.dart";
import "package:photos/ui/tools/editor/image_editor/image_editor_tune_bar.dart";
import "package:photos/ui/viewer/file/detail_page.dart";
import "package:photos/utils/dialog_util.dart";
import 'package:pro_image_editor/pro_image_editor.dart';

class ImageEditorPage extends StatefulWidget {
  final ente.EnteFile originalFile;
  final File file;
  final DetailPageConfiguration detailPageConfig;

  const ImageEditorPage({
    super.key,
    required this.file,
    required this.originalFile,
    required this.detailPageConfig,
  });

  @override
  State<ImageEditorPage> createState() => _ImageEditorPageState();
}

class _ImageEditorPageState extends State<ImageEditorPage> {
  final _mainEditorBarKey = GlobalKey<ImageEditorMainBottomBarState>();
  final editorKey = GlobalKey<ProImageEditorState>();
  final _logger = Logger("ImageEditor");
  Color? _jpegBackgroundColor;
  bool _isExitFlowInProgress = false;

  @override
  void initState() {
    super.initState();
    unawaited(_initJpegBackgroundColor());
  }

  Future<void> _initJpegBackgroundColor() async {
    try {
      final assetEntity = await widget.originalFile.getAsset;
      final Uint8List? thumbBytes = await assetEntity?.thumbnailDataWithSize(
        const ThumbnailSize(64, 64),
        quality: 60,
        format: ThumbnailFormat.jpeg,
      );
      if (thumbBytes == null) return;

      final color = await _averageBottomEdgeColor(thumbBytes);
      if (!mounted || color == null) return;
      setState(() {
        _jpegBackgroundColor = color;
      });
    } catch (e, s) {
      _logger.warning("Failed to sample JPEG matte color", e, s);
    }
  }

  Future<Color?> _averageBottomEdgeColor(Uint8List bytes) async {
    ui.Codec? codec;
    ui.Image? image;
    try {
      codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: 64,
        targetHeight: 64,
      );
      final frame = await codec.getNextFrame();
      image = frame.image;
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) return null;

      final width = image.width;
      final height = image.height;
      if (width <= 0 || height <= 0) return null;

      final yStart = max(0, height - 2);
      int count = 0;
      int sumR = 0;
      int sumG = 0;
      int sumB = 0;

      for (int y = yStart; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final i = (y * width + x) * 4;
          sumR += byteData.getUint8(i);
          sumG += byteData.getUint8(i + 1);
          sumB += byteData.getUint8(i + 2);
          count++;
        }
      }
      if (count == 0) return null;

      return Color.fromARGB(
        255,
        (sumR / count).round().clamp(0, 255),
        (sumG / count).round().clamp(0, 255),
        (sumB / count).round().clamp(0, 255),
      );
    } finally {
      image?.dispose();
      codec?.dispose();
    }
  }

  String _buildEditedFileName() {
    final originalTitle = widget.originalFile.title?.trim();
    final baseName = (originalTitle == null || originalTitle.isEmpty)
        ? "ente_photo"
        : path.basenameWithoutExtension(originalTitle);

    final sanitizedBaseName =
        baseName.replaceAll(RegExp(r'[\\/:*?"<>|]'), "_").trim();

    final safeBaseName =
        sanitizedBaseName.isEmpty ? "ente_photo" : sanitizedBaseName;

    return "${safeBaseName}_edited_${DateTime.now().microsecondsSinceEpoch}.jpg";
  }

  Future<void> saveImage(Uint8List? bytes) async {
    if (bytes == null || bytes.isEmpty) return;
    if (!mounted) return;

    final dialog =
        createProgressDialog(context, AppLocalizations.of(context).saving);
    await dialog.show();

    _logger.info("Image saved with size: ${bytes.length} bytes");
    final DateTime start = DateTime.now();

    final bytesToSave = bytes;

    final Duration diff = DateTime.now().difference(start);
    _logger.info('image_editor time : $diff');

    if (!mounted) {
      await dialog.hide();
      return;
    }

    try {
      final fileName = _buildEditedFileName();
      //Disabling notifications for assets changing to insert the file into
      //files db before triggering a sync.
      await PhotoManager.stopChangeNotify();
      final AssetEntity newAsset = await (PhotoManager.editor
          .saveImage(bytesToSave, filename: fileName));
      final newFile = await ente.EnteFile.fromAsset(
        widget.originalFile.deviceFolder ?? '',
        newAsset,
      );

      newFile.creationTime = widget.originalFile.creationTime;
      newFile.collectionID = widget.originalFile.collectionID;
      newFile.location = widget.originalFile.location;
      if (!newFile.hasLocation && widget.originalFile.localID != null) {
        final assetEntity = await widget.originalFile.getAsset;
        if (assetEntity != null) {
          final latLong = await assetEntity.latlngAsync();
          newFile.location = Location(
            latitude: latLong.latitude,
            longitude: latLong.longitude,
          );
        }
      }
      newFile.generatedID = await FilesDB.instance.insertAndGetId(newFile);
      Bus.instance.fire(LocalPhotosUpdatedEvent([newFile], source: "editSave"));
      unawaited(SyncService.instance.sync());
      if (mounted) {
        showShortToast(context, AppLocalizations.of(context).editsSaved);
      }
      _logger.info("Original file ${widget.originalFile}");
      _logger.info("Saved edits to file $newFile");
      final files = widget.detailPageConfig.files;

      // the index could be -1 if the files fetched doesn't contain the newly
      // edited files
      int selectionIndex =
          files.indexWhere((file) => file.generatedID == newFile.generatedID);
      if (selectionIndex == -1) {
        files.add(newFile);
        selectionIndex = files.length - 1;
      }
      await dialog.hide();
      if (!mounted) return;
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
      await dialog.hide();
      if (mounted) {
        showToast(context, AppLocalizations.of(context).oopsCouldNotSaveEdits);
      }
      _logger.severe(e, s);
    } finally {
      await PhotoManager.startChangeNotify();
    }
  }

  Future<void> _showExitConfirmationDialog(BuildContext context) async {
    if (_isExitFlowInProgress) return;
    _isExitFlowInProgress = true;
    editorKey.currentState?.isPopScopeDisabled = true;

    try {
      // If there are no edits, avoid showing a discard confirmation.
      if (editorKey.currentState?.canUndo != true) {
        if (mounted) {
          replacePage(context, DetailPage(widget.detailPageConfig));
        }
        return;
      }

      final actionResult = await showActionSheet(
        context: context,
        buttons: [
          ButtonWidget(
            labelText: AppLocalizations.of(context).yesDiscardChanges,
            buttonType: ButtonType.critical,
            buttonSize: ButtonSize.large,
            shouldStickToDarkTheme: true,
            buttonAction: ButtonAction.first,
            isInAlert: true,
          ),
          ButtonWidget(
            labelText: AppLocalizations.of(context).no,
            buttonType: ButtonType.secondary,
            buttonSize: ButtonSize.large,
            buttonAction: ButtonAction.second,
            shouldStickToDarkTheme: true,
            isInAlert: true,
          ),
        ],
        body:
            AppLocalizations.of(context).doYouWantToDiscardTheEditsYouHaveMade,
        actionSheetType: ActionSheetType.defaultActionSheet,
      );
      if (actionResult?.action != null &&
          actionResult!.action == ButtonAction.first) {
        replacePage(context, DetailPage(widget.detailPageConfig));
      }
    } finally {
      editorKey.currentState?.isPopScopeDisabled = false;
      _isExitFlowInProgress = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLightMode = Theme.of(context).brightness == Brightness.light;
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _showExitConfirmationDialog(context);
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        resizeToAvoidBottomInset: false,
        backgroundColor: colorScheme.backgroundBase,
        body: ProImageEditor.file(
          key: editorKey,
          widget.file,
          callbacks: ProImageEditorCallbacks(
            onCloseEditor: (_) {
              _showExitConfirmationDialog(context);
            },
            mainEditorCallbacks: MainEditorCallbacks(
              onStartCloseSubEditor: (value) {
                _mainEditorBarKey.currentState?.setState(() {});
              },
              onPopInvoked: (didPop, result) {
                editorKey.currentState?.isPopScopeDisabled = false;
              },
            ),
          ),
          configs: ProImageEditorConfigs(
            imageGeneration: ImageGenerationConfigs(
              outputFormat: OutputFormat.jpg,
              enableIsolateGeneration: true,
              jpegBackgroundColor:
                  (_jpegBackgroundColor ?? colorScheme.backgroundBase)
                      .withValues(alpha: 1),
              jpegQuality: 100,
            ),
            layerInteraction: const LayerInteractionConfigs(
              hideToolbarOnInteraction: false,
            ),
            theme: ThemeData(
              scaffoldBackgroundColor: colorScheme.backgroundBase,
              appBarTheme: AppBarTheme(
                titleTextStyle: textTheme.body,
                backgroundColor: colorScheme.backgroundBase,
              ),
              bottomAppBarTheme: BottomAppBarTheme(
                color: colorScheme.backgroundBase,
              ),
              brightness: isLightMode ? Brightness.light : Brightness.dark,
            ),
            mainEditor: MainEditorConfigs(
              enableZoom: true,
              style: MainEditorStyle(
                uiOverlayStyle: SystemUiOverlayStyle(
                  systemNavigationBarContrastEnforced: true,
                  systemNavigationBarColor: Colors.transparent,
                  statusBarBrightness:
                      isLightMode ? Brightness.dark : Brightness.light,
                  statusBarIconBrightness:
                      isLightMode ? Brightness.dark : Brightness.light,
                ),
                appBarBackground: colorScheme.backgroundBase,
                background: colorScheme.backgroundBase,
                bottomBarBackground: colorScheme.backgroundBase,
              ),
              widgets: MainEditorWidgets(
                removeLayerArea: (
                  removeAreaKey,
                  __,
                  rebuildStream,
                  isLayerBeingTransformed,
                ) {
                  return Align(
                    alignment: Alignment.bottomCenter,
                    child: StreamBuilder(
                      stream: rebuildStream,
                      builder: (context, snapshot) {
                        final isHovered = editorKey.currentState!
                            .layerInteractionManager.hoverRemoveBtn;

                        return AnimatedSwitcher(
                          duration: const Duration(milliseconds: 150),
                          child: isLayerBeingTransformed
                              ? Container(
                                  key: removeAreaKey,
                                  height: 56,
                                  width: 56,
                                  margin: const EdgeInsets.only(bottom: 24),
                                  decoration: BoxDecoration(
                                    color: isHovered
                                        ? colorScheme.warning400
                                            .withValues(alpha: 0.8)
                                        : Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  child: Center(
                                    child: SvgPicture.asset(
                                      "assets/image-editor/image-editor-delete.svg",
                                      colorFilter: ColorFilter.mode(
                                        isHovered
                                            ? Colors.white
                                            : colorScheme.warning400
                                                .withValues(alpha: 0.8),
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                  ),
                                )
                              : SizedBox.shrink(
                                  // When hidden, key still needed for hit
                                  // detection to work (returns empty bounds)
                                  key: removeAreaKey,
                                ),
                        );
                      },
                    ),
                  );
                },
                appBar: (editor, rebuildStream) {
                  return ReactiveAppbar(
                    builder: (context) {
                      return ImageEditorAppBar(
                        enableRedo: editor.canRedo,
                        enableUndo: editor.canUndo,
                        key: const Key('image_editor_app_bar'),
                        redo: () => editor.redoAction(),
                        undo: () => editor.undoAction(),
                        configs: editor.configs,
                        done: () async {
                          final Uint8List bytes = await editorKey.currentState!
                              .captureEditorImage();
                          await saveImage(bytes);
                        },
                        close: () {
                          _showExitConfirmationDialog(context);
                        },
                        isMainEditor: true,
                      );
                    },
                    stream: rebuildStream,
                  );
                },
                bottomBar: (editor, rebuildStream, key) => ReactiveWidget(
                  key: key,
                  builder: (context) {
                    return ImageEditorMainBottomBar(
                      key: _mainEditorBarKey,
                      editor: editor,
                      configs: editor.configs,
                      callbacks: editor.callbacks,
                    );
                  },
                  stream: rebuildStream,
                ),
              ),
            ),
            paintEditor: PaintEditorConfigs(
              enabled: true,
              style: PaintEditorStyle(
                initialColor: const Color(0xFF00FFFF),
                background: colorScheme.backgroundBase,
              ),
              widgets: PaintEditorWidgets(
                appBar: (editor, rebuildStream) {
                  return ReactiveAppbar(
                    builder: (context) {
                      return ImageEditorAppBar(
                        enableRedo: editor.canRedo,
                        enableUndo: editor.canUndo,
                        key: const Key('image_editor_app_bar'),
                        redo: () => editor.redoAction(),
                        undo: () => editor.undoAction(),
                        configs: editor.configs,
                        done: () => editor.done(),
                        close: () => editor.close(),
                      );
                    },
                    stream: rebuildStream,
                  );
                },
                colorPicker:
                    (paintEditor, rebuildStream, currentColor, setColor) =>
                        null,
                bottomBar: (editorState, rebuildStream) {
                  return ReactiveWidget(
                    builder: (context) {
                      return ImageEditorPaintBar(
                        configs: editorState.configs,
                        callbacks: editorState.callbacks,
                        editor: editorState,
                        i18nColor: 'Color',
                      );
                    },
                    stream: rebuildStream,
                  );
                },
              ),
            ),
            textEditor: TextEditorConfigs(
              enabled: false,
              showBackgroundModeButton: true,
              showTextAlignButton: true,
              style: const TextEditorStyle(
                background: Colors.transparent,
                textFieldMargin: EdgeInsets.only(top: kToolbarHeight),
              ),
              widgets: TextEditorWidgets(
                appBar: (textEditor, rebuildStream) => ReactiveAppbar(
                  builder: (context) {
                    return ImageEditorAppBar(
                      key: const Key('image_editor_app_bar'),
                      configs: textEditor.configs,
                      done: () => textEditor.done(),
                      close: () => textEditor.close(),
                    );
                  },
                  stream: rebuildStream,
                ),
                bodyItems: (editor, rebuildStream) {
                  return [
                    ReactiveWidget(
                      builder: (context) {
                        return Positioned.fill(
                          child: GestureDetector(
                            onTap: () {},
                            child: Container(
                              color: Colors.transparent,
                            ),
                          ),
                        );
                      },
                      stream: rebuildStream,
                    ),
                  ];
                },
                colorPicker:
                    (textEditor, rebuildStream, currentColor, setColor) => null,
                bottomBar: (editorState, rebuildStream) {
                  return ReactiveWidget(
                    builder: (context) {
                      return ImageEditorTextBar(
                        configs: editorState.configs,
                        callbacks: editorState.callbacks,
                        editor: editorState,
                      );
                    },
                    stream: rebuildStream,
                  );
                },
              ),
            ),
            cropRotateEditor: CropRotateEditorConfigs(
              showAspectRatioButton: true,
              showFlipButton: true,
              showRotateButton: true,
              enabled: true,
              style: CropRotateEditorStyle(
                background: colorScheme.backgroundBase,
                cropCornerColor:
                    Theme.of(context).colorScheme.imageEditorPrimaryColor,
              ),
              widgets: CropRotateEditorWidgets(
                appBar: (editor, rebuildStream) {
                  return ReactiveAppbar(
                    builder: (context) {
                      return ImageEditorAppBar(
                        key: const Key('image_editor_app_bar'),
                        configs: editor.configs,
                        done: () => editor.done(),
                        close: () => editor.close(),
                        enableRedo: editor.canRedo,
                        enableUndo: editor.canUndo,
                        redo: () => editor.redoAction(),
                        undo: () => editor.undoAction(),
                      );
                    },
                    stream: rebuildStream,
                  );
                },
                bottomBar: (cropRotateEditor, rebuildStream) => ReactiveWidget(
                  stream: rebuildStream,
                  builder: (_) => ImageEditorCropRotateBar(
                    configs: cropRotateEditor.configs,
                    callbacks: cropRotateEditor.callbacks,
                    editor: cropRotateEditor,
                  ),
                ),
              ),
            ),
            filterEditor: FilterEditorConfigs(
              enabled: true,
              fadeInUpDuration: fadeInDuration,
              fadeInUpStaggerDelayDuration: fadeInDelay,
              filterList: filterList,
              style: FilterEditorStyle(
                background: colorScheme.backgroundBase,
              ),
              widgets: FilterEditorWidgets(
                slider: (
                  editorState,
                  rebuildStream,
                  value,
                  onChanged,
                  onChangeEnd,
                ) =>
                    ReactiveWidget(
                  builder: (context) {
                    return const SizedBox.shrink();
                  },
                  stream: rebuildStream,
                ),
                filterButton: (
                  filter,
                  isSelected,
                  scaleFactor,
                  onSelectFilter,
                  editorImage,
                  filterKey,
                ) {
                  return ImageEditorFilterBar(
                    filterModel: filter,
                    isSelected: isSelected,
                    onSelectFilter: () {
                      onSelectFilter.call();
                      editorKey.currentState?.setState(() {});
                    },
                    editorImage: editorImage,
                    filterKey: filterKey,
                  );
                },
                appBar: (editor, rebuildStream) {
                  return ReactiveAppbar(
                    builder: (context) {
                      return ImageEditorAppBar(
                        key: const Key('image_editor_app_bar'),
                        configs: editor.configs,
                        done: () => editor.done(),
                        close: () => editor.close(),
                      );
                    },
                    stream: rebuildStream,
                  );
                },
              ),
            ),
            tuneEditor: TuneEditorConfigs(
              enabled: true,
              style: TuneEditorStyle(
                background: colorScheme.backgroundBase,
              ),
              widgets: TuneEditorWidgets(
                appBar: (editor, rebuildStream) {
                  return ReactiveAppbar(
                    builder: (context) {
                      return ImageEditorAppBar(
                        enableRedo: editor.canRedo,
                        enableUndo: editor.canUndo,
                        key: const Key('image_editor_app_bar'),
                        redo: () => editor.redo(),
                        undo: () => editor.undo(),
                        configs: editor.configs,
                        done: () => editor.done(),
                        close: () => editor.close(),
                      );
                    },
                    stream: rebuildStream,
                  );
                },
                bottomBar: (editorState, rebuildStream) {
                  return ReactiveWidget(
                    builder: (context) {
                      return ImageEditorTuneBar(
                        configs: editorState.configs,
                        callbacks: editorState.callbacks,
                        editor: editorState,
                      );
                    },
                    stream: rebuildStream,
                  );
                },
              ),
            ),
            blurEditor: const BlurEditorConfigs(
              enabled: false,
            ),
            emojiEditor: EmojiEditorConfigs(
              enabled: true,
              checkPlatformCompatibility: true,
              style: EmojiEditorStyle(
                bottomActionBarConfig: BottomActionBarConfig(
                  showSearchViewButton: true,
                  buttonColor: colorScheme.backgroundBase,
                  buttonIconColor: colorScheme.tabIcon,
                  backgroundColor: colorScheme.backgroundBase,
                ),
                backgroundColor: colorScheme.backgroundBase,
              ),
            ),
            stickerEditor: StickerEditorConfigs(
              enabled: false,
              builder: (setLayer, scrollController) {
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    );
  }
}
