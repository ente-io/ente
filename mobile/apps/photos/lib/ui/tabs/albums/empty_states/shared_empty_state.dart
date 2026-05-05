import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/account/user_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/buttons/button_widget_v2.dart";
import "package:photos/ui/tabs/albums/empty_states/albums_empty_state_feature_row.dart";
import "package:photos/utils/dialog_util.dart";

class SharedEmptyState extends StatelessWidget {
  const SharedEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final strings = AppLocalizations.of(context);
    final bottomPadding = 64 + MediaQuery.paddingOf(context).bottom + 32;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 32, 16, bottomPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Column(
                children: [
                  Text(
                    strings.albumsSharedWithYouShowUpHere,
                    textAlign: TextAlign.center,
                    style: textTheme.largeBold.copyWith(
                      fontFamily: "Nunito",
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      height: 28 / 18,
                      color: colorScheme.content,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    strings.inviteFamilyToSharePhotosPrivately,
                    textAlign: TextAlign.center,
                    style: textTheme.miniMuted,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Column(
                children: [
                  AlbumsEmptyStateFeatureRow(
                    icon: HugeIcons.strokeRoundedUserMultiple,
                    label: strings.shareStorageWithUpToFiveFamilyMembers,
                  ),
                  const SizedBox(height: 24),
                  AlbumsEmptyStateFeatureRow(
                    icon: HugeIcons.strokeRoundedLock,
                    label: strings.privateSpaceForEveryMember,
                  ),
                  const SizedBox(height: 24),
                  AlbumsEmptyStateFeatureRow(
                    icon: HugeIcons.strokeRoundedFavourite,
                    label: strings.reactAndChatOnSharedMemories,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ButtonWidgetV2(
              buttonType: ButtonTypeV2.primary,
              labelText: strings.addFamily,
              onTap: () => _addFamily(context),
              shouldSurfaceExecutionStates: false,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addFamily(BuildContext context) async {
    try {
      final userDetails =
          await UserService.instance.getUserDetailsV2(memoryCount: false);
      if (!context.mounted) {
        return;
      }
      await billingService.launchFamilyPortal(
        context,
        userDetails,
        refreshOnOpen: false,
      );
    } catch (e) {
      if (context.mounted) {
        await showGenericErrorDialog(context: context, error: e);
      }
    }
  }
}
