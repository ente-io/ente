import 'dart:async';
import "dart:io";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:logging/logging.dart";
import "package:photos/core/configuration.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/ente_theme_data.dart";
import "package:photos/events/people_changed_event.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/l10n/l10n.dart";
import "package:photos/models/api/collection/user.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/ml/face/person.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/account/user_service.dart";
import "package:photos/services/machine_learning/face_ml/feedback/cluster_feedback.dart";
import "package:photos/services/machine_learning/face_ml/person/person_service.dart";
import "package:photos/services/search_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/common/date_input.dart";
import "package:photos/ui/common/loading_widget.dart";
import "package:photos/ui/components/action_sheet_widget.dart";
import "package:photos/ui/components/buttons/button_widget.dart";
import "package:photos/ui/components/captioned_text_widget.dart";
import "package:photos/ui/components/expandable_menu_item_widget.dart";
import "package:photos/ui/components/menu_item_widget/menu_item_widget.dart";
import "package:photos/ui/components/models/button_type.dart";
import "package:photos/ui/components/toggle_switch_widget.dart";
import "package:photos/ui/notification/toast.dart";
import "package:photos/ui/sharing/album_share_info_widget.dart";
import "package:photos/ui/sharing/user_avator_widget.dart";
import "package:photos/ui/viewer/file/no_thumbnail_widget.dart";
import "package:photos/ui/viewer/gallery/hooks/pick_person_avatar.dart";
import "package:photos/ui/viewer/people/link_email_screen.dart";
import "package:photos/ui/viewer/people/people_util.dart";
import "package:photos/ui/viewer/people/person_clusters_page.dart";
import "package:photos/ui/viewer/people/person_face_widget.dart";
import "package:photos/ui/viewer/people/person_row_item.dart";
import "package:photos/utils/dialog_util.dart";
import "package:photos/utils/navigation_util.dart";
import "package:photos/utils/person_contact_linking_util.dart";

class SaveOrEditPerson extends StatefulWidget {
  final String? clusterID;
  final EnteFile? file;
  final bool isEditing;
  final PersonEntity? person;

  const SaveOrEditPerson(
    this.clusterID, {
    super.key,
    this.file,
    this.person,
    this.isEditing = false,
  }) : assert(
          !isEditing || person != null,
          'Person cannot be null when editing',
        );

  @override
  State<SaveOrEditPerson> createState() => _SaveOrEditPersonState();
}

class _SaveOrEditPersonState extends State<SaveOrEditPerson> {
  bool isKeypadOpen = false;
  String _inputName = "";
  String? _selectedDate;
  String? _email;
  bool _isPinned = false;
  bool _hideFromMemories = false;
  bool userAlreadyAssigned = false;
  late final Logger _logger = Logger("_SavePersonState");
  Timer? _debounce;
  List<(PersonEntity, EnteFile)> _cachedPersons = [];
  PersonEntity? person;
  final _nameFocsNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _inputName = widget.person?.data.name ?? "";
    _selectedDate = widget.person?.data.birthDate;
    _email = widget.person?.data.email;
    person = widget.person;
    _isPinned = widget.person?.data.isPinned ?? false;
    _hideFromMemories = widget.person?.data.hideFromMemories ?? false;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _nameFocsNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !(changed && _inputName.isNotEmpty),
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) {
          return;
        }

        _nameFocsNode.unfocus();
        final result = await _saveChangesPrompt(context);

        if (result is PersonEntity) {
          if (context.mounted) {
            Navigator.pop(context, result);
          }

          return;
        }

        late final bool shouldPop;
        if (result == ButtonAction.first || result == ButtonAction.second) {
          shouldPop = true;
        } else {
          shouldPop = false;
        }

        if (context.mounted && shouldPop) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: isKeypadOpen,
        appBar: AppBar(
          title: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              widget.isEditing
                  ? context.l10n.editPerson
                  : context.l10n.savePerson,
            ),
          ),
        ),
        body: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(
                      bottom: 32.0,
                      left: 16.0,
                      right: 16.0,
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 48),
                        if (person != null)
                          Stack(
                            children: [
                              SizedBox(
                                height: 110,
                                width: 110,
                                child: ClipPath(
                                  clipper: ShapeBorderClipper(
                                    shape: ContinuousRectangleBorder(
                                      borderRadius: BorderRadius.circular(80),
                                    ),
                                  ),
                                  child: PersonFaceWidget(
                                    key: ValueKey(
                                      person?.data.avatarFaceID ?? "",
                                    ),
                                    personId: person!.remoteID,
                                  ),
                                ),
                              ),
                              if (person != null)
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8.0),
                                      boxShadow: Theme.of(context)
                                          .colorScheme
                                          .enteTheme
                                          .shadowMenu,
                                      color: getEnteColorScheme(context)
                                          .backgroundElevated2,
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.edit),
                                      iconSize:
                                          16, // specify the size of the icon
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () async {
                                        final result =
                                            await showPersonAvatarPhotoSheet(
                                          context,
                                          person!,
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
                                              type: PeopleEventType
                                                  .saveOrEditPerson,
                                              source: "_SaveOrEditPersonState",
                                              person: result,
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        if (person == null)
                          SizedBox(
                            height: 110,
                            width: 110,
                            child: ClipPath(
                              clipper: ShapeBorderClipper(
                                shape: ContinuousRectangleBorder(
                                  borderRadius: BorderRadius.circular(80),
                                ),
                              ),
                              child: widget.file != null
                                  ? PersonFaceWidget(
                                      clusterID: widget.clusterID,
                                    )
                                  : const NoThumbnailWidget(
                                      addBorder: false,
                                    ),
                            ),
                          ),
                        const SizedBox(height: 36),
                        TextFormField(
                          keyboardType: TextInputType.name,
                          textCapitalization: TextCapitalization.words,
                          autocorrect: false,
                          focusNode: _nameFocsNode,
                          onChanged: (value) {
                            if (_debounce?.isActive ?? false) {
                              _debounce?.cancel();
                            }
                            _debounce =
                                Timer(const Duration(milliseconds: 300), () {
                              setState(() {
                                _inputName = value;
                              });
                            });
                          },
                          initialValue: _inputName,
                          decoration: InputDecoration(
                            focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(8.0)),
                              borderSide: BorderSide(
                                color: getEnteColorScheme(context).strokeMuted,
                              ),
                            ),
                            fillColor: getEnteColorScheme(context).fillFaint,
                            filled: true,
                            hintText: context.l10n.enterName,
                            hintStyle: getEnteTextTheme(context).bodyFaint,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            border: UnderlineInputBorder(
                              borderSide: BorderSide.none,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        DatePickerField(
                          hintText: context.l10n.enterDateOfBirth,
                          firstDate: DateTime(100),
                          lastDate: DateTime.now(),
                          initialValue: _selectedDate,
                          isRequired: false,
                          onChanged: (date) {
                            setState(() {
                              // format date to yyyy-MM-dd
                              _selectedDate =
                                  date?.toIso8601String().split("T").first;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOutQuad,
                          child: _EmailSection(_email, person?.remoteID),
                        ),
                        const SizedBox(height: 24),
                        _buildVisibilitySection(context),
                        const SizedBox(height: 24),
                        ButtonWidget(
                          buttonType: ButtonType.primary,
                          labelText: context.l10n.save,
                          isDisabled: !changed || _inputName.isEmpty,
                          onTap: () async {
                            if (widget.isEditing) {
                              final updatedPersonEntity =
                                  await updatePerson(context);
                              if (updatedPersonEntity != null) {
                                Navigator.pop(context, updatedPersonEntity);
                              }
                            } else {
                              final newPersonEntity = await addNewPerson(
                                context,
                                text: _inputName,
                                clusterID: widget.clusterID!,
                                birthdate: _selectedDate,
                                email: _email,
                              ).catchError((e) {
                                _logger.severe("Error adding new person", e);
                                return null;
                              });
                              if (newPersonEntity != null) {
                                Navigator.pop(context, newPersonEntity);
                              }
                            }
                          },
                        ),
                        const SizedBox(height: 32),
                        if (!widget.isEditing) _getPersonItems(),
                        if (widget.isEditing)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              context.l10n.mergedPhotos,
                              style: getEnteTextTheme(context).body,
                            ),
                          ),
                        if (widget.isEditing)
                          Padding(
                            padding:
                                const EdgeInsets.only(bottom: 12.0, top: 24.0),
                            child: PersonClustersWidget(person!),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVisibilitySection(BuildContext context) {
    return ExpandableMenuItemWidget(
      title: context.l10n.visibility,
      leadingIcon: Icons.visibility_outlined,
      selectionOptionsWidget: Column(
        children: [
          MenuItemWidget(
            captionedTextWidget: CaptionedTextWidget(
              title: context.l10n.pinToTop,
            ),
            trailingWidget: ToggleSwitchWidget(
              value: () => _isPinned,
              onChanged: () async {
                if (!mounted) return;
                setState(() {
                  _isPinned = !_isPinned;
                });
              },
            ),
            singleBorderRadius: 8,
            isGestureDetectorDisabled: true,
          ),
          const SizedBox(height: 12),
          MenuItemWidget(
            captionedTextWidget: CaptionedTextWidget(
              title: context.l10n.hideFromMemories,
            ),
            trailingWidget: ToggleSwitchWidget(
              value: () => _hideFromMemories,
              onChanged: () async {
                if (!mounted) return;
                setState(() {
                  _hideFromMemories = !_hideFromMemories;
                });
                memoriesCacheService.queueUpdateCache();
              },
            ),
            singleBorderRadius: 8,
            isGestureDetectorDisabled: true,
          ),
        ],
      ),
    );
  }

  Future<dynamic> _saveChangesPrompt(BuildContext context) async {
    PersonEntity? updatedPersonEntity;
    return await showActionSheet(
      useRootNavigator: Platform.isIOS ? true : false,
      body: context.l10n.saveChangesBeforeLeavingQuestion,
      context: context,
      buttons: [
        ButtonWidget(
          buttonType: ButtonType.neutral,
          labelText: AppLocalizations.of(context).save,
          isInAlert: true,
          buttonAction: ButtonAction.first,
          shouldStickToDarkTheme: true,
          onTap: () async {
            if (widget.isEditing) {
              updatedPersonEntity = await updatePerson(context);
            } else {
              try {
                updatedPersonEntity = await addNewPerson(
                  context,
                  text: _inputName,
                  clusterID: widget.clusterID!,
                  birthdate: _selectedDate,
                  email: _email,
                );
              } catch (e) {
                _logger.severe("Error updating person", e);
              }
            }
          },
        ),
        ButtonWidget(
          buttonType: ButtonType.secondary,
          labelText: context.l10n.dontSave,
          isInAlert: true,
          buttonAction: ButtonAction.second,
          shouldStickToDarkTheme: true,
        ),
        ButtonWidget(
          buttonType: ButtonType.secondary,
          labelText: AppLocalizations.of(context).cancel,
          isInAlert: true,
          buttonAction: ButtonAction.cancel,
          shouldStickToDarkTheme: true,
        ),
      ],
    ).then((buttonResult) {
      if (buttonResult == null ||
          buttonResult.action == null ||
          buttonResult.action == ButtonAction.cancel) {
        return ButtonAction.cancel;
      } else if (buttonResult.action == ButtonAction.second) {
        return ButtonAction.second;
      } else {
        return updatedPersonEntity;
      }
    });
  }

  Widget _getPersonItems() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: StreamBuilder<List<(PersonEntity, EnteFile)>>(
        stream: _getPersonsWithRecentFileStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            _logger.severe(
              "Error in _getPersonItems: ${snapshot.error} ${snapshot.stackTrace}}",
            );
            if (kDebugMode) {
              return Column(
                mainAxisSize: MainAxisSize.min,
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
            final filteredResults = _inputName.isNotEmpty
                ? persons
                    .where(
                      (element) => element.$1.data.name
                          .toLowerCase()
                          .contains(_inputName.toLowerCase()),
                    )
                    .toList()
                : persons;
            if (filteredResults.isEmpty) {
              return const SizedBox.shrink();
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                const horizontalEdgePadding = 20.0;
                const gridPadding = 16.0;
                final maxWidth = constraints.maxWidth > 0
                    ? constraints.maxWidth
                    : MediaQuery.of(context).size.width;
                final availableWidth = (maxWidth - (horizontalEdgePadding * 2))
                    .clamp(0.0, maxWidth);
                var crossAxisCount = (availableWidth / 100).floor();
                if (crossAxisCount <= 0) {
                  crossAxisCount = 1;
                }
                final totalSpacing = (crossAxisCount - 1) * gridPadding;
                var tileSize = (availableWidth - totalSpacing) / crossAxisCount;
                if (!tileSize.isFinite || tileSize <= 0) {
                  tileSize = 96;
                }
                const double extraVerticalSpacing = 6.0;
                final smallFontSize =
                    getEnteTextTheme(context).small.fontSize ?? 14;
                final textScaleFactor =
                    MediaQuery.textScalerOf(context).scale(smallFontSize) /
                        smallFontSize;
                final childAspectRatio = tileSize /
                    (tileSize + extraVerticalSpacing + (24 * textScaleFactor));

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                      child: Text(
                        context.l10n.orMergeWithExistingPerson,
                        style: getEnteTextTheme(context).largeBold,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: gridPadding,
                          mainAxisSpacing: gridPadding,
                          childAspectRatio: childAspectRatio,
                        ),
                        itemCount: filteredResults.length,
                        itemBuilder: (context, index) {
                          final person = filteredResults[index];
                          return PersonGridItem(
                            key: ValueKey(person.$1.remoteID),
                            person: person.$1,
                            personFile: person.$2,
                            size: tileSize,
                            onTap: () async {
                              if (userAlreadyAssigned) {
                                return;
                              }
                              userAlreadyAssigned = true;
                              await ClusterFeedbackService.instance
                                  .addClusterToExistingPerson(
                                person: person.$1,
                                clusterID: widget.clusterID!,
                              );

                              Navigator.pop(context, person);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          } else {
            return const EnteLoadingWidget();
          }
        },
      ),
    );
  }

  Stream<List<(PersonEntity, EnteFile)>>
      _getPersonsWithRecentFileStream() async* {
    if (_cachedPersons.isEmpty) {
      _cachedPersons = await _getPersonsWithRecentFile();
    }
    yield _cachedPersons;
  }

  Future<PersonEntity?> addNewPerson(
    BuildContext context, {
    String text = '',
    required String clusterID,
    String? birthdate,
    String? email,
  }) async {
    if (email != null &&
        email.isNotEmpty &&
        await checkIfEmailAlreadyAssignedToAPerson(email)) {
      _logger.severe(
        "Failed to addNewPerson, email is already assigned to a person",
      );
      await showAlreadyLinkedEmailDialog(context, email);
      return null;
    }

    try {
      if (userAlreadyAssigned) {
        return null;
      }
      if (text.trim() == "") {
        return null;
      }
      userAlreadyAssigned = true;
      final personEntity = await PersonService.instance.addPerson(
        name: text,
        clusterID: clusterID,
        isPinned: _isPinned,
        hideFromMemories: _hideFromMemories,
        birthdate: birthdate,
        email: email,
      );
      final bool extraPhotosFound =
          await ClusterFeedbackService.instance.checkAndDoAutomaticMerges(
        personEntity,
        personClusterID: clusterID,
      );
      if (extraPhotosFound) {
        showShortToast(context, AppLocalizations.of(context).extraPhotosFound);
      }
      Bus.instance.fire(
        PeopleChangedEvent(
          type: PeopleEventType.saveOrEditPerson,
          source: "_SaveOrEditPersonState addNewPerson",
          person: personEntity,
        ),
      );
      return personEntity;
    } catch (e) {
      _logger.severe("Error adding new person", e);
      userAlreadyAssigned = false;
      await showGenericErrorDialog(context: context, error: e);
      return null;
    }
  }

  bool get changed => widget.isEditing
      ? (_inputName.trim() != person!.data.name ||
          _selectedDate != person!.data.birthDate ||
          _email != person!.data.email ||
          _isPinned != person!.data.isPinned ||
          _hideFromMemories != person!.data.hideFromMemories)
      : _inputName.trim().isNotEmpty;

  Future<PersonEntity?> updatePerson(BuildContext context) async {
    try {
      if (_email != null &&
          _email!.isNotEmpty &&
          _email != person!.data.email &&
          await checkIfEmailAlreadyAssignedToAPerson(_email!)) {
        await showAlreadyLinkedEmailDialog(context, _email!);
        return null;
      }
      final String name = _inputName.trim();
      final String? birthDate = _selectedDate;
      final personEntity = await PersonService.instance.updateAttributes(
        person!.remoteID,
        name: name,
        birthDate: birthDate,
        isPinned: _isPinned,
        hideFromMemories: _hideFromMemories,
        email: _email,
      );

      Bus.instance.fire(
        PeopleChangedEvent(
          type: PeopleEventType.saveOrEditPerson,
          source: "_SaveOrEditPersonState updatePerson",
          person: personEntity,
        ),
      );
      return personEntity;
    } catch (e) {
      _logger.severe("Error adding updating person", e);
      await showGenericErrorDialog(context: context, error: e);
      return null;
    }
  }

  Future<List<(PersonEntity, EnteFile)>> _getPersonsWithRecentFile({
    bool excludeHidden = true,
  }) async {
    final persons = await PersonService.instance.getPersons();
    if (excludeHidden) {
      persons.removeWhere((person) => person.data.isIgnored);
    }
    final List<(PersonEntity, EnteFile, int)> personFileCounts = [];
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
      personFileCounts.add((person, files.first, files.length));
    }
    personFileCounts.sort(
      (a, b) => b.$3.compareTo(a.$3),
    );
    return personFileCounts
        .map<(PersonEntity, EnteFile)>((entry) => (entry.$1, entry.$2))
        .toList();
  }
}

class _EmailSection extends StatefulWidget {
  final String? personID;
  final String? email;
  const _EmailSection(this.email, this.personID);

  @override
  State<_EmailSection> createState() => _EmailSectionState();
}

class _EmailSectionState extends State<_EmailSection> {
  String? _email;
  final _logger = Logger("_EmailSectionState");
  bool _initialEmailIsUserEmail = false;
  late final List<User> _contacts;

  @override
  void initState() {
    super.initState();
    _email = widget.email;
    _initialEmailIsUserEmail = Configuration.instance.getEmail() == _email;
    _contacts = _getContacts();
  }

  @override
  void didUpdateWidget(covariant _EmailSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.email != widget.email) {
      setState(() {
        _email = widget.email;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const limitCountTo = 5;
    final avatarSize = getAvatarSize(AvatarType.small);
    final overlapPadding = getOverlapPadding(AvatarType.small);
    if (_email == null || _email!.isEmpty) {
      return AnimatedSize(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOutQuad,
        child: Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16),
            decoration: BoxDecoration(
              color: getEnteColorScheme(context).fillFaint,
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (_contacts.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 1.0),
                      height: 32 + 2 * UserAvatarWidget.strokeWidth,
                      width: ((avatarSize) * (limitCountTo + 1)) -
                          (((avatarSize) - overlapPadding) * limitCountTo) +
                          (2 * UserAvatarWidget.strokeWidth),
                      child: AlbumSharesIcons(
                        sharees: _contacts,
                        limitCountTo: limitCountTo,
                        type: AvatarType.small,
                        padding: EdgeInsets.zero,
                        stackAlignment: Alignment.center,
                      ),
                    ),
                  ),
                if (_contacts.isNotEmpty) const SizedBox(height: 38),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: FutureBuilder<bool>(
                    future: isMeAssigned(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        final isMeAssigned = snapshot.data!;
                        if (!isMeAssigned || _initialEmailIsUserEmail) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: ButtonWidget(
                                  buttonType: ButtonType.secondary,
                                  labelText: context.l10n.thisIsMeExclamation,
                                  onTap: () async {
                                    _updateEmailField(
                                      Configuration.instance.getEmail(),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ButtonWidget(
                                  buttonType: ButtonType.primary,
                                  labelText: context.l10n.linkEmail,
                                  shouldSurfaceExecutionStates: false,
                                  onTap: () async {
                                    final newEmail = await routeToPage(
                                      context,
                                      LinkEmailScreen(
                                        widget.personID,
                                        isFromSaveOrEditPerson: true,
                                      ),
                                    );
                                    if (newEmail != null) {
                                      _updateEmailField(newEmail as String);
                                    }
                                  },
                                ),
                              ),
                            ],
                          );
                        } else {
                          return ButtonWidget(
                            buttonType: ButtonType.primary,
                            labelText: context.l10n.linkEmail,
                            shouldSurfaceExecutionStates: false,
                            onTap: () async {
                              final newEmail = await routeToPage(
                                context,
                                LinkEmailScreen(
                                  widget.personID,
                                  isFromSaveOrEditPerson: true,
                                ),
                              );
                              if (newEmail != null) {
                                _updateEmailField(newEmail as String);
                              }
                            },
                          );
                        }
                      } else if (snapshot.hasError) {
                        _logger.severe(
                          "Error getting isMeAssigned",
                          snapshot.error,
                        );
                        return const EnteLoadingWidget();
                      } else {
                        return const EnteLoadingWidget();
                      }
                    },
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOutQuad,
              ),
        ),
      );
    } else {
      return TextFormField(
        canRequestFocus: false,
        autocorrect: false,
        decoration: InputDecoration(
          suffixIcon: GestureDetector(
            onTap: () {
              _updateEmailField("");
            },
            child: Icon(
              Icons.close_outlined,
              color: getEnteColorScheme(context).strokeMuted,
            ),
          ),
          fillColor: getEnteColorScheme(context).fillFaint,
          filled: true,
          hintText: _email,
          hintStyle: getEnteTextTheme(context).bodyFaint,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: UnderlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ).animate().fadeIn(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOutQuad,
          );
    }
  }

  void _updateEmailField(String? newEmail) {
    final saveOrEditPersonState =
        context.findAncestorStateOfType<_SaveOrEditPersonState>()!;
    saveOrEditPersonState.setState(() {
      saveOrEditPersonState._email = newEmail;
    });
  }

  List<User> _getContacts() {
    final userEmailsToAviod =
        PersonService.instance.emailToPartialPersonDataMapCache.keys;
    final ownerEmail = Configuration.instance.getEmail();
    final relevantUsers = UserService.instance.getRelevantContacts()
      ..add(User(email: ownerEmail!))
      ..removeWhere(
        (user) => userEmailsToAviod.contains(user.email),
      );

    relevantUsers.sort(
      (a, b) => (a.email).compareTo(b.email),
    );

    return relevantUsers;
  }
}
