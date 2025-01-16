import "package:email_validator/email_validator.dart";
import 'package:flutter/material.dart';
import 'package:photos/core/configuration.dart';
import "package:photos/generated/l10n.dart";
import "package:photos/models/api/collection/user.dart";
import 'package:photos/services/collections_service.dart';
import "package:photos/services/user_service.dart";
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/actions/collection/collection_sharing_actions.dart';
import 'package:photos/ui/components/buttons/button_widget.dart';
import 'package:photos/ui/components/captioned_text_widget.dart';
import 'package:photos/ui/components/divider_widget.dart';
import 'package:photos/ui/components/menu_item_widget/menu_item_widget.dart';
import 'package:photos/ui/components/menu_section_title.dart';
import 'package:photos/ui/components/models/button_type.dart';
import "package:photos/ui/components/text_input_widget.dart";
import 'package:photos/ui/sharing/user_avator_widget.dart';
import "package:photos/utils/toast_util.dart";

class LinkEmailScreen extends StatefulWidget {
  const LinkEmailScreen({super.key});

  @override
  State<StatefulWidget> createState() => _LinkEmailScreen();
}

class _LinkEmailScreen extends State<LinkEmailScreen> {
  String? _selectedEmail;
  String _newEmail = '';
  bool _emailIsValid = false;
  bool isKeypadOpen = false;
  late CollectionActions collectionActions;
  late List<User> _suggestedUsers;

  // Focus nodes are necessary
  final textFieldFocusNode = FocusNode();
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    collectionActions = CollectionActions(CollectionsService.instance);
    _suggestedUsers = _getContacts();
  }

  @override
  void dispose() {
    _textController.dispose();
    textFieldFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filterSuggestedUsers = _suggestedUsers
        .where(
          (element) => element.email.toLowerCase().contains(
                _textController.text.trim().toLowerCase(),
              ),
        )
        .toList();
    isKeypadOpen = MediaQuery.viewInsetsOf(context).bottom > 100;

    return Scaffold(
      resizeToAvoidBottomInset: isKeypadOpen,
      appBar: AppBar(
        title: const Text(
          "Link email",
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: MenuSectionTitle(
              title: "Add a new email",
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextInputWidget(
              hintText: S.of(context).email,
              textEditingController: _textController,
              shouldSurfaceExecutionStates: false,
              onChange: (value) {
                _newEmail = value.trim();
                _emailIsValid = EmailValidator.validate(_newEmail);
                setState(() {});
              },
              focusNode: textFieldFocusNode,
              keyboardType: TextInputType.emailAddress,
              shouldUnfocusOnClearOrSubmit: true,
              autoCorrect: false,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  filterSuggestedUsers.isNotEmpty
                      ? const MenuSectionTitle(
                          title: "Or pick from your contacts",
                        )
                      : const SizedBox.shrink(),
                  Expanded(
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        final currentUser = filterSuggestedUsers[index];
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
                                  (_selectedEmail == currentUser.email)
                                      ? Icons.check
                                      : null,
                              onTap: () async {
                                textFieldFocusNode.unfocus();
                                if (_selectedEmail == currentUser.email) {
                                  _selectedEmail = null;
                                } else {
                                  _selectedEmail = currentUser.email;
                                }
                                setState(() => {});
                              },
                              isTopBorderRadiusRemoved: index > 0,
                              isBottomBorderRadiusRemoved:
                                  index < (filterSuggestedUsers.length - 1),
                            ),
                            (index == (filterSuggestedUsers.length - 1))
                                ? const SizedBox.shrink()
                                : DividerWidget(
                                    dividerType: DividerType.menu,
                                    bgColor:
                                        getEnteColorScheme(context).fillFaint,
                                  ),
                          ],
                        );
                      },
                      itemCount: filterSuggestedUsers.length,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(
                top: 8,
                bottom: 8,
                left: 16,
                right: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 8),
                  ButtonWidget(
                    buttonType: ButtonType.primary,
                    buttonSize: ButtonSize.large,
                    labelText: "Link",
                    isDisabled: _selectedEmail == null,
                    onTap: () async {
                      //Check if email is vaild and do operation
                      showToast(
                        context,
                        "Linked",
                      );

                      //if successfull
                      Navigator.of(context).pop(true);
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<User> _getContacts() {
    final List<User> suggestedUsers = [];
    final int ownerID = Configuration.instance.getUserID()!;

    for (final c in CollectionsService.instance.getActiveCollections()) {
      if (c.owner?.id == ownerID) {
        for (final User? u in c.sharees ?? []) {
          if (u != null && u.id != null && u.email.isNotEmpty) {
            if (!suggestedUsers.any((user) => user.email == u.email)) {
              suggestedUsers.add(u);
            }
          }
        }
      } else if (c.owner != null &&
          c.owner!.id != null &&
          c.owner!.email.isNotEmpty) {
        if (!suggestedUsers.any((user) => user.email == c.owner!.email)) {
          suggestedUsers.add(c.owner!);
        }
      }
    }
    final cachedUserDetails = UserService.instance.getCachedUserDetails();
    if (cachedUserDetails != null &&
        (cachedUserDetails.familyData?.members?.isNotEmpty ?? false)) {
      for (final member in cachedUserDetails.familyData!.members!) {
        if (!suggestedUsers.any((user) => user.email == member.email)) {
          suggestedUsers.add(User(email: member.email));
        }
      }
    }

    suggestedUsers.sort((a, b) => a.email.compareTo(b.email));

    return suggestedUsers;
  }
}
