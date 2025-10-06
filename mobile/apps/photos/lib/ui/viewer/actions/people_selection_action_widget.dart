import "package:flutter/material.dart";
import "package:logging/logging.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/events/people_changed_event.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/ml/face/person.dart";
import "package:photos/models/selected_people.dart";
import "package:photos/services/machine_learning/face_ml/feedback/cluster_feedback.dart";
import "package:photos/services/machine_learning/face_ml/person/person_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/collections/collection_action_sheet.dart";
import "package:photos/ui/components/bottom_action_bar/selection_action_button_widget.dart";
import "package:photos/ui/viewer/gallery/hooks/pick_person_avatar.dart";
import "package:photos/ui/viewer/people/person_cluster_suggestion.dart";
import "package:photos/ui/viewer/people/save_or_edit_person.dart";
import "package:photos/utils/dialog_util.dart";
import "package:photos/utils/navigation_util.dart";
import "package:smooth_page_indicator/smooth_page_indicator.dart";

class PeopleSelectionActionWidget extends StatefulWidget {
  final SelectedPeople selectedPeople;
  final bool isCollapsed;

  const PeopleSelectionActionWidget(
    this.selectedPeople, {
    this.isCollapsed = false,
    super.key,
  });

  @override
  State<PeopleSelectionActionWidget> createState() =>
      _PeopleSelectionActionWidgetState();
}

class _PeopleSelectionActionWidgetState
    extends State<PeopleSelectionActionWidget> {
  late Future<Map<String, PersonEntity>> personEntitiesMapFuture;
  final _logger = Logger("PeopleSelectionActionWidget");
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    widget.selectedPeople.addListener(_selectionChangedListener);
    personEntitiesMapFuture = PersonService.instance.getPersonsMap();
  }

  @override
  void dispose() {
    widget.selectedPeople.removeListener(_selectionChangedListener);
    super.dispose();
  }

  List<String> _getSelectedPersonIds() {
    return widget.selectedPeople.personIds
        .where((id) => !id.startsWith('cluster_'))
        .toList();
  }

  List<String> _getSelectedClusterIds() {
    return widget.selectedPeople.personIds
        .where((id) => id.startsWith('cluster_'))
        .toList();
  }

  void _selectionChangedListener() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.selectedPeople.personIds.isEmpty) {
      return const SizedBox.shrink();
    }

    final List<SelectionActionButton> items = [];
    final selectedPersonIds = _getSelectedPersonIds();
    final selectedClusterIds = _getSelectedClusterIds();
    final onlyOnePerson =
        selectedPersonIds.length == 1 && selectedClusterIds.isEmpty;
    final onlyPersonSelected =
        selectedPersonIds.isNotEmpty && selectedClusterIds.isEmpty;
    final onePersonAndClusters =
        selectedPersonIds.length == 1 && selectedClusterIds.isNotEmpty;
    final anythingSelected =
        selectedPersonIds.isNotEmpty || selectedClusterIds.isNotEmpty;

    items.add(
      SelectionActionButton(
        labelText: AppLocalizations.of(context).edit,
        icon: Icons.edit_outlined,
        onTap: _onEditPerson,
        shouldShow: onlyOnePerson,
      ),
    );
    items.add(
      SelectionActionButton(
        labelText: AppLocalizations.of(context).setCover,
        icon: Icons.image_outlined,
        onTap: _setCoverPhoto,
        shouldShow: onlyOnePerson,
      ),
    );
    items.add(
      SelectionActionButton(
        labelText: AppLocalizations.of(context).setCover,
        icon: Icons.image_outlined,
        onTap: _setCoverPhoto,
        shouldShow: onlyOnePerson,
      ),
    );
    items.add(
      SelectionActionButton(
        labelText: AppLocalizations.of(context).review,
        icon: Icons.search_outlined,
        onTap: _onReviewSuggestion,
        shouldShow: onlyOnePerson,
      ),
    );
    items.add(
      SelectionActionButton(
        labelText: AppLocalizations.of(context).ignore,
        icon: Icons.hide_image_outlined,
        onTap: _onIgnore,
        shouldShow: anythingSelected,
      ),
    );
    items.add(
      SelectionActionButton(
        labelText: AppLocalizations.of(context).merge,
        icon: Icons.merge_outlined,
        onTap: _onMerge,
        shouldShow: onePersonAndClusters,
      ),
    );
    items.add(
      SelectionActionButton(
        labelText: AppLocalizations.of(context).reset,
        icon: Icons.remove_outlined,
        onTap: _onResetPerson,
        shouldShow: onlyOnePerson,
      ),
    );
    items.add(
      SelectionActionButton(
        labelText: AppLocalizations.of(context).autoAddToAlbum,
        iconWidget: Image.asset(
          "assets/auto-add-people.png",
          width: 24,
          height: 24,
          color: EnteTheme.isDark(context) ? Colors.white : Colors.black,
        ),
        onTap: _autoAddToAlbum,
        shouldShow: onlyPersonSelected,
      ),
    );

    final List<SelectionActionButton> visibleItems = items
        .where((item) => item.shouldShow == null || item.shouldShow == true)
        .toList();

    final List<SelectionActionButton> firstThreeItems =
        visibleItems.length > 3 ? visibleItems.take(3).toList() : visibleItems;

    final List<SelectionActionButton> otherItems =
        visibleItems.length > 3 ? visibleItems.sublist(3) : [];

    final List<List<SelectionActionButton>> groupedOtherItems = [];
    for (int i = 0; i < otherItems.length; i += 4) {
      int end = (i + 4 < otherItems.length) ? i + 4 : otherItems.length;
      groupedOtherItems.add(otherItems.sublist(i, end));
    }

    if (visibleItems.isNotEmpty) {
      return MediaQuery(
        data: MediaQuery.of(context).removePadding(removeBottom: true),
        child: SafeArea(
          child: Container(
            padding: const EdgeInsets.only(
              bottom: 20.0,
              left: 20.0,
              right: 20.0,
            ),
            child: Column(
              children: [
                // First Row
                const SizedBox(
                  height: 4,
                ),
                Row(
                  children: [
                    for (int i = 0; i < firstThreeItems.length; i++) ...[
                      Expanded(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              height: MediaQuery.of(context).size.height * 0.10,
                              decoration: BoxDecoration(
                                color: getEnteColorScheme(context)
                                    .backgroundElevated2,
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            firstThreeItems[i],
                          ],
                        ),
                      ),
                      if (i != firstThreeItems.length - 1)
                        const SizedBox(width: 15),
                    ],
                  ],
                ),

                // Second Row
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: widget.isCollapsed
                      ? const SizedBox.shrink()
                      : Column(
                          children: [
                            if (groupedOtherItems.isNotEmpty) ...[
                              const SizedBox(height: 24),
                              Container(
                                width: double.infinity,
                                height: 74,
                                decoration: BoxDecoration(
                                  color: getEnteColorScheme(context)
                                      .backgroundElevated2,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: PageView.builder(
                                  controller: _pageController,
                                  itemCount: groupedOtherItems.length,
                                  onPageChanged: (index) {
                                    if (index >= groupedOtherItems.length &&
                                        groupedOtherItems.isNotEmpty) {
                                      _pageController.animateToPage(
                                        groupedOtherItems.length - 1,
                                        duration:
                                            const Duration(milliseconds: 100),
                                        curve: Curves.easeInOut,
                                      );
                                    }
                                  },
                                  itemBuilder: (context, pageIndex) {
                                    if (pageIndex >= groupedOtherItems.length) {
                                      return const SizedBox();
                                    }

                                    final currentGroup =
                                        groupedOtherItems[pageIndex];

                                    return Row(
                                      children: currentGroup.map((item) {
                                        return Expanded(
                                          child: AnimatedSwitcher(
                                            duration: const Duration(
                                              milliseconds: 100,
                                            ),
                                            transitionBuilder: (
                                              Widget child,
                                              Animation<double> animation,
                                            ) {
                                              return FadeTransition(
                                                opacity: animation,
                                                child: child,
                                              );
                                            },
                                            child: item is Widget
                                                ? KeyedSubtree(
                                                    key: ValueKey(
                                                      item.hashCode,
                                                    ),
                                                    child: item,
                                                  )
                                                : const SizedBox(),
                                          ),
                                        );
                                      }).toList(),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (groupedOtherItems.length > 1)
                                SmoothPageIndicator(
                                  controller: _pageController,
                                  count: groupedOtherItems.length,
                                  effect: const WormEffect(
                                    dotHeight: 6,
                                    dotWidth: 6,
                                    spacing: 6,
                                    activeDotColor: Colors.white,
                                  ),
                                ),
                            ],
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return const SizedBox();
  }

  Future<void> _onEditPerson() async {
    final selectedPersonIds = _getSelectedPersonIds();
    if (selectedPersonIds.length != 1) return;
    final personID = selectedPersonIds.first;
    final personMap = await personEntitiesMapFuture;
    final person = personMap[personID];
    if (person == null) return;

    await routeToPage(
      context,
      SaveOrEditPerson(
        person.data.assigned.first.id,
        person: person,
        isEditing: true,
      ),
    );
    widget.selectedPeople.clearAll();
  }

  Future<void> _onReviewSuggestion() async {
    final selectedPersonIds = _getSelectedPersonIds();
    if (selectedPersonIds.length != 1) return;
    final personID = selectedPersonIds.first;
    final personMap = await personEntitiesMapFuture;
    final person = personMap[personID];
    if (person == null) return;

    await routeToPage(
      context,
      PersonReviewClusterSuggestion(person),
    );
    widget.selectedPeople.clearAll();
  }

  Future<void> _autoAddToAlbum() async {
    final selectedPersonIds = _getSelectedPersonIds();
    if (selectedPersonIds.isEmpty) return;
    showCollectionActionSheet(
      context,
      selectedPeople: selectedPersonIds,
      actionType: CollectionActionType.autoAddPeople,
    );
    widget.selectedPeople.clearAll();
  }

  Future<void> _onResetPerson() async {
    final selectedPersonIds = _getSelectedPersonIds();
    if (selectedPersonIds.length != 1) return;
    final personID = selectedPersonIds.first;
    final personMap = await personEntitiesMapFuture;
    final person = personMap[personID];
    if (person == null) return;

    await showChoiceDialog(
      context,
      title: AppLocalizations.of(context).areYouSureYouWantToResetThisPerson,
      body: AppLocalizations.of(context).allPersonGroupingWillReset,
      firstButtonLabel: AppLocalizations.of(context).yesResetPerson,
      firstButtonOnTap: () async {
        try {
          await PersonService.instance.deletePerson(person.remoteID);
          widget.selectedPeople.clearAll();
        } on Exception catch (e, s) {
          _logger.severe('Failed to delete person', e, s);
        }
      },
    );
  }

  Future<void> _setCoverPhoto() async {
    final selectedPersonIds = _getSelectedPersonIds();
    if (selectedPersonIds.length != 1) return;

    final personID = selectedPersonIds.first;
    final personMap = await personEntitiesMapFuture;
    final person = personMap[personID];
    if (person == null) return;

    final result = await showPersonAvatarPhotoSheet(
      context,
      person,
    );

    if (result != null) {
      _logger.info('Person avatar updated');

      personEntitiesMapFuture = PersonService.instance.getPersonsMap();

      setState(() {});

      Bus.instance.fire(
        PeopleChangedEvent(
          type: PeopleEventType.saveOrEditPerson,
          source: "_PeopleSelectionActionWidgetState.setCoverPhoto",
          person: result,
        ),
      );

      widget.selectedPeople.clearAll();
    }
  }

  Future<void> _onIgnore() async {
    final selectedPersonIds = _getSelectedPersonIds();
    final selectedClusterIds = _getSelectedClusterIds();
    if (selectedPersonIds.isEmpty && selectedClusterIds.isEmpty) return;
    final multiple = (selectedPersonIds.length + selectedClusterIds.length) > 1;

    await showChoiceDialog(
      context,
      title: multiple
          ? AppLocalizations.of(context).areYouSureYouWantToIgnoreThesePersons
          : AppLocalizations.of(context).areYouSureYouWantToIgnoreThisPerson,
      body: multiple
          ? AppLocalizations.of(context).thePersonGroupsWillNotBeDisplayed
          : AppLocalizations.of(context).thePersonWillNotBeDisplayed,
      firstButtonLabel: AppLocalizations.of(context).yesIgnore,
      firstButtonOnTap: () async {
        try {
          for (final clusterID in selectedClusterIds) {
            await ClusterFeedbackService.instance.ignoreCluster(clusterID);
          }
          final personMap = await personEntitiesMapFuture;
          for (final personID in selectedPersonIds) {
            final person = personMap[personID];
            if (person == null) continue;
            final ignoredPerson = person.copyWith(
              data: person.data.copyWith(name: "", isHidden: true),
            );
            await PersonService.instance.updatePerson(ignoredPerson);
          }
          Bus.instance.fire(PeopleChangedEvent());
          widget.selectedPeople.clearAll();
        } catch (e, s) {
          _logger.severe('Ignoring a cluster failed', e, s);
        }
      },
    );
  }

  Future<void> _onMerge() async {
    final selectedPersonIds = _getSelectedPersonIds();
    final selectedClusterIds = _getSelectedClusterIds();
    if (selectedPersonIds.length != 1 || selectedClusterIds.isEmpty) return;

    await showChoiceDialog(
      context,
      title: AppLocalizations.of(context).areYouSureYouWantToMergeThem,
      body: AppLocalizations.of(context)
          .allUnnamedGroupsWillBeMergedIntoTheSelectedPerson,
      firstButtonLabel: AppLocalizations.of(context).confirm,
      firstButtonOnTap: () async {
        try {
          final personMap = await personEntitiesMapFuture;
          final personID = selectedPersonIds.first;
          final person = personMap[personID];
          if (person == null) return;
          for (final clusterID in selectedClusterIds) {
            await ClusterFeedbackService.instance.addClusterToExistingPerson(
              clusterID: clusterID,
              person: person,
            );
          }
          widget.selectedPeople.clearAll();
        } catch (e, s) {
          _logger.severe('Merging clusters failed', e, s);
        }
      },
    );
  }
}
