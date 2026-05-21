import "package:ente_components/ente_components.dart" as components;
import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";

class SelectAllStatusIcon extends StatelessWidget {
  static const _tickScale = 14 / 18;

  final bool isSelected;
  final double size;
  final Color? selectedFillColor;
  final Color? selectedTickColor;
  final Color? unselectedColor;

  const SelectAllStatusIcon({
    required this.isSelected,
    this.size = 18,
    this.selectedFillColor,
    this.selectedTickColor,
    this.unselectedColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colors = components.ComponentTheme.colorsOf(context);
    final tickSize = size * _tickScale;
    final selectedFill = selectedFillColor ?? colors.fillBase;
    final selectedTick = selectedTickColor ?? colors.textReverse;
    final unselected = unselectedColor ?? colors.textLight;

    if (isSelected) {
      return Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selectedFill,
          shape: BoxShape.circle,
        ),
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedTick02,
          color: selectedTick,
          size: tickSize,
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: unselected),
      ),
      child: HugeIcon(
        icon: HugeIcons.strokeRoundedTick02,
        color: unselected,
        size: tickSize,
      ),
    );
  }
}
