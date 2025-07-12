import "dart:async";
import 'dart:io';

import 'package:bip39/bip39.dart' as bip39;
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/ente_theme_data.dart';
import "package:photos/generated/l10n.dart";
import 'package:photos/ui/common/gradient_button.dart';
import 'package:photos/ui/notification/toast.dart';
import "package:share_plus/share_plus.dart";
import 'package:step_progress_indicator/step_progress_indicator.dart';

class RecoveryKeyPage extends StatefulWidget {
  final bool? showAppBar;
  final String recoveryKey;
  final String doneText;
  final Function()? onDone;
  final bool? isDismissible;
  final String? title;
  final String? text;
  final String? subText;
  final bool showProgressBar;

  const RecoveryKeyPage(
    this.recoveryKey,
    this.doneText, {
    super.key,
    this.showAppBar,
    this.onDone,
    this.isDismissible,
    this.title,
    this.text,
    this.subText,
    this.showProgressBar = false,
  });

  @override
  State<RecoveryKeyPage> createState() => _RecoveryKeyPageState();
}

class _RecoveryKeyPageState extends State<RecoveryKeyPage> {
  bool _hasTriedToSave = false;
  final _recoveryKeyFile = File(
    Configuration.instance.getTempDirectory() + "ente-recovery-key.txt",
  );

  @override
  Widget build(BuildContext context) {
    final String recoveryKey = bip39.entropyToMnemonic(widget.recoveryKey);
    if (recoveryKey.split(' ').length != mnemonicKeyWordCount) {
      throw AssertionError(
        'recovery code should have $mnemonicKeyWordCount words',
      );
    }
    final double topPadding = widget.showAppBar!
        ? 40
        : widget.showProgressBar
            ? 32
            : 120;

    return Scaffold(
      appBar: widget.showProgressBar
          ? AppBar(
              automaticallyImplyLeading: false,
              elevation: 0,
              title: Hero(
                tag: "recovery_key",
                child: StepProgressIndicator(
                  totalSteps: 4,
                  currentStep: 3,
                  selectedColor: Theme.of(context).colorScheme.greenAlternative,
                  roundedEdges: const Radius.circular(10),
                  unselectedColor:
                      Theme.of(context).colorScheme.stepProgressUnselectedColor,
                ),
              ),
            )
          : widget.showAppBar!
              ? AppBar(
                  elevation: 0,
                  title: Text(widget.title ?? S.of(context).recoveryKey),
                )
              : null,
      body: Padding(
        padding: EdgeInsets.fromLTRB(20, topPadding, 20, 20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: constraints.maxWidth,
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      widget.showAppBar!
                          ? const SizedBox.shrink()
                          : Text(
                              widget.title ?? S.of(context).recoveryKey,
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                      Padding(
                        padding: EdgeInsets.all(widget.showAppBar! ? 0 : 12),
                      ),
                      Text(
                        widget.text ??
                            S.of(context).recoveryKeyOnForgotPassword,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Padding(padding: EdgeInsets.only(top: 24)),
                      DottedBorder(
                        color: const Color.fromRGBO(17, 127, 56, 1),
                        //color of dotted/dash line
                        strokeWidth: 1,
                        //thickness of dash/dots
                        dashPattern: const [6, 6],
                        radius: const Radius.circular(8),
                        //dash patterns, 10 is dash width, 6 is space width
                        child: SizedBox(
                          //inner container
                          // height: 120, //height of inner container
                          width: double
                              .infinity, //width to 100% match to parent container.
                          // ignore: prefer_const_literals_to_create_immutables
                          child: Column(
                            children: [
                              GestureDetector(
                                onTap: () async {
                                  await Clipboard.setData(
                                    ClipboardData(text: recoveryKey),
                                  );
                                  showShortToast(
                                    context,
                                    S.of(context).recoveryKeyCopiedToClipboard,
                                  );
                                  setState(() {
                                    _hasTriedToSave = true;
                                  });
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: const Color.fromRGBO(
                                        49,
                                        155,
                                        86,
                                        .2,
                                      ),
                                    ),
                                    borderRadius: const BorderRadius.all(
                                      Radius.circular(2),
                                    ),
                                    color: Theme.of(context)
                                        .colorScheme
                                        .recoveryKeyBoxColor,
                                  ),
                                  padding: const EdgeInsets.all(20),
                                  width: double.infinity,
                                  child: Text(
                                    recoveryKey,
                                    style:
                                        Theme.of(context).textTheme.bodyLarge,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          widget.subText ??
                              S.of(context).recoveryKeySaveDescription,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                      Expanded(
                        child: Container(
                          alignment: Alignment.bottomCenter,
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(10, 10, 10, 42),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: _saveOptions(context, recoveryKey),
                          ),
                        ),
                      ),
                    ],
                  ), // columnEnds
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _saveOptions(BuildContext context, String recoveryKey) {
    final List<Widget> childrens = [];
    if (!_hasTriedToSave) {
      childrens.add(
        ElevatedButton(
          style: Theme.of(context).colorScheme.optionalActionButtonStyle,
          onPressed: () async {
            await _saveKeys();
          },
          child: Text(S.of(context).doThisLater),
        ),
      );
      childrens.add(const SizedBox(height: 10));
    }

    childrens.add(
      GradientButton(
        onTap: () async {
          await _shareRecoveryKey(recoveryKey);
        },
        text: S.of(context).saveKey,
      ),
    );
    if (_hasTriedToSave) {
      childrens.add(const SizedBox(height: 10));
      childrens.add(
        ElevatedButton(
          child: Text(widget.doneText),
          onPressed: () async {
            await _saveKeys();
          },
        ),
      );
    }
    childrens.add(const SizedBox(height: 12));
    return childrens;
  }

  Future _shareRecoveryKey(String recoveryKey) async {
    if (_recoveryKeyFile.existsSync()) {
      await _recoveryKeyFile.delete();
    }
    _recoveryKeyFile.writeAsStringSync(recoveryKey);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(_recoveryKeyFile.path)],
      ),
    );
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _hasTriedToSave = true;
        });
      }
    });
  }

  Future<void> _saveKeys() async {
    Navigator.of(context).pop();
    if (_recoveryKeyFile.existsSync()) {
      await _recoveryKeyFile.delete();
    }
    widget.onDone!();
  }
}
