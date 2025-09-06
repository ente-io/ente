import 'package:flutter/material.dart';
import "package:photos/generated/l10n.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/tools/editor/image_editor/image_editor_color_picker.dart";
import "package:photos/ui/tools/editor/image_editor/image_editor_configs_mixin.dart";
import "package:photos/ui/tools/editor/image_editor/image_editor_constants.dart";
import "package:pro_image_editor/mixins/converted_configs.dart";
import "package:pro_image_editor/models/editor_callbacks/pro_image_editor_callbacks.dart";
import "package:pro_image_editor/models/editor_configs/pro_image_editor_configs.dart";
import "package:pro_image_editor/modules/paint_editor/paint_editor.dart";
import "package:pro_image_editor/widgets/animated/fade_in_up.dart";

class ImageEditorPaintBar extends StatefulWidget with SimpleConfigsAccess {
  const ImageEditorPaintBar({
    super.key,
    required this.configs,
    required this.callbacks,
    required this.editor,
    required this.i18nColor,
  });

  final PaintingEditorState editor;

  @override
  final ProImageEditorConfigs configs;
  @override
  final ProImageEditorCallbacks callbacks;

  final String i18nColor;

  @override
  State<ImageEditorPaintBar> createState() => _ImageEditorPaintBarState();
}

class _ImageEditorPaintBarState extends State<ImageEditorPaintBar>
    with ImageEditorConvertedConfigs, SimpleConfigsAccessState {
  double colorSliderValue = 0.5;
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFunctions(constraints),
          ],
        );
      },
    );
  }

  Widget _buildFunctions(BoxConstraints constraints) {
    return BottomAppBar(
      height: editorBottomBarHeight,
      padding: EdgeInsets.zero,
      child: Align(
        alignment: Alignment.center,
        child: FadeInUp(
          duration: fadeInDuration,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(left: 20.0),
                child: Text(
                  AppLocalizations.of(context).brushColor,
                  style: getEnteTextTheme(context).body,
                ),
              ),
              const SizedBox(height: 24),
              ImageEditorColorPicker(
                value: colorSliderValue,
                onChanged: (value) {
                  setState(() {
                    colorSliderValue = value;
                  });
                  final hue = value * 360;
                  final color = HSVColor.fromAHSV(1.0, hue, 1.0, 1.0).toColor();
                  widget.editor.colorChanged(color);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
