import 'package:flutter/material.dart';
import 'package:photos/ente_theme_data.dart';

class LinearProgressDialog extends StatefulWidget {
  final String message;

  const LinearProgressDialog(this.message, {super.key});

  @override
  LinearProgressDialogState createState() => LinearProgressDialogState();
}

class LinearProgressDialogState extends State<LinearProgressDialog> {
  double? _progress;

  @override
  void initState() {
    _progress = 0;
    super.initState();
  }

  void setProgress(double progress) {
    setState(() {
      _progress = progress;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: Text(
          widget.message,
          style: const TextStyle(
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
        content: LinearProgressIndicator(
          value: _progress,
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).colorScheme.greenAlternative,
          ),
        ),
      ),
    );
  }
}
