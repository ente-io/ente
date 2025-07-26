import "dart:async";
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui show Image;

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import "package:flutter_image_compress/flutter_image_compress.dart";
import 'package:image_editor/image_editor.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:photo_manager/photo_manager.dart';
import "package:photos/generated/l10n.dart";
import 'package:photos/models/file/file.dart' as ente;
import 'package:photos/ui/common/loading_widget.dart';
import 'package:photos/ui/components/action_sheet_widget.dart';
import 'package:photos/ui/components/buttons/button_widget.dart';
import 'package:photos/ui/components/models/button_type.dart';
import 'package:photos/ui/notification/toast.dart';
import 'package:photos/ui/tools/editor/editor_utils.dart';
import 'package:photos/ui/tools/editor/filtered_image.dart';
import 'package:photos/ui/viewer/file/detail_page.dart';
import "package:photos/utils/dialog_util.dart";
import 'package:photos/utils/navigation_util.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';

class ImageEditorPage extends StatefulWidget {
  final ImageProvider imageProvider;
  final DetailPageConfiguration detailPageConfig;
  final ente.EnteFile originalFile;

  const ImageEditorPage(
    this.imageProvider,
    this.originalFile,
    this.detailPageConfig, {
    super.key,
  });

  @override
  State<ImageEditorPage> createState() => _ImageEditorPageState();
}

class _ImageEditorPageState extends State<ImageEditorPage> {
  static const double kBrightnessDefault = 1;
  static const double kBrightnessMin = 0;
  static const double kBrightnessMax = 2;
  static const double kSaturationDefault = 1;
  static const double kSaturationMin = 0;
  static const double kSaturationMax = 2;

  final _logger = Logger("ImageEditor");
  final GlobalKey<ExtendedImageEditorState> editorKey =
      GlobalKey<ExtendedImageEditorState>();

  double? _brightness = kBrightnessDefault;
  double? _saturation = kSaturationDefault;
  bool _hasEdited = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (_hasBeenEdited()) {
          await _showExitConfirmationDialog(context);
        } else {
          replacePage(context, DetailPage(widget.detailPageConfig));
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0x00000000),
          elevation: 0,
          actions: _hasBeenEdited()
              ? [
                  IconButton(
                    padding: const EdgeInsets.only(right: 16, left: 16),
                    onPressed: () {
                      editorKey.currentState!.reset();
                      setState(() {
                        _brightness = kBrightnessDefault;
                        _saturation = kSaturationDefault;
                      });
                    },
                    icon: const Icon(Icons.history),
                  ),
                ]
              : [],
        ),
        body: Column(
          children: [
            Expanded(child: _buildImage()),
            const Padding(padding: EdgeInsets.all(4)),
            Column(
              children: [
                _buildBrightness(),
                _buildSat(),
              ],
            ),
            const Padding(padding: EdgeInsets.all(8)),
            SafeArea(child: _buildBottomBar()),
            Padding(padding: EdgeInsets.all(Platform.isIOS ? 16 : 6)),
          ],
        ),
      ),
    );
  }

  bool _hasBeenEdited() {
    return _hasEdited ||
        _saturation != kSaturationDefault ||
        _brightness != kBrightnessDefault;
  }

  Widget _buildImage() {
    return Hero(
      tag: widget.detailPageConfig.tagPrefix + widget.originalFile.tag,
      child: ExtendedImage(
        image: widget.imageProvider,
        extendedImageEditorKey: editorKey,
        mode: ExtendedImageMode.editor,
        fit: BoxFit.contain,
        initEditorConfigHandler: (_) => EditorConfig(
          maxScale: 8.0,
          cropRectPadding: const EdgeInsets.all(20.0),
          hitTestSize: 20.0,
          cornerColor: const Color.fromRGBO(45, 150, 98, 1),
          editActionDetailsIsChanged: (_) {
            setState(() {
              _hasEdited = true;
            });
          },
        ),
        loadStateChanged: (state) {
          if (state.extendedImageLoadState == LoadState.completed) {
            return FilteredImage(
              brightness: _brightness,
              saturation: _saturation,
              child: state.completedWidget,
            );
          }
          return const EnteLoadingWidget();
        },
      ),
    );
  }

  Widget _buildBottomBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildFlipButton(),
        _buildRotateLeftButton(),
        _buildRotateRightButton(),
        _buildSaveButton(),
      ],
    );
  }

  Widget _buildFlipButton() {
    final TextStyle subtitle2 = Theme.of(context).textTheme.titleSmall!;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        flip();
      },
      child: SizedBox(
        width: 80,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Icon(
                Icons.flip,
                color: Theme.of(context).iconTheme.color!.withOpacity(0.8),
                size: 20,
              ),
            ),
            const Padding(padding: EdgeInsets.all(2)),
            Text(
              S.of(context).flip,
              style: subtitle2.copyWith(
                color: subtitle2.color!.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRotateLeftButton() {
    final TextStyle subtitle2 = Theme.of(context).textTheme.titleSmall!;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        rotate(false);
      },
      child: SizedBox(
        width: 80,
        child: Column(
          children: [
            Icon(
              Icons.rotate_left,
              color: Theme.of(context).iconTheme.color!.withOpacity(0.8),
            ),
            const Padding(padding: EdgeInsets.all(2)),
            Text(
              S.of(context).rotateLeft,
              style: subtitle2.copyWith(
                color: subtitle2.color!.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRotateRightButton() {
    final TextStyle subtitle2 = Theme.of(context).textTheme.titleSmall!;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        rotate(true);
      },
      child: SizedBox(
        width: 80,
        child: Column(
          children: [
            Icon(
              Icons.rotate_right,
              color: Theme.of(context).iconTheme.color!.withOpacity(0.8),
            ),
            const Padding(padding: EdgeInsets.all(2)),
            Text(
              S.of(context).rotateRight,
              style: subtitle2.copyWith(
                color: subtitle2.color!.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    final TextStyle subtitle2 = Theme.of(context).textTheme.titleSmall!;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        _saveEdits();
      },
      child: SizedBox(
        width: 80,
        child: Column(
          children: [
            Icon(
              Icons.save_alt_outlined,
              color: Theme.of(context).iconTheme.color!.withOpacity(0.8),
            ),
            const Padding(padding: EdgeInsets.all(2)),
            Text(
              S.of(context).saveCopy,
              style: subtitle2.copyWith(
                color: subtitle2.color!.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveEdits() async {
    final dialog = createProgressDialog(context, S.of(context).saving);
    await dialog.show();
    final ExtendedImageEditorState? state = editorKey.currentState;
    if (state == null) {
      return;
    }
    final Rect? rect = state.getCropRect();
    if (rect == null) {
      return;
    }
    final EditActionDetails action = state.editAction!;
    final double radian = action.rotateAngle;

    final bool flipHorizontal = action.flipY;
    final bool flipVertical = action.flipX;
    final Uint8List img = state.rawImageData;

    final ImageEditorOption option = ImageEditorOption();

    option.addOption(ClipOption.fromRect(rect));
    option.addOption(
      FlipOption(horizontal: flipHorizontal, vertical: flipVertical),
    );
    if (action.hasRotateAngle) {
      option.addOption(RotateOption(radian.toInt()));
    }

    option.addOption(ColorOption.saturation(_saturation!));
    option.addOption(ColorOption.brightness(_brightness!));

    option.outputFormat = const OutputFormat.jpeg(100);

    final DateTime start = DateTime.now();
    final result = await ImageEditor.editImage(
      image: img,
      imageEditorOption: option,
    );
    if (result == null) {
      _logger.severe("null result");
      showToast(context, S.of(context).somethingWentWrong);
      return;
    }
    _logger.info('Size before compression = ${result.length}');

    final ui.Image decodedResult = await decodeImageFromList(result);
    final compressedResult = await FlutterImageCompress.compressWithList(
      result,
      minWidth: decodedResult.width,
      minHeight: decodedResult.height,
    );
    _logger.info('Size after compression = ${compressedResult.length}');
    final Duration diff = DateTime.now().difference(start);
    _logger.info('image_editor time : $diff');

    await saveAsset(
      context: context,
      originalFile: widget.originalFile,
      detailPageConfig: widget.detailPageConfig,
      saveAction: () async {
        final fileName =
            path.basenameWithoutExtension(widget.originalFile.title!) +
                "_edited_" +
                DateTime.now().microsecondsSinceEpoch.toString() +
                ".JPEG";
        return PhotoManager.editor.saveImage(
          compressedResult,
          filename: fileName,
        );
      },
      fileExtension: ".JPEG",
      logger: _logger,
      onSaveFinished: () async {
        await dialog.hide();
      },
    );
  }

  void flip() {
    editorKey.currentState?.flip();
  }

  void rotate(bool right) {
    editorKey.currentState?.rotate(right: right);
  }

  Widget _buildSat() {
    final TextStyle subtitle2 = Theme.of(context).textTheme.titleSmall!;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Row(
        children: [
          SizedBox(
            width: 42,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                S.of(context).color,
                style: subtitle2.copyWith(
                  color: subtitle2.color!.withOpacity(0.8),
                ),
              ),
            ),
          ),
          Expanded(
            child: SfSliderTheme(
              data: SfSliderThemeData(
                activeTrackHeight: 4,
                inactiveTrackHeight: 2,
                inactiveTrackColor: Colors.grey[900],
                activeTrackColor: const Color.fromRGBO(45, 150, 98, 1),
                thumbColor: const Color.fromRGBO(45, 150, 98, 1),
                thumbRadius: 10,
                tooltipBackgroundColor: Colors.grey[900],
              ),
              child: SfSlider(
                onChanged: (value) {
                  setState(() {
                    _saturation = value;
                  });
                },
                value: _saturation,
                enableTooltip: true,
                stepSize: 0.01,
                min: kSaturationMin,
                max: kSaturationMax,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrightness() {
    final TextStyle subtitle2 = Theme.of(context).textTheme.titleSmall!;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Row(
        children: [
          SizedBox(
            width: 42,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                S.of(context).light,
                style: subtitle2.copyWith(
                  color: subtitle2.color!.withOpacity(0.8),
                ),
              ),
            ),
          ),
          Expanded(
            child: SfSliderTheme(
              data: SfSliderThemeData(
                activeTrackHeight: 4,
                inactiveTrackHeight: 2,
                activeTrackColor: const Color.fromRGBO(45, 150, 98, 1),
                inactiveTrackColor: Colors.grey[900],
                thumbColor: const Color.fromRGBO(45, 150, 98, 1),
                thumbRadius: 10,
                tooltipBackgroundColor: Colors.grey[900],
              ),
              child: SfSlider(
                onChanged: (value) {
                  setState(() {
                    _brightness = value;
                  });
                },
                value: _brightness,
                enableTooltip: true,
                stepSize: 0.01,
                min: kBrightnessMin,
                max: kBrightnessMax,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showExitConfirmationDialog(BuildContext context) async {
    final actionResult = await showActionSheet(
      context: context,
      buttons: [
        ButtonWidget(
          labelText: S.of(context).yesDiscardChanges,
          buttonType: ButtonType.critical,
          buttonSize: ButtonSize.large,
          shouldStickToDarkTheme: true,
          buttonAction: ButtonAction.first,
          isInAlert: true,
        ),
        ButtonWidget(
          labelText: S.of(context).no,
          buttonType: ButtonType.secondary,
          buttonSize: ButtonSize.large,
          buttonAction: ButtonAction.second,
          shouldStickToDarkTheme: true,
          isInAlert: true,
        ),
      ],
      body: S.of(context).doYouWantToDiscardTheEditsYouHaveMade,
      actionSheetType: ActionSheetType.defaultActionSheet,
    );
    if (actionResult?.action != null &&
        actionResult!.action == ButtonAction.first) {
      replacePage(context, DetailPage(widget.detailPageConfig));
    }
  }
}
