import 'dart:convert';
import 'dart:typed_data';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:image_editor/image_editor.dart';

class ImageEditorPage extends StatefulWidget {
  final ImageProvider imageProvider;
  final String heroTag;

  const ImageEditorPage(this.imageProvider, this.heroTag, {Key key}) : super(key: key);

  @override
  _ImageEditorPageState createState() => _ImageEditorPageState();
}

class _ImageEditorPageState extends State<ImageEditorPage> {
  final GlobalKey<ExtendedImageEditorState> editorKey =
      GlobalKey<ExtendedImageEditorState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0x00000000),
        elevation: 0,
      ),
      body: Container(
        child: Column(
          children: [
            Expanded(child: _buildImage()),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    return Hero(
      tag: widget.heroTag,
      child: ExtendedImage(
        image: widget.imageProvider,
        extendedImageEditorKey: editorKey,
        mode: ExtendedImageMode.editor,
        fit: BoxFit.contain,
        initEditorConfigHandler: (_) => EditorConfig(
          maxScale: 8.0,
          cropRectPadding: const EdgeInsets.all(20.0),
          hitTestSize: 20.0,
          cornerColor: Color.fromRGBO(45, 194, 98, 1.0),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
      _buildFlipButton(),
      _buildRotateLeftButton(),
      _buildRotateRightButton(),
      _buildSaveButton(),
    ]);
  }

  Widget _buildFlipButton() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
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
      onTap: () {
        // todo
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

  Future<void> crop([bool test = false]) async {
    final ExtendedImageEditorState state = editorKey.currentState;
    if (state == null) {
      return;
    }
    final Rect rect = state.getCropRect();
    if (rect == null) {
      // showToast('The crop rect is null.');
      return;
    }
    final EditActionDetails action = state.editAction;
    final double radian = action.rotateAngle;

    final bool flipHorizontal = action.flipY;
    final bool flipVertical = action.flipX;
    // final img = await getImageFromEditorKey(editorKey);
    final Uint8List img = state.rawImageData;

    if (img == null) {
      // showToast('The img is null.');
      return;
    }

    final ImageEditorOption option = ImageEditorOption();

    option.addOption(ClipOption.fromRect(rect));
    option.addOption(
        FlipOption(horizontal: flipHorizontal, vertical: flipVertical));
    if (action.hasRotateAngle) {
      option.addOption(RotateOption(radian.toInt()));
    }

    option.addOption(ColorOption.saturation(sat));
    option.addOption(ColorOption.brightness(bright));
    option.addOption(ColorOption.contrast(con));

    option.outputFormat = const OutputFormat.png(88);

    print(const JsonEncoder.withIndent('  ').convert(option.toJson()));

    final DateTime start = DateTime.now();
    final Uint8List result = await ImageEditor.editImage(
      image: img,
      imageEditorOption: option,
    );

    print('result.length = ${result?.length}');

    final Duration diff = DateTime.now().difference(start);

    print('image_editor time : $diff');
    // showToast('handle duration: $diff',
    // duration: const Duration(seconds: 5), dismissOtherToast: true);

    if (result == null) return;

    showPreviewDialog(result);
  }

  void flip() {
    editorKey.currentState?.flip();
  }

  void rotate(bool right) {
    editorKey.currentState?.rotate(right: right);
  }

  void showPreviewDialog(Uint8List image) {
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          color: Colors.grey.withOpacity(0.5),
          child: Center(
            child: SizedBox.fromSize(
              size: const Size.square(200),
              child: Container(
                child: Image.memory(image),
              ),
            ),
          ),
        ),
      ),
    );
  }

  double sat = 1;
  double bright = 1;
  double con = 1;

  Widget _buildSat() {
    return Slider(
      label: 'sat : ${sat.toStringAsFixed(2)}',
      onChanged: (double value) {
        setState(() {
          sat = value;
        });
      },
      value: sat,
      min: 0,
      max: 2,
    );
  }

  Widget _buildBrightness() {
    return Slider(
      label: 'brightness : ${bright.toStringAsFixed(2)}',
      onChanged: (double value) {
        setState(() {
          bright = value;
        });
      },
      value: bright,
      min: 0,
      max: 2,
    );
  }

  Widget _buildCon() {
    return Slider(
      label: 'con : ${con.toStringAsFixed(2)}',
      onChanged: (double value) {
        setState(() {
          con = value;
        });
      },
      value: con,
      min: 0,
      max: 4,
    );
  }
}
