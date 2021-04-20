import 'package:flutter/material.dart';

class ScrollBarThumb extends StatelessWidget {
  final backgroundColor;
  final drawColor;
  final height;
  final title;
  final animation;

  const ScrollBarThumb(
    this.backgroundColor,
    this.drawColor,
    this.height,
    this.title,
    this.animation, {
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FadeTransition(
          opacity: animation,
          child: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.white.withOpacity(0.8),
            ),
            child: Text(
              title,
              style: TextStyle(
                color: Colors.black,
                backgroundColor: Colors.transparent,
                fontSize: 14,
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(2),
        ),
        CustomPaint(
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
        ),
      ],
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
