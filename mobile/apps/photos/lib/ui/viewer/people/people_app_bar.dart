import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import "package:photos/core/constants.dart";
import 'package:photos/core/event_bus.dart';
import "package:photos/events/people_changed_event.dart";
import 'package:photos/events/subscription_purchased_event.dart';
import "package:photos/generated/l10n.dart";
import "package:photos/l10n/l10n.dart";
import "package:photos/models/file/file.dart";
import 'package:photos/models/gallery_type.dart';
import "package:photos/models/ml/face/person.dart";
import 'package:photos/models/selected_files.dart';
import 'package:photos/services/collections_service.dart';
import "package:photos/services/machine_learning/face_ml/person/person_service.dart";
import "package:photos/theme/ente_theme.dart";
import 'package:photos/ui/actions/collection/collection_sharing_actions.dart';
import "package:photos/ui/viewer/gallery/hooks/pick_person_avatar.dart";
import "package:photos/ui/viewer/gallery/state/inherited_search_filter_data.dart";
import "package:photos/ui/viewer/hierarchicial_search/applied_filters_for_appbar.dart";
import "package:photos/ui/viewer/hierarchicial_search/recommended_filters_for_appbar.dart";
import "package:photos/ui/viewer/people/add_person_action_sheet.dart";
import "package:photos/ui/viewer/people/people_page.dart";
import "package:photos/ui/viewer/people/person_cluster_suggestion.dart";
import "package:photos/ui/viewer/people/person_selection_action_widgets.dart";
import "package:photos/ui/viewer/people/save_or_edit_person.dart";
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
    super.key,
  });

  @override
  State<PeopleAppBar> createState() => _AppBarWidgetState();
}

enum PeoplePopupAction {
  rename,
  setCover,
  removeLabel,
  reviewSuggestions,
  unignore,
  reassignMe,
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
  late PersonEntity person;
  late StreamSubscription<PeopleChangedEvent> _peopleChangedEventSubscription;

  @override
  void initState() {
    super.initState();
    person = widget.person;
    galleryType = widget.type;
    collectionActions = CollectionActions(CollectionsService.instance);
    _selectedFilesListener = () {
      setState(() {});
    };

    widget.selectedFiles.addListener(_selectedFilesListener);
    _userAuthEventSubscription =
        Bus.instance.on<SubscriptionPurchasedEvent>().listen((event) {
      setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        if (person.data.email == Configuration.instance.getEmail()) {
          // Don't know of any case where this will be null but just being safe
          if (widget.title == null) {
            _appBarTitle = "Me";
          } else {
            _appBarTitle = context.l10n
                .accountOwnerPersonAppbarTitle(title: widget.title!);
          }
        } else {
          _appBarTitle = widget.title;
        }

        _peopleChangedEventSubscription =
            Bus.instance.on<PeopleChangedEvent>().listen(
          (event) {
            if (event.person != null &&
                event.type == PeopleEventType.saveOrEditPerson &&
                widget.person.remoteID == event.person!.remoteID &&
                (event.source == "linkEmailToPerson" ||
                    event.source == "reassignMe")) {
              person = event.person!;

              if (person.data.email == Configuration.instance.getEmail()) {
                _appBarTitle = context.l10n.accountOwnerPersonAppbarTitle(
                  title: person.data.name,
                );
              } else {
                _appBarTitle = person.data.name;
              }
              setState(() {});
            }
          },
        );
      });
    });
  }

  @override
  void dispose() {
    _userAuthEventSubscription.cancel();
    widget.selectedFiles.removeListener(_selectedFilesListener);
    _peopleChangedEventSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inheritedSearchFilterData =
        InheritedSearchFilterData.maybeOf(context);
    final isHierarchicalSearchable =
        inheritedSearchFilterData?.isHierarchicalSearchable ?? false;
    return isHierarchicalSearchable
        ? ValueListenableBuilder(
            valueListenable: inheritedSearchFilterData!
                .searchFilterDataProvider!.isSearchingNotifier,
            child: const PreferredSize(
              preferredSize: Size.fromHeight(0),
              child: Flexible(child: RecommendedFiltersForAppbar()),
            ),
            builder: (context, isSearching, child) {
              return AppBar(
                elevation: 0,
                centerTitle: false,
                title: isSearching
                    ? const SizedBox(
                        // +1 to account for the filter's outer stroke width
                        height: kFilterChipHeight + 1,
                        child: AppliedFiltersForAppbar(),
                      )
                    : Text(
                        _appBarTitle ?? "",
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall!
                            .copyWith(fontSize: 16),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                bottom: child as PreferredSizeWidget,
                actions: isSearching ? null : _getDefaultActions(context),
                surfaceTintColor: Colors.transparent,
              );
            },
          )
        : AppBar(
            elevation: 0,
            centerTitle: false,
            title: Text(
              _appBarTitle ?? "",
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall!
                  .copyWith(fontSize: 16),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            actions: _getDefaultActions(context),
          );
  }

  Future<dynamic> _editPerson(BuildContext context) async {
    final result = await routeToPage(
      context,
      SaveOrEditPerson(
        person.data.assigned.first.id,
        person: person,
        isEditing: true,
      ),
    );
    if (result is PersonEntity) {
      _appBarTitle = result.data.name;
      person = result;
      setState(() {});
    }
  }

  List<Widget> _getDefaultActions(BuildContext context) {
    final textTheme = getEnteTextTheme(context);
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
                Text(
                  AppLocalizations.of(context).edit,
                  style: textTheme.bodyBold,
                ),
              ],
            ),
          ),
          PopupMenuItem(
            value: PeoplePopupAction.reviewSuggestions,
            child: Row(
              children: [
                const Icon(Icons.search_outlined),
                const Padding(
                  padding: EdgeInsets.all(8),
                ),
                Text(
                  AppLocalizations.of(context).review,
                  style: textTheme.bodyBold,
                ),
              ],
            ),
          ),
          PopupMenuItem(
            value: PeoplePopupAction.setCover,
            child: Row(
              children: [
                const Icon(Icons.image_outlined),
                const Padding(
                  padding: EdgeInsets.all(8),
                ),
                Text(
                  AppLocalizations.of(context).setCover,
                  style: textTheme.bodyBold,
                ),
              ],
            ),
          ),
          if (widget.person.data.email != null &&
              (widget.person.data.email == Configuration.instance.getEmail()))
            PopupMenuItem(
              value: PeoplePopupAction.reassignMe,
              child: Row(
                children: [
                  const Icon(Icons.person_2_outlined),
                  const Padding(
                    padding: EdgeInsets.all(8),
                  ),
                  Text(
                    context.l10n.reassignMe,
                    style: textTheme.bodyBold,
                  ),
                ],
              ),
            ),
          PopupMenuItem(
            value: PeoplePopupAction.removeLabel,
            child: Row(
              children: [
                const Icon(Icons.delete_outline),
                const Padding(
                  padding: EdgeInsets.all(8),
                ),
                Text(
                  AppLocalizations.of(context).remove,
                  style: textTheme.bodyBold,
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      items.addAll(
        [
          PopupMenuItem(
            value: PeoplePopupAction.unignore,
            child: Row(
              children: [
                const Icon(Icons.visibility_outlined),
                const Padding(
                  padding: EdgeInsets.all(8),
                ),
                Text(AppLocalizations.of(context).showPerson),
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
                    builder: (context) => PersonReviewClusterSuggestion(person),
                  ),
                ),
              );
            } else if (value == PeoplePopupAction.rename) {
              await _editPerson(context);
            } else if (value == PeoplePopupAction.setCover) {
              await setCoverPhoto(context);
            } else if (value == PeoplePopupAction.unignore) {
              await _showPerson(context);
            } else if (value == PeoplePopupAction.removeLabel) {
              await _resetPerson(context);
            } else if (value == PeoplePopupAction.reassignMe) {
              await _reassignMe(context);
            }
          },
        ),
      );
    }

    return actions;
  }

  Future<void> _resetPerson(BuildContext context) async {
    await showChoiceDialog(
      context,
      title: AppLocalizations.of(context).areYouSureYouWantToResetThisPerson,
      body: AppLocalizations.of(context).allPersonGroupingWillReset,
      firstButtonLabel: AppLocalizations.of(context).yesResetPerson,
      firstButtonOnTap: () async {
        try {
          await PersonService.instance.deletePerson(person.remoteID);
          Navigator.of(context).pop();
        } catch (e, s) {
          _logger.severe('Resetting person failed', e, s);
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
        clusterID: widget.person.data.assigned.first.id,
      );
      Navigator.pop(context);
      if (result != null) {
        final person = result is (PersonEntity, EnteFile) ? result.$1 : result;
        // ignore: unawaited_futures
        routeToPage(
          context,
          PeoplePage(
            person: person,
            searchResult: null,
          ),
        );
      }
    }
  }

  Future<void> setCoverPhoto(BuildContext context) async {
    final result = await showPersonAvatarPhotoSheet(
      context,
      person,
    );
    if (result != null) {
      _logger.info(
        'Person avatar updated',
      );
      setState(() {
        person = result;
      });
      Bus.instance.fire(
        PeopleChangedEvent(
          type: PeopleEventType.saveOrEditPerson,
          source: "_PeopleAppBarState.setCoverPhoto",
          person: result,
        ),
      );
    }
  }

  Future<void> _reassignMe(BuildContext context) async {
    await routeToPage(
      context,
      ReassignMeSelectionPage(
        currentMeId: widget.person.remoteID,
      ),
    );
  }
}
