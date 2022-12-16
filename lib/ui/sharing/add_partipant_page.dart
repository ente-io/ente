import 'package:email_validator/email_validator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/models/collection.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/actions/collection/collection_sharing_actions.dart';
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
  String _email = '';
  bool hideListOfEmails = false;
  bool _emailIsValid = false;
  bool isKeypadOpen = false;
  late CollectionActions collectionActions;

  // Focus nodes are necessary
  final textFieldFocusNode = FocusNode();
  final _textController = TextEditingController();

  @override
  void initState() {
    selectAsViewer = true;
    collectionActions = CollectionActions(CollectionsService.instance);
    super.initState();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    isKeypadOpen = MediaQuery.of(context).viewInsets.bottom > 100;
    final enteTextTheme = getEnteTextTheme(context);
    final List<User> suggestedUsers = _getSuggestedUser();
    hideListOfEmails = suggestedUsers.isEmpty;
    return Scaffold(
      resizeToAvoidBottomInset: isKeypadOpen,
      appBar: AppBar(
        title: const Text("Add people"),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              "Add a new email",
              style: enteTextTheme.body,
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _getEmailField(),
          ),
          (hideListOfEmails || isKeypadOpen)
              ? const Expanded(child: SizedBox())
              : Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                                      textFieldFocusNode.unfocus();
                                      if (selectedEmail == currentUser.email) {
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
                ),
          const DividerWidget(
            dividerType: DividerType.solid,
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const MenuSectionTitle(title: "Add as"),
                  MenuItemWidget(
                    captionedTextWidget: const CaptionedTextWidget(
                      title: "Collaborator",
                    ),
                    leadingIcon: Icons.edit_outlined,
                    menuItemColor: getEnteColorScheme(context).fillFaint,
                    pressedColor: getEnteColorScheme(context).fillFaint,
                    trailingIcon: !selectAsViewer ? Icons.check : null,
                    onTap: () async {
                      if (kDebugMode) {
                        setState(() => {selectAsViewer = false});
                      } else {
                        showShortToast(context, "Coming soon...");
                      }
                    },
                    isBottomBorderRadiusRemoved: true,
                  ),
                  DividerWidget(
                    dividerType: DividerType.menu,
                    bgColor: getEnteColorScheme(context).blurStrokeFaint,
                  ),
                  MenuItemWidget(
                    captionedTextWidget: const CaptionedTextWidget(
                      title: "Viewer",
                    ),
                    leadingIcon: Icons.photo_outlined,
                    menuItemColor: getEnteColorScheme(context).fillFaint,
                    pressedColor: getEnteColorScheme(context).fillFaint,
                    trailingIcon: selectAsViewer ? Icons.check : null,
                    onTap: () async {
                      setState(() => {selectAsViewer = true});
                      // showShortToast(context, "yet to implement");
                    },
                    isTopBorderRadiusRemoved: true,
                  ),
                  !isKeypadOpen
                      ? const MenuSectionDescriptionWidget(
                          content:
                              "Collaborators can add photos and videos to the shared album.",
                        )
                      : const SizedBox.shrink(),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: GradientButton(
                      onTap: (selectedEmail == '' && !_emailIsValid)
                          ? null
                          : () async {
                              final emailToAdd =
                                  selectedEmail == '' ? _email : selectedEmail;
                              final result =
                                  await collectionActions.addEmailToCollection(
                                context,
                                widget.collection,
                                emailToAdd,
                                role: selectAsViewer
                                    ? CollectionParticipantRole.viewer
                                    : CollectionParticipantRole.collaborator,
                              );
                              if (result != null && result && mounted) {
                                Navigator.of(context).pop(true);
                              }
                            },
                      text: selectAsViewer ? "Add viewer" : "Add collaborator",
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void clearFocus() {
    _textController.clear();
    _email = _textController.text;
    _emailIsValid = false;
    textFieldFocusNode.unfocus();
    setState(() => {});
  }

  Widget _getEmailField() {
    return TextFormField(
      controller: _textController,
      focusNode: textFieldFocusNode,
      style: getEnteTextTheme(context).body,
      autofillHints: const [AutofillHints.email],
      decoration: InputDecoration(
        focusedBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(4.0)),
          borderSide:
              BorderSide(color: getEnteColorScheme(context).strokeMuted),
        ),
        fillColor: getEnteColorScheme(context).fillFaint,
        filled: true,
        hintText: 'Enter email',
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: UnderlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(4),
        ),
        prefixIcon: Icon(
          Icons.email_outlined,
          color: getEnteColorScheme(context).strokeMuted,
        ),
        suffixIcon: _email == ''
            ? null
            : IconButton(
                onPressed: clearFocus,
                icon: Icon(
                  Icons.cancel,
                  color: getEnteColorScheme(context).strokeMuted,
                ),
              ),
      ),
      onChanged: (value) {
        if (selectedEmail != '') {
          selectedEmail = '';
        }
        _email = value.trim();
        if (_emailIsValid != EmailValidator.validate(_email)) {
          setState(() {
            _emailIsValid = EmailValidator.validate(_email);
          });
        } else if (_email.length < 2) {
          setState(() {});
        }
      },
      autocorrect: false,
      keyboardType: TextInputType.emailAddress,
      //initialValue: _email,
      textInputAction: TextInputAction.next,
    );
  }

  List<User> _getSuggestedUser() {
    final List<User> suggestedUsers = [];
    final Set<int> existingUserIDs = {};
    final int ownerID = Configuration.instance.getUserID()!;
    for (final User? u in widget.collection.sharees ?? []) {
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
