import 'package:flutter/material.dart';

class ScrollBarThumb extends StatelessWidget {
  final backgroundColor;
  final drawColor;
  final height;
  final title;
  final labelAnimation;
  final thumbAnimation;

  const ScrollBarThumb(
    this.backgroundColor,
    this.drawColor,
    this.height,
    this.title,
    this.labelAnimation,
    this.thumbAnimation, {
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FadeTransition(
          opacity: labelAnimation,
          child: Container(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.grey[850],
            ),
            child: Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                backgroundColor: Colors.transparent,
                fontSize: 14,
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(12),
        ),
        SlideFadeTransition(
          animation: thumbAnimation,
          child: CustomPaint(
            foregroundPainter: _ArrowCustomPainter(drawColor),
            child: Material(
              elevation: 4.0,
              child: Container(
                  constraints:
                      BoxConstraints.tight(Size(height * 0.54, height))),
              color: backgroundColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(height),
                bottomLeft: Radius.circular(height),
                topRight: Radius.circular(4.0),
                bottomRight: Radius.circular(4.0),
              ),
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
    const width = 10.0;
    const height = 8.0;
    final baseX = size.width / 2;
    final baseY = size.height / 2;

    canvas.drawPath(
        trianglePath(Offset(baseX - 2.0, baseY - 2.0), width, height, true),
        paint);
    canvas.drawPath(
        trianglePath(Offset(baseX - 2.0, baseY + 2.0), width, height, false),
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

class SlideFadeTransition extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const SlideFadeTransition({
    Key key,
    @required this.animation,
    @required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) => animation.value == 0.0 ? Container() : child,
      child: SlideTransition(
        position: Tween(
          begin: Offset(0.3, 0.0),
          end: Offset(0.0, 0.0),
        ).animate(animation),
        child: FadeTransition(
          opacity: animation,
          child: child,
        ),
      ),
    );
  }
}
