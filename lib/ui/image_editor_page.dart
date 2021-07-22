import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:image_editor/image_editor.dart';
import 'package:logging/logging.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/events/local_photos_updated_event.dart';
import 'package:photos/services/local_sync_service.dart';
import 'package:photos/services/sync_service.dart';
import 'package:photos/ui/detail_page.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/navigation_util.dart';
import 'package:photos/utils/toast_util.dart';
import 'package:photos/models/file.dart' as ente;
import 'package:photos/models/location.dart';
import 'package:path/path.dart' as path;
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';

class ImageEditorPage extends StatefulWidget {
  final ImageProvider imageProvider;
  final DetailPageConfiguration detailPageConfig;
  final ente.File originalFile;

  const ImageEditorPage(
    this.imageProvider,
    this.originalFile,
    this.detailPageConfig, {
    Key key,
  }) : super(key: key);

  @override
  _ImageEditorPageState createState() => _ImageEditorPageState();
}

class _ImageEditorPageState extends State<ImageEditorPage> {
  final _logger = Logger("ImageEditor");
  final GlobalKey<ExtendedImageEditorState> editorKey =
      GlobalKey<ExtendedImageEditorState>();

  double _brightness = 0;
  double _saturation = 0;
  bool _hasEdited = false;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_hasBeenEdited()) {
          await _showExitConfirmationDialog();
        } else {
          replacePage(context, DetailPage(widget.detailPageConfig));
        }
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Color(0x00000000),
          elevation: 0,
          actions: _hasBeenEdited()
              ? [
                  IconButton(
                    padding: const EdgeInsets.only(right: 16, left: 16),
                    onPressed: () {
                      editorKey.currentState.reset();
                      setState(() {
                        _brightness = 0;
                        _saturation = 0;
                      });
                    },
                    icon: Icon(Icons.history),
                  )
                ]
              : [],
        ),
        body: Container(
          child: Column(
            children: [
              Expanded(child: _buildImage()),
              Padding(padding: EdgeInsets.all(4)),
              Column(
                children: [
                  _buildBrightness(),
                  _buildSat(),
                ],
              ),
              Padding(padding: EdgeInsets.all(8)),
              _buildBottomBar(),
              Padding(padding: EdgeInsets.all(Platform.isIOS ? 16 : 6)),
            ],
          ),
        ),
      ),
    );
  }

  bool _hasBeenEdited() {
    return _hasEdited || _saturation != 0 || _brightness != 0;
  }

  Widget _buildImage() {
    return Hero(
      tag: widget.detailPageConfig.tagPrefix + widget.originalFile.tag(),
      child: ExtendedImage(
        image: widget.imageProvider,
        extendedImageEditorKey: editorKey,
        mode: ExtendedImageMode.editor,
        fit: BoxFit.contain,
        initEditorConfigHandler: (_) => EditorConfig(
          maxScale: 8.0,
          cropRectPadding: const EdgeInsets.all(20.0),
          hitTestSize: 20.0,
          cornerColor: Color.fromRGBO(45, 150, 98, 1),
          editActionDetailsIsChanged: (_) {
            setState(() {
              _hasEdited = true;
            });
          },
        ),
        brightness: _brightness,
        saturation: _saturation,
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
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        flip();
      },
      child: Container(
        width: 80,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Icon(
                Icons.flip,
                color: Colors.white.withOpacity(0.8),
                size: 20,
              ),
            ),
            Padding(padding: EdgeInsets.all(2)),
            Text(
              "flip",
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRotateLeftButton() {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        rotate(false);
      },
      child: Container(
        width: 80,
        child: Column(
          children: [
            Icon(Icons.rotate_left, color: Colors.white.withOpacity(0.8)),
            Padding(padding: EdgeInsets.all(2)),
            Text(
              "rotate left",
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRotateRightButton() {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        rotate(true);
      },
      child: Container(
        width: 80,
        child: Column(
          children: [
            Icon(Icons.rotate_right, color: Colors.white.withOpacity(0.8)),
            Padding(padding: EdgeInsets.all(2)),
            Text(
              "rotate right",
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        _saveEdits();
      },
      child: Container(
        width: 80,
        child: Column(
          children: [
            Icon(Icons.save_alt_outlined, color: Colors.white.withOpacity(0.8)),
            Padding(padding: EdgeInsets.all(2)),
            Text(
              "save copy",
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveEdits() async {
    final dialog = createProgressDialog(context, "saving...");
    await dialog.show();
    final ExtendedImageEditorState state = editorKey.currentState;
    if (state == null) {
      return;
    }
    final Rect rect = state.getCropRect();
    if (rect == null) {
      return;
    }
    final EditActionDetails action = state.editAction;
    final double radian = action.rotateAngle;

    final bool flipHorizontal = action.flipY;
    final bool flipVertical = action.flipX;
    final Uint8List img = state.rawImageData;

    if (img == null) {
      _logger.severe("null rawImageData");
      showToast("something went wrong");
      return;
    }

    final ImageEditorOption option = ImageEditorOption();

    option.addOption(ClipOption.fromRect(rect));
    option.addOption(
        FlipOption(horizontal: flipHorizontal, vertical: flipVertical));
    if (action.hasRotateAngle) {
      option.addOption(RotateOption(radian.toInt()));
    }

    option.addOption(ColorOption.saturation(_saturation + 1));
    option.addOption(ColorOption.brightness(_brightness + 1));

    option.outputFormat = const OutputFormat.png(88);

    print(const JsonEncoder.withIndent('  ').convert(option.toJson()));

    final DateTime start = DateTime.now();
    final Uint8List result = await ImageEditor.editImage(
      image: img,
      imageEditorOption: option,
    );
    _logger.info('result.length = ${result?.length}');
    final Duration diff = DateTime.now().difference(start);
    _logger.info('image_editor time : $diff');

    if (result == null) {
      _logger.severe("null result");
      showToast("something went wrong");
      return;
    }
    try {
      final fileName =
          path.basenameWithoutExtension(widget.originalFile.title) +
              "_edited_" +
              DateTime.now().microsecondsSinceEpoch.toString() +
              path.extension(widget.originalFile.title);
      final newAsset = await PhotoManager.editor.saveImage(
        result,
        title: fileName,
      );
      final newFile =
          await ente.File.fromAsset(widget.originalFile.deviceFolder, newAsset);
      newFile.creationTime = widget.originalFile.creationTime;
      newFile.collectionID = widget.originalFile.collectionID;
      newFile.location = widget.originalFile.location;
      if (!newFile.hasLocation() && widget.originalFile.localID != null) {
        final latLong =
            await (await widget.originalFile.getAsset()).latlngAsync();
        newFile.location = Location(latLong.latitude, latLong.longitude);
      }
      newFile.generatedID = await FilesDB.instance.insert(newFile);
      await LocalSyncService.instance.trackEditedFile(newFile);
      Bus.instance.fire(LocalPhotosUpdatedEvent([newFile]));
      SyncService.instance.sync();
      showToast("edits saved");
      _logger.info("Original file " + widget.originalFile.toString());
      _logger.info("Saved edits to file " + newFile.toString());
      final existingFiles = widget.detailPageConfig.files;
      final files = (await widget.detailPageConfig.asyncLoader(
              existingFiles[existingFiles.length - 1].creationTime,
              existingFiles[0].creationTime))
          .files;
      replacePage(
        context,
        DetailPage(
          widget.detailPageConfig.copyWith(
            files: files,
            selectedIndex: files
                .indexWhere((file) => file.generatedID == newFile.generatedID),
          ),
        ),
      );
    } catch (e, s) {
      showToast("oops, could not save edits");
      _logger.severe(e, s);
    }
    await dialog.hide();
  }

  void flip() {
    editorKey.currentState?.flip();
  }

  void rotate(bool right) {
    editorKey.currentState?.rotate(right: right);
  }

  Widget _buildSat() {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Row(
        children: [
          Container(
            width: 40,
            child: Text(
              "color",
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: SfSliderTheme(
              data: SfSliderThemeData(
                activeTrackHeight: 4,
                inactiveTrackHeight: 2,
                inactiveTrackColor: Colors.grey[900],
                activeTrackColor: Color.fromRGBO(45, 150, 98, 1),
                thumbColor: Color.fromRGBO(45, 150, 98, 1),
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
                min: -1.0,
                max: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrightness() {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Row(
        children: [
          Container(
            width: 40,
            child: Text(
              "light",
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: SfSliderTheme(
              data: SfSliderThemeData(
                activeTrackHeight: 4,
                inactiveTrackHeight: 2,
                activeTrackColor: Color.fromRGBO(45, 150, 98, 1),
                inactiveTrackColor: Colors.grey[900],
                thumbColor: Color.fromRGBO(45, 150, 98, 1),
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
                min: -1.0,
                max: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showExitConfirmationDialog() async {
    AlertDialog alert = AlertDialog(
      title: Text("discard edits?"),
      actions: [
        TextButton(
          child: Text("yes", style: TextStyle(color: Colors.red)),
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop('dialog');
            replacePage(context, DetailPage(widget.detailPageConfig));
          },
        ),
        TextButton(
          child: Text("no", style: TextStyle(color: Colors.white)),
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop('dialog');
          },
        ),
      ],
    );

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
      barrierColor: Colors.black87,
    );
  }
}
