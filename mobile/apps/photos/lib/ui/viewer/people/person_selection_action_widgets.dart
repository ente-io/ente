import "dart:async";

import "package:flutter/material.dart";
import "package:logging/logging.dart";
import "package:photos/core/configuration.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/events/people_changed_event.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/l10n/l10n.dart";
import "package:photos/models/ml/face/person.dart";
import "package:photos/models/typedefs.dart";
import "package:photos/services/machine_learning/face_ml/person/person_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/common/loading_widget.dart";
import "package:photos/ui/components/buttons/button_widget.dart";
import "package:photos/ui/components/dialog_widget.dart";
import "package:photos/ui/components/models/button_type.dart";
import "package:photos/ui/notification/toast.dart";
import "package:photos/ui/viewer/people/person_face_widget.dart";
import "package:photos/utils/dialog_util.dart";
import "package:photos/utils/person_contact_linking_util.dart";

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
  late Future<List<PersonEntity>> _personEntities;
  final _logger = Logger('LinkContactToPersonSelectionPage');

  @override
  void initState() {
    super.initState();

    _personEntities = PersonService.instance.getPersons().then((persons) async {
      final List<PersonEntity> result = [];
      for (final person in persons) {
        if ((person.data.email != null && person.data.email!.isNotEmpty) ||
            (person.data.isIgnored)) {
          continue;
        }
        result.add(person);
      }
      return result;
    });
  }

  @override
  Widget build(BuildContext context) {
    _logger.info("Building LinkContactToPersonSelectionPage");
    final smallFontSize = getEnteTextTheme(context).small.fontSize!;
    final textScaleFactor =
        MediaQuery.textScalerOf(context).scale(smallFontSize) / smallFontSize;
    const horizontalEdgePadding = 20.0;
    const gridPadding = 16.0;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.l10n.selectPersonToLink,
        ),
        centerTitle: false,
      ),
      body: FutureBuilder<List<PersonEntity>>(
        future: _personEntities,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: EnteLoadingWidget());
          } else if (snapshot.hasError) {
            _logger.severe(
              "Failed to load _personEntities",
              snapshot.error,
              snapshot.stackTrace,
            );
            return const Center(child: Icon(Icons.error_outline_rounded));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(AppLocalizations.of(context).noResultsFound + '.'),
            );
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
                        personEntity: results[index],
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
                  personEntity: results[index],
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
      await showAlreadyLinkedEmailDialog(context, emailToLink);
      return null;
    }

    final personName = personEntity.data.name;
    PersonEntity? updatedPerson;
    final result = await showDialogWidget(
      context: context,
      title: context.l10n.linkPersonToEmail(email: emailToLink),
      icon: Icons.info_outline,
      body: context.l10n.linkPersonToEmailConfirmation(
          personName: personName, email: emailToLink,),
      isDismissible: true,
      buttons: [
        ButtonWidget(
          buttonAction: ButtonAction.first,
          buttonType: ButtonType.neutral,
          labelText: context.l10n.link,
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
          labelText: AppLocalizations.of(context).cancel,
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
  late Future<List<PersonEntity>> _personEntities;
  final _logger = Logger('ReassignMeSelectionPage');

  @override
  void initState() {
    super.initState();

    _personEntities = PersonService.instance.getPersons().then((persons) async {
      final List<PersonEntity> result = [];
      for (final person in persons) {
        if ((person.data.email != null && person.data.email!.isNotEmpty) ||
            (person.data.isIgnored)) {
          continue;
        }
        result.add(person);
      }
      return result;
    });
  }

  @override
  Widget build(BuildContext context) {
    _logger.info("Building ReassignMeSelectionPage");
    final smallFontSize = getEnteTextTheme(context).small.fontSize!;
    final textScaleFactor =
        MediaQuery.textScalerOf(context).scale(smallFontSize) / smallFontSize;
    const horizontalEdgePadding = 20.0;
    const gridPadding = 16.0;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.l10n.selectYourFace,
        ),
        centerTitle: false,
      ),
      body: FutureBuilder<List<PersonEntity>>(
        future: _personEntities,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: EnteLoadingWidget());
          } else if (snapshot.hasError) {
            _logger.severe(
              "Failed to load _personEntitiesWithThumnailFile",
              snapshot.error,
              snapshot.stackTrace,
            );
            return const Center(child: Icon(Icons.error_outline_rounded));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(AppLocalizations.of(context).noResultsFound + '.'),
            );
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
                    final dialog = createProgressDialog(
                      context,
                      context.l10n.reassigningLoading,
                    );
                    unawaited(dialog.show());
                    try {
                      await reassignMe(
                        currentPersonID: widget.currentMeId,
                        newPersonID: results[index].remoteID,
                      );
                      showToast(
                        context,
                        context.l10n
                            .reassignedToName(name: results[index].data.name),
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
                  personEntity: results[index],
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
  final PersonEntity personEntity;

  const _RoundedPersonFaceWidget({
    required this.onTap,
    required this.itemSize,
    required this.personEntity,
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
                      personId: personEntity.remoteID,
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
              personEntity.data.name,
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
