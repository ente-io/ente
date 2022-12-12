import 'dart:async';

import 'package:clipboard/clipboard.dart';
import 'package:ente_auth/ente_theme_data.dart';
import 'package:ente_auth/l10n/l10n.dart';
import 'package:ente_auth/models/code.dart';
import 'package:ente_auth/onboarding/view/setup_enter_secret_key_page.dart';
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
    final l10n = context.l10n;
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 8, top: 8),
      child: Slidable(
        key: ValueKey(widget.code.hashCode),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: _onEditPressed,
              backgroundColor: Colors.grey.withOpacity(0.1),
              borderRadius: const BorderRadius.all(Radius.circular(12.0)),
              foregroundColor:
                  Theme.of(context).colorScheme.inverseBackgroundColor,
              icon: Icons.edit_outlined,
              label: 'Edit',
              padding: const EdgeInsets.only(left: 4, right: 0),
              spacing: 8,
            ),
            const SizedBox(
              width: 4,
            ),
            SlidableAction(
              onPressed: _onDeletePressed,
              backgroundColor: Colors.grey.withOpacity(0.1),
              borderRadius: const BorderRadius.all(Radius.circular(12.0)),
              foregroundColor: const Color(0xFFFE4A49),
              icon: Icons.delete,
              label: 'Delete',
              padding: const EdgeInsets.only(left: 0, right: 0),
              spacing: 8,
            ),
          ],
        ),
        child: Container(
          margin: const EdgeInsets.only(right: 10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              color: Theme.of(context).colorScheme.codeCardBackgroundColor,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  customBorder: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  onTap: () {
                    _copyToClipboard();
                  },
                  onLongPress: () {
                    _copyToClipboard();
                  },
                  child: SizedBox(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FAProgressBar(
                          currentValue:
                              _timeRemaining / widget.code.period * 100,
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
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    Uri.decodeFull(widget.code.issuer).trim(),
                                    style:
                                        Theme.of(context).textTheme.headline6,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    Uri.decodeFull(
                                      widget.code.account,
                                    ).trim(),
                                    style: Theme.of(context)
                                        .textTheme
                                        .caption
                                        ?.copyWith(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                  ),
                                ],
                              ),
                              widget.code.hasSynced != null &&
                                      widget.code.hasSynced!
                                  ? Container()
                                  : const Icon(
                                      Icons.sync_disabled,
                                      size: 20,
                                      color: Colors.amber,
                                    ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.only(left: 16, right: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Text(
                                  _getTotp(),
                                  style: const TextStyle(fontSize: 24),
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    l10n.nextTotpTitle,
                                    style: Theme.of(context).textTheme.caption,
                                  ),
                                  Text(
                                    _getNextTotp(),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
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
      ),
    );
  }

  void _copyToClipboard() {
    FlutterClipboard.copy(_getTotp()).then(
      (value) => showToast(context, "Copied to clipboard"),
    );
  }

  Future<void> _onEditPressed(_) async {
    final Code? code = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) {
          return SetupEnterSecretKeyPage(code: widget.code);
        },
      ),
    );
    if (code != null) {
      CodeStore.instance.addCode(code);
    }
  }

  void _onDeletePressed(_) {
    final l10n = context.l10n;
    final AlertDialog alert = AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      title: Text(
        l10n.deleteCodeTitle,
        style: Theme.of(context).textTheme.headline6,
      ),
      content: Text(
        l10n.deleteCodeMessage,
      ),
      actions: [
        TextButton(
          child: Text(
            l10n.delete,
            style: const TextStyle(
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
