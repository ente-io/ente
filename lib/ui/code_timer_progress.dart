import 'dart:async';

import 'package:flutter/material.dart';
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

class _CodeTimerProgressState extends State<CodeTimerProgress> {
  Timer? _everySecondTimer;
  late int _timeRemaining;

  @override
  void initState() {
    super.initState();
    _timeRemaining = widget.period;
    _updateTimeRemaining();
    _everySecondTimer =
        Timer.periodic(const Duration(milliseconds: 200), (Timer t) {
      _updateTimeRemaining();
    });
  }

  void _updateTimeRemaining() {
    int newTimeRemaining =
        widget.period - (DateTime.now().second % widget.period);
    if (newTimeRemaining != _timeRemaining) {
      setState(() {
        _timeRemaining = newTimeRemaining;
      });
    }
  }

  @override
  void dispose() {
    _everySecondTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FAProgressBar(
      currentValue: _timeRemaining / widget.period * 100,
      size: 4,
      animatedDuration: const Duration(milliseconds: 200),
      progressColor: Colors.orange,
      changeColorValue: 40,
      changeProgressColor: Colors.green,
    );
  }
}
