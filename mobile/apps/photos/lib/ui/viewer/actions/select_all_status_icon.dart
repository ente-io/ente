import "package:ente_components/ente_components.dart" as components;
import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";

class SelectAllStatusIcon extends StatelessWidget {
  static const _tickScale = 14 / 18;

  final bool isSelected;
  final double size;

  const SelectAllStatusIcon({
    required this.isSelected,
    this.size = 18,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colors = components.ComponentTheme.colorsOf(context);
    final tickSize = size * _tickScale;

    if (isSelected) {
      return Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.fillBase,
          shape: BoxShape.circle,
        ),
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedTick02,
          color: colors.textReverse,
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
        border: Border.all(color: colors.textLight),
      ),
      child: HugeIcon(
        icon: HugeIcons.strokeRoundedTick02,
        color: colors.textLight,
        size: tickSize,
      ),
    );
  }
}
