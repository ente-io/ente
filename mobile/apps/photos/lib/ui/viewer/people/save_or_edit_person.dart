import 'dart:async';
import 'dart:math' show max;

import "package:collection/collection.dart";
import "package:ente_pure_utils/ente_pure_utils.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:logging/logging.dart";
import "package:ml_linalg/linalg.dart" as ml;
import "package:photos/core/configuration.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/db/ml/db.dart";
import "package:photos/ente_theme_data.dart";
import "package:photos/events/people_changed_event.dart";
import "package:photos/events/people_sort_order_change_event.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/generated/protos/ente/common/vector.pb.dart";
import "package:photos/l10n/l10n.dart";
import "package:photos/models/api/collection/user.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/ml/face/person.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/account/user_service.dart";
import "package:photos/services/machine_learning/face_ml/feedback/cluster_feedback.dart";
import "package:photos/services/machine_learning/face_ml/person/person_service.dart";
import "package:photos/services/search_service.dart";
import "package:photos/theme/colors.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/theme/text_style.dart";
import "package:photos/ui/common/date_input.dart";
import "package:photos/ui/common/loading_widget.dart";
import "package:photos/ui/components/action_sheet_widget.dart";
import "package:photos/ui/components/buttons/button_widget.dart";
import "package:photos/ui/components/buttons/icon_button_widget.dart";
import "package:photos/ui/components/models/button_type.dart";
import "package:photos/ui/notification/toast.dart";
import "package:photos/ui/sharing/album_share_info_widget.dart";
import "package:photos/ui/sharing/user_avator_widget.dart";
import "package:photos/ui/viewer/file/no_thumbnail_widget.dart";
import "package:photos/ui/viewer/gallery/hooks/pick_person_avatar.dart";
import "package:photos/ui/viewer/people/face_thumbnail_squircle.dart";
import "package:photos/ui/viewer/people/link_email_screen.dart";
import "package:photos/ui/viewer/people/people_util.dart";
import "package:photos/ui/viewer/people/person_clusters_page.dart";
import "package:photos/ui/viewer/people/person_face_widget.dart";
import "package:photos/ui/viewer/people/person_row_item.dart";
import "package:photos/utils/dialog_util.dart";
import "package:photos/utils/local_settings.dart";
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
  String _mergeSearchQuery = "";
  bool _isMergeSearchActive = false;
  String? _selectedDate;
  String? _email;
  bool _isPinned = false;
  bool _hideFromMemories = false;
  bool userAlreadyAssigned = false;
  late final Logger _logger = Logger("_SavePersonState");
  Timer? _debounce;
  List<_MergePersonEntry> _cachedPersons = [];
  Map<String, double> _personToMaxSimilarity = {};
  late PeopleSortKey _sortKey;
  bool _nameSortAscending = true;
  bool _updatedSortAscending = false;
  bool _photosSortAscending = false;
  bool _useSimilaritySort = true;
  PersonEntity? person;
  final _nameFocsNode = FocusNode();
  final _mergeSearchFocusNode = FocusNode();
  final _mergeSearchController = TextEditingController();
  final _mergeSearchFieldKey = GlobalKey();

  static const double _sortMenuItemHeight = 52;
  static const double _sortMenuCornerRadius = 12;

  @override
  void initState() {
    super.initState();
    _inputName = widget.person?.data.name ?? "";
    _selectedDate = widget.person?.data.birthDate;
    _email = widget.person?.data.email;
    person = widget.person;
    _isPinned = widget.person?.data.isPinned ?? false;
    _hideFromMemories = widget.person?.data.hideFromMemories ?? false;
    final settings = localSettings;
    _sortKey = settings.peopleSortKey();
    _nameSortAscending = settings.peopleNameSortAscending;
    _updatedSortAscending = settings.peopleUpdatedSortAscending;
    _photosSortAscending = settings.peoplePhotosSortAscending;
    _useSimilaritySort = settings.peopleSimilaritySortSelected;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _nameFocsNode.dispose();
    _mergeSearchFocusNode.dispose();
    _mergeSearchController.dispose();
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
                                child: FaceThumbnailSquircleClip(
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
                            child: FaceThumbnailSquircleClip(
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

  Future<dynamic> _saveChangesPrompt(BuildContext context) async {
    PersonEntity? updatedPersonEntity;
    return await showActionSheet(
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
      child: StreamBuilder<List<_MergePersonEntry>>(
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
            if (persons.isEmpty) {
              return const SizedBox.shrink();
            }
            final sortedPersons = [...persons];
            _sortMergePersons(sortedPersons);
            final mergeQuery = _mergeSearchQuery.trim().toLowerCase();
            final inputQuery = _inputName.trim().toLowerCase();
            final activeQuery = mergeQuery.isNotEmpty ? mergeQuery : inputQuery;
            final filteredResults = activeQuery.isNotEmpty
                ? sortedPersons
                    .where(
                      (element) => element.person.data.name
                          .toLowerCase()
                          .contains(activeQuery),
                    )
                    .toList()
                : sortedPersons;

            return LayoutBuilder(
              builder: (context, constraints) {
                const horizontalEdgePadding = 20.0;
                const gridPadding = 16.0;
                final textTheme = getEnteTextTheme(context);
                final colorScheme = getEnteColorScheme(context);
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
                final smallFontSize = textTheme.small.fontSize ?? 14;
                final textScaleFactor =
                    MediaQuery.textScalerOf(context).scale(smallFontSize) /
                        smallFontSize;
                final childAspectRatio = tileSize /
                    (tileSize + extraVerticalSpacing + (24 * textScaleFactor));
                final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
                final extraBottomPadding =
                    _isMergeSearchActive ? keyboardInset : 0.0;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        child: _isMergeSearchActive
                            ? _buildMergeSearchField(
                                context,
                                textTheme,
                                colorScheme,
                              )
                            : _buildMergeHeaderRow(
                                context,
                                textTheme,
                                colorScheme,
                              ),
                      ),
                    ),
                    if (filteredResults.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          20,
                          0,
                          20,
                          16 + extraBottomPadding,
                        ),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: gridPadding,
                            mainAxisSpacing: gridPadding,
                            childAspectRatio: childAspectRatio,
                          ),
                          itemCount: filteredResults.length,
                          itemBuilder: (context, index) {
                            final person = filteredResults[index];
                            return PersonGridItem(
                              key: ValueKey(person.person.remoteID),
                              person: person.person,
                              personFile: person.personFile,
                              size: tileSize,
                              onTap: () async {
                                if (userAlreadyAssigned) {
                                  return;
                                }
                                userAlreadyAssigned = true;
                                await ClusterFeedbackService.instance
                                    .addClusterToExistingPerson(
                                  person: person.person,
                                  clusterID: widget.clusterID!,
                                );

                                Navigator.pop(context, person.person);
                              },
                            );
                          },
                        ),
                      )
                    else
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          20,
                          0,
                          20,
                          16 + extraBottomPadding,
                        ),
                        child: Text(
                          AppLocalizations.of(context).noResultsFound,
                          style: getEnteTextTheme(context).small,
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

  void _activateMergeSearch() {
    setState(() {
      _isMergeSearchActive = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final fieldContext = _mergeSearchFieldKey.currentContext;
      if (fieldContext != null) {
        Scrollable.ensureVisible(
          fieldContext,
          alignment: 0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        ).whenComplete(() {
          if (mounted) {
            _mergeSearchFocusNode.requestFocus();
          }
        });
      } else {
        _mergeSearchFocusNode.requestFocus();
      }
    });
  }

  void _deactivateMergeSearch() {
    setState(() {
      _isMergeSearchActive = false;
      _mergeSearchQuery = "";
    });
    _mergeSearchController.clear();
    _mergeSearchFocusNode.unfocus();
  }

  Widget _buildMergeHeaderRow(
    BuildContext context,
    EnteTextTheme textTheme,
    EnteColorScheme colorScheme,
  ) {
    return Row(
      key: const ValueKey("mergeHeader"),
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            context.l10n.orMergeWithExistingPerson,
            style: textTheme.largeBold,
          ),
        ),
        IconButtonWidget(
          icon: Icons.search,
          iconButtonType: IconButtonType.secondary,
          iconColor: colorScheme.blurStrokePressed,
          onTap: _activateMergeSearch,
        ),
        const SizedBox(width: 8),
        _buildMergeSortMenu(context, textTheme, colorScheme),
      ],
    );
  }

  Widget _buildMergeSearchField(
    BuildContext context,
    EnteTextTheme textTheme,
    EnteColorScheme colorScheme,
  ) {
    return TextFormField(
      key: _mergeSearchFieldKey,
      controller: _mergeSearchController,
      focusNode: _mergeSearchFocusNode,
      decoration: InputDecoration(
        filled: true,
        fillColor: colorScheme.fillFaint,
        hintText: AppLocalizations.of(context).search,
        prefixIcon: Icon(
          Icons.search_rounded,
          color: colorScheme.strokeMuted,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            Icons.cancel_rounded,
            color: colorScheme.strokeMuted,
          ),
          onPressed: _deactivateMergeSearch,
        ),
        border: const UnderlineInputBorder(
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.fromLTRB(12, 12, 0, 12),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: colorScheme.strokeFaint,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onChanged: (value) {
        setState(() {
          _mergeSearchQuery = value.trim();
        });
      },
    );
  }

  _MergeSortKey get _selectedMergeSortKey => _useSimilaritySort
      ? _MergeSortKey.similar
      : _mergeSortKeyFromPeopleSortKey(_sortKey);

  _MergeSortKey _mergeSortKeyFromPeopleSortKey(PeopleSortKey key) {
    switch (key) {
      case PeopleSortKey.mostPhotos:
        return _MergeSortKey.mostPhotos;
      case PeopleSortKey.name:
        return _MergeSortKey.name;
      case PeopleSortKey.lastUpdated:
        return _MergeSortKey.lastUpdated;
    }
  }

  PeopleSortKey? _peopleSortKeyFromMergeSortKey(_MergeSortKey key) {
    switch (key) {
      case _MergeSortKey.similar:
        return null;
      case _MergeSortKey.mostPhotos:
        return PeopleSortKey.mostPhotos;
      case _MergeSortKey.name:
        return PeopleSortKey.name;
      case _MergeSortKey.lastUpdated:
        return PeopleSortKey.lastUpdated;
    }
  }

  bool _isSortAscending(PeopleSortKey key) {
    switch (key) {
      case PeopleSortKey.name:
        return _nameSortAscending;
      case PeopleSortKey.lastUpdated:
        return _updatedSortAscending;
      case PeopleSortKey.mostPhotos:
        return _photosSortAscending;
    }
  }

  bool _toggleSortDirection(PeopleSortKey key) {
    switch (key) {
      case PeopleSortKey.name:
        _nameSortAscending = !_nameSortAscending;
        return true;
      case PeopleSortKey.lastUpdated:
        _updatedSortAscending = !_updatedSortAscending;
        return true;
      case PeopleSortKey.mostPhotos:
        _photosSortAscending = !_photosSortAscending;
        return true;
    }
  }

  bool _canToggleSortDirection(PeopleSortKey key) {
    return key == PeopleSortKey.name ||
        key == PeopleSortKey.lastUpdated ||
        key == PeopleSortKey.mostPhotos;
  }

  void _sortMergePersons(List<_MergePersonEntry> persons) {
    if (persons.isEmpty) {
      return;
    }
    if (_useSimilaritySort) {
      _sortBySimilarity(persons);
      return;
    }
    persons.sort((a, b) {
      final aPinned = a.person.data.isPinned;
      final bPinned = b.person.data.isPinned;
      if (aPinned != bPinned) {
        return aPinned ? -1 : 1;
      }

      int compareValue;
      switch (_sortKey) {
        case PeopleSortKey.mostPhotos:
          compareValue = a.fileCount.compareTo(b.fileCount);
          if (!_photosSortAscending) {
            compareValue = -compareValue;
          }
          break;
        case PeopleSortKey.name:
          compareValue = compareAsciiLowerCaseNatural(
            a.person.data.name,
            b.person.data.name,
          );
          if (!_nameSortAscending) {
            compareValue = -compareValue;
          }
          break;
        case PeopleSortKey.lastUpdated:
          compareValue = a.latestTime.compareTo(b.latestTime);
          if (!_updatedSortAscending) {
            compareValue = -compareValue;
          }
          break;
      }

      if (compareValue != 0) {
        return compareValue;
      }
      return compareAsciiLowerCaseNatural(
        a.person.data.name,
        b.person.data.name,
      );
    });
  }

  void _sortBySimilarity(List<_MergePersonEntry> persons) {
    if (widget.clusterID == null || _personToMaxSimilarity.isEmpty) {
      return;
    }

    persons.sort((a, b) {
      final similarityA = _personToMaxSimilarity[a.person.remoteID] ?? 0;
      final similarityB = _personToMaxSimilarity[b.person.remoteID] ?? 0;
      final compareValue = similarityB.compareTo(similarityA);
      if (compareValue != 0) {
        return compareValue;
      }
      return compareAsciiLowerCaseNatural(
        a.person.data.name,
        b.person.data.name,
      );
    });
  }

  Future<void> _persistSortPreferences() async {
    await localSettings.setPeopleSimilaritySortSelected(_useSimilaritySort);
    if (!_useSimilaritySort) {
      await localSettings.setPeopleSortKey(_sortKey);
      await localSettings.setPeopleNameSortAscending(_nameSortAscending);
      await localSettings.setPeopleUpdatedSortAscending(_updatedSortAscending);
      await localSettings.setPeoplePhotosSortAscending(_photosSortAscending);
      Bus.instance.fire(PeopleSortOrderChangeEvent());
    }
  }

  Widget _buildMergeSortMenu(
    BuildContext context,
    EnteTextTheme textTheme,
    EnteColorScheme colorScheme,
  ) {
    return Theme(
      data: Theme.of(context).copyWith(
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
      ),
      child: GestureDetector(
        onTapDown: (TapDownDetails details) async {
          final l10n = AppLocalizations.of(context);
          const sortKeys = _MergeSortKey.values;
          final _MergeSortKey? selectedKey = await showMenu<_MergeSortKey>(
            color: colorScheme.backgroundElevated,
            context: context,
            elevation: 0,
            shape: RoundedRectangleBorder(
              side: BorderSide(
                width: 0.5,
                color: colorScheme.strokeFaint,
              ),
              borderRadius: BorderRadius.circular(_sortMenuCornerRadius),
            ),
            position: RelativeRect.fromLTRB(
              details.globalPosition.dx,
              details.globalPosition.dy,
              details.globalPosition.dx,
              details.globalPosition.dy + 50,
            ),
            items: List.generate(sortKeys.length, (index) {
              final key = sortKeys[index];
              return _buildMergeSortMenuItem(
                key,
                index == sortKeys.length - 1,
                textTheme,
                colorScheme,
                l10n,
              );
            }),
          );
          if (!mounted || selectedKey == null) {
            return;
          }
          final currentKey = _selectedMergeSortKey;
          if (selectedKey == currentKey) {
            if (selectedKey == _MergeSortKey.similar ||
                !_canToggleSortDirection(_sortKey)) {
              return;
            }
            setState(() {
              _toggleSortDirection(_sortKey);
            });
            unawaited(_persistSortPreferences());
            return;
          }

          setState(() {
            if (selectedKey == _MergeSortKey.similar) {
              _useSimilaritySort = true;
            } else {
              _useSimilaritySort = false;
              _sortKey = _peopleSortKeyFromMergeSortKey(selectedKey)!;
            }
          });
          unawaited(_persistSortPreferences());
        },
        child: IconButtonWidget(
          icon: Icons.sort_rounded,
          iconButtonType: IconButtonType.secondary,
          iconColor: colorScheme.textMuted,
        ),
      ),
    );
  }

  PopupMenuItem<_MergeSortKey> _buildMergeSortMenuItem(
    _MergeSortKey key,
    bool isLast,
    EnteTextTheme textTheme,
    EnteColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
    String label;
    late final String detail;
    IconData? directionIcon;

    if (key == _MergeSortKey.similar) {
      label = l10n.similar;
      detail = l10n.closest;
    } else {
      final peopleKey = _peopleSortKeyFromMergeSortKey(key)!;
      switch (peopleKey) {
        case PeopleSortKey.mostPhotos:
          label = l10n.photos;
          break;
        case PeopleSortKey.name:
          label = l10n.name;
          break;
        case PeopleSortKey.lastUpdated:
          label = l10n.updated;
          break;
      }

      switch (peopleKey) {
        case PeopleSortKey.mostPhotos:
          detail = l10n.count;
          break;
        case PeopleSortKey.name:
          detail = _isSortAscending(peopleKey) ? "A-Z" : "Z-A";
          break;
        case PeopleSortKey.lastUpdated:
          detail = _isSortAscending(peopleKey)
              ? l10n.sortOldestFirst
              : l10n.sortNewestFirst;
          break;
      }

      final bool isAscending = _isSortAscending(peopleKey);
      directionIcon = peopleKey == PeopleSortKey.name
          ? (isAscending ? Icons.arrow_downward : Icons.arrow_upward)
          : (isAscending ? Icons.arrow_upward : Icons.arrow_downward);
    }

    final bool isSelected = _selectedMergeSortKey == key;

    return PopupMenuItem<_MergeSortKey>(
      value: key,
      padding: EdgeInsets.zero,
      height: _sortMenuItemHeight,
      child: Container(
        width: double.infinity,
        height: _sortMenuItemHeight,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(
                  bottom: BorderSide(
                    width: 0.5,
                    color: colorScheme.strokeFaint,
                  ),
                ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              label,
              style: textTheme.mini,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.textMuted.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                detail,
                style: textTheme.miniMuted,
              ),
              if (directionIcon != null) ...[
                const SizedBox(width: 4),
                Icon(
                  directionIcon,
                  size: 16,
                  color: colorScheme.textMuted,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Stream<List<_MergePersonEntry>> _getPersonsWithRecentFileStream() async* {
    if (_cachedPersons.isEmpty) {
      _cachedPersons = await _getPersonsWithRecentFile();
    }
    if (_personToMaxSimilarity.isEmpty && widget.clusterID != null) {
      _personToMaxSimilarity = await _calculateSimilarityWithPersons();
    }
    yield _cachedPersons;
  }

  Future<Map<String, double>> _calculateSimilarityWithPersons() async {
    final allClusterSummary = await MLDataDB.instance.getAllClusterSummary();

    final currentClusterEmbeddingData =
        allClusterSummary[widget.clusterID!]?.$1;
    if (currentClusterEmbeddingData == null) {
      return {};
    }
    final ml.Vector currentClusterEmbedding = ml.Vector.fromList(
      EVector.fromBuffer(currentClusterEmbeddingData).values,
      dtype: ml.DType.float32,
    );

    final persons = _cachedPersons.map((entry) => entry.person).toList();
    final personIDs = persons.map((person) => person.remoteID).toSet();
    final clusterToPerson = await MLDataDB.instance.getClusterIDToPersonID();
    clusterToPerson.removeWhere((_, personID) => !personIDs.contains(personID));
    allClusterSummary
        .removeWhere((key, value) => !clusterToPerson.containsKey(key));
    final Map<String, ml.Vector> allClusterEmbeddings = allClusterSummary.map(
      (key, value) => MapEntry(
        key,
        ml.Vector.fromList(
          EVector.fromBuffer(value.$1).values,
          dtype: ml.DType.float32,
        ),
      ),
    );

    for (final entry in allClusterEmbeddings.entries) {
      final personId = clusterToPerson[entry.key]!;
      final similarity = currentClusterEmbedding.dot(entry.value);
      _personToMaxSimilarity[personId] = max(
        _personToMaxSimilarity[personId] ?? double.negativeInfinity,
        similarity,
      );
    }
    return _personToMaxSimilarity;
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

  Future<List<_MergePersonEntry>> _getPersonsWithRecentFile({
    bool excludeHidden = true,
  }) async {
    final persons = await PersonService.instance.getPersons();
    if (excludeHidden) {
      persons.removeWhere((person) => person.data.isIgnored);
    }
    final List<_MergePersonEntry> personEntries = [];
    for (final person in persons) {
      final files = await SearchService.instance.getFilesForPersonID(
        person.remoteID,
        sortOnTime: true,
      );
      if (files.isEmpty) {
        debugPrint(
          "Person ${kDebugMode ? person.data.name : person.remoteID} has no files",
        );
        continue;
      }
      personEntries.add(
        _MergePersonEntry(
          person: person,
          personFile: files.first,
          fileCount: files.length,
          latestTime: files.first.creationTime ?? 0,
        ),
      );
    }
    personEntries.sort(
      (a, b) => b.fileCount.compareTo(a.fileCount),
    );
    return personEntries;
  }
}

enum _MergeSortKey {
  similar,
  mostPhotos,
  name,
  lastUpdated,
}

class _MergePersonEntry {
  final PersonEntity person;
  final EnteFile personFile;
  final int fileCount;
  final int latestTime;

  const _MergePersonEntry({
    required this.person,
    required this.personFile,
    required this.fileCount,
    required this.latestTime,
  });
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
    final avatarSize = getAvatarSize(AvatarType.xl);
    final overlapPadding = getOverlapPadding(AvatarType.xl);
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
                        type: AvatarType.xl,
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
