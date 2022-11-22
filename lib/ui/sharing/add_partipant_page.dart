import 'package:flutter/material.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/models/collection.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/services/update_service.dart';
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
  const AddParticipantPage({super.key});

  @override
  State<StatefulWidget> createState() => _AddParticipantPage();
}

class _AddParticipantPage extends State<AddParticipantPage> {
  late bool selectAsViewer;
  String selectedEmail = '';

  @override
  void initState() {
    selectAsViewer = true;
    super.initState();
  }

  Widget build(BuildContext context) {
    final enteColorScheme = getEnteColorScheme(context);
    final enteTextTheme = getEnteTextTheme(context);
    final int ownerID = Configuration.instance.getUserID()!;
    final List<String> emails = [];
    for (final c in CollectionsService.instance.getActiveCollections()) {
      if (c.owner?.id == ownerID) {
        c.sharees?.forEach((e) => emails.add(e!.email));
      } else {
        emails.add(c.owner!.email);
      }
    }
    final List<String> finalList = emails.toSet().toList();
    finalList.sort();
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
              const SizedBox(height: 24),
              const MenuSectionTitle(title: "or pick an existing one"),
              Expanded(
                child: ListView.builder(
                  itemBuilder: (context, index) {
                    final currentEmail = finalList[index];
                    return Column(
                      children: [
                        MenuItemWidget(
                          captionedTextWidget: CaptionedTextWidget(
                            title: finalList[index],
                          ),
                          leadingIconSize: 24.0,
                          leadingIconWidget: UserAvatarWidget(
                            User(
                              id: currentEmail.hashCode,
                              email: currentEmail,
                            ),
                            type: AvatarType.mini,
                          ),
                          menuItemColor: getEnteColorScheme(context).fillFaint,
                          pressedColor: getEnteColorScheme(context).fillFaint,
                          trailingIcon: (selectedEmail == finalList[index])
                              ? Icons.check
                              : null,
                          onTap: () async {
                            if(selectedEmail == finalList[index]) {
                              selectedEmail = '';
                            } else {
                              selectedEmail = finalList[index];
                            }

                            setState(() => {});
                            // showShortToast(context, "yet to implement");
                          },
                          isTopBorderRadiusRemoved: index > 0,
                          isBottomBorderRadiusRemoved:
                              index < (finalList.length - 1),
                        ),
                        (index == (finalList.length - 1))
                            ? const SizedBox.shrink()
                            : DividerWidget(
                                dividerType: DividerType.menu,
                                bgColor:
                                    getEnteColorScheme(context).blurStrokeFaint,
                              ),
                      ],
                    );
                  },
                  itemCount: finalList.length,

                  // physics: const ClampingScrollPhysics(),
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
                                  await UpdateService.instance.hideChangeLog();
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
}
