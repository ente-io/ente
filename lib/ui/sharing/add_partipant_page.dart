import 'package:flutter/material.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/models/collection.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/common/gradient_button.dart';
import 'package:photos/ui/components/captioned_text_widget.dart';
import 'package:photos/ui/components/divider_widget.dart';
import 'package:photos/ui/components/menu_item_widget.dart';
import 'package:photos/ui/components/menu_section_description_widget.dart';
import 'package:photos/ui/components/menu_section_title.dart';
import 'package:photos/ui/sharing/user_avator_widget.dart';
import 'package:photos/utils/toast_util.dart';

class AddParticipantPage extends StatefulWidget {
  final Collection collection;

  const AddParticipantPage(this.collection, {super.key});

  @override
  State<StatefulWidget> createState() => _AddParticipantPage();
}

class _AddParticipantPage extends State<AddParticipantPage> {
  late bool selectAsViewer;
  String selectedEmail = '';
  bool hideListOfEmails = false;

  @override
  void initState() {
    selectAsViewer = true;
    super.initState();
  }

  Widget build(BuildContext context) {
    final enteColorScheme = getEnteColorScheme(context);
    final enteTextTheme = getEnteTextTheme(context);
    final List<User> suggestedUsers = _getSuggestedUser();
    hideListOfEmails = suggestedUsers.isEmpty;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add people"),
      ),
      body: Container(
        color: enteColorScheme.backgroundElevated,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Text(
                "Add a new email",
                style: enteTextTheme.body,
              ),
              hideListOfEmails
                  ? const Expanded(child: SizedBox())
                  : Expanded(
                      child: Column(
                        children: [
                          const SizedBox(height: 24),
                          const MenuSectionTitle(
                            title: "or pick an existing one",
                          ),
                          Expanded(
                            child: ListView.builder(
                              itemBuilder: (context, index) {
                                final currentUser = suggestedUsers[index];
                                return Column(
                                  children: [
                                    MenuItemWidget(
                                      captionedTextWidget: CaptionedTextWidget(
                                        title: currentUser.email,
                                      ),
                                      leadingIconSize: 24.0,
                                      leadingIconWidget: UserAvatarWidget(
                                        currentUser,
                                        type: AvatarType.mini,
                                      ),
                                      menuItemColor:
                                          getEnteColorScheme(context).fillFaint,
                                      pressedColor:
                                          getEnteColorScheme(context).fillFaint,
                                      trailingIcon:
                                          (selectedEmail == currentUser.email)
                                              ? Icons.check
                                              : null,
                                      onTap: () async {
                                        if (selectedEmail ==
                                            currentUser.email) {
                                          selectedEmail = '';
                                        } else {
                                          selectedEmail = currentUser.email;
                                        }

                                        setState(() => {});
                                        // showShortToast(context, "yet to implement");
                                      },
                                      isTopBorderRadiusRemoved: index > 0,
                                      isBottomBorderRadiusRemoved:
                                          index < (suggestedUsers.length - 1),
                                    ),
                                    (index == (suggestedUsers.length - 1))
                                        ? const SizedBox.shrink()
                                        : DividerWidget(
                                            dividerType: DividerType.menu,
                                            bgColor: getEnteColorScheme(context)
                                                .blurStrokeFaint,
                                          ),
                                  ],
                                );
                              },
                              itemCount: suggestedUsers.length,

                              // physics: const ClampingScrollPhysics(),
                            ),
                          ),
                        ],
                      ),
                    ),
              const DividerWidget(
                dividerType: DividerType.solid,
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const MenuSectionTitle(title: "Add as"),
                      MenuItemWidget(
                        captionedTextWidget: const CaptionedTextWidget(
                          title: "Collaborator",
                        ),
                        leadingIcon: Icons.edit,
                        menuItemColor: getEnteColorScheme(context).fillFaint,
                        pressedColor: getEnteColorScheme(context).fillFaint,
                        trailingIcon: !selectAsViewer ? Icons.check : null,
                        onTap: () async {
                          showShortToast(context, "coming soon!");
                          setState(() => {selectAsViewer = false});
                        },
                        isBottomBorderRadiusRemoved: true,
                      ),
                      DividerWidget(
                        dividerType: DividerType.menu,
                        bgColor: getEnteColorScheme(context).blurStrokeFaint,
                      ),
                      MenuItemWidget(
                        captionedTextWidget: const CaptionedTextWidget(
                          title: " Viewer",
                        ),
                        leadingIcon: Icons.photo,
                        menuItemColor: getEnteColorScheme(context).fillFaint,
                        pressedColor: getEnteColorScheme(context).fillFaint,
                        trailingIcon: selectAsViewer ? Icons.check : null,
                        onTap: () async {
                          setState(() => {selectAsViewer = true});
                          // showShortToast(context, "yet to implement");
                        },
                        isTopBorderRadiusRemoved: true,
                      ),
                      const MenuSectionDescriptionWidget(
                        content:
                            "Collaborators can add photos and videos to the shared album.",
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: GradientButton(
                          onTap: selectedEmail == ''
                              ? null
                              : () async {
                                  showToast(context, "yet to implement");
                                  Navigator.of(context).pop();
                                },
                          text: selectAsViewer
                              ? "Add viewer"
                              : "Add collaborator",
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<User> _getSuggestedUser() {
    final List<User> suggestedUsers = [];
    final Set<int> existingUserIDs = {};
    final int ownerID = Configuration.instance.getUserID()!;
    for (final User? u in widget.collection?.sharees ?? []) {
      if (u != null && u.id != null) {
        existingUserIDs.add(u.id!);
      }
    }
    for (final c in CollectionsService.instance.getActiveCollections()) {
      if (c.owner?.id == ownerID) {
        for (final User? u in c?.sharees ?? []) {
          if (u != null && u.id != null && !existingUserIDs.contains(u.id)) {
            existingUserIDs.add(u.id!);
            suggestedUsers.add(u);
          }
        }
      } else if (c.owner != null &&
          c.owner!.id != null &&
          !existingUserIDs.contains(c.owner!.id!)) {
        existingUserIDs.add(c.owner!.id!);
        suggestedUsers.add(c.owner!);
      }
    }
    suggestedUsers.sort((a, b) => a.email.compareTo(b.email));
    return suggestedUsers;
  }
}
