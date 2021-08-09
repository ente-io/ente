import 'dart:io' as io;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/utils/toast_util.dart';
import 'package:share/share.dart';

class RecoveryKeyDialog extends StatefulWidget {
  final String recoveryKey;
  final String doneText;
  final Function() onDone;
  final bool isDismissible;
  final String title;
  final String text;
  final String subText;

  RecoveryKeyDialog(
    this.recoveryKey,
    this.doneText,
    this.onDone, {
    this.title,
    this.text,
    this.subText,
    Key key,
    this.isDismissible = true,
  }) : super(key: key);

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
          await _saveKeys();
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
            await _saveKeys();
          },
        ),
      );
    }
    return WillPopScope(
      onWillPop: () async => widget.isDismissible,
      child: AlertDialog(
        title: Text(widget.title ?? "recovery key"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.text ??
                    "if you forget your password, the only way you can recover your data is with this key",
                style: TextStyle(height: 1.2),
              ),
              Padding(padding: EdgeInsets.all(8)),
              GestureDetector(
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: recoveryKey));
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
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ),
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              Padding(padding: EdgeInsets.all(8)),
              Text(
                widget.subText ?? "we don't store this key",
              ),
              Padding(padding: EdgeInsets.all(8)),
              Text(
                "please save this in a safe place",
              ),
            ],
          ),
        ),
        actions: actions,
      ),
    );
  }

  Future _shareRecoveryKey(String recoveryKey) async {
    if (_recoveryKeyFile.existsSync()) {
      await _recoveryKeyFile.delete();
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

  Future<void> _saveKeys() async {
    Navigator.of(context, rootNavigator: true).pop();
    if (_recoveryKeyFile.existsSync()) {
      await _recoveryKeyFile.delete();
    }
    widget.onDone();
  }
}
