import "dart:async";
import "dart:developer";
import "dart:math" as math;

import 'package:flutter/material.dart';
import "package:logging/logging.dart";
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import "package:photos/core/event_bus.dart";
import "package:photos/events/people_changed_event.dart";
import "package:photos/face/db.dart";
import "package:photos/face/model/person.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/services/face_ml/feedback/cluster_feedback.dart";
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
import "package:uuid/uuid.dart";

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
  required int clusterID,
  PersonActionType actionType = PersonActionType.assignPerson,
  bool showOptionToCreateNewAlbum = true,
}) {
  return showBarModalBottomSheet(
    context: context,
    builder: (context) {
      return PersonActionSheet(
        actionType: actionType,
        showOptionToCreateNewAlbum: showOptionToCreateNewAlbum,
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
  final int cluserID;
  final bool showOptionToCreateNewAlbum;
  const PersonActionSheet({
    required this.actionType,
    required this.cluserID,
    required this.showOptionToCreateNewAlbum,
    super.key,
  });

  @override
  State<PersonActionSheet> createState() => _PersonActionSheetState();
}

class _PersonActionSheetState extends State<PersonActionSheet> {
  static const int cancelButtonSize = 80;
  String _searchQuery = "";

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
        child: FutureBuilder<List<Person>>(
          future: _getPersons(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              log("Error: ${snapshot.error} ${snapshot.stackTrace}}");
              //Need to show an error on the UI here
              return const SizedBox.shrink();
            } else if (snapshot.hasData) {
              final persons = snapshot.data as List<Person>;
              final searchResults = _searchQuery.isNotEmpty
                  ? persons
                      .where(
                        (element) => element.attr.name
                            .toLowerCase()
                            .contains(_searchQuery),
                      )
                      .toList()
                  : persons;
              final shouldShowCreateAlbum = widget.showOptionToCreateNewAlbum &&
                  (_searchQuery.isEmpty || searchResults.isEmpty);

              return Scrollbar(
                thumbVisibility: true,
                radius: const Radius.circular(2),
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: ListView.separated(
                    itemCount:
                        searchResults.length + (shouldShowCreateAlbum ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == 0 && shouldShowCreateAlbum) {
                        return GestureDetector(
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
                      final person = searchResults[
                          index - (shouldShowCreateAlbum ? 1 : 0)];
                      return PersonRowItem(
                        person: person,
                        onTap: () async {
                          await FaceMLDataDB.instance.assignClusterToPerson(
                            personID: person.remoteID,
                            clusterID: widget.cluserID,
                          );
                          Bus.instance.fire(PeopleChangedEvent());

                          Navigator.pop(context, person);
                        },
                      );
                    },
                    separatorBuilder: (context, index) {
                      return const SizedBox(height: 2);
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
    required int clusterID,
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
        // indicates user cancelled the rename request
        if (text.trim() == "") {
          return;
        }
        try {
          final String id = const Uuid().v4().toString();
          final Person p = Person(
            id,
            PersonAttr(name: text, faces: <String>[]),
          );
          await FaceMLDataDB.instance.insert(p, clusterID);
          final bool extraPhotosFound =
              await ClusterFeedbackService.instance.checkAndDoAutomaticMerges(p);
          if (extraPhotosFound) {
            showShortToast(context, "Extra photos found for $text");
          }
          Bus.instance.fire(PeopleChangedEvent());
          Navigator.pop(context, p);
          log("inserted person");
        } catch (e, s) {
          Logger("_PersonActionSheetState")
              .severe("Failed to rename album", e, s);
          rethrow;
        }
      },
    );
    if (result is Exception) {
      await showGenericErrorDialog(context: context, error: result);
    }
  }

  Future<List<Person>> _getPersons() async {
    return FaceMLDataDB.instance.getPeople();
  }
}
