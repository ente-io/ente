import "package:ente_sharing/models/user.dart";
import "package:ente_ui/components/buttons/button_widget.dart";
import "package:ente_ui/components/captioned_text_widget.dart";
import "package:ente_ui/components/divider_widget.dart";
import "package:ente_ui/components/menu_item_widget.dart";
import "package:ente_ui/components/menu_section_description_widget.dart";
import "package:ente_ui/components/menu_section_title.dart";
import "package:ente_ui/components/title_bar_title_widget.dart";
import "package:ente_ui/theme/colors.dart";
import "package:ente_ui/theme/ente_theme.dart";
import "package:ente_ui/utils/dialog_util.dart";
import 'package:flutter/material.dart';
import "package:locker/extensions/user_extension.dart";
import "package:locker/l10n/l10n.dart";
import "package:locker/services/collections/models/collection.dart";
import "package:locker/utils/collection_actions.dart";

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
  late CollectionActions collectionActions;

  @override
  void initState() {
    super.initState();
    collectionActions = CollectionActions();
  }

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
                    title: context.l10n.manage,
                  ),
                  Text(
                    widget.user.email,
                    textAlign: TextAlign.left,
                    style:
                        textTheme.small.copyWith(color: colorScheme.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            MenuSectionTitle(title: context.l10n.addedAs),
            MenuItemWidget(
              captionedTextWidget: CaptionedTextWidget(
                title: context.l10n.collaborator,
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
                title: context.l10n.viewer,
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
                        title: context.l10n.changePermissions,
                        firstButtonLabel: context.l10n.yesConvertToViewer,
                        body:
                            context.l10n.cannotAddMoreFilesAfterBecomingViewer(
                          widget.user.displayName ?? widget.user.email,
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
              content: context.l10n.collaboratorsCanAddFilesToTheSharedAlbum,
            ),
            const SizedBox(height: 24),
            MenuSectionTitle(title: context.l10n.removeParticipant),
            MenuItemWidget(
              captionedTextWidget: CaptionedTextWidget(
                title: context.l10n.remove,
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
