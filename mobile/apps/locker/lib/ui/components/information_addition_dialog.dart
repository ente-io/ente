import 'package:ente_ui/components/buttons/button_widget.dart';
import 'package:ente_ui/components/buttons/models/button_type.dart';
import 'package:ente_ui/theme/ente_theme.dart';
import 'package:flutter/material.dart';
import 'package:locker/l10n/l10n.dart';

enum InformationType {
  physicalDocument,
  emergencyContact,
  accountCredential,
}

class InformationAdditionResult {
  final InformationType type;

  InformationAdditionResult({
    required this.type,
  });
}

class InformationAdditionDialog extends StatefulWidget {
  const InformationAdditionDialog({super.key});

  @override
  State<InformationAdditionDialog> createState() =>
      _InformationAdditionDialogState();
}

class _InformationAdditionDialogState extends State<InformationAdditionDialog> {
  void _onTypeSelected(InformationType type) {
    final result = InformationAdditionResult(type: type);
    Navigator.of(context).pop(result);
  }

  Future<void> _onCancel() async {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    return Dialog(
      backgroundColor: colorScheme.backgroundElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Container(
        width: 400,
        constraints: const BoxConstraints(maxHeight: 600),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.post_add,
                  color: Colors.blue,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.l10n.addInformation,
                    style: textTheme.largeBold,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.addInformationDialogSubtitle,
              style: textTheme.body.copyWith(
                color: colorScheme.textMuted,
              ),
            ),
            const SizedBox(height: 20),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildOptionTile(
                      type: InformationType.physicalDocument,
                      icon: Icons.description,
                      title: context.l10n.physicalDocument,
                      subtitle: context.l10n.physicalDocumentDescription,
                      colorScheme: colorScheme,
                      textTheme: textTheme,
                    ),
                    const SizedBox(height: 12),
                    _buildOptionTile(
                      type: InformationType.emergencyContact,
                      icon: Icons.emergency,
                      title: context.l10n.emergencyContact,
                      subtitle: context.l10n.emergencyContactDescription,
                      colorScheme: colorScheme,
                      textTheme: textTheme,
                    ),
                    const SizedBox(height: 12),
                    _buildOptionTile(
                      type: InformationType.accountCredential,
                      icon: Icons.key,
                      title: context.l10n.accountCredential,
                      subtitle: context.l10n.accountCredentialDescription,
                      colorScheme: colorScheme,
                      textTheme: textTheme,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: ButtonWidget(
                    buttonType: ButtonType.secondary,
                    labelText: context.l10n.cancel,
                    onTap: _onCancel,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required InformationType type,
    required IconData icon,
    required String title,
    required String subtitle,
    required colorScheme,
    required textTheme,
  }) {
    return InkWell(
      onTap: () => _onTypeSelected(type),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.fillFaint,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: colorScheme.strokeFaint,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.fillMuted,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                icon,
                color: colorScheme.textMuted,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.textBase,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: textTheme.small.copyWith(
                      color: colorScheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<InformationAdditionResult?> showInformationAdditionDialog(
  BuildContext context,
) async {
  return showDialog<InformationAdditionResult>(
    context: context,
    barrierColor: getEnteColorScheme(context).backdropBase,
    builder: (context) => const InformationAdditionDialog(),
  );
}
