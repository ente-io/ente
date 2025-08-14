import 'dart:convert';
import 'dart:io' as io;

import 'package:bip39/bip39.dart' as bip39;
import 'package:dotted_border/dotted_border.dart';
import 'package:ente_configuration/base_configuration.dart';
import 'package:ente_configuration/constants.dart';
import 'package:ente_strings/ente_strings.dart';
import 'package:ente_ui/components/buttons/gradient_button.dart';
import 'package:ente_ui/theme/ente_theme.dart';
import "package:ente_ui/theme/ente_theme_data.dart";
import 'package:ente_ui/utils/toast_util.dart';
import 'package:ente_utils/platform_util.dart';
import 'package:ente_utils/share_utils.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:step_progress_indicator/step_progress_indicator.dart';

class RecoveryKeyPage extends StatefulWidget {
  final BaseConfiguration config;
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
    this.config,
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
  late final io.File _recoveryKeyFile;

  @override
  void initState() {
    super.initState();
    _recoveryKeyFile = io.File(
      "${widget.config.getTempDirectory()}ente-recovery-key.txt",
    );
  }

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

    Future<void> copy() async {
      await Clipboard.setData(
        ClipboardData(
          text: recoveryKey,
        ),
      );
      showShortToast(
        context,
        context.strings.recoveryKeyCopiedToClipboard,
      );
      setState(() {
        _hasTriedToSave = true;
      });
    }

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
                  selectedColor: getEnteColorScheme(context).alternativeColor,
                  roundedEdges: const Radius.circular(10),
                  unselectedColor:
                      getEnteColorScheme(context).stepProgressUnselectedColor,
                ),
              ),
            )
          : widget.showAppBar!
              ? AppBar(
                  elevation: 0,
                  title: Text(widget.title ?? context.strings.recoveryKey),
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
                              widget.title ?? context.strings.recoveryKey,
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                      Padding(
                        padding: EdgeInsets.all(widget.showAppBar! ? 0 : 12),
                      ),
                      Text(
                        widget.text ??
                            context.strings.recoveryKeyOnForgotPassword,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Padding(padding: EdgeInsets.only(top: 24)),
                      Container(
                        padding: const EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              getEnteColorScheme(context).primary700,
                              getEnteColorScheme(context).primary300,
                            ],
                            stops: const [0.0, 0.9753],
                          ),
                        ),
                        child: DottedBorder(
                          options: const RoundedRectDottedBorderOptions(
                            padding: EdgeInsets.zero,
                            strokeWidth: 1,
                            color: Color(0xFF6B6B6B),
                            dashPattern: [6, 6],
                            radius: Radius.circular(8),
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            child: Stack(
                              children: [
                                Column(
                                  children: [
                                    Builder(
                                      builder: (context) {
                                        final content = Container(
                                          padding: const EdgeInsets.all(20),
                                          width: double.infinity,
                                          child: Text(
                                            recoveryKey,
                                            textAlign: TextAlign.justify,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge,
                                          ),
                                        );

                                        if (PlatformUtil.isMobile()) {
                                          return GestureDetector(
                                            onTap: () async => await copy(),
                                            child: content,
                                          );
                                        } else {
                                          return SelectableRegion(
                                            focusNode: FocusNode(),
                                            selectionControls:
                                                PlatformUtil.selectionControls,
                                            child: content,
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                ),
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: PlatformCopy(
                                    onPressed: copy,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          widget.subText ??
                              context.strings.recoveryKeySaveDescription,
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
                  ),
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
        SizedBox(
          height: 56,
          child: ElevatedButton(
            style: Theme.of(context).colorScheme.optionalActionButtonStyle,
            onPressed: () async {
              await _saveKeys();
            },
            child: Text(context.strings.doThisLater),
          ),
        ),
      );
      childrens.add(const SizedBox(height: 10));
    }

    childrens.add(
      GradientButton(
        onTap: () async {
          await shareDialog(
            context,
            context.strings.recoveryKey,
            saveAction: () async {
              await _saveRecoveryKey(recoveryKey);
            },
            sendAction: () async {
              await _shareRecoveryKey(recoveryKey);
            },
          );
        },
        text: context.strings.saveKey,
      ),
    );

    if (_hasTriedToSave) {
      childrens.add(const SizedBox(height: 10));
      childrens.add(
        SizedBox(
          height: 56,
          child: ElevatedButton(
            child: Text(widget.doneText),
            onPressed: () async {
              await _saveKeys();
            },
          ),
        ),
      );
    }
    childrens.add(const SizedBox(height: 12));
    return childrens;
  }

  Future _saveRecoveryKey(String recoveryKey) async {
    final bytes = utf8.encode(recoveryKey);
    final time = DateTime.now().millisecondsSinceEpoch;

    await PlatformUtil.shareFile(
      "ente_recovery_key_$time",
      "txt",
      bytes,
      MimeType.text,
    );

    if (mounted) {
      showToast(
        context,
        context.strings.recoveryKeySaved,
      );
      setState(() {
        _hasTriedToSave = true;
      });
    }
  }

  Future _shareRecoveryKey(String recoveryKey) async {
    if (_recoveryKeyFile.existsSync()) {
      await _recoveryKeyFile.delete();
    }
    _recoveryKeyFile.writeAsStringSync(recoveryKey);
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile(_recoveryKeyFile.path),
        ],
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

class PlatformCopy extends StatelessWidget {
  const PlatformCopy({
    super.key,
    required this.onPressed,
  });

  final void Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => onPressed(),
      visualDensity: VisualDensity.compact,
      icon: const Icon(
        Icons.copy,
        size: 16,
      ),
    );
  }
}
