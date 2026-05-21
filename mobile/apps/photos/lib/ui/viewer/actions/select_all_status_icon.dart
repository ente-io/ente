import "package:ente_components/ente_components.dart" as components;
import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";

class SelectAllStatusIcon extends StatelessWidget {
  static const _containerSize = 18.0;
  static const _tickSize = 14.0;

  final bool isSelected;

  const SelectAllStatusIcon({
    required this.isSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colors = components.ComponentTheme.colorsOf(context);

    if (isSelected) {
      return Container(
        width: _containerSize,
        height: _containerSize,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.fillBase,
          shape: BoxShape.circle,
        ),
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedTick02,
          color: colors.textReverse,
          size: _tickSize,
        ),
      );
    }

    return Container(
      width: _containerSize,
      height: _containerSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: colors.textLight),
      ),
      child: HugeIcon(
        icon: HugeIcons.strokeRoundedTick02,
        color: colors.textLight,
        size: _tickSize,
      ),
    );
  }
}
