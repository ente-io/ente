import "dart:async";
import "dart:io";
import "dart:math";
import 'dart:ui' as ui show Image;

import 'package:flutter/material.dart';
import "package:flutter/services.dart";
import "package:flutter_image_compress/flutter_image_compress.dart";
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
import "package:photos/utils/navigation_util.dart";
import "package:pro_image_editor/models/editor_configs/main_editor_configs.dart";
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

  Future<void> saveImage(Uint8List? bytes) async {
    if (bytes == null) return;

    final dialog =
        createProgressDialog(context, AppLocalizations.of(context).saving);
    await dialog.show();

    debugPrint("Image saved with size: ${bytes.length} bytes");
    final DateTime start = DateTime.now();

    final ui.Image decodedResult = await decodeImageFromList(bytes);
    final result = await FlutterImageCompress.compressWithList(
      bytes,
      minWidth: decodedResult.width,
      minHeight: decodedResult.height,
    );
    _logger.info('Size after compression = ${result.length}');
    final Duration diff = DateTime.now().difference(start);
    _logger.info('image_editor time : $diff');

    try {
      final fileName =
          path.basenameWithoutExtension(widget.originalFile.title!) +
              "_edited_" +
              DateTime.now().microsecondsSinceEpoch.toString() +
              ".JPEG";
      //Disabling notifications for assets changing to insert the file into
      //files db before triggering a sync.
      await PhotoManager.stopChangeNotify();
      final AssetEntity newAsset =
          await (PhotoManager.editor.saveImage(result, filename: fileName));
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
      showShortToast(context, AppLocalizations.of(context).editsSaved);
      _logger.info("Original file " + widget.originalFile.toString());
      _logger.info("Saved edits to file " + newFile.toString());
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
      showToast(context, AppLocalizations.of(context).oopsCouldNotSaveEdits);
      _logger.severe(e, s);
    } finally {
      await PhotoManager.startChangeNotify();
    }
  }

  Future<void> _showExitConfirmationDialog(BuildContext context) async {
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
      body: AppLocalizations.of(context).doYouWantToDiscardTheEditsYouHaveMade,
      actionSheetType: ActionSheetType.defaultActionSheet,
    );
    if (actionResult?.action != null &&
        actionResult!.action == ButtonAction.first) {
      replacePage(context, DetailPage(widget.detailPageConfig));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLightMode = Theme.of(context).brightness == Brightness.light;
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        editorKey.currentState?.disablePopScope = true;
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
            onCloseEditor: () {
              editorKey.currentState?.disablePopScope = true;
              _showExitConfirmationDialog(context);
            },
            mainEditorCallbacks: MainEditorCallbacks(
              onStartCloseSubEditor: (value) {
                _mainEditorBarKey.currentState?.setState(() {});
              },
              onPopInvoked: (didPop, result) {
                editorKey.currentState?.disablePopScope = false;
              },
            ),
          ),
          configs: ProImageEditorConfigs(
            imageEditorTheme: ImageEditorTheme(
              uiOverlayStyle: SystemUiOverlayStyle(
                systemNavigationBarContrastEnforced: true,
                systemNavigationBarColor: Colors.transparent,
                statusBarBrightness:
                    isLightMode ? Brightness.dark : Brightness.light,
                statusBarIconBrightness:
                    isLightMode ? Brightness.dark : Brightness.light,
              ),
              appBarBackgroundColor: colorScheme.backgroundBase,
              background: colorScheme.backgroundBase,
              bottomBarBackgroundColor: colorScheme.backgroundBase,
              filterEditor: FilterEditorTheme(
                background: colorScheme.backgroundBase,
              ),
              paintingEditor: PaintingEditorTheme(
                initialColor: const Color(0xFF00FFFF),
                background: colorScheme.backgroundBase,
              ),
              textEditor: const TextEditorTheme(
                background: Colors.transparent,
                textFieldMargin: EdgeInsets.only(top: kToolbarHeight),
              ),
              cropRotateEditor: CropRotateEditorTheme(
                background: colorScheme.backgroundBase,
                cropCornerColor:
                    Theme.of(context).colorScheme.imageEditorPrimaryColor,
              ),
              tuneEditor: TuneEditorTheme(
                background: colorScheme.backgroundBase,
              ),
              emojiEditor: EmojiEditorTheme(
                bottomActionBarConfig: BottomActionBarConfig(
                  showSearchViewButton: true,
                  buttonColor: colorScheme.backgroundBase,
                  buttonIconColor: colorScheme.tabIcon,
                  backgroundColor: colorScheme.backgroundBase,
                ),
                backgroundColor: colorScheme.backgroundBase,
              ),
            ),
            imageGenerationConfigs: const ImageGenerationConfigs(
              jpegQuality: 100,
              generateInsideSeparateThread: true,
              pngLevel: 0,
            ),
            layerInteraction: const LayerInteraction(
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
            customWidgets: ImageEditorCustomWidgets(
              filterEditor: CustomWidgetsFilterEditor(
                slider: (
                  editorState,
                  rebuildStream,
                  value,
                  onChanged,
                  onChangeEnd,
                ) =>
                    ReactiveCustomWidget(
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
                  return ReactiveCustomAppbar(
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
              tuneEditor: CustomWidgetsTuneEditor(
                appBar: (editor, rebuildStream) {
                  return ReactiveCustomAppbar(
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
                  return ReactiveCustomWidget(
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
              mainEditor: CustomWidgetsMainEditor(
                removeLayerArea: (key, __, rebuildStream) {
                  return ReactiveCustomWidget(
                    key: key,
                    builder: (context) {
                      return Align(
                        alignment: Alignment.bottomCenter,
                        child: StreamBuilder(
                          stream: rebuildStream,
                          builder: (context, snapshot) {
                            final isHovered = editorKey.currentState!
                                .layerInteractionManager.hoverRemoveBtn;

                            return AnimatedContainer(
                              key: key,
                              duration: const Duration(milliseconds: 150),
                              height: 56,
                              width: 56,
                              margin: const EdgeInsets.only(bottom: 24),
                              decoration: BoxDecoration(
                                color: isHovered
                                    ? colorScheme.warning400.withOpacity(0.8)
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
                                            .withOpacity(0.8),
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                    stream: rebuildStream,
                  );
                },
                appBar: (editor, rebuildStream) {
                  return ReactiveCustomAppbar(
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
                bottomBar: (editor, rebuildStream, key) => ReactiveCustomWidget(
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
              paintEditor: CustomWidgetsPaintEditor(
                appBar: (editor, rebuildStream) {
                  return ReactiveCustomAppbar(
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
                  return ReactiveCustomWidget(
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
              textEditor: CustomWidgetsTextEditor(
                appBar: (textEditor, rebuildStream) => ReactiveCustomAppbar(
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
                    ReactiveCustomWidget(
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
                  return ReactiveCustomWidget(
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
              cropRotateEditor: CustomWidgetsCropRotateEditor(
                appBar: (editor, rebuildStream) {
                  return ReactiveCustomAppbar(
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
                bottomBar: (cropRotateEditor, rebuildStream) =>
                    ReactiveCustomWidget(
                  stream: rebuildStream,
                  builder: (_) => ImageEditorCropRotateBar(
                    configs: cropRotateEditor.configs,
                    callbacks: cropRotateEditor.callbacks,
                    editor: cropRotateEditor,
                  ),
                ),
              ),
            ),
            mainEditorConfigs: const MainEditorConfigs(enableZoom: true),
            paintEditorConfigs: const PaintEditorConfigs(enabled: true),
            textEditorConfigs: const TextEditorConfigs(
              enabled: false,
              canToggleBackgroundMode: true,
              canToggleTextAlign: true,
            ),
            cropRotateEditorConfigs: const CropRotateEditorConfigs(
              canChangeAspectRatio: true,
              canFlip: true,
              canRotate: true,
              canReset: true,
              enabled: true,
            ),
            filterEditorConfigs: FilterEditorConfigs(
              enabled: true,
              fadeInUpDuration: fadeInDuration,
              fadeInUpStaggerDelayDuration: fadeInDelay,
              filterList: filterList,
            ),
            tuneEditorConfigs: const TuneEditorConfigs(enabled: true),
            blurEditorConfigs: const BlurEditorConfigs(
              enabled: false,
            ),
            emojiEditorConfigs: const EmojiEditorConfigs(
              enabled: true,
              checkPlatformCompatibility: true,
            ),
            stickerEditorConfigs: StickerEditorConfigs(
              enabled: false,
              buildStickers: (setLayer, scrollController) {
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    );
  }
}
