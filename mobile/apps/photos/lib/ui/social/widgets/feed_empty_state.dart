import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/account/email_entry_page.dart";
import "package:photos/ui/collections/collection_action_sheet.dart";
import "package:photos/ui/components/buttons/button_widget_v2.dart";
import "package:photos/ui/tabs/albums/empty_states/empty_state_feature_row.dart";

class FeedEmptyState extends StatelessWidget {
  const FeedEmptyState({
    required this.localGalleryMode,
    super.key,
  });

  final bool localGalleryMode;

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
                    localGalleryMode
                        ? strings.seeWhatYourPeopleAreUpTo
                        : strings.nothingHereYet,
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
                    localGalleryMode
                        ? strings.signUpToShareMomentsPrivately
                        : strings.shareAnAlbumWithSomeoneYouLove,
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
                children: localGalleryMode
                    ? [
                        EmptyStateFeatureRow(
                          icon: HugeIcons.strokeRoundedFavourite,
                          label: strings.reactToTheMomentsThatMatter,
                        ),
                        const SizedBox(height: 24),
                        EmptyStateFeatureRow(
                          icon: HugeIcons.strokeRoundedComment01,
                          label: strings.leaveANoteOnTheMomentsSharedWithYou,
                        ),
                        const SizedBox(height: 24),
                        EmptyStateFeatureRow(
                          icon: HugeIcons.strokeRoundedLockSync01,
                          label:
                              strings.endToEndEncryptedOnlyYourPeopleCanSeeIt,
                        ),
                      ]
                    : [
                        EmptyStateFeatureRow(
                          icon: HugeIcons.strokeRoundedFavourite,
                          label: strings.seeTheLoveYourPhotosGet,
                        ),
                        const SizedBox(height: 24),
                        EmptyStateFeatureRow(
                          icon: HugeIcons.strokeRoundedComment01,
                          label: strings.yourConversationsAttachedToTheMoment,
                        ),
                        const SizedBox(height: 24),
                        EmptyStateFeatureRow(
                          icon: HugeIcons.strokeRoundedUserMultiple,
                          label: strings.stayConnectedWithThePeopleYouShareWith,
                        ),
                      ],
              ),
            ),
            const SizedBox(height: 32),
            ButtonWidgetV2(
              buttonType: ButtonTypeV2.primary,
              labelText:
                  localGalleryMode ? strings.getStarted : strings.shareAnAlbum,
              onTap: () async {
                if (localGalleryMode) {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const EmailEntryPage(
                        showReferralSourceField: false,
                        referralSource: "Offline",
                      ),
                    ),
                  );
                  return;
                }
                showCollectionActionSheet(
                  context,
                  actionType: CollectionActionType.shareCollection,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
