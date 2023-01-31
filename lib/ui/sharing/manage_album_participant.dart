import 'package:flutter/material.dart';
import 'package:photos/models/collection.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/theme/colors.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/actions/collection/collection_sharing_actions.dart';
import 'package:photos/ui/components/action_sheet_widget.dart';
import 'package:photos/ui/components/button_widget.dart';
import 'package:photos/ui/components/captioned_text_widget.dart';
import 'package:photos/ui/components/divider_widget.dart';
import 'package:photos/ui/components/menu_item_widget.dart';
import 'package:photos/ui/components/menu_section_description_widget.dart';
import 'package:photos/ui/components/menu_section_title.dart';
import 'package:photos/ui/components/models/button_type.dart';
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
                  const TitleBarTitleWidget(
                    title: "Manage",
                  ),
                  Text(
                    widget.user.email.toString().trim(),
                    textAlign: TextAlign.left,
                    style:
                        textTheme.small.copyWith(color: colorScheme.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const MenuSectionTitle(title: "Added as"),
            MenuItemWidget(
              captionedTextWidget: const CaptionedTextWidget(
                title: "Collaborator",
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
                        showProgress: true,
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
              captionedTextWidget: const CaptionedTextWidget(
                title: "Viewer",
              ),
              leadingIcon: Icons.photo_outlined,
              leadingIconColor: getEnteColorScheme(context).strokeBase,
              menuItemColor: getEnteColorScheme(context).fillFaint,
              trailingIcon: widget.user.isViewer ? Icons.check : null,
              onTap: widget.user.isViewer
                  ? null
                  : () async {
                      final ButtonAction? result = await showActionSheet(
                        context: context,
                        buttons: [
                          ButtonWidget(
                            buttonType: ButtonType.critical,
                            isInAlert: true,
                            shouldStickToDarkTheme: true,
                            buttonAction: ButtonAction.first,
                            shouldSurfaceExecutionStates: true,
                            labelText: "Yes, convert to viewer",
                            onTap: () async {
                              isConvertToViewSuccess =
                                  await collectionActions.addEmailToCollection(
                                context,
                                widget.collection,
                                widget.user.email,
                                CollectionParticipantRole.viewer,
                              );
                            },
                          ),
                          const ButtonWidget(
                            buttonType: ButtonType.secondary,
                            buttonAction: ButtonAction.cancel,
                            isInAlert: true,
                            shouldStickToDarkTheme: true,
                            labelText: "Cancel",
                          )
                        ],
                        title: "Change permissions?",
                        body:
                            '${widget.user.email} will not be able to add more photos to this album\n\nThey will still be able to remove existing photos added by them',
                      );
                      if (result != null) {
                        if (result == ButtonAction.error) {
                          showGenericErrorDialog(context: context);
                        }
                        if (result == ButtonAction.first &&
                            isConvertToViewSuccess &&
                            mounted) {
                          // reset value
                          isConvertToViewSuccess = false;
                          widget.user.role =
                              CollectionParticipantRole.viewer.toStringVal();
                          setState(() => {});
                        }
                      }
                    },
              isTopBorderRadiusRemoved: true,
            ),
            const MenuSectionDescriptionWidget(
              content:
                  "Collaborators can add photos and videos to the shared album.",
            ),
            const SizedBox(height: 24),
            const MenuSectionTitle(title: "Remove participant"),
            MenuItemWidget(
              captionedTextWidget: const CaptionedTextWidget(
                title: "Remove",
                textColor: warning500,
                makeTextBold: true,
              ),
              leadingIcon: Icons.not_interested_outlined,
              leadingIconColor: warning500,
              menuItemColor: getEnteColorScheme(context).fillFaint,
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
            )
          ],
        ),
      ),
    );
  }
}
