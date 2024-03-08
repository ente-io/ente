import 'dart:async';

import "package:flutter/cupertino.dart";
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/event_bus.dart';
import "package:photos/events/people_changed_event.dart";
import 'package:photos/events/subscription_purchased_event.dart';
import "package:photos/face/db.dart";
import "package:photos/face/model/person.dart";
import "package:photos/generated/l10n.dart";
import 'package:photos/models/gallery_type.dart';
import 'package:photos/models/selected_files.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/ui/actions/collection/collection_sharing_actions.dart';
import "package:photos/ui/viewer/people/person_cluserts.dart";
import "package:photos/ui/viewer/people/person_cluster_suggestion.dart";
import "package:photos/utils/dialog_util.dart";

class PeopleAppBar extends StatefulWidget {
  final GalleryType type;
  final String? title;
  final SelectedFiles selectedFiles;
  final Person person;

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

enum PeoplPopupAction {
  rename,
  setCover,
  viewPhotos,
  confirmPhotos,
  hide,
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

  Future<dynamic> _renameAlbum(BuildContext context) async {
    final result = await showTextInputDialog(
      context,
      title: 'Rename',
      submitButtonLabel: S.of(context).done,
      hintText: S.of(context).enterAlbumName,
      alwaysShowSuccessState: true,
      initialValue: widget.person.attr.name,
      textCapitalization: TextCapitalization.words,
      onSubmit: (String text) async {
        // indicates user cancelled the rename request
        if (text == "" || text == _appBarTitle!) {
          return;
        }

        try {
          final updatePerson = widget.person
              .copyWith(attr: widget.person.attr.copyWith(name: text));
          await FaceMLDataDB.instance.updatePerson(updatePerson);
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

    final List<PopupMenuItem<PeoplPopupAction>> items = [];

    items.addAll(
      [
        PopupMenuItem(
          value: PeoplPopupAction.rename,
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
        // PopupMenuItem(
        //   value: PeoplPopupAction.rename,
        //   child: Row(
        //     children: [
        //       const Icon(Icons.visibility_off),
        //       const Padding(
        //         padding: EdgeInsets.all(8),
        //       ),
        //       Text(S.of(context).hide),
        //     ],
        //   ),
        // ),
        const PopupMenuItem(
          value: PeoplPopupAction.viewPhotos,
          child: Row(
            children: [
              Icon(Icons.view_array_outlined),
              Padding(
                padding: EdgeInsets.all(8),
              ),
              Text('View confirmed photos'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: PeoplPopupAction.confirmPhotos,
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

    if (items.isNotEmpty) {
      actions.add(
        PopupMenuButton(
          itemBuilder: (context) {
            return items;
          },
          onSelected: (PeoplPopupAction value) async {
            if (value == PeoplPopupAction.viewPhotos) {
              // ignore: unawaited_futures
              unawaited(
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => PersonClusters(widget.person),
                  ),
                ),
              );
            } else if (value == PeoplPopupAction.confirmPhotos) {
              // ignore: unawaited_futures
              unawaited(
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        PersonReviewClusterSuggestion(widget.person),
                  ),
                ),
              );
            } else if (value == PeoplPopupAction.rename) {
              await _renameAlbum(context);
            } else if (value == PeoplPopupAction.setCover) {
              await setCoverPhoto(context);
            } else if (value == PeoplPopupAction.hide) {
              // ignore: unawaited_futures
            }
          },
        ),
      );
    }

    return actions;
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
