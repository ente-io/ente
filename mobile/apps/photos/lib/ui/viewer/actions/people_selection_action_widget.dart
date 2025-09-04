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
import "package:photos/ui/viewer/people/person_cluster_suggestion.dart";
import "package:photos/ui/viewer/people/save_or_edit_person.dart";
import "package:photos/utils/dialog_util.dart";
import "package:photos/utils/navigation_util.dart";

class PeopleSelectionActionWidget extends StatefulWidget {
  final SelectedPeople selectedPeople;

  const PeopleSelectionActionWidget(
    this.selectedPeople, {
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

    return MediaQuery(
      data: MediaQuery.of(context).removePadding(removeBottom: true),
      child: SafeArea(
        child: Scrollbar(
          radius: const Radius.circular(1),
          thickness: 2,
          thumbVisibility: true,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(
              decelerationRate: ScrollDecelerationRate.fast,
            ),
            scrollDirection: Axis.horizontal,
            child: Container(
              padding: const EdgeInsets.only(bottom: 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(width: 4),
                  ...items,
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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
