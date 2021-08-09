import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:photos/ui/loading_widget.dart';

class LogFileViewer extends StatefulWidget {
  final File file;
  const LogFileViewer(this.file, {Key key}) : super(key: key);

  @override
  _LogFileViewerState createState() => _LogFileViewerState();
}

class _LogFileViewerState extends State<LogFileViewer> {
  String _logs;
  @override
  void initState() {
    widget.file.readAsString().then((logs) {
      setState(() {
        _logs = logs;
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("today's logs"),
      ),
      body: _getBody(),
    );
  }

  Widget _getBody() {
    if (_logs == null) {
      return loadWidget;
    }
    return Container(
      padding: EdgeInsets.only(left: 12, top: 8, right: 12),
      child: SingleChildScrollView(
        child: Text(
          _logs,
          style: TextStyle(
            fontFeatures: const [
              FontFeature.tabularFigures(),
            ],
            color: Colors.white.withOpacity(0.7),
            height: 1.2,
          ),
        ),
      ),
    );
  }
}
