import "package:flutter/material.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/l10n/l10n.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/buttons/button_widget.dart";
import "package:photos/ui/components/models/button_type.dart";

class CastChooseDialog extends StatefulWidget {
  const CastChooseDialog({
    super.key,
  });

  @override
  State<CastChooseDialog> createState() => _CastChooseDialogState();
}

class _CastChooseDialogState extends State<CastChooseDialog> {
  final bool doesUserExist = true;

  @override
  Widget build(BuildContext context) {
    final textStyle = getEnteTextTheme(context);
    final AlertDialog alert = AlertDialog(
      title: Text(
        context.l10n.playOnTv,
        style: textStyle.largeBold,
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).autoPairDesc,
            style: textStyle.bodyMuted,
          ),
          const SizedBox(height: 12),
          ButtonWidget(
            labelText: AppLocalizations.of(context).autoPair,
            icon: Icons.cast_outlined,
            buttonType: ButtonType.neutral,
            buttonSize: ButtonSize.large,
            shouldStickToDarkTheme: true,
            buttonAction: ButtonAction.first,
            shouldSurfaceExecutionStates: false,
            isInAlert: true,
          ),
          const SizedBox(height: 36),
          Text(
            AppLocalizations.of(context).manualPairDesc,
            style: textStyle.bodyMuted,
          ),
          const SizedBox(height: 12),
          ButtonWidget(
            labelText: AppLocalizations.of(context).pairWithPin,
            buttonType: ButtonType.neutral,
            // icon for pairing with TV manually
            icon: Icons.tv_outlined,
            buttonSize: ButtonSize.large,
            isInAlert: true,

            shouldStickToDarkTheme: true,
            buttonAction: ButtonAction.second,
            shouldSurfaceExecutionStates: false,
          ),
        ],
      ),
    );
    return alert;
  }
}
