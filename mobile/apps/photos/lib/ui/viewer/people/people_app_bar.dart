import 'dart:async';

import "package:ente_pure_utils/ente_pure_utils.dart";
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import "package:photos/core/constants.dart";
import 'package:photos/core/event_bus.dart';
import "package:photos/events/people_changed_event.dart";
import 'package:photos/events/subscription_purchased_event.dart';
import "package:photos/generated/l10n.dart";
import "package:photos/l10n/l10n.dart";
import 'package:photos/models/gallery_type.dart';
import "package:photos/models/ml/face/person.dart";
import 'package:photos/models/selected_files.dart';
import 'package:photos/services/collections_service.dart';
import "package:photos/services/machine_learning/face_ml/person/person_service.dart";
import "package:photos/theme/ente_theme.dart";
import 'package:photos/ui/actions/collection/collection_sharing_actions.dart';
import "package:photos/ui/components/buttons/button_widget.dart";
import "package:photos/ui/notification/toast.dart";
import "package:photos/ui/viewer/gallery/hooks/pick_person_avatar.dart";
import "package:photos/ui/viewer/gallery/state/inherited_search_filter_data.dart";
import "package:photos/ui/viewer/hierarchicial_search/applied_filters_for_appbar.dart";
import "package:photos/ui/viewer/hierarchicial_search/recommended_filters_for_appbar.dart";
import "package:photos/ui/viewer/people/person_cluster_suggestion.dart";
import "package:photos/ui/viewer/people/person_selection_action_widgets.dart";
import "package:photos/ui/viewer/people/save_or_edit_person.dart";
import "package:photos/utils/dialog_util.dart";

const kShowUnnamedIgnoredPersonEventSource =
    "_AppBarWidgetState._showPersonUnnamedDelete";

class PeopleAppBar extends StatefulWidget {
  final GalleryType type;
  final String? title;
  final SelectedFiles selectedFiles;
  final PersonEntity person;
  final bool memoryLaneReady;
  final Future<void> Function()? onMemoryLaneTap;

  bool get isIgnored => person.data.isIgnored;

  const PeopleAppBar(
    this.type,
    this.title,
    this.selectedFiles,
    this.person, {
    this.memoryLaneReady = false,
    this.onMemoryLaneTap,
    super.key,
  });

  @override
  State<PeopleAppBar> createState() => _AppBarWidgetState();
}

enum PeoplePopupAction {
  rename,
  setCover,
  pinPerson,
  hideFromMemories,
  ignore,
  removeLabel,
  reviewSuggestions,
  unignore,
  reassignMe,
  memoryLane,
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

  String? _resolveAppBarTitle({
    required PersonEntity sourcePerson,
    required String? title,
  }) {
    if (sourcePerson.data.email == Configuration.instance.getEmail()) {
      if (title == null) {
        return context.l10n.me;
      }
      return context.l10n.accountOwnerPersonAppbarTitle(title: title);
    }
    return title;
  }

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
        _appBarTitle = _resolveAppBarTitle(
          sourcePerson: person,
          title: widget.title,
        );

        _peopleChangedEventSubscription =
            Bus.instance.on<PeopleChangedEvent>().listen(
          (event) {
            if (event.person != null &&
                event.type == PeopleEventType.saveOrEditPerson &&
                widget.person.remoteID == event.person!.remoteID &&
                (event.source == "linkEmailToPerson" ||
                    event.source == "reassignMe")) {
              person = event.person!;

              _appBarTitle = _resolveAppBarTitle(
                sourcePerson: person,
                title: person.data.name,
              );
              setState(() {});
            }
          },
        );
      });
    });
  }

  @override
  void didUpdateWidget(covariant PeopleAppBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.title != widget.title ||
        oldWidget.person.remoteID != widget.person.remoteID ||
        oldWidget.person.data.name != widget.person.data.name ||
        oldWidget.person.data.email != widget.person.data.email) {
      person = widget.person;
      _appBarTitle = _resolveAppBarTitle(
        sourcePerson: person,
        title: widget.title,
      );
    }
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
    final currentPerson = person;
    final bool isIgnored = currentPerson.data.isIgnored;
    final bool isPinned = currentPerson.data.isPinned;
    final bool hideFromMemories = currentPerson.data.hideFromMemories;
    final List<Widget> actions = <Widget>[];
    // If the user has selected files, don't show any actions
    if (widget.selectedFiles.files.isNotEmpty ||
        !Configuration.instance.hasConfiguredAccount()) {
      return actions;
    }

    final List<PopupMenuItem<PeoplePopupAction>> items = [];
    final bool showTimelineAction =
        widget.memoryLaneReady && widget.onMemoryLaneTap != null;
    if (showTimelineAction) {
      items.add(
        PopupMenuItem(
          value: PeoplePopupAction.memoryLane,
          child: Row(
            children: [
              const Icon(Icons.auto_awesome_outlined),
              const Padding(
                padding: EdgeInsets.all(8),
              ),
              Text(
                context.l10n.facesTimelineAppBarTitle,
                style: textTheme.bodyBold,
              ),
            ],
          ),
        ),
      );
    }

    if (!isIgnored) {
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
          PopupMenuItem(
            value: PeoplePopupAction.pinPerson,
            child: Row(
              children: [
                Icon(isPinned ? Icons.push_pin : Icons.push_pin_outlined),
                const Padding(
                  padding: EdgeInsets.all(8),
                ),
                Text(
                  isPinned ? context.l10n.unpinPerson : context.l10n.pinPerson,
                  style: textTheme.bodyBold,
                ),
              ],
            ),
          ),
          PopupMenuItem(
            value: PeoplePopupAction.hideFromMemories,
            child: Row(
              children: [
                Icon(
                  hideFromMemories
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                const Padding(
                  padding: EdgeInsets.all(8),
                ),
                Text(
                  hideFromMemories
                      ? context.l10n.showInMemories
                      : context.l10n.hideFromMemories,
                  style: textTheme.bodyBold,
                ),
              ],
            ),
          ),
          if (currentPerson.data.email != null &&
              (currentPerson.data.email == Configuration.instance.getEmail()))
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
            value: PeoplePopupAction.ignore,
            child: Row(
              children: [
                const Icon(Icons.hide_image_outlined),
                const Padding(
                  padding: EdgeInsets.all(8),
                ),
                Text(
                  AppLocalizations.of(context).ignore,
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
            value: PeoplePopupAction.unignore,
            child: Row(
              children: [
                const Icon(Icons.visibility_outlined),
                const Padding(
                  padding: EdgeInsets.all(8),
                ),
                Text(
                  AppLocalizations.of(context).showPerson,
                  style: textTheme.bodyBold,
                ),
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
            } else if (value == PeoplePopupAction.memoryLane) {
              final callback = widget.onMemoryLaneTap;
              if (callback != null) {
                unawaited(callback());
              }
            } else if (value == PeoplePopupAction.rename) {
              await _editPerson(context);
            } else if (value == PeoplePopupAction.setCover) {
              await setCoverPhoto(context);
            } else if (value == PeoplePopupAction.pinPerson) {
              await _togglePinState();
            } else if (value == PeoplePopupAction.hideFromMemories) {
              await _toggleHideFromMemories();
            } else if (value == PeoplePopupAction.ignore) {
              await _ignorePerson(context);
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

  Future<void> _togglePinState() async {
    final shouldPin = !person.data.isPinned;
    try {
      final updatedPerson = await PersonService.instance.updateAttributes(
        person.remoteID,
        isPinned: shouldPin,
      );
      setState(() {
        person = updatedPerson;
      });
      Bus.instance.fire(
        PeopleChangedEvent(
          type: PeopleEventType.saveOrEditPerson,
          source: "_AppBarWidgetState._togglePinState",
          person: updatedPerson,
        ),
      );
    } catch (e, s) {
      _logger.severe('Failed to update pin state', e, s);
    }
  }

  Future<void> _toggleHideFromMemories() async {
    final shouldHideFromMemories = !person.data.hideFromMemories;
    try {
      final updatedPerson = await PersonService.instance.updateAttributes(
        person.remoteID,
        hideFromMemories: shouldHideFromMemories,
      );
      setState(() {
        person = updatedPerson;
      });
      Bus.instance.fire(
        PeopleChangedEvent(
          type: PeopleEventType.saveOrEditPerson,
          source: "_AppBarWidgetState._toggleHideFromMemories",
          person: updatedPerson,
        ),
      );
    } catch (e, s) {
      _logger.severe('Failed to update hide from memories state', e, s);
    }
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

  bool _isLegacyIgnoredName(String name) {
    final normalizedName = name.trim().toLowerCase();
    return normalizedName.isEmpty ||
        normalizedName == "(ignored)" ||
        normalizedName == "(hidden)";
  }

  Future<void> _ignorePerson(BuildContext context) async {
    final result = await showChoiceDialog(
      context,
      title: AppLocalizations.of(context).areYouSureYouWantToIgnoreThisPerson,
      body: AppLocalizations.of(context).thePersonWillNotBeDisplayed,
      firstButtonLabel: AppLocalizations.of(context).yesIgnore,
      firstButtonOnTap: () async {
        try {
          final updatedPerson = await PersonService.instance.updateAttributes(
            person.remoteID,
            isHidden: true,
          );
          setState(() {
            person = updatedPerson;
          });
          Bus.instance.fire(
            PeopleChangedEvent(
              type: PeopleEventType.saveOrEditPerson,
              source: "_AppBarWidgetState._ignorePerson",
              person: updatedPerson,
            ),
          );
        } catch (e, s) {
          _logger.severe('Ignoring/showing person failed', e, s);
          rethrow;
        }
      },
    );
    if (!mounted || result?.action != ButtonAction.error) {
      return;
    }
    showShortToast(
      context,
      AppLocalizations.of(context).somethingWentWrongPleaseTryAgain,
    );
  }

  Future<void> _showPerson(BuildContext context) async {
    final isUnnamedIgnoredPerson = _isLegacyIgnoredName(person.data.name);
    var shouldCloseDetailPage = false;
    await showChoiceDialog(
      context,
      title: AppLocalizations.of(
        context,
      ).areYouSureYouWantToShowThisPersonInPeopleSectionAgain,
      firstButtonLabel: AppLocalizations.of(context).yesShowPerson,
      firstButtonOnTap: () async {
        try {
          if (isUnnamedIgnoredPerson) {
            await PersonService.instance.deletePerson(person.remoteID);
            Bus.instance.fire(
              PeopleChangedEvent(
                source: kShowUnnamedIgnoredPersonEventSource,
                person: person,
              ),
            );
            shouldCloseDetailPage = true;
          } else {
            final updatedPerson = await PersonService.instance.updateAttributes(
              person.remoteID,
              isHidden: false,
            );
            setState(() {
              person = updatedPerson;
              _appBarTitle = _resolveAppBarTitle(
                sourcePerson: person,
                title: person.data.name,
              );
            });
            Bus.instance.fire(
              PeopleChangedEvent(
                type: PeopleEventType.saveOrEditPerson,
                source: "_AppBarWidgetState._showPerson",
                person: updatedPerson,
              ),
            );
          }
          Navigator.of(context).pop();
        } catch (e, s) {
          _logger.severe('Unignoring/showing person failed', e, s);
        }
      },
    );
    if (!mounted || !shouldCloseDetailPage) {
      return;
    }
    await Navigator.of(context).maybePop();
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
