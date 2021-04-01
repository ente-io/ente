import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/utils/toast_util.dart';
import 'package:share/share.dart';
import 'dart:io' as io;

class RecoveryKeyDialog extends StatefulWidget {
  final String recoveryKey;
  final String doneText;
  final Function() onDone;

  RecoveryKeyDialog(this.recoveryKey, this.doneText, this.onDone, {Key key})
      : super(key: key);

  @override
  _RecoveryKeyDialogState createState() => _RecoveryKeyDialogState();
}

class _RecoveryKeyDialogState extends State<RecoveryKeyDialog> {
  bool _hasTriedToSave = false;
  final _recoveryKeyFile = io.File(
      Configuration.instance.getTempDirectory() + "ente-recovery-key.txt");

  @override
  Widget build(BuildContext context) {
    final recoveryKey = widget.recoveryKey;
    List<Widget> actions = [];
    if (!_hasTriedToSave) {
      actions.add(TextButton(
        child: Text(
          "save later",
          style: TextStyle(
            color: Colors.red,
          ),
        ),
        onPressed: () async {
          _saveKeys();
        },
      ));
    }
    actions.add(
      TextButton(
        child: Text(
          "save",
          style: TextStyle(
            color: Theme.of(context).buttonColor,
          ),
        ),
        onPressed: () {
          _shareRecoveryKey(recoveryKey);
        },
      ),
    );
    if (_hasTriedToSave) {
      actions.add(
        TextButton(
          child: Text(
            widget.doneText,
            style: TextStyle(
              color: Colors.white,
            ),
          ),
          onPressed: () async {
            _saveKeys();
          },
        ),
      );
    }
    return AlertDialog(
      title: Text("recovery key"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "if you forget your password, the only way you can recover your data is with this key",
              style: TextStyle(height: 1.2),
            ),
            Padding(padding: EdgeInsets.all(8)),
            GestureDetector(
              onTap: () async {
                await Clipboard.setData(new ClipboardData(text: recoveryKey));
                showToast("recovery key copied to clipboard");
                setState(() {
                  _hasTriedToSave = true;
                });
              },
              child: Container(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    recoveryKey,
                    style: TextStyle(
                      fontSize: 16,
                      fontFeatures: [FontFeature.tabularFigures()],
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ),
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            Padding(padding: EdgeInsets.all(8)),
            Text(
              "we don't store this key",
            ),
            Padding(padding: EdgeInsets.all(8)),
            Text(
              "please save this in a safe place",
            ),
          ],
        ),
      ),
      actions: actions,
    );
  }

  Future _shareRecoveryKey(String recoveryKey) async {
    if (_recoveryKeyFile.existsSync()) {
      _recoveryKeyFile.deleteSync();
    }
    _recoveryKeyFile.writeAsStringSync(recoveryKey);
    await Share.shareFiles([_recoveryKeyFile.path]);
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _hasTriedToSave = true;
        });
      }
    });
  }

  void _saveKeys() async {
    Navigator.of(context, rootNavigator: true).pop();
    if (_recoveryKeyFile.existsSync()) {
      _recoveryKeyFile.deleteSync();
    }
    widget.onDone();
  }
}
