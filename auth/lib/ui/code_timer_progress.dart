import 'package:ente_auth/ui/linear_progress_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class CodeTimerProgress extends StatefulWidget {
  final int period;

  CodeTimerProgress({
    super.key,
    required this.period,
  });

  @override
  State createState() => _CodeTimerProgressState();
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
    return LinearProgressWidget(
      color: _progress > 0.4 ? Colors.green : Colors.orange,
      fractionOfStorage: _progress,
    );
  }
}
