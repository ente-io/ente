import 'package:flutter/material.dart';

typedef ScrollThumbBuilder = Widget Function(
    Color backgroundColor, Color drawColor, double height, int index);

class DraggableScrollbarThumbs {
  static Widget RoundedRectThumb(
      Color backgroundColor, Color drawColor, double height, int index) {
    return Material(
      elevation: 4.0,
      child: Container(
        constraints: BoxConstraints.tight(Size(16.0, height)),
      ),
      color: backgroundColor,
      borderRadius: BorderRadius.all(Radius.circular(7.0)),
    );
  }

  static Widget ArrowThumb(
      Color backgroundColor, Color drawColor, double height, int index) {
    return ClipPath(
      child: Container(
        width: 20.0,
        height: height,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.all(Radius.circular(12.0)),
        ),
      ),
      clipper: _ArrowClipper(),
    );
  }

  static Widget SemicircleThumb(
      Color backgroundColor, Color drawColor, double height, int index) {
    return CustomPaint(
      foregroundPainter: _ArrowCustomPainter(drawColor),
      child: Material(
        elevation: 4.0,
        child: Container(
            constraints: BoxConstraints.tight(Size(height * 0.6, height))),
        color: backgroundColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(height),
          bottomLeft: Radius.circular(height),
          topRight: Radius.circular(4.0),
          bottomRight: Radius.circular(4.0),
        ),
      ),
    );
  }
}

class _ArrowCustomPainter extends CustomPainter {
  final Color drawColor;

  _ArrowCustomPainter(this.drawColor);

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.fill
      ..color = drawColor;
    const width = 12.0;
    const height = 8.0;
    final baseX = size.width / 2;
    final baseY = size.height / 2;

    canvas.drawPath(
        trianglePath(Offset(baseX - 4.0, baseY - 2.0), width, height, true),
        paint);
    canvas.drawPath(
        trianglePath(Offset(baseX - 4.0, baseY + 2.0), width, height, false),
        paint);
  }

  static Path trianglePath(
      Offset offset, double width, double height, bool isUp) {
    return Path()
      ..moveTo(offset.dx, offset.dy)
      ..lineTo(offset.dx + width, offset.dy)
      ..lineTo(offset.dx + (width / 2),
          isUp ? offset.dy - height : offset.dy + height)
      ..close();
  }
}

class _ArrowClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    double arrowWidth = 8.0;
    double startPointX = (size.width - arrowWidth) / 2;
    double startPointY1 = size.height / 2 - arrowWidth / 2;
    double startPointY2 = size.height / 2 + arrowWidth / 2;

    return Path()
      ..lineTo(0.0, size.height)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width, 0.0)
      ..lineTo(0.0, 0.0)
      ..close()
      ..moveTo(startPointX, startPointY1)
      ..lineTo(startPointX + arrowWidth / 2, startPointY1 - arrowWidth / 2)
      ..lineTo(startPointX + arrowWidth, startPointY1)
      ..lineTo(startPointX + arrowWidth, startPointY1 + 1.0)
      ..lineTo(
          startPointX + arrowWidth / 2, startPointY1 - arrowWidth / 2 + 1.0)
      ..lineTo(startPointX, startPointY1 + 1.0)
      ..close()
      ..moveTo(startPointX + arrowWidth, startPointY2)
      ..lineTo(startPointX + arrowWidth / 2, startPointY2 + arrowWidth / 2)
      ..lineTo(startPointX, startPointY2)
      ..lineTo(startPointX, startPointY2 - 1.0)
      ..lineTo(
          startPointX + arrowWidth / 2, startPointY2 + arrowWidth / 2 - 1.0)
      ..lineTo(startPointX + arrowWidth, startPointY2 - 1.0)
      ..close();
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
