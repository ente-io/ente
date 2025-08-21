import 'dart:io';

import 'package:flutter/material.dart';
import "package:photos/generated/l10n.dart";
import 'package:photos/ui/common/loading_widget.dart';

class LogFileViewer extends StatefulWidget {
  final File file;
  const LogFileViewer(this.file, {super.key});

  @override
  State<LogFileViewer> createState() => _LogFileViewerState();
}

class _LogFileViewerState extends State<LogFileViewer> {
  String? _logs;
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
        elevation: 0,
        title: Text(AppLocalizations.of(context).todaysLogs),
      ),
      body: _getBody(),
    );
  }

  Widget _getBody() {
    if (_logs == null) {
      return const EnteLoadingWidget();
    }
    return Container(
      padding: const EdgeInsets.only(left: 12, top: 8, right: 12),
      child: Scrollbar(
        interactive: true,
        thickness: 4,
        radius: const Radius.circular(2),
        child: SingleChildScrollView(
          child: Text(
            _logs!,
            style: const TextStyle(
              fontFeatures: [
                FontFeature.tabularFigures(),
              ],
              height: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}
