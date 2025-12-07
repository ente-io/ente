import "package:ente_legacy/components/gradient_button.dart";
import "package:ente_strings/ente_strings.dart";
import "package:ente_ui/theme/colors.dart";
import "package:ente_ui/theme/ente_theme.dart";
import "package:ente_ui/theme/text_style.dart";
import "package:flutter/material.dart";

Future<InviteAction?> showInviteBottomSheet(
  BuildContext context, {
  required String email,
}) {
  return showModalBottomSheet<InviteAction>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    builder: (context) => InviteBottomSheet(email: email),
  );
}

enum InviteAction { accept, decline }

class InviteBottomSheet extends StatelessWidget {
  final String email;

  const InviteBottomSheet({
    required this.email,
    super.key,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(colorScheme, textTheme),
              const SizedBox(height: 12),
              _buildDescription(colorScheme, textTheme, context),
              const SizedBox(height: 20),
              GradientButton(
                text: context.strings.acceptTrustInvite,
                backgroundColor: colorScheme.primary700,
                onTap: () => Navigator.of(context).pop(InviteAction.accept),
              ),
              const SizedBox(height: 8),
              GradientButton(
                text: context.strings.declineTrustInvite,
                backgroundColor: colorScheme.warning400,
                onTap: () => Navigator.of(context).pop(InviteAction.decline),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    EnteColorScheme colorScheme,
    EnteTextTheme textTheme,
  ) {
    return Builder(
      builder: (context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              email,
              style: textTheme.largeBold,
              overflow: TextOverflow.ellipsis,
            ),
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
      ),
    );
  }

  Widget _buildDescription(
    EnteColorScheme colorScheme,
    EnteTextTheme textTheme,
    BuildContext context,
  ) {
    return Text(
      context.strings.legacyInvite(email),
      style: textTheme.small.copyWith(color: colorScheme.textMuted),
    );
  }
}
