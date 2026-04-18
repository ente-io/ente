import "package:ente_ui/components/buttons/button_widget.dart";
import "package:ente_ui/components/buttons/models/button_result.dart";
import "package:ente_ui/components/close_icon_button.dart";
import "package:ente_ui/theme/ente_theme.dart";
import "package:flutter/material.dart";
import "package:locker/l10n/l10n.dart";
import "package:locker/ui/components/gradient_button.dart";

class DeleteConfirmationResult {
  final ButtonResult buttonResult;
  final bool deleteFromAllCollections;

  DeleteConfirmationResult({
    required this.buttonResult,
    required this.deleteFromAllCollections,
  });
}

Future<DeleteConfirmationResult?> showDeleteConfirmationSheet(
  BuildContext context, {
  required String title,
  required String body,
  required String deleteButtonLabel,
  required String assetPath,
  bool showDeleteFromAllCollectionsOption = false,
}) {
  return showModalBottomSheet<DeleteConfirmationResult>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DeleteConfirmationSheet(
      title: title,
      body: body,
      deleteButtonLabel: deleteButtonLabel,
      assetPath: assetPath,
      showDeleteFromAllCollectionsOption: showDeleteFromAllCollectionsOption,
    ),
  );
}

class DeleteConfirmationSheet extends StatefulWidget {
  final String title;
  final String body;
  final String deleteButtonLabel;
  final String assetPath;
  final bool showDeleteFromAllCollectionsOption;

  const DeleteConfirmationSheet({
    super.key,
    required this.title,
    required this.body,
    required this.deleteButtonLabel,
    required this.assetPath,
    required this.showDeleteFromAllCollectionsOption,
  });

  @override
  State<DeleteConfirmationSheet> createState() =>
      _DeleteConfirmationSheetState();
}

class _DeleteConfirmationSheetState extends State<DeleteConfirmationSheet> {
  bool _deleteFromAllCollections = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = getEnteTextTheme(context);
    final colorScheme = getEnteColorScheme(context);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.backgroundElevated2,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CloseIconButton(),
                ],
              ),
              const SizedBox(height: 12),
              Center(child: Image.asset(widget.assetPath)),
              const SizedBox(height: 20),
              Text(
                widget.title,
                style: textTheme.h3Bold,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                widget.body,
                style: textTheme.body.copyWith(
                  color: colorScheme.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
              if (widget.showDeleteFromAllCollectionsOption) ...[
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _deleteFromAllCollections = !_deleteFromAllCollections;
                    });
                  },
                  child: SizedBox(
                    width: double.infinity,
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _deleteFromAllCollections
                                  ? colorScheme.primary700
                                  : colorScheme.strokeMuted,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(6),
                            color: _deleteFromAllCollections
                                ? colorScheme.primary700
                                : Colors.transparent,
                          ),
                          alignment: Alignment.center,
                          child: _deleteFromAllCollections
                              ? const Icon(
                                  Icons.check,
                                  size: 12,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        Text(
                          context.l10n.deleteCollectionFromEverywhere,
                          style: textTheme.small,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: GradientButton(
                  onTap: () {
                    Navigator.of(context).pop(
                      DeleteConfirmationResult(
                        buttonResult: ButtonResult(ButtonAction.first),
                        deleteFromAllCollections: _deleteFromAllCollections,
                      ),
                    );
                  },
                  text: widget.deleteButtonLabel,
                  backgroundColor: colorScheme.warning400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
