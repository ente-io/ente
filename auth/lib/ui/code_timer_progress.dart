import 'package:ente_auth/theme/ente_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class CodeTimerProgress extends StatefulWidget {
  final int period;

  const CodeTimerProgress({
    super.key,
    required this.period,
  });

  @override
  State<CodeTimerProgress> createState() => _CodeTimerProgressState();
}

class _CodeTimerProgressState extends State<CodeTimerProgress>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  late final ValueNotifier<double> _progress;
  late final int _microSecondsInPeriod;

  @override
  void initState() {
    super.initState();
    _microSecondsInPeriod = widget.period * 1000000;
    _progress = ValueNotifier<double>(0.0);
    _ticker = createTicker(_updateTimeRemaining);
    _ticker.start();
    _updateTimeRemaining(Duration.zero);
  }

  void _updateTimeRemaining(Duration elapsed) {
    int timeRemaining = _microSecondsInPeriod -
        (DateTime.now().microsecondsSinceEpoch % _microSecondsInPeriod);
    _progress.value = timeRemaining / _microSecondsInPeriod;
  }

  @override
  void dispose() {
    _ticker.dispose();
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 3,
      child: ValueListenableBuilder<double>(
        valueListenable: _progress,
        builder: (context, progress, _) {
          return CustomPaint(
            painter: _ProgressPainter(
              progress: progress,
              color: progress > 0.4
                  ? getEnteColorScheme(context).primary700
                  : Colors.orange,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _ProgressPainter extends CustomPainter {
  final double progress;
  final Color color;

  _ProgressPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width * progress, size.height),
      const Radius.circular(2),
    );

    canvas.drawRRect(rect, paint);
  }

  @override
  bool shouldRepaint(_ProgressPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
