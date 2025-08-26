import 'package:flutter/material.dart';
import "package:photos/extensions/user_extension.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/api/collection/user.dart";
import 'package:photos/models/collection/collection.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/theme/colors.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/actions/collection/collection_sharing_actions.dart';
import 'package:photos/ui/components/buttons/button_widget.dart';
import 'package:photos/ui/components/captioned_text_widget.dart';
import 'package:photos/ui/components/divider_widget.dart';
import 'package:photos/ui/components/menu_item_widget/menu_item_widget.dart';
import 'package:photos/ui/components/menu_section_description_widget.dart';
import 'package:photos/ui/components/menu_section_title.dart';
import 'package:photos/ui/components/title_bar_title_widget.dart';
import 'package:photos/utils/dialog_util.dart';

class ManageIndividualParticipant extends StatefulWidget {
  final Collection collection;
  final User user;

  const ManageIndividualParticipant({
    super.key,
    required this.collection,
    required this.user,
  });

  @override
  State<StatefulWidget> createState() => _ManageIndividualParticipantState();
}

class _ManageIndividualParticipantState
    extends State<ManageIndividualParticipant> {
  final CollectionActions collectionActions =
      CollectionActions(CollectionsService.instance);

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    bool isConvertToViewSuccess = false;
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    height: 12,
                  ),
                  TitleBarTitleWidget(
                    title: AppLocalizations.of(context).manage,
                  ),
                  Text(
                    widget.user.displayName ?? widget.user.email,
                    textAlign: TextAlign.left,
                    style:
                        textTheme.small.copyWith(color: colorScheme.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            MenuSectionTitle(title: AppLocalizations.of(context).addedAs),
            MenuItemWidget(
              captionedTextWidget: CaptionedTextWidget(
                title: AppLocalizations.of(context).collaborator,
              ),
              leadingIcon: Icons.edit_outlined,
              menuItemColor: getEnteColorScheme(context).fillFaint,
              trailingIcon: widget.user.isCollaborator ? Icons.check : null,
              onTap: widget.user.isCollaborator
                  ? null
                  : () async {
                      final result =
                          await collectionActions.addEmailToCollection(
                        context,
                        widget.collection,
                        widget.user.email,
                        CollectionParticipantRole.collaborator,
                      );
                      if (result && mounted) {
                        widget.user.role = CollectionParticipantRole
                            .collaborator
                            .toStringVal();
                        setState(() => {});
                      }
                    },
              isBottomBorderRadiusRemoved: true,
            ),
            DividerWidget(
              dividerType: DividerType.menu,
              bgColor: getEnteColorScheme(context).fillFaint,
            ),
            MenuItemWidget(
              captionedTextWidget: CaptionedTextWidget(
                title: AppLocalizations.of(context).viewer,
              ),
              leadingIcon: Icons.photo_outlined,
              leadingIconColor: getEnteColorScheme(context).strokeBase,
              menuItemColor: getEnteColorScheme(context).fillFaint,
              trailingIcon: widget.user.isViewer ? Icons.check : null,
              showOnlyLoadingState: true,
              onTap: widget.user.isViewer
                  ? null
                  : () async {
                      final actionResult = await showChoiceActionSheet(
                        context,
                        title: AppLocalizations.of(context).changePermissions,
                        firstButtonLabel:
                            AppLocalizations.of(context).yesConvertToViewer,
                        body: AppLocalizations.of(context)
                            .cannotAddMorePhotosAfterBecomingViewer(
                          user: widget.user.displayName ?? widget.user.email,
                        ),
                        isCritical: true,
                      );
                      if (actionResult?.action != null) {
                        if (actionResult!.action == ButtonAction.first) {
                          try {
                            isConvertToViewSuccess =
                                await collectionActions.addEmailToCollection(
                              context,
                              widget.collection,
                              widget.user.email,
                              CollectionParticipantRole.viewer,
                            );
                          } catch (e) {
                            await showGenericErrorDialog(
                              context: context,
                              error: e,
                            );
                          }
                          if (isConvertToViewSuccess && mounted) {
                            // reset value
                            isConvertToViewSuccess = false;
                            widget.user.role =
                                CollectionParticipantRole.viewer.toStringVal();
                            setState(() => {});
                          }
                        }
                      }
                    },
              isTopBorderRadiusRemoved: true,
            ),
            MenuSectionDescriptionWidget(
              content: AppLocalizations.of(context)
                  .collaboratorsCanAddPhotosAndVideosToTheSharedAlbum,
            ),
            const SizedBox(height: 24),
            MenuSectionTitle(
              title: AppLocalizations.of(context).removeParticipant,
            ),
            MenuItemWidget(
              captionedTextWidget: CaptionedTextWidget(
                title: AppLocalizations.of(context).remove,
                textColor: warning500,
                makeTextBold: true,
              ),
              leadingIcon: Icons.not_interested_outlined,
              leadingIconColor: warning500,
              menuItemColor: getEnteColorScheme(context).fillFaint,
              surfaceExecutionStates: false,
              onTap: () async {
                final result = await collectionActions.removeParticipant(
                  context,
                  widget.collection,
                  widget.user,
                );

                if ((result) && mounted) {
                  Navigator.of(context).pop(true);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
