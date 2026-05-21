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
  final double? tickIconSize;
  final bool selectedTickCutsOut;

  const SelectAllStatusIcon({
    required this.isSelected,
    this.size = 18,
    this.selectedFillColor,
    this.selectedTickColor,
    this.unselectedColor,
    this.tickIconSize,
    this.selectedTickCutsOut = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colors = components.ComponentTheme.colorsOf(context);
    final tickSize = tickIconSize ?? size * _tickScale;
    final selectedFill = selectedFillColor ?? colors.fillBase;
    final selectedTick = selectedTickColor ?? colors.textReverse;
    final unselected = unselectedColor ?? colors.textLight;

    if (isSelected) {
      if (selectedTickCutsOut) {
        return CustomPaint(
          size: Size.square(size),
          painter: _SelectedTickCutoutPainter(
            fillColor: selectedFill,
            tickSize: tickSize,
          ),
        );
      }

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

class _SelectedTickCutoutPainter extends CustomPainter {
  static const _tickStrokeWidth = 1.5;

  final Color fillColor;
  final double tickSize;

  const _SelectedTickCutoutPainter({
    required this.fillColor,
    required this.tickSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.saveLayer(bounds, Paint());
    canvas.drawCircle(
      bounds.center,
      size.shortestSide / 2,
      Paint()..color = fillColor,
    );

    final scale = tickSize / 24;
    final offset = Offset(
      (size.width - tickSize) / 2,
      (size.height - tickSize) / 2,
    );
    final tickPath = Path()
      ..moveTo(offset.dx + 5 * scale, offset.dy + 14 * scale)
      ..lineTo(offset.dx + 8.5 * scale, offset.dy + 17.5 * scale)
      ..lineTo(offset.dx + 19 * scale, offset.dy + 6.5 * scale);

    canvas.drawPath(
      tickPath,
      Paint()
        ..blendMode = BlendMode.clear
        ..style = PaintingStyle.stroke
        ..strokeWidth = _tickStrokeWidth * scale
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SelectedTickCutoutPainter oldDelegate) {
    return oldDelegate.fillColor != fillColor ||
        oldDelegate.tickSize != tickSize;
  }
}
