import 'dart:async';

import 'package:clipboard/clipboard.dart';
import 'package:ente_auth/ente_theme_data.dart';
import 'package:ente_auth/l10n/l10n.dart';
import 'package:ente_auth/models/code.dart';
import 'package:ente_auth/onboarding/view/setup_enter_secret_key_page.dart';
import 'package:ente_auth/store/code_store.dart';
import 'package:ente_auth/ui/code_timer_progress.dart';
import 'package:ente_auth/utils/toast_util.dart';
import 'package:ente_auth/utils/totp_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:logging/logging.dart';

class CodeWidget extends StatefulWidget {
  final Code code;

  const CodeWidget(this.code, {Key? key}) : super(key: key);

  @override
  State<CodeWidget> createState() => _CodeWidgetState();
}

class _CodeWidgetState extends State<CodeWidget> {
  Timer? _everySecondTimer;
  final ValueNotifier<String> _currentCode = ValueNotifier<String>("");
  final ValueNotifier<String> _nextCode = ValueNotifier<String>("");
  final Logger logger = Logger("_CodeWidgetState");

  @override
  void initState() {
    super.initState();
    _currentCode.value = _getTotp();
    _nextCode.value = _getNextTotp();
    _everySecondTimer =
        Timer.periodic(const Duration(milliseconds: 500), (Timer t) {
      String newCode = _getTotp();
      if (newCode != _currentCode.value) {
        _currentCode.value = newCode;
        _nextCode.value = _getNextTotp();
      }
    });
  }

  @override
  void dispose() {
    _everySecondTimer?.cancel();
    _currentCode.dispose();
    _nextCode.dispose();
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
              label: l10n.edit,
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
              label: l10n.delete,
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
                        CodeTimerProgress(
                          period: widget.code.period,
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
                                    safeDecode(widget.code.issuer).trim(),
                                    style:
                                        Theme.of(context).textTheme.headline6,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    safeDecode(widget.code.account).trim(),
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
                                child: ValueListenableBuilder<String>(
                                  valueListenable: _currentCode,
                                  builder: (context, value, child) {
                                    return Text(
                                      value,
                                      style: const TextStyle(fontSize: 24),
                                    );
                                  },
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    l10n.nextTotpTitle,
                                    style: Theme.of(context).textTheme.caption,
                                  ),
                                  ValueListenableBuilder<String>(
                                    valueListenable: _nextCode,
                                    builder: (context, value, child) {
                                      return Text(
                                        value,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          color: Colors.grey,
                                        ),
                                      );
                                    },
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
    FlutterClipboard.copy(_getTotp())
        .then((value) => showToast(context, context.l10n.copiedToClipboard));
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
            l10n.cancel,
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

  String safeDecode(String value) {
    try {
      return Uri.decodeComponent(value);
    } catch (e) {
      // note: don't log the value, it might contain sensitive information
      logger.severe("Failed to decode", e);
      return value;
    }
  }

  String _getTotp() {
    try {
      return getTotp(widget.code);
    } catch (e) {
      return context.l10n.error;
    }
  }

  String _getNextTotp() {
    try {
      return getNextTotp(widget.code);
    } catch (e) {
      return context.l10n.error;
    }
  }
}
