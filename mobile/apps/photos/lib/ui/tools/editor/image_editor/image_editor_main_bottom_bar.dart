import 'dart:math';

import 'package:flutter/material.dart';
import "package:photos/generated/l10n.dart";
import "package:photos/ui/tools/editor/image_editor/circular_icon_button.dart";
import "package:photos/ui/tools/editor/image_editor/image_editor_configs_mixin.dart";
import "package:photos/ui/tools/editor/image_editor/image_editor_constants.dart";
import "package:pro_image_editor/mixins/converted_configs.dart";
import 'package:pro_image_editor/pro_image_editor.dart';

class ImageEditorMainBottomBar extends StatefulWidget with SimpleConfigsAccess {
  const ImageEditorMainBottomBar({
    super.key,
    required this.configs,
    required this.callbacks,
    required this.editor,
  });

  final ProImageEditorState editor;

  @override
  final ProImageEditorConfigs configs;
  @override
  final ProImageEditorCallbacks callbacks;

  @override
  State<ImageEditorMainBottomBar> createState() =>
      ImageEditorMainBottomBarState();
}

class ImageEditorMainBottomBarState extends State<ImageEditorMainBottomBar>
    with ImageEditorConvertedConfigs, SimpleConfigsAccessState {
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
      clipBehavior: Clip.none,
      child: AnimatedSwitcher(
        layoutBuilder: (currentChild, previousChildren) => Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: <Widget>[
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        ),
        duration: const Duration(milliseconds: 400),
        reverseDuration: const Duration(milliseconds: 0),
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SizeTransition(
              sizeFactor: animation,
              axis: Axis.vertical,
              axisAlignment: -1,
              child: child,
            ),
          );
        },
        switchInCurve: Curves.ease,
        child: widget.editor.isSubEditorOpen &&
                !widget.editor.isSubEditorClosing
            ? const SizedBox.shrink()
            : Align(
                alignment: Alignment.center,
                child: SingleChildScrollView(
                  clipBehavior: Clip.none,
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: min(constraints.maxWidth, 600),
                      maxWidth: 600,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        CircularIconButton(
                          svgPath: "assets/image-editor/image-editor-crop.svg",
                          label: S.of(context).crop,
                          onTap: () {
                            widget.editor.openCropRotateEditor();
                          },
                        ),
                        CircularIconButton(
                          svgPath:
                              "assets/image-editor/image-editor-filter.svg",
                          label: S.of(context).filter,
                          onTap: () {
                            widget.editor.openFilterEditor();
                          },
                        ),
                        CircularIconButton(
                          svgPath: "assets/image-editor/image-editor-tune.svg",
                          label: S.of(context).adjust,
                          onTap: () {
                            widget.editor.openTuneEditor();
                          },
                        ),
                        CircularIconButton(
                          svgPath: "assets/image-editor/image-editor-paint.svg",
                          label: S.of(context).draw,
                          onTap: () {
                            widget.editor.openPaintingEditor();
                          },
                        ),
                        CircularIconButton(
                          svgPath:
                              "assets/image-editor/image-editor-sticker.svg",
                          label: S.of(context).sticker,
                          onTap: () {
                            widget.editor.openEmojiEditor();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
