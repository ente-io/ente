import 'dart:math' as math;

import 'package:ente_components/theme/text_styles.dart';
import 'package:ente_components/theme/theme.dart';
import 'package:flutter/material.dart';

// Figma: https://www.figma.com/design/BuBNPPytxlVnqfmCUW0mgz/Ente-Visual-Design?node-id=7884-4001&m=dev
enum LoadingComponentSize {
  small(16, 2),
  medium(24, 2.5),
  large(40, 3);

  const LoadingComponentSize(this.diameter, this.stroke);

  final double diameter;
  final double stroke;
}

class LoadingComponent extends StatefulWidget {
  const LoadingComponent({
    super.key,
    this.size = LoadingComponentSize.medium,
    this.value,
    this.color,
    this.semanticsLabel,
  });

  final LoadingComponentSize size;
  final double? value;
  final Color? color;
  final String? semanticsLabel;

  @override
  State<LoadingComponent> createState() => _LoadingComponentState();
}

class _LoadingComponentState extends State<LoadingComponent>
    with SingleTickerProviderStateMixin {
  late final _turn = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  );

  @override
  void initState() {
    super.initState();
    _syncTurn();
  }

  @override
  void didUpdateWidget(covariant LoadingComponent oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncTurn();
  }

  void _syncTurn() {
    if (widget.value == null) {
      if (!_turn.isAnimating) _turn.repeat();
    } else {
      _turn.stop();
    }
  }

  @override
  void dispose() {
    _turn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.value;
    final percent = value == null ? null : '${(value * 100).round()}%';
    final color = widget.color ?? context.componentColors.primary;
    return Semantics(
      label: widget.semanticsLabel,
      value: percent,
      child: SizedBox.square(
        dimension: widget.size.diameter,
        child: RepaintBoundary(
          child: CustomPaint(
            painter: _LoadingPainter(
              color: color,
              stroke: widget.size.stroke,
              value: value,
              turn: _turn,
            ),
            child: percent != null && widget.size == LoadingComponentSize.large
                ? Center(
                    child: ExcludeSemantics(
                      child: Text(
                        percent,
                        style: TextStyles.mini.copyWith(color: color),
                      ),
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

class _LoadingPainter extends CustomPainter {
  _LoadingPainter({
    required this.color,
    required this.stroke,
    required this.value,
    required this.turn,
  }) : super(repaint: value == null ? turn : null);

  final Color color;
  final double stroke;
  final double? value;
  final Animation<double> turn;

  @override
  void paint(Canvas canvas, Size size) {
    final rect =
        Offset(stroke / 2, stroke / 2) &
        Size(size.width - stroke, size.height - stroke);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawOval(rect, paint..color = color.withValues(alpha: 0.16));
    paint.color = color;
    final value = this.value;
    if (value == null) {
      canvas.drawArc(
        rect,
        -math.pi / 2 + 2 * math.pi * turn.value,
        math.pi / 2,
        false,
        paint,
      );
    } else if (value > 0) {
      canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * value, false, paint);
    }
  }

  @override
  bool shouldRepaint(_LoadingPainter old) =>
      old.color != color || old.stroke != stroke || old.value != value;
}
