import "package:ente_auth/l10n/l10n.dart";
import 'package:ente_auth/models/code.dart';
import 'package:ente_auth/models/code_display.dart';
import 'package:ente_auth/store/code_store.dart';
import 'package:ente_auth/ui/components/buttons/button_widget.dart';
import 'package:ente_auth/ui/components/models/button_result.dart';
import 'package:ente_auth/utils/dialog_util.dart';
import 'package:ente_auth/utils/totp_util.dart';
import "package:flutter/material.dart";
import 'package:gradient_borders/box_borders/gradient_box_border.dart';

class SetupEnterSecretKeyPage extends StatefulWidget {
  final Code? code;
  final List<String> tags;

  SetupEnterSecretKeyPage({this.code, super.key, required this.tags});

  @override
  State<SetupEnterSecretKeyPage> createState() =>
      _SetupEnterSecretKeyPageState();
}

class _SetupEnterSecretKeyPageState extends State<SetupEnterSecretKeyPage> {
  late TextEditingController _issuerController;
  late TextEditingController _accountController;
  late TextEditingController _secretController;
  late bool _secretKeyObscured;
  late List<String> tags = [...?widget.code?.display.tags];
  late List<String> allTags = [...widget.tags];

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
    _secretKeyObscured = widget.code != null;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.importAccountPageTitle),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  // The validator receives the text that the user has entered.
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter some text";
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: l10n.codeIssuerHint,
                  ),
                  controller: _issuerController,
                  autofocus: true,
                ),
                const SizedBox(
                  height: 20,
                ),
                TextFormField(
                  // The validator receives the text that the user has entered.
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter some text";
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: l10n.codeSecretKeyHint,
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _secretKeyObscured = !_secretKeyObscured;
                        });
                      },
                      icon: _secretKeyObscured
                          ? const Icon(Icons.visibility_off_rounded)
                          : const Icon(Icons.visibility_rounded),
                    ),
                  ),
                  obscureText: _secretKeyObscured,
                  controller: _secretController,
                ),
                const SizedBox(
                  height: 20,
                ),
                TextFormField(
                  // The validator receives the text that the user has entered.
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter some text";
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: l10n.codeAccountHint,
                  ),
                  controller: _accountController,
                ),
                const SizedBox(
                  height: 20,
                ),
                Text(
                  l10n.tags,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  alignment: WrapAlignment.start,
                  children: [
                    ...allTags.map(
                      (e) => TagChip(
                        label: e,
                        action: TagChipAction.check,
                        state: tags.contains(e)
                            ? TagChipState.selected
                            : TagChipState.unselected,
                        onTap: () {
                          if (tags.contains(e)) {
                            tags.remove(e);
                          } else {
                            tags.add(e);
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
                                if (allTags.contains(tag) &&
                                    tags.contains(tag)) {
                                  return;
                                }
                                allTags.add(tag);
                                tags.add(tag);
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
                const SizedBox(
                  height: 40,
                ),
                SizedBox(
                  width: 400,
                  child: OutlinedButton(
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
                        _showIncorrectDetailsDialog(context, message: message);
                        return;
                      }
                      await _saveCode();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                      ),
                      child: Text(l10n.saveAction),
                    ),
                  ),
                ),
              ],
            ),
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
      final CodeDisplay display = widget.code!.display.copyWith(tags: tags);
      final Code newCode = widget.code == null
          ? Code.fromAccountAndSecret(
              account,
              issuer,
              secret,
              display,
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
    } catch (e) {
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
}

class AddChip extends StatelessWidget {
  final VoidCallback? onTap;

  const AddChip({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Icon(
          Icons.add_circle_outline,
          size: 30,
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF9610D6)
              : const Color(0xFF8232E1),
        ),
      ),
    );
  }
}

enum TagChipState {
  selected,
  unselected,
}

enum TagChipAction {
  none,
  menu,
  check,
}

class TagChip extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final TagChipState state;
  final TagChipAction action;

  const TagChip({
    super.key,
    required this.label,
    this.state = TagChipState.unselected,
    this.action = TagChipAction.none,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: state == TagChipState.selected
              ? const Color(0xFF722ED1)
              : Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1C0F22)
                  : const Color(0xFFFCF5FF),
          borderRadius: BorderRadius.circular(100),
          border: GradientBoxBorder(
            gradient: LinearGradient(
              colors: state == TagChipState.selected
                  ? [
                      const Color(0xFFB37FEB),
                      const Color(0xFFAE40E3).withOpacity(
                        Theme.of(context).brightness == Brightness.dark
                            ? .53
                            : 1,
                      ),
                    ]
                  : [
                      Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFFAD00FF)
                          : const Color(0xFFAD00FF).withOpacity(0.2),
                      Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFFA269BD).withOpacity(0.53)
                          : const Color(0xFF8609C2).withOpacity(0.2),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16)
            .copyWith(right: 0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: state == TagChipState.selected ||
                        Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : const Color(0xFF8232E1),
              ),
            ),
            if (state == TagChipState.selected &&
                action == TagChipAction.check) ...[
              const SizedBox(width: 16),
              const Icon(
                Icons.check,
                size: 16,
                color: Colors.white,
              ),
              const SizedBox(width: 16),
            ] else if (state == TagChipState.selected &&
                action == TagChipAction.menu) ...[
              SizedBox(
                width: 48,
                child: PopupMenuButton<int>(
                  iconSize: 16,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  surfaceTintColor: Theme.of(context).cardColor,
                  iconColor: Colors.white,
                  initialValue: -1,
                  onSelected: (value) {
                    if (value == 0) {
                      showEditDialog(context, label);
                    } else if (value == 1) {
                      showDeleteTagDialog(context, label);
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    return [
                      PopupMenuItem(
                        child: Row(
                          children: [
                            const Icon(Icons.edit_outlined, size: 16),
                            const SizedBox(width: 12),
                            Text(context.l10n.edit),
                          ],
                        ),
                        value: 0,
                      ),
                      PopupMenuItem(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.delete_outline,
                              size: 16,
                              color: Color(0xFFF53434),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              context.l10n.delete,
                              style: const TextStyle(
                                color: Color(0xFFF53434),
                              ),
                            ),
                          ],
                        ),
                        value: 1,
                      ),
                    ];
                  },
                ),
              ),
            ] else ...[
              const SizedBox(width: 16),
            ],
          ],
        ),
      ),
    );
  }
}

class AddTagDialog extends StatefulWidget {
  const AddTagDialog({
    super.key,
    required this.onTap,
  });

  final void Function(String) onTap;

  @override
  State<AddTagDialog> createState() => _AddTagDialogState();
}

class _AddTagDialogState extends State<AddTagDialog> {
  String _tag = "";

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.createNewTag),
      content: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              decoration: InputDecoration(
                hintText: l10n.tag,
                hintStyle: const TextStyle(
                  color: Colors.white30,
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
              onChanged: (value) {
                setState(() {
                  _tag = value;
                });
              },
              autocorrect: false,
              initialValue: _tag,
              autofocus: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: Text(
            l10n.cancel,
            style: const TextStyle(
              color: Colors.redAccent,
            ),
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        TextButton(
          child: Text(
            l10n.create,
            style: const TextStyle(
              color: Colors.purple,
            ),
          ),
          onPressed: () {
            if (_tag.trim().isEmpty) return;

            widget.onTap(_tag);
          },
        ),
      ],
    );
  }
}

class EditTagDialog extends StatefulWidget {
  const EditTagDialog({
    super.key,
    required this.tag,
  });

  final String tag;

  @override
  State<EditTagDialog> createState() => _EditTagDialogState();
}

class _EditTagDialogState extends State<EditTagDialog> {
  late String _tag = widget.tag;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.editTag),
      content: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              decoration: InputDecoration(
                hintText: l10n.tag,
                hintStyle: const TextStyle(
                  color: Colors.white30,
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
              onChanged: (value) {
                setState(() {
                  _tag = value;
                });
              },
              autocorrect: false,
              initialValue: _tag,
              autofocus: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: Text(
            l10n.cancel,
            style: const TextStyle(
              color: Colors.redAccent,
            ),
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        TextButton(
          child: Text(
            l10n.saveAction,
            style: const TextStyle(
              color: Colors.purple,
            ),
          ),
          onPressed: () async {
            if (_tag.trim().isEmpty) return;

            final dialog = createProgressDialog(
              context,
              context.l10n.pleaseWait,
            );
            await dialog.show();

            // traverse through all the codes and edit this tag's value
            final relevantCodes = (await CodeStore.instance.getAllCodes())
                .validCodes
                .where((element) => element.display.tags.contains(widget.tag));

            final tasks = <Future>[];

            for (final code in relevantCodes) {
              final tags = code.display.tags;
              tags.remove(widget.tag);
              tags.add(_tag);
              tasks.add(
                CodeStore.instance.addCode(
                  code.copyWith(
                    display: code.display.copyWith(tags: tags),
                  ),
                ),
              );
            }

            await Future.wait(tasks);
            await dialog.hide();

            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}

Future<void> showDeleteTagDialog(BuildContext context, String tag) async {
  FocusScope.of(context).requestFocus();
  final l10n = context.l10n;
  await showChoiceActionSheet(
    context,
    title: l10n.deleteTagTitle,
    body: l10n.deleteTagMessage,
    firstButtonLabel: l10n.delete,
    isCritical: true,
    firstButtonOnTap: () async {
      // traverse through all the codes and edit this tag's value
      final relevantCodes = (await CodeStore.instance.getAllCodes())
          .validCodes
          .where((element) => element.display.tags.contains(tag));

      final tasks = <Future>[];

      for (final code in relevantCodes) {
        final tags = code.display.tags;
        tags.remove(tag);
        tasks.add(
          CodeStore.instance.addCode(
            code.copyWith(
              display: code.display.copyWith(tags: tags),
            ),
          ),
        );
      }

      await Future.wait(tasks);
    },
  );
}

Future<void> showEditDialog(BuildContext context, String tag) async {
  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return EditTagDialog(tag: tag);
    },
    barrierColor: Colors.black.withOpacity(0.85),
    barrierDismissible: false,
  );
}
