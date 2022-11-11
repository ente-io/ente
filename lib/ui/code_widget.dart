import 'dart:async';

import 'package:clipboard/clipboard.dart';
import 'package:ente_auth/ente_theme_data.dart';
import 'package:ente_auth/models/code.dart';
import 'package:ente_auth/store/code_store.dart';
import 'package:ente_auth/utils/toast_util.dart';
import 'package:ente_auth/utils/totp_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animation_progress_bar/flutter_animation_progress_bar.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class CodeWidget extends StatefulWidget {
  final Code code;

  const CodeWidget(this.code, {Key? key}) : super(key: key);

  @override
  State<CodeWidget> createState() => _CodeWidgetState();
}

class _CodeWidgetState extends State<CodeWidget> {
  Timer? _everySecondTimer;
  int _timeRemaining = 30;

  @override
  void initState() {
    super.initState();
    _updateTimeRemaining();
    _everySecondTimer =
        Timer.periodic(const Duration(milliseconds: 200), (Timer t) {
      setState(() {
        _updateTimeRemaining();
      });
    });
  }

  void _updateTimeRemaining() {
    _timeRemaining =
        widget.code.period - (DateTime.now().second % widget.code.period);
  }

  @override
  void dispose() {
    _everySecondTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 8, top: 8),
      child: Slidable(
        key: ValueKey(widget.code.hashCode),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: _onDeletePressed,
              backgroundColor: Colors.grey.withOpacity(0.1),
              borderRadius: const BorderRadius.all(Radius.circular(12.0)),
              foregroundColor: const Color(0xFFFE4A49),
              icon: Icons.delete,
              label: 'Delete',
              padding: const EdgeInsets.only(left: 0, right: 0),
            ),
          ],
        ),
        child: Container(
          margin: const EdgeInsets.only(right: 10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              color: Theme.of(context).colorScheme.codeCardBackgroundColor,
              child: InkWell(
                customBorder: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                onTap: () {
                  FlutterClipboard.copy(_getTotp()).then(
                    (value) => showToast(context, "Copied to clipboard"),
                  );
                },
                child: SizedBox(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FAProgressBar(
                        currentValue: _timeRemaining / widget.code.period * 100,
                        size: 4,
                        animatedDuration: const Duration(milliseconds: 200),
                        progressColor: Colors.orange,
                        changeColorValue: 40,
                        changeProgressColor: Colors.green,
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 16, right: 16),
                        child: Text(
                          Uri.decodeFull(widget.code.issuer),
                          style: Theme.of(context).textTheme.headline6,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.only(right: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              "next",
                              style: Theme.of(context).textTheme.caption,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.only(left: 16, right: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                _getTotp(),
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                            Text(
                              _getNextTotp(),
                              style: const TextStyle(
                                fontSize: 24,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onDeletePressed(_) {
    final AlertDialog alert = AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      title: Text(
        "Delete code?",
        style: Theme.of(context).textTheme.headline6,
      ),
      content: const Text(
        "Are you sure you want to delete this code? This action is irreversible.",
      ),
      actions: [
        TextButton(
          child: const Text(
            "Delete",
            style: TextStyle(
              color: Colors.red,
            ),
          ),
          onPressed: () {
            CodeStore.instance.removeCode(widget.code);
            Navigator.of(context, rootNavigator: true).pop('dialog');
          },
        ),
        TextButton(
          child: Text(
            "Cancel",
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop('dialog');
          },
        ),
      ],
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
      barrierColor: Colors.black12,
    );
  }

  String _getTotp() {
    try {
      return getTotp(widget.code);
    } catch (e) {
      return "Error";
    }
  }

  String _getNextTotp() {
    try {
      return getNextTotp(widget.code);
    } catch (e) {
      return "Error";
    }
  }
}
