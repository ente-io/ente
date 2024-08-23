import "dart:async";
import "dart:developer";
import "dart:math" as math;

import "package:flutter/foundation.dart";
import 'package:flutter/material.dart';
import "package:logging/logging.dart";
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import "package:photos/core/event_bus.dart";
import "package:photos/db/ml/db.dart";
import "package:photos/events/people_changed_event.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/ml/face/person.dart";
import 'package:photos/services/machine_learning/face_ml/feedback/cluster_feedback.dart';
import "package:photos/services/machine_learning/face_ml/person/person_service.dart";
import "package:photos/services/search_service.dart";
import 'package:photos/theme/colors.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/common/loading_widget.dart';
import 'package:photos/ui/components/bottom_of_title_bar_widget.dart';
import 'package:photos/ui/components/buttons/button_widget.dart';
import 'package:photos/ui/components/models/button_type.dart';
import "package:photos/ui/components/text_input_widget.dart";
import 'package:photos/ui/components/title_bar_title_widget.dart';
import "package:photos/ui/viewer/people/new_person_item_widget.dart";
import "package:photos/ui/viewer/people/person_row_item.dart";
import "package:photos/utils/dialog_util.dart";
import "package:photos/utils/toast_util.dart";

enum PersonActionType {
  assignPerson,
}

String _actionName(
  BuildContext context,
  PersonActionType type,
) {
  String text = "";
  switch (type) {
    case PersonActionType.assignPerson:
      text = "Add name";
      break;
  }
  return text;
}

Future<dynamic> showAssignPersonAction(
  BuildContext context, {
  required String clusterID,
  PersonActionType actionType = PersonActionType.assignPerson,
  bool showOptionToAddNewPerson = true,
}) {
  return showBarModalBottomSheet(
    context: context,
    builder: (context) {
      return PersonActionSheet(
        actionType: actionType,
        showOptionToCreateNewPerson: showOptionToAddNewPerson,
        cluserID: clusterID,
      );
    },
    shape: const RoundedRectangleBorder(
      side: BorderSide(width: 0),
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(5),
      ),
    ),
    topControl: const SizedBox.shrink(),
    backgroundColor: getEnteColorScheme(context).backgroundElevated,
    barrierColor: backdropFaintDark,
    enableDrag: false,
  );
}

class PersonActionSheet extends StatefulWidget {
  final PersonActionType actionType;
  final String cluserID;
  final bool showOptionToCreateNewPerson;
  const PersonActionSheet({
    required this.actionType,
    required this.cluserID,
    required this.showOptionToCreateNewPerson,
    super.key,
  });

  @override
  State<PersonActionSheet> createState() => _PersonActionSheetState();
}

class _PersonActionSheetState extends State<PersonActionSheet> {
  static const int cancelButtonSize = 80;
  String _searchQuery = "";
  bool userAlreadyAssigned = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardUp = bottomInset > 100;
    return Padding(
      padding: EdgeInsets.only(
        bottom: isKeyboardUp ? bottomInset - cancelButtonSize : 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: math.min(428, MediaQuery.of(context).size.width),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 32, 0, 8),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        BottomOfTitleBarWidget(
                          title: TitleBarTitleWidget(
                            title: _actionName(context, widget.actionType),
                          ),
                          // caption: 'Select or create a ',
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 16,
                            left: 16,
                            right: 16,
                          ),
                          child: TextInputWidget(
                            hintText: 'Person name',
                            prefixIcon: Icons.search_rounded,
                            onChange: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                            },
                            isClearable: true,
                            shouldUnfocusOnClearOrSubmit: true,
                            borderRadius: 2,
                          ),
                        ),
                        _getPersonItems(),
                      ],
                    ),
                  ),
                  SafeArea(
                    child: Container(
                      //inner stroke of 1pt + 15 pts of top padding = 16 pts
                      padding: const EdgeInsets.fromLTRB(16, 15, 16, 8),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: getEnteColorScheme(context).strokeFaint,
                          ),
                        ),
                      ),
                      child: ButtonWidget(
                        buttonType: ButtonType.secondary,
                        buttonAction: ButtonAction.cancel,
                        isInAlert: true,
                        labelText: S.of(context).cancel,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Flexible _getPersonItems() {
    return Flexible(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 4, 0),
        child: FutureBuilder<List<(PersonEntity, EnteFile)>>(
          future: _getPersonsWithRecentFile(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              log("Error: ${snapshot.error} ${snapshot.stackTrace}}");
              //Need to show an error on the UI here
              if (kDebugMode) {
                return Column(
                  children: [
                    Text('${snapshot.error}'),
                    Text('${snapshot.stackTrace}'),
                  ],
                );
              } else {
                return const SizedBox.shrink();
              }
            } else if (snapshot.hasData) {
              final persons = snapshot.data!;
              final searchResults = _searchQuery.isNotEmpty
                  ? persons
                      .where(
                        (element) => element.$1.data.name
                            .toLowerCase()
                            .contains(_searchQuery),
                      )
                      .toList()
                  : persons;
              // sort searchResults alphabetically by name
              searchResults.sort(
                (a, b) => a.$1.data.name.compareTo(b.$1.data.name),
              );
              final shouldShowAddPerson = widget.showOptionToCreateNewPerson &&
                  (_searchQuery.isEmpty || searchResults.isEmpty);

              return Scrollbar(
                thumbVisibility: true,
                radius: const Radius.circular(2),
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: ListView.separated(
                    itemCount:
                        searchResults.length + (shouldShowAddPerson ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == 0 && shouldShowAddPerson) {
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          child: const NewPersonItemWidget(),
                          onTap: () async => {
                            addNewPerson(
                              context,
                              initValue: _searchQuery.trim(),
                              clusterID: widget.cluserID,
                            ),
                          },
                        );
                      }
                      final person =
                          searchResults[index - (shouldShowAddPerson ? 1 : 0)];
                      return PersonRowItem(
                        person: person.$1,
                        personFile: person.$2,
                        onTap: () async {
                          if (userAlreadyAssigned) {
                            return;
                          }
                          userAlreadyAssigned = true;
                          await MLDataDB.instance.assignClusterToPerson(
                            personID: person.$1.remoteID,
                            clusterID: widget.cluserID,
                          );
                          Bus.instance.fire(PeopleChangedEvent());

                          Navigator.pop(context, person);
                        },
                      );
                    },
                    separatorBuilder: (context, index) {
                      return const SizedBox(height: 6);
                    },
                  ),
                ),
              );
            } else {
              return const EnteLoadingWidget();
            }
          },
        ),
      ),
    );
  }

  Future<void> addNewPerson(
    BuildContext context, {
    String initValue = '',
    required String clusterID,
  }) async {
    final result = await showTextInputDialog(
      context,
      title: "New person",
      submitButtonLabel: 'Add',
      hintText: 'Add name',
      alwaysShowSuccessState: false,
      initialValue: initValue,
      textCapitalization: TextCapitalization.words,
      onSubmit: (String text) async {
        if (userAlreadyAssigned) {
          return;
        }
        // indicates user cancelled the rename request
        if (text.trim() == "") {
          return;
        }
        try {
          userAlreadyAssigned = true;
          final PersonEntity p =
              await PersonService.instance.addPerson(text, clusterID);
          final bool extraPhotosFound = await ClusterFeedbackService.instance
              .checkAndDoAutomaticMerges(p, personClusterID: clusterID);
          if (extraPhotosFound) {
            showShortToast(context, "Extra photos found for $text");
          }
          Bus.instance.fire(PeopleChangedEvent());
          Navigator.pop(context, p);
        } catch (e, s) {
          Logger("_PersonActionSheetState")
              .severe("Failed to add person", e, s);
          rethrow;
        }
      },
    );
    if (result is Exception) {
      await showGenericErrorDialog(context: context, error: result);
    }
  }

  Future<List<(PersonEntity, EnteFile)>> _getPersonsWithRecentFile({
    bool excludeHidden = true,
  }) async {
    final persons = await PersonService.instance.getPersons();
    if (excludeHidden) {
      persons.removeWhere((person) => person.data.isIgnored);
    }
    final List<(PersonEntity, EnteFile)> personAndFileID = [];
    for (final person in persons) {
      final clustersToFiles =
          await SearchService.instance.getClusterFilesForPersonID(
        person.remoteID,
      );
      final files = clustersToFiles.values.expand((e) => e).toList();
      if (files.isEmpty) {
        debugPrint(
          "Person ${kDebugMode ? person.data.name : person.remoteID} has no files",
        );
        continue;
      }
      personAndFileID.add((person, files.first));
    }
    return personAndFileID;
  }
}
