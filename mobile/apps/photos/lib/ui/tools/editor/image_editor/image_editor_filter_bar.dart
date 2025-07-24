import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import "package:photos/ente_theme_data.dart";
import "package:photos/theme/ente_theme.dart";
import 'package:pro_image_editor/pro_image_editor.dart';

class ImageEditorFilterBar extends StatefulWidget {
  const ImageEditorFilterBar({
    required this.filterModel,
    required this.isSelected,
    required this.onSelectFilter,
    required this.editorImage,
    this.filterKey,
    super.key,
  });

  final FilterModel filterModel;
  final bool isSelected;
  final VoidCallback onSelectFilter;
  final Widget editorImage;
  final Key? filterKey;

  @override
  State<ImageEditorFilterBar> createState() => _ImageEditorFilterBarState();
}

class _ImageEditorFilterBarState extends State<ImageEditorFilterBar> {
  @override
  Widget build(BuildContext context) {
    return buildFilteredOptions(
      widget.editorImage,
      widget.isSelected,
      widget.filterModel.name,
      widget.onSelectFilter,
      widget.filterKey ?? ValueKey(widget.filterModel.name),
    );
  }

  Widget buildFilteredOptions(
    Widget editorImage,
    bool isSelected,
    String filterName,
    VoidCallback onSelectFilter,
    Key filterKey,
  ) {
    return GestureDetector(
      onTap: () => onSelectFilter(),
      child: SizedBox(
        height: 90,
        width: 80,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Container(
              height: 60,
              width: 60,
              decoration: ShapeDecoration(
                shape: SmoothRectangleBorder(
                  borderRadius: SmoothBorderRadius(
                    cornerRadius: 12,
                    cornerSmoothing: 0.6,
                  ),
                  side: BorderSide(
                    color: isSelected
                        ? Theme.of(context).colorScheme.imageEditorPrimaryColor
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
              ),
              child: Padding(
                padding: isSelected ? const EdgeInsets.all(2) : EdgeInsets.zero,
                child: ClipSmoothRect(
                  radius: SmoothBorderRadius(
                    cornerRadius: 9.69,
                    cornerSmoothing: 0.4,
                  ),
                  child: SizedBox(
                    height: isSelected ? 56 : 60,
                    width: isSelected ? 56 : 60,
                    child: editorImage,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              filterName,
              style: isSelected
                  ? getEnteTextTheme(context).smallBold
                  : getEnteTextTheme(context).smallMuted,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
