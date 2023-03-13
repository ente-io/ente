import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animation_progress_bar/flutter_animation_progress_bar.dart';

class CodeTimerProgress extends StatefulWidget {
  final int period;

  CodeTimerProgress({
    Key? key,
    required this.period,
  }) : super(key: key);

  @override
  _CodeTimerProgressState createState() => _CodeTimerProgressState();
}

class _CodeTimerProgressState extends State<CodeTimerProgress>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  double _progress = 0.0;
  late final int _microSecondsInPeriod;

  @override
  void initState() {
    super.initState();
    _microSecondsInPeriod = widget.period * 1000000;
    _ticker = createTicker((elapsed) {
      _updateTimeRemaining();
    });
    _ticker.start();
    _updateTimeRemaining();
  }

  void _updateTimeRemaining() {
    int timeRemaining = (_microSecondsInPeriod) -
        (DateTime.now().microsecondsSinceEpoch % _microSecondsInPeriod);
    setState(() {
      _progress = (timeRemaining / _microSecondsInPeriod);
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FAProgressBar(
      currentValue: _progress * 100,
      size: 4,
      animatedDuration: const Duration(milliseconds: 10),
      progressColor: Colors.orange,
      changeColorValue: 40,
      changeProgressColor: Colors.green,
    );
  }
}
