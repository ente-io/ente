
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photos/core/constants.dart';
import "package:photos/generated/l10n.dart";
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/components/captioned_text_widget.dart';
import 'package:photos/ui/components/menu_item_widget/menu_item_widget.dart';
import 'package:photos/utils/email_util.dart';

class SupportSectionWidget extends StatelessWidget {
  const SupportSectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return MenuItemWidget(
      captionedTextWidget: CaptionedTextWidget(
        title: S.of(context).support,
        makeTextBold: true,
      ),
      leadingIcon: Icons.help_outline_outlined,
      menuItemColor: getEnteColorScheme(context).fillFaint,
      pressedColor: getEnteColorScheme(context).fillFaint,
      onTap: () async {
        // Open support app via method channel
        const MethodChannel _supportChannel = MethodChannel('support_channel');
        try {
          await _supportChannel.invokeMethod('openSupportApp');
        } catch (e) {
          // Fallback to default support behavior if method channel fails
          await sendEmail(context, to: supportEmail);
        }
      },
    );
  }
}
