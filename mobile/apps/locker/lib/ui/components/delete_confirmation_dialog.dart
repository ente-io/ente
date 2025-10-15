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
  required int fileCount,
}) {
  return showModalBottomSheet<ButtonResult>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    isDismissible: true,
    builder: (context) {
      return _DeleteConfirmationBottomSheet(
        title: title,
        body: body,
        deleteButtonLabel: deleteButtonLabel,
        fileCount: fileCount,
      );
    },
  );
}

class _DeleteConfirmationBottomSheet extends StatelessWidget {
  final String title;
  final String body;
  final String deleteButtonLabel;
  final int fileCount;

  const _DeleteConfirmationBottomSheet({
    required this.title,
    required this.body,
    required this.deleteButtonLabel,
    required this.fileCount,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = getEnteTextTheme(context);
    final colorScheme = getEnteColorScheme(context);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.backgroundBase,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
          ),
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
                        color: colorScheme.backdropBase,
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.close,
                        size: 24,
                        color: colorScheme.iconColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Image.asset('assets/delete_icon.png'),
              const SizedBox(height: 24),
              Text(
                "Are you sure?",
                style: textTheme.h3Bold,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                "This action is immediate and cannot be undone.\n$fileCount files will be deleted permanently.",
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
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedFileUpload,
                    color: colorScheme.backdropBase,
                    size: 20,
                    strokeWidth: 1.9,
                  ),
                  label: Text(
                    "Yes, delete files",
                    style: textTheme.bodyBold.copyWith(
                      color: colorScheme.backdropBase,
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
