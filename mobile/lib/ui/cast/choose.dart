import "package:flutter/material.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/service_locator.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/buttons/button_widget.dart";
import "package:photos/ui/components/models/button_type.dart";

class CastChooseDialog extends StatefulWidget {
  CastChooseDialog({
    Key? key,
  }) : super(key: key) {}

  @override
  State<CastChooseDialog> createState() => _AutoCastDialogState();
}

class _AutoCastDialogState extends State<CastChooseDialog> {
  final bool doesUserExist = true;

  @override
  Widget build(BuildContext context) {
    final textStyle = getEnteTextTheme(context);
    final AlertDialog alert = AlertDialog(
      title: Text(
        "Play album on TV",
        style: textStyle.largeBold,
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Text(
            "Auto Pair requires connecting to Google servers and only works with Chromecast supported devices. Google will not receive sensitive data, such as your photos.",
            style: textStyle.bodyMuted,
          ),
          const SizedBox(height: 12),
          ButtonWidget(
            labelText: S.of(context).autoPair,
            icon: Icons.cast_outlined,
            buttonType: ButtonType.primary,
            buttonSize: ButtonSize.large,
            shouldStickToDarkTheme: true,
            buttonAction: ButtonAction.first,
            shouldSurfaceExecutionStates: false,
            isInAlert: true,
            onTap: () async {
              Navigator.of(context).pop(ButtonAction.first);
            },
          ),
          const SizedBox(height: 36),
          Text(
            "Pair with PIN works for any large screen device you want to play your album on.",
            style: textStyle.bodyMuted,
          ),
          const SizedBox(height: 12),
          ButtonWidget(
            labelText: S.of(context).pairWithPin,
            buttonType: ButtonType.primary,
            // icon for pairing with TV manually
            icon: Icons.tv_outlined,
            buttonSize: ButtonSize.large,
            isInAlert: true,
            onTap: () async {
              Navigator.of(context).pop(ButtonAction.second);
            },
            shouldStickToDarkTheme: true,
            buttonAction: ButtonAction.second,
            shouldSurfaceExecutionStates: false,
          ),
        ],
      ),
    );
    return alert;
  }

  Future<void> _connectToYourApp(
    BuildContext context,
    Object castDevice,
  ) async {
    await castService.connectDevice(context, castDevice);
  }
}
