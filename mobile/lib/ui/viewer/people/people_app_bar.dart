import 'dart:async';

import "package:flutter/cupertino.dart";
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/event_bus.dart';
import "package:photos/events/people_changed_event.dart";
import 'package:photos/events/subscription_purchased_event.dart';
import "package:photos/generated/l10n.dart";
import "package:photos/models/file/file.dart";
import 'package:photos/models/gallery_type.dart';
import "package:photos/models/ml/face/person.dart";
import 'package:photos/models/selected_files.dart';
import 'package:photos/services/collections_service.dart';
import "package:photos/services/machine_learning/face_ml/person/person_service.dart";
import 'package:photos/ui/actions/collection/collection_sharing_actions.dart';
import "package:photos/ui/viewer/people/add_person_action_sheet.dart";
import "package:photos/ui/viewer/people/people_page.dart";
import "package:photos/ui/viewer/people/person_cluster_suggestion.dart";
import "package:photos/utils/dialog_util.dart";
import "package:photos/utils/navigation_util.dart";

class PeopleAppBar extends StatefulWidget {
  final GalleryType type;
  final String? title;
  final SelectedFiles selectedFiles;
  final PersonEntity person;

  bool get isIgnored => person.data.isIgnored;

  const PeopleAppBar(
    this.type,
    this.title,
    this.selectedFiles,
    this.person, {
    Key? key,
  }) : super(key: key);

  @override
  State<PeopleAppBar> createState() => _AppBarWidgetState();
}

enum PeoplePopupAction {
  rename,
  setCover,
  removeLabel,
  reviewSuggestions,
  unignore,
}

class _AppBarWidgetState extends State<PeopleAppBar> {
  final _logger = Logger("_AppBarWidgetState");
  late StreamSubscription _userAuthEventSubscription;
  late Function() _selectedFilesListener;
  String? _appBarTitle;
  late CollectionActions collectionActions;
  final GlobalKey shareButtonKey = GlobalKey();
  bool isQuickLink = false;
  late GalleryType galleryType;

  @override
  void initState() {
    super.initState();
    _selectedFilesListener = () {
      setState(() {});
    };
    collectionActions = CollectionActions(CollectionsService.instance);
    widget.selectedFiles.addListener(_selectedFilesListener);
    _userAuthEventSubscription =
        Bus.instance.on<SubscriptionPurchasedEvent>().listen((event) {
      setState(() {});
    });
    _appBarTitle = widget.title;
    galleryType = widget.type;
  }

  @override
  void dispose() {
    _userAuthEventSubscription.cancel();
    widget.selectedFiles.removeListener(_selectedFilesListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      centerTitle: false,
      title: Text(
        _appBarTitle!,
        style:
            Theme.of(context).textTheme.headlineSmall!.copyWith(fontSize: 16),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      actions: _getDefaultActions(context),
    );
  }

  Future<dynamic> _renamePerson(BuildContext context) async {
    final result = await showTextInputDialog(
      context,
      title: S.of(context).rename,
      submitButtonLabel: S.of(context).done,
      hintText: S.of(context).enterPersonName,
      alwaysShowSuccessState: true,
      initialValue: widget.person.data.name,
      textCapitalization: TextCapitalization.words,
      onSubmit: (String text) async {
        // indicates user cancelled the rename request
        if (text == "" || text == _appBarTitle!) {
          return;
        }

        try {
          await PersonService.instance
              .updateAttributes(widget.person.remoteID, name: text);
          if (mounted) {
            _appBarTitle = text;
            setState(() {});
          }
          Bus.instance.fire(PeopleChangedEvent());
        } catch (e, s) {
          _logger.severe("Failed to rename album", e, s);
          rethrow;
        }
      },
    );
    if (result is Exception) {
      await showGenericErrorDialog(context: context, error: result);
    }
  }

  List<Widget> _getDefaultActions(BuildContext context) {
    final List<Widget> actions = <Widget>[];
    // If the user has selected files, don't show any actions
    if (widget.selectedFiles.files.isNotEmpty ||
        !Configuration.instance.hasConfiguredAccount()) {
      return actions;
    }

    final List<PopupMenuItem<PeoplePopupAction>> items = [];

    if (!widget.isIgnored) {
      items.addAll(
        [
          PopupMenuItem(
            value: PeoplePopupAction.rename,
            child: Row(
              children: [
                const Icon(Icons.edit),
                const Padding(
                  padding: EdgeInsets.all(8),
                ),
                Text(S.of(context).rename),
              ],
            ),
          ),
          // PopupMenuItem(
          //   value: PeoplPopupAction.setCover,
          //   child: Row(
          //     children: [
          //       const Icon(Icons.image_outlined),
          //       const Padding(
          //         padding: EdgeInsets.all(8),
          //       ),
          //       Text(S.of(context).setCover),
          //     ],
          //   ),
          // ),

          PopupMenuItem(
            value: PeoplePopupAction.removeLabel,
            child: Row(
              children: [
                const Icon(Icons.remove_circle_outline),
                const Padding(
                  padding: EdgeInsets.all(8),
                ),
                Text(S.of(context).removePersonLabel),
              ],
            ),
          ),
          const PopupMenuItem(
            value: PeoplePopupAction.reviewSuggestions,
            child: Row(
              children: [
                Icon(CupertinoIcons.square_stack_3d_down_right),
                Padding(
                  padding: EdgeInsets.all(8),
                ),
                Text('Review suggestions'),
              ],
            ),
          ),
        ],
      );
    } else {
      items.addAll(
        [
          const PopupMenuItem(
            value: PeoplePopupAction.unignore,
            child: Row(
              children: [
                Icon(Icons.visibility_outlined),
                Padding(
                  padding: EdgeInsets.all(8),
                ),
                Text("Show person"),
              ],
            ),
          ),
        ],
      );
    }

    if (items.isNotEmpty) {
      actions.add(
        PopupMenuButton(
          itemBuilder: (context) {
            return items;
          },
          onSelected: (PeoplePopupAction value) async {
            if (value == PeoplePopupAction.reviewSuggestions) {
              // ignore: unawaited_futures
              unawaited(
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        PersonReviewClusterSuggestion(widget.person),
                  ),
                ),
              );
            } else if (value == PeoplePopupAction.rename) {
              await _renamePerson(context);
            } else if (value == PeoplePopupAction.setCover) {
              await setCoverPhoto(context);
            } else if (value == PeoplePopupAction.unignore) {
              await _showPerson(context);
            } else if (value == PeoplePopupAction.removeLabel) {
              await _removePersonLabel(context);
            }
          },
        ),
      );
    }

    return actions;
  }

  Future<void> _removePersonLabel(BuildContext context) async {
    await showChoiceDialog(
      context,
      title: "Are you sure you want to remove this person label?",
      body:
          "All groupings for this person will be reset, and you will lose all suggestions made for this person",
      firstButtonLabel: "Yes, remove person",
      firstButtonOnTap: () async {
        try {
          await PersonService.instance.deletePerson(widget.person.remoteID);
          Navigator.of(context).pop();
        } catch (e, s) {
          _logger.severe('Removing person label failed', e, s);
        }
      },
    );
  }

  Future<void> _showPerson(BuildContext context) async {
    bool assignName = false;
    await showChoiceDialog(
      context,
      title:
          "Are you sure you want to show this person in people section again?",
      firstButtonLabel: "Yes, show person",
      firstButtonOnTap: () async {
        try {
          await PersonService.instance
              .deletePerson(widget.person.remoteID, onlyMapping: false);
          Bus.instance.fire(PeopleChangedEvent());
          assignName = true;
        } catch (e, s) {
          _logger.severe('Unignoring/showing and naming person failed', e, s);
          // await showGenericErrorDialog(context: context, error: e);
        }
      },
    );
    if (assignName) {
      final result = await showAssignPersonAction(
        context,
        clusterID: widget.person.data.assigned!.first.id,
      );
      Navigator.pop(context);
      if (result != null && result is (PersonEntity, EnteFile)) {
        // ignore: unawaited_futures
        routeToPage(context, PeoplePage(person: result.$1));
      } else if (result != null && result is PersonEntity) {
        // ignore: unawaited_futures
        routeToPage(context, PeoplePage(person: result));
      }
    }
  }

  Future<void> setCoverPhoto(BuildContext context) async {
    // final int? coverPhotoID = await showPickCoverPhotoSheet(
    //   context,
    //   widget.collection!,
    // );
    // if (coverPhotoID != null) {
    //   unawaited(changeCoverPhoto(context, widget.collection!, coverPhotoID));
    // }
  }
}
