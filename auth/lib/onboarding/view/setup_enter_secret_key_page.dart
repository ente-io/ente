import 'dart:async';

import 'package:ente_auth/core/event_bus.dart';
import 'package:ente_auth/events/codes_updated_event.dart';
import "package:ente_auth/l10n/l10n.dart";
import 'package:ente_auth/models/all_icon_data.dart';
import 'package:ente_auth/models/code.dart';
import 'package:ente_auth/models/code_display.dart';
import 'package:ente_auth/onboarding/model/tag_enums.dart';
import 'package:ente_auth/onboarding/view/common/add_chip.dart';
import 'package:ente_auth/onboarding/view/common/add_tag.dart';
import 'package:ente_auth/onboarding/view/common/field_label.dart';
import 'package:ente_auth/onboarding/view/common/tag_chip.dart';
import 'package:ente_auth/store/code_display_store.dart';
import 'package:ente_auth/theme/ente_theme.dart';
import 'package:ente_auth/ui/components/buttons/button_widget.dart';
import 'package:ente_auth/ui/components/custom_icon_widget.dart';
import 'package:ente_auth/ui/components/models/button_result.dart';
import 'package:ente_auth/ui/custom_icon_page.dart';
import 'package:ente_auth/ui/utils/icon_utils.dart';
import 'package:ente_auth/utils/dialog_util.dart';
import 'package:ente_auth/utils/toast_util.dart';
import 'package:ente_auth/utils/totp_util.dart';
import "package:flutter/material.dart";
import 'package:logging/logging.dart';

class SetupEnterSecretKeyPage extends StatefulWidget {
  final Code? code;

  SetupEnterSecretKeyPage({this.code, super.key});

  @override
  State<SetupEnterSecretKeyPage> createState() =>
      _SetupEnterSecretKeyPageState();
}

class _SetupEnterSecretKeyPageState extends State<SetupEnterSecretKeyPage> {
  final Logger _logger = Logger('_SetupEnterSecretKeyPageState');
  final int _notesLimit = 500;
  final int _otherTextLimit = 200;
  late TextEditingController _issuerController;
  late TextEditingController _accountController;
  late TextEditingController _secretController;
  late TextEditingController _notesController;
  late bool _secretKeyObscured;
  late List<String> selectedTags = [...?widget.code?.display.tags];
  List<String> allTags = [];
  StreamSubscription<CodesUpdatedEvent>? _streamSubscription;
  bool isCustomIcon = false;
  String _customIconID = "";
  late IconType _iconSrc;

  @override
  void initState() {
    _issuerController = TextEditingController(
      text: widget.code != null ? safeDecode(widget.code!.issuer).trim() : null,
    );
    _accountController = TextEditingController(
      text:
          widget.code != null ? safeDecode(widget.code!.account).trim() : null,
    );
    _secretController = TextEditingController(
      text: widget.code?.secret,
    );
    _notesController = TextEditingController(
      text: widget.code?.display.note,
    );
    _secretKeyObscured = widget.code != null;
    _loadTags();
    _streamSubscription = Bus.instance.on<CodesUpdatedEvent>().listen((event) {
      _loadTags();
    });
    _notesController.addListener(() {
      if (_notesController.text.length > _notesLimit) {
        _notesController.text = _notesController.text.substring(0, _notesLimit);
        _notesController.selection = TextSelection.fromPosition(
          TextPosition(offset: _notesController.text.length),
        );
        showToast(context, context.l10n.notesLengthLimit(_notesLimit));
      }
    });

    if (widget.code == null ||
        (widget.code!.issuer.length < _otherTextLimit &&
            widget.code!.account.length < _otherTextLimit &&
            widget.code!.secret.length < _otherTextLimit)) {
      _limitTextLength(_issuerController, _otherTextLimit);
      _limitTextLength(_accountController, _otherTextLimit);
      _limitTextLength(_secretController, _otherTextLimit);
    }

    isCustomIcon = widget.code?.display.isCustomIcon ?? false;
    if (isCustomIcon) {
      _customIconID = widget.code?.display.iconID ?? "ente";
    } else {
      if (widget.code != null) {
        _customIconID = widget.code!.issuer;
      }
    }
    _iconSrc = widget.code?.display.iconSrc == "simpleIcon"
        ? IconType.simpleIcon
        : IconType.customIcon;

    super.initState();
  }

  void _limitTextLength(TextEditingController controller, int limit) {
    controller.addListener(() {
      if (controller.text.length > limit) {
        controller.text = controller.text.substring(0, limit);
        controller.selection = TextSelection.fromPosition(
          TextPosition(offset: controller.text.length),
        );
      }
    });
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _issuerController.dispose();
    _accountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadTags() async {
    allTags = await CodeDisplayStore.instance.getAllTags();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.importAccountPageTitle)),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (widget.code != null)
                GestureDetector(
                  onTap: () async {
                    await navigateToCustomIconPage();
                  },
                  child: CustomIconWidget(iconData: _customIconID),
                ),
              const SizedBox(height: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      FieldLabel(l10n.codeIssuerHint),
                      Expanded(
                        child: TextFormField(
                          // The validator receives the text that the user has entered.
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Please enter some text";
                            }
                            return null;
                          },
                          decoration: const InputDecoration(
                            contentPadding:
                                EdgeInsets.symmetric(vertical: 12.0),
                          ),
                          style: getEnteTextTheme(context).small,
                          controller: _issuerController,
                          autofocus: true,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      FieldLabel(l10n.secret),
                      Expanded(
                        child: TextFormField(
                          // The validator receives the text that the user has entered.
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Please enter some text";
                            }
                            return null;
                          },
                          style: getEnteTextTheme(context).small,
                          decoration: InputDecoration(
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 12.0),
                            suffixIcon: GestureDetector(
                              // padding: EdgeInsets.zero,
                              onTap: () {
                                setState(() {
                                  _secretKeyObscured = !_secretKeyObscured;
                                });
                              },
                              child: _secretKeyObscured
                                  ? const Icon(
                                      Icons.visibility_off_rounded,
                                      size: 18,
                                    )
                                  : const Icon(
                                      Icons.visibility_rounded,
                                      size: 18,
                                    ),
                            ),
                          ),
                          obscureText: _secretKeyObscured,
                          controller: _secretController,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      FieldLabel(l10n.account),
                      Expanded(
                        child: TextFormField(
                          // The validator receives the text that the user has entered.
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Please enter some text";
                            }
                            return null;
                          },
                          decoration: const InputDecoration(
                            contentPadding:
                                EdgeInsets.symmetric(vertical: 12.0),
                          ),
                          style: getEnteTextTheme(context).small,
                          controller: _accountController,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      FieldLabel(l10n.notes),
                      Expanded(
                        child: TextFormField(
                          // The validator receives the text that the user has entered.
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Please enter some text";
                            }
                            if (value.length > _notesLimit) {
                              return "Notes can't be more than 1000 characters";
                            }
                            return null;
                          },
                          maxLength: _notesLimit,
                          minLines: 1,
                          maxLines: 5,
                          decoration: const InputDecoration(
                            contentPadding:
                                EdgeInsets.symmetric(vertical: 12.0),
                          ),
                          style: getEnteTextTheme(context).small,
                          controller: _notesController,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    alignment: WrapAlignment.start,
                    children: [
                      ...allTags.map(
                        (e) => TagChip(
                          label: e,
                          action: TagChipAction.check,
                          state: selectedTags.contains(e)
                              ? TagChipState.selected
                              : TagChipState.unselected,
                          onTap: () {
                            if (selectedTags.contains(e)) {
                              selectedTags.remove(e);
                            } else {
                              selectedTags.add(e);
                            }
                            setState(() {});
                          },
                        ),
                      ),
                      AddChip(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AddTagDialog(
                                onTap: (tag) {
                                  final exist = allTags.contains(tag);
                                  if (exist && selectedTags.contains(tag)) {
                                    return Navigator.pop(context);
                                  }
                                  if (!exist) allTags.add(tag);
                                  selectedTags.add(tag);
                                  setState(() {});
                                  Navigator.pop(context);
                                },
                              );
                            },
                            barrierColor: Colors.black.withOpacity(0.85),
                            barrierDismissible: false,
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: 400,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onPressed: () async {
                        if ((_accountController.text.trim().isEmpty &&
                                _issuerController.text.trim().isEmpty) ||
                            _secretController.text.trim().isEmpty) {
                          String message;
                          if (_secretController.text.trim().isEmpty) {
                            message = context.l10n.secretCanNotBeEmpty;
                          } else {
                            message =
                                context.l10n.bothIssuerAndAccountCanNotBeEmpty;
                          }
                          _showIncorrectDetailsDialog(
                            context,
                            message: message,
                          );
                          return;
                        }
                        await _saveCode();
                      },
                      child: Text(l10n.saveAction),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveCode() async {
    try {
      final account = _accountController.text.trim();
      final issuer = _issuerController.text.trim();
      final secret = _secretController.text.trim().replaceAll(' ', '');
      final notes = _notesController.text.trim();
      final isStreamCode = issuer.toLowerCase() == "steam" ||
          issuer.toLowerCase().contains('steampowered.com');
      final CodeDisplay display =
          widget.code?.display.copyWith(tags: selectedTags) ??
              CodeDisplay(tags: selectedTags);
      display.note = notes;
      if (widget.code != null) {
        if (widget.code!.issuer != issuer) {
          display.iconID = issuer.toLowerCase();
        }
        if (widget.code!.display.iconID != _customIconID.toLowerCase()) {
          display.iconID = _customIconID.toLowerCase();
        }
      }

      display.iconSrc =
          _iconSrc == IconType.simpleIcon ? 'simpleIcon' : 'customIcon';

      if (widget.code != null && widget.code!.secret != secret) {
        ButtonResult? result = await showChoiceActionSheet(
          context,
          title: context.l10n.warning,
          body: context.l10n.confirmUpdatingkey,
          firstButtonLabel: context.l10n.yes,
          secondButtonAction: ButtonAction.cancel,
          secondButtonLabel: context.l10n.cancel,
        );
        if (result == null) return;
        if (result.action != ButtonAction.first) {
          return;
        }
      }

      final Code newCode = widget.code == null
          ? Code.fromAccountAndSecret(
              isStreamCode ? Type.steam : Type.totp,
              account,
              issuer,
              secret,
              display,
              isStreamCode ? Code.steamDigits : Code.defaultDigits,
            )
          : widget.code!.copyWith(
              account: account,
              issuer: issuer,
              secret: secret,
              display: display,
            );
      // Verify the validity of the code
      getOTP(newCode);
      Navigator.of(context).pop(newCode);
    } catch (e, s) {
      _logger.severe("Error saving code", e, s);
      _showIncorrectDetailsDialog(context);
    }
  }

  void _showIncorrectDetailsDialog(
    BuildContext context, {
    String? message,
  }) {
    showErrorDialog(
      context,
      context.l10n.incorrectDetails,
      message ?? context.l10n.pleaseVerifyDetails,
    );
  }

  Future<void> navigateToCustomIconPage() async {
    final allIcons = IconUtils.instance.getAllIcons();
    String currentIcon;
    if (widget.code!.display.isCustomIcon) {
      currentIcon = widget.code!.display.iconID;
    } else {
      currentIcon = widget.code!.issuer;
    }
    final AllIconData newCustomIcon = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return CustomIconPage(
            currentIcon: currentIcon,
            allIcons: allIcons,
          );
        },
      ),
    );
    setState(() {
      _customIconID = newCustomIcon.title;
      _iconSrc = newCustomIcon.type;
    });
  }
}
