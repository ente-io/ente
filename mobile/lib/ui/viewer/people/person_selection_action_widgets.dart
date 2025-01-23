import "dart:async";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/ml/face/person.dart";
import "package:photos/models/typedefs.dart";
import "package:photos/services/machine_learning/face_ml/person/person_service.dart";
import "package:photos/services/machine_learning/ml_result.dart";
import "package:photos/services/search_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/actions/person_contact_linking_actions.dart";
import "package:photos/ui/common/loading_widget.dart";
import "package:photos/ui/viewer/search/result/person_face_widget.dart";
import "package:photos/utils/dialog_util.dart";
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
        final file = await _getRecentFile(person);
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
                    await PersonContactLinkingActions()
                        .linkPersonToContact(
                      context,
                      emailToLink: widget.emailToLink!,
                      personEntity: results[index].person,
                    )
                        .then((updatedPerson) {
                      if (updatedPerson != null) {
                        Navigator.of(context).pop(updatedPerson);
                      }
                    });
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

  Future<EnteFile> _getRecentFile(
    PersonEntity person,
  ) async {
    final clustersToFiles =
        await SearchService.instance.getClusterFilesForPersonID(
      person.remoteID,
    );
    int? avatarFileID;
    if (person.data.hasAvatar()) {
      avatarFileID = tryGetFileIdFromFaceId(person.data.avatarFaceID!);
    }
    EnteFile? resultFile;
    // iterate over all clusters and get the first file
    for (final clusterFiles in clustersToFiles.values) {
      for (final file in clusterFiles) {
        if (avatarFileID != null && file.uploadedFileID! == avatarFileID) {
          resultFile = file;
          break;
        }
        resultFile ??= file;
        if (resultFile.creationTime! < file.creationTime!) {
          resultFile = file;
        }
      }
    }
    if (resultFile == null) {
      debugPrint(
        "Person ${kDebugMode ? person.data.name : person.remoteID} has no files",
      );
      return EnteFile();
    }
    return resultFile;
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
        final file = await _getRecentFile(person);
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
                      await PersonContactLinkingActions().reassignMe(
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

  Future<EnteFile> _getRecentFile(
    PersonEntity person,
  ) async {
    final clustersToFiles =
        await SearchService.instance.getClusterFilesForPersonID(
      person.remoteID,
    );
    int? avatarFileID;
    if (person.data.hasAvatar()) {
      avatarFileID = tryGetFileIdFromFaceId(person.data.avatarFaceID!);
    }
    EnteFile? resultFile;
    // iterate over all clusters and get the first file
    for (final clusterFiles in clustersToFiles.values) {
      for (final file in clusterFiles) {
        if (avatarFileID != null && file.uploadedFileID! == avatarFileID) {
          resultFile = file;
          break;
        }
        resultFile ??= file;
        if (resultFile.creationTime! < file.creationTime!) {
          resultFile = file;
        }
      }
    }
    if (resultFile == null) {
      debugPrint(
        "Person ${kDebugMode ? person.data.name : person.remoteID} has no files",
      );
      return EnteFile();
    }
    return resultFile;
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
