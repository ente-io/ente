import "package:ente_ui/components/buttons/button_widget.dart";
import "package:ente_ui/components/buttons/models/button_result.dart";
import "package:ente_ui/theme/ente_theme.dart";
import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";

Future<ButtonResult?> showDeleteConfirmationDialog(
  BuildContext context, {
  required String title,
  required String body,
  required String deleteButtonLabel,
}) {
  return showModalBottomSheet<ButtonResult>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    builder: (context) {
      return _DeleteConfirmationBottomSheet(
        title: title,
        body: body,
        deleteButtonLabel: deleteButtonLabel,
      );
    },
  );
}

class _DeleteConfirmationBottomSheet extends StatelessWidget {
  final String title;
  final String body;
  final String deleteButtonLabel;

  const _DeleteConfirmationBottomSheet({
    required this.title,
    required this.body,
    required this.deleteButtonLabel,
  });

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
            children: [
              const SizedBox(height: 8),
              Row(
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
              const SizedBox(height: 8),
              Image.asset('assets/delete_icon.png'),
              const SizedBox(height: 24),
              Text(
                title,
                style: textTheme.h3Bold,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                body,
                style: textTheme.body.copyWith(
                  color: colorScheme.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop(
                      ButtonResult(ButtonAction.first),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.warning400,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedFileUpload,
                    color: Colors.white,
                    size: 20,
                    strokeWidth: 1.9,
                  ),
                  label: Text(
                    deleteButtonLabel,
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
