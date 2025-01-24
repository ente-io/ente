import "dart:async";

import "package:flutter/material.dart";
import "package:logging/logging.dart";
import "package:photos/core/configuration.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/events/people_changed_event.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/ml/face/person.dart";
import "package:photos/models/typedefs.dart";
import "package:photos/services/machine_learning/face_ml/person/person_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/common/loading_widget.dart";
import "package:photos/ui/components/buttons/button_widget.dart";
import "package:photos/ui/components/dialog_widget.dart";
import "package:photos/ui/components/models/button_type.dart";
import "package:photos/ui/viewer/search/result/person_face_widget.dart";
import "package:photos/utils/dialog_util.dart";
import "package:photos/utils/person_contact_linking_util.dart";
import "package:photos/utils/toast_util.dart";

class PersonEntityWithThumbnailFile {
  final PersonEntity person;
  final EnteFile thumbnailFile;

  const PersonEntityWithThumbnailFile(
    this.person,
    this.thumbnailFile,
  );
}

class LinkContactToPersonSelectionPage extends StatefulWidget {
  final String? emailToLink;
  const LinkContactToPersonSelectionPage({
    this.emailToLink,
    super.key,
  });

  @override
  State<LinkContactToPersonSelectionPage> createState() =>
      _LinkContactToPersonSelectionPageState();
}

class _LinkContactToPersonSelectionPageState
    extends State<LinkContactToPersonSelectionPage> {
  late Future<List<PersonEntityWithThumbnailFile>>
      _personEntitiesWithThumnailFile;
  final _logger = Logger('LinkContactToPersonSelectionPage');

  @override
  void initState() {
    super.initState();

    _personEntitiesWithThumnailFile =
        PersonService.instance.getPersons().then((persons) async {
      final List<PersonEntityWithThumbnailFile> result = [];
      for (final person in persons) {
        if (person.data.email != null && person.data.email!.isNotEmpty) {
          continue;
        }
        final file = await PersonService.instance.getRecentFileOfPerson(person);
        result.add(PersonEntityWithThumbnailFile(person, file));
      }
      return result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final smallFontSize = getEnteTextTheme(context).small.fontSize!;
    final textScaleFactor =
        MediaQuery.textScalerOf(context).scale(smallFontSize) / smallFontSize;
    const horizontalEdgePadding = 20.0;
    const gridPadding = 16.0;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Select person to link",
        ),
        centerTitle: false,
      ),
      body: FutureBuilder<List<PersonEntityWithThumbnailFile>>(
        future: _personEntitiesWithThumnailFile,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: EnteLoadingWidget());
          } else if (snapshot.hasError) {
            return const Center(child: Icon(Icons.error_outline_rounded));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text(S.of(context).noResultsFound + '.'));
          } else {
            final results = snapshot.data!;
            final screenWidth = MediaQuery.of(context).size.width;
            final crossAxisCount = (screenWidth / 100).floor();

            final itemSize = (screenWidth -
                    ((horizontalEdgePadding * 2) +
                        ((crossAxisCount - 1) * gridPadding))) /
                crossAxisCount;

            return GridView.builder(
              padding: const EdgeInsets.fromLTRB(
                horizontalEdgePadding,
                16,
                horizontalEdgePadding,
                96,
              ),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                mainAxisSpacing: gridPadding,
                crossAxisSpacing: gridPadding,
                crossAxisCount: crossAxisCount,
                childAspectRatio:
                    itemSize / (itemSize + (24 * textScaleFactor)),
              ),
              itemCount: results.length,
              itemBuilder: (context, index) {
                return _RoundedPersonFaceWidget(
                  onTap: () async {
                    try {
                      final updatedPerson = await linkPersonToContact(
                        context,
                        emailToLink: widget.emailToLink!,
                        personEntity: results[index].person,
                      );

                      if (updatedPerson != null) {
                        Navigator.of(context).pop(updatedPerson);
                      }
                    } catch (e) {
                      await showGenericErrorDialog(context: context, error: e);
                      _logger.severe("Failed to link person to contact", e);
                    }
                  },
                  itemSize: itemSize,
                  personEntitiesWithThumbnailFile: results[index],
                );
              },
            );
          }
        },
      ),
    );
  }

  Future<PersonEntity?> linkPersonToContact(
    BuildContext context, {
    required String emailToLink,
    required PersonEntity personEntity,
  }) async {
    if (await checkIfEmailAlreadyAssignedToAPerson(emailToLink)) {
      throw Exception("Email already linked to a person");
    }

    final personName = personEntity.data.name;
    PersonEntity? updatedPerson;
    final result = await showDialogWidget(
      context: context,
      title: "Link person to $emailToLink",
      icon: Icons.info_outline,
      body: "This will link $personName to $emailToLink",
      isDismissible: true,
      buttons: [
        ButtonWidget(
          buttonAction: ButtonAction.first,
          buttonType: ButtonType.neutral,
          labelText: "Link",
          isInAlert: true,
          onTap: () async {
            updatedPerson = await PersonService.instance
                .updateAttributes(personEntity.remoteID, email: emailToLink);
            Bus.instance.fire(
              PeopleChangedEvent(
                type: PeopleEventType.saveOrEditPerson,
                source: "linkPersonToContact",
                person: updatedPerson,
              ),
            );
          },
        ),
        ButtonWidget(
          buttonAction: ButtonAction.cancel,
          buttonType: ButtonType.secondary,
          labelText: S.of(context).cancel,
          isInAlert: true,
        ),
      ],
    );

    if (result?.exception != null) {
      Logger("linkPersonToContact")
          .severe("Failed to link person to contact", result!.exception);
      await showGenericErrorDialog(context: context, error: result.exception);
      return null;
    } else {
      return updatedPerson;
    }
  }
}

class ReassignMeSelectionPage extends StatefulWidget {
  final String currentMeId;
  const ReassignMeSelectionPage({
    required this.currentMeId,
    super.key,
  });

  @override
  State<ReassignMeSelectionPage> createState() =>
      _ReassignMeSelectionPageState();
}

class _ReassignMeSelectionPageState extends State<ReassignMeSelectionPage> {
  late Future<List<PersonEntityWithThumbnailFile>>
      _personEntitiesWithThumnailFile;
  final _logger = Logger('ReassignMeSelectionPage');

  @override
  void initState() {
    super.initState();

    _personEntitiesWithThumnailFile =
        PersonService.instance.getPersons().then((persons) async {
      final List<PersonEntityWithThumbnailFile> result = [];
      for (final person in persons) {
        if (person.data.email != null && person.data.email!.isNotEmpty) {
          continue;
        }
        final file = await PersonService.instance.getRecentFileOfPerson(person);
        result.add(PersonEntityWithThumbnailFile(person, file));
      }
      return result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final smallFontSize = getEnteTextTheme(context).small.fontSize!;
    final textScaleFactor =
        MediaQuery.textScalerOf(context).scale(smallFontSize) / smallFontSize;
    const horizontalEdgePadding = 20.0;
    const gridPadding = 16.0;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Select your face",
        ),
        centerTitle: false,
      ),
      body: FutureBuilder<List<PersonEntityWithThumbnailFile>>(
        future: _personEntitiesWithThumnailFile,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: EnteLoadingWidget());
          } else if (snapshot.hasError) {
            return const Center(child: Icon(Icons.error_outline_rounded));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text(S.of(context).noResultsFound + '.'));
          } else {
            final results = snapshot.data!;
            final screenWidth = MediaQuery.of(context).size.width;
            final crossAxisCount = (screenWidth / 100).floor();

            final itemSize = (screenWidth -
                    ((horizontalEdgePadding * 2) +
                        ((crossAxisCount - 1) * gridPadding))) /
                crossAxisCount;

            return GridView.builder(
              padding: const EdgeInsets.fromLTRB(
                horizontalEdgePadding,
                16,
                horizontalEdgePadding,
                96,
              ),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                mainAxisSpacing: gridPadding,
                crossAxisSpacing: gridPadding,
                crossAxisCount: crossAxisCount,
                childAspectRatio:
                    itemSize / (itemSize + (24 * textScaleFactor)),
              ),
              itemCount: results.length,
              itemBuilder: (context, index) {
                return _RoundedPersonFaceWidget(
                  onTap: () async {
                    final dialog =
                        createProgressDialog(context, "Reassigning...");
                    unawaited(dialog.show());
                    try {
                      await reassignMe(
                        currentPersonID: widget.currentMeId,
                        newPersonID: results[index].person.remoteID,
                      );
                      showToast(
                        context,
                        "Reassigned you to ${results[index].person.data.name}",
                      );
                      await Future.delayed(const Duration(milliseconds: 1250));
                      unawaited(dialog.hide());
                      Navigator.of(context).pop();
                    } catch (e) {
                      unawaited(dialog.hide());
                      unawaited(
                        showGenericErrorDialog(context: context, error: e),
                      );
                    }
                  },
                  itemSize: itemSize,
                  personEntitiesWithThumbnailFile: results[index],
                );
              },
            );
          }
        },
      ),
    );
  }

  Future<void> reassignMe({
    required String currentPersonID,
    required String newPersonID,
  }) async {
    try {
      final email = Configuration.instance.getEmail();

      final updatedPerson1 = await PersonService.instance
          .updateAttributes(currentPersonID, email: '');
      Bus.instance.fire(
        PeopleChangedEvent(
          type: PeopleEventType.saveOrEditPerson,
          source: "reassignMe",
          person: updatedPerson1,
        ),
      );

      final updatedPerson2 = await PersonService.instance
          .updateAttributes(newPersonID, email: email);
      Bus.instance.fire(
        PeopleChangedEvent(
          type: PeopleEventType.saveOrEditPerson,
          source: "reassignMe",
          person: updatedPerson2,
        ),
      );
    } catch (e) {
      _logger.severe("Failed to reassign me", e);
      rethrow;
    }
  }
}

class _RoundedPersonFaceWidget extends StatelessWidget {
  final FutureVoidCallback onTap;
  final double itemSize;
  final PersonEntityWithThumbnailFile personEntitiesWithThumbnailFile;

  const _RoundedPersonFaceWidget({
    required this.onTap,
    required this.itemSize,
    required this.personEntitiesWithThumbnailFile,
  });

  double get borderRadius => 82 * (itemSize / 102);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              ClipPath(
                clipper: ShapeBorderClipper(
                  shape: ContinuousRectangleBorder(
                    borderRadius: BorderRadius.circular(borderRadius),
                  ),
                ),
                child: Container(
                  width: itemSize,
                  height: itemSize,
                  decoration: BoxDecoration(
                    color: getEnteColorScheme(context).strokeFaint,
                  ),
                ),
              ),
              SizedBox(
                width: itemSize,
                height: itemSize,
                child: SizedBox(
                  width: itemSize - 2,
                  height: itemSize - 2,
                  child: ClipPath(
                    clipper: ShapeBorderClipper(
                      shape: ContinuousRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          borderRadius - 1,
                        ),
                      ),
                    ),
                    child: PersonFaceWidget(
                      personEntitiesWithThumbnailFile.thumbnailFile,
                      personId: personEntitiesWithThumbnailFile.person.remoteID,
                      useFullFile: true,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 0),
            child: Text(
              personEntitiesWithThumbnailFile.person.data.name,
              maxLines: 1,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: getEnteTextTheme(context).small,
            ),
          ),
        ],
      ),
    );
  }
}
