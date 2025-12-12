import "package:ente_sharing/components/gradient_button.dart";
import "package:ente_strings/ente_strings.dart";
import "package:ente_ui/theme/colors.dart";
import "package:ente_ui/theme/ente_theme.dart";
import "package:ente_ui/theme/text_style.dart";
import "package:ente_utils/share_utils.dart";
import "package:flutter/material.dart";

/// Shows the invite dialog bottom sheet when a user doesn't have an Ente account
Future<void> showInviteSheet(
  BuildContext context, {
  required String email,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => InviteDialog(email: email),
  );
}

class InviteDialog extends StatelessWidget {
  final String email;

  const InviteDialog({
    super.key,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

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
            children: [
              _buildHeader(context, colorScheme, textTheme),
              const SizedBox(height: 20),
              _buildContent(context, colorScheme, textTheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    EnteColorScheme colorScheme,
    EnteTextTheme textTheme,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          context.strings.inviteToEnte,
          style: textTheme.largeBold,
        ),
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.fillFaint,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.close,
              size: 20,
              color: colorScheme.textBase,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(
    BuildContext context,
    EnteColorScheme colorScheme,
    EnteTextTheme textTheme,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          context.strings.emailNoEnteAccount(email),
          style: textTheme.small.copyWith(color: colorScheme.textMuted),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        GradientButton(
          text: context.strings.sendInvite,
          onTap: () {
            shareText(context.strings.shareTextRecommendUsingEnte);
          },
        ),
      ],
    );
  }
}
