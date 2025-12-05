import "package:ente_legacy/components/gradient_button.dart";
import "package:ente_legacy/models/emergency_models.dart";
import "package:ente_strings/ente_strings.dart";
import "package:ente_ui/theme/colors.dart";
import "package:ente_ui/theme/ente_theme.dart";
import "package:ente_ui/theme/text_style.dart";
import "package:flutter/material.dart";

Future<TrustedContactAction?> showTrustedContactBottomSheet(
  BuildContext context, {
  required EmergencyContact contact,
}) {
  return showModalBottomSheet<TrustedContactAction>(
    context: context,
    isScrollControlled: true,
    builder: (context) => TrustedContactBottomSheet(contact: contact),
  );
}

enum TrustedContactAction {
  revoke,
  updateTime,
}

class TrustedContactBottomSheet extends StatefulWidget {
  final EmergencyContact contact;

  const TrustedContactBottomSheet({
    required this.contact,
    super.key,
  });

  @override
  State<TrustedContactBottomSheet> createState() =>
      _TrustedContactBottomSheetState();
}

class _TrustedContactBottomSheetState extends State<TrustedContactBottomSheet> {
  late int _selectedRecoveryDays;

  @override
  void initState() {
    super.initState();
    // Default to 14 days if not set
    _selectedRecoveryDays = 14;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final isPending = widget.contact.isPendingInvite();
    final email = widget.contact.emergencyContact.email;

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
              _buildHeader(colorScheme, textTheme, email),
              const SizedBox(height: 12),
              _buildDescription(colorScheme, textTheme, email, isPending),
              const SizedBox(height: 20),
              _buildRecoveryTimeSection(colorScheme, textTheme),
              const SizedBox(height: 20),
              _buildUpdateTimeButton(colorScheme, textTheme),
              const SizedBox(height: 20),
              _buildRevokeButton(colorScheme, textTheme, isPending),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    EnteColorScheme colorScheme,
    EnteTextTheme textTheme,
    String email,
  ) {
    return Row(
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
    );
  }

  Widget _buildDescription(
    EnteColorScheme colorScheme,
    EnteTextTheme textTheme,
    String email,
    bool isPending,
  ) {
    final String description = isPending
        ? context.strings.trustedContactInvitePending(email)
        : context.strings.trustedContactAccepted(email);

    return Text(
      description,
      style: textTheme.small.copyWith(color: colorScheme.textMuted),
    );
  }

  Widget _buildRecoveryTimeSection(
    EnteColorScheme colorScheme,
    EnteTextTheme textTheme,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildRecoveryChip(7, colorScheme, textTheme),
        const SizedBox(width: 12),
        _buildRecoveryChip(14, colorScheme, textTheme),
        const SizedBox(width: 12),
        _buildRecoveryChip(30, colorScheme, textTheme),
      ],
    );
  }

  Widget _buildRecoveryChip(
    int days,
    EnteColorScheme colorScheme,
    EnteTextTheme textTheme,
  ) {
    final isSelected = _selectedRecoveryDays == days;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRecoveryDays = days;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 20.0,
          vertical: 16.0,
        ),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary700 : colorScheme.fillFaint,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          context.strings.nDays(days),
          style: textTheme.body.copyWith(
            color: isSelected ? Colors.white : colorScheme.primary700,
          ),
        ),
      ),
    );
  }

  Widget _buildUpdateTimeButton(
    EnteColorScheme colorScheme,
    EnteTextTheme textTheme,
  ) {
    return GradientButton(
      text: context.strings.updateTime,
      onTap: () {
        Navigator.of(context).pop(TrustedContactAction.updateTime);
      },
    );
  }

  Widget _buildRevokeButton(
    EnteColorScheme colorScheme,
    EnteTextTheme textTheme,
    bool isPending,
  ) {
    final String label =
        isPending ? context.strings.revokeInvite : context.strings.remove;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop(TrustedContactAction.revoke);
      },
      child: SizedBox(
        width: double.infinity,
        child: Center(
          child: Text(
            label,
            style: textTheme.bodyBold.copyWith(
              color: colorScheme.warning700,
              decoration: TextDecoration.underline,
              decorationColor: colorScheme.warning700,
            ),
          ),
        ),
      ),
    );
  }
}
