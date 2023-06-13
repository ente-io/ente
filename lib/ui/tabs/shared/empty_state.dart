import "package:flutter/material.dart";
import "package:fluttertoast/fluttertoast.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/events/tab_changed_event.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/theme/ente_theme.dart";
import 'package:photos/ui/collections/collection_action_sheet.dart';
import "package:photos/ui/common/gradient_button.dart";
import 'package:photos/ui/components/buttons/button_widget.dart';
import "package:photos/ui/components/empty_state_item_widget.dart";
import "package:photos/ui/components/models/button_type.dart";
import "package:photos/utils/share_util.dart";
import "package:photos/utils/toast_util.dart";

class SharedEmptyStateWidget extends StatelessWidget {
  const SharedEmptyStateWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = getEnteTextTheme(context);
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 114),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      S.of(context).privateSharing,
                      style: textTheme.h3Bold,
                      textAlign: TextAlign.start,
                    ),
                    const SizedBox(height: 24),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        EmptyStateItemWidget(
                          S.of(context).shareOnlyWithThePeopleYouWant,
                        ),
                        const SizedBox(height: 12),
                        EmptyStateItemWidget(
                          S.of(context).usePublicLinksForPeopleNotOnEnte,
                        ),
                        const SizedBox(height: 12),
                        EmptyStateItemWidget(
                          S.of(context).allowPeopleToAddPhotos,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ButtonWidget(
                      buttonType: ButtonType.trailingIconPrimary,
                      labelText: S.of(context).shareAnAlbumNow,
                      icon: Icons.arrow_forward_outlined,
                      onTap: () async {
                        showCollectionActionSheet(
                          context,
                          actionType: CollectionActionType.shareCollection,
                        );
                      },
                    ),
                    const SizedBox(height: 6),
                    ButtonWidget(
                      buttonType: ButtonType.trailingIconSecondary,
                      labelText: S.of(context).collectEventPhotos,
                      icon: Icons.add_photo_alternate_outlined,
                      onTap: () async {
                        showCollectionActionSheet(
                          context,
                          actionType: CollectionActionType.collectPhotos,
                        );
                      },
                    ),
                    const SizedBox(height: 6),
                    ButtonWidget(
                      buttonType: ButtonType.trailingIconSecondary,
                      labelText: S.of(context).inviteYourFriends,
                      icon: Icons.ios_share_outlined,
                      onTap: () async {
                        shareText(S.of(context).shareTextRecommendUsingEnte);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OutgoingAlbumEmptyState extends StatelessWidget {
  const OutgoingAlbumEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            S.of(context).shareYourFirstAlbum,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const Padding(padding: EdgeInsets.only(top: 14)),
          SizedBox(
            width: 200,
            height: 50,
            child: GradientButton(
              onTap: () async {
                await showToast(
                  context,
                  S.of(context).shareAlbumHint,
                  toastLength: Toast.LENGTH_LONG,
                );
                Bus.instance.fire(
                  TabChangedEvent(1, TabChangedEventSource.collectionsPage),
                );
              },
              iconData: Icons.person_add,
              text: S.of(context).share,
            ),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }
}

class IncomingAlbumEmptyState extends StatelessWidget {
  const IncomingAlbumEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            S.of(context).askYourLovedOnesToShare,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const Padding(padding: EdgeInsets.only(top: 14)),
          SizedBox(
            width: 200,
            height: 50,
            child: GradientButton(
              onTap: () async {
                shareText(S.of(context).shareTextRecommendUsingEnte);
              },
              iconData: Icons.outgoing_mail,
              text: S.of(context).invite,
            ),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }
}
