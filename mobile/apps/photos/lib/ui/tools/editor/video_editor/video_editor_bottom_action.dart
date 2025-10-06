import "package:flutter/material.dart";
import "package:photos/ui/tools/editor/image_editor/circular_icon_button.dart";

class VideoEditorBottomAction extends StatelessWidget {
  const VideoEditorBottomAction({
    super.key,
    required this.label,
    this.icon,
    this.svgPath,
    this.child,
    required this.onPressed,
    this.isSelected = false,
  }) : assert(icon != null || svgPath != null || child != null);

  final String label;
  final IconData? icon;
  final String? svgPath;
  final Widget? child;
  final VoidCallback onPressed;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return CircularIconButton(
      label: label,
      onTap: onPressed,
      svgPath: svgPath,
      icon: icon,
      size: 60,
      isSelected: isSelected,
      child: child,
    );
  }
}
