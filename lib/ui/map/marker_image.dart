import "package:flutter/material.dart";
import "package:photos/models/file.dart";
import "package:photos/ui/viewer/file/thumbnail_widget.dart";

class MarkerImage extends StatelessWidget {
  final File file;
  final double seperator;

  const MarkerImage({super.key, required this.file, required this.seperator});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: Colors.green,
              width: 1.75,
            ),
          ),
          child: ThumbnailWidget(file),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            margin: EdgeInsets.only(top: seperator),
            child: CustomPaint(
              painter: MarkerPointer(),
            ),
          ),
        )
      ],
    );
  }
}

class MarkerPointer extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.green;

    final path = Path();
    path.moveTo(5, -12);
    path.lineTo(0, 0);
    path.lineTo(-5, -12);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
