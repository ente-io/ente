import "package:ente_ui/components/buttons/button_widget.dart";
import "package:ente_ui/components/buttons/models/button_result.dart";
import "package:ente_ui/theme/ente_theme.dart";
import "package:flutter/material.dart";
import 'package:locker/l10n/l10n.dart';

class DeleteConfirmationResult {
  final ButtonResult buttonResult;
  final bool deleteFromAllCollections;

  DeleteConfirmationResult({
    required this.buttonResult,
    required this.deleteFromAllCollections,
  });
}

Future<DeleteConfirmationResult?> showDeleteConfirmationDialog(
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
    builder: (context) {
      return _DeleteConfirmationBottomSheet(
        title: title,
        body: body,
        deleteButtonLabel: deleteButtonLabel,
        assetPath: assetPath,
        showDeleteFromAllCollectionsOption: showDeleteFromAllCollectionsOption,
      );
    },
  );
}

class _DeleteConfirmationBottomSheet extends StatefulWidget {
  final String title;
  final String body;
  final String deleteButtonLabel;
  final String assetPath;
  final bool showDeleteFromAllCollectionsOption;

  const _DeleteConfirmationBottomSheet({
    required this.title,
    required this.body,
    required this.deleteButtonLabel,
    required this.assetPath,
    required this.showDeleteFromAllCollectionsOption,
  });

  @override
  State<_DeleteConfirmationBottomSheet> createState() =>
      _DeleteConfirmationBottomSheetState();
}

class _DeleteConfirmationBottomSheetState
    extends State<_DeleteConfirmationBottomSheet> {
  bool _deleteFromAllCollections = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = getEnteTextTheme(context);
    final colorScheme = getEnteColorScheme(context);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.backdropBase,
        border: Border(top: BorderSide(color: colorScheme.strokeFaint)),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(50),
                          color: colorScheme.backgroundElevated,
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.close,
                          size: 24,
                          color: colorScheme.textBase,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Center(child: Image.asset(widget.assetPath)),
              const SizedBox(height: 24),
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
              const SizedBox(height: 20),
              if (widget.showDeleteFromAllCollectionsOption) ...[
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
                const SizedBox(height: 20),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(
                      DeleteConfirmationResult(
                        buttonResult: ButtonResult(ButtonAction.first),
                        deleteFromAllCollections: _deleteFromAllCollections,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.warning400,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    widget.deleteButtonLabel,
                    style: textTheme.bodyBold.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
