import "dart:async";

import "package:flutter/material.dart";
import "package:logging/logging.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/db/ml/db.dart";
import "package:photos/events/pets_changed_event.dart";
import "package:photos/l10n/l10n.dart";
import "package:photos/models/ml/pet/pet_entity.dart";
import "package:photos/service_locator.dart" show isOfflineMode;
import "package:photos/services/machine_learning/pet_ml/pet_clustering_service.dart";
import "package:photos/services/machine_learning/pet_ml/pet_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/common/date_input.dart";
import "package:photos/ui/components/buttons/button_widget.dart";
import "package:photos/ui/components/models/button_type.dart";
import "package:photos/ui/viewer/people/face_thumbnail_squircle.dart";
import "package:photos/ui/viewer/people/merge_pet_sheet.dart";
import "package:photos/ui/viewer/people/pet_face_widget.dart";

/// Full-page screen for saving or editing a pet, mirroring the person
/// save/edit screen layout (minus email/suggestions).
class SaveOrEditPet extends StatefulWidget {
  final String clusterId;
  final int species;
  final String? currentName;
  final String? petId;
  final bool isEditing;

  const SaveOrEditPet({
    required this.clusterId,
    required this.species,
    this.currentName,
    this.petId,
    this.isEditing = false,
    super.key,
  });

  @override
  State<SaveOrEditPet> createState() => _SaveOrEditPetState();
}

class _SaveOrEditPetState extends State<SaveOrEditPet> {
  final _logger = Logger("_SaveOrEditPetState");
  String _inputName = "";
  String? _selectedDate;
  PetData? _existingData;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _inputName = widget.currentName ?? "";
    _loadExistingData();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadExistingData() async {
    final mlDataDB =
        isOfflineMode ? MLDataDB.offlineInstance : MLDataDB.instance;
    final resolvedPetId =
        widget.petId ?? (await mlDataDB.getClusterToPetId())[widget.clusterId];
    if (resolvedPetId != null) {
      final pet = await PetService.instance.getPet(resolvedPetId);
      if (pet != null && mounted) {
        setState(() {
          _existingData = pet.data;
          _selectedDate = pet.data.birthDate;
          if (_inputName.isEmpty) _inputName = pet.data.name;
        });
      }
    }
  }

  bool get _hasChanges {
    if (_existingData == null) return _inputName.isNotEmpty;
    return _inputName != _existingData!.name ||
        _selectedDate != _existingData!.birthDate;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = getEnteTextTheme(context);
    final colorScheme = getEnteColorScheme(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            widget.isEditing ? context.l10n.editPerson : context.l10n.savePet,
          ),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
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
                      SizedBox(
                        height: 110,
                        width: 110,
                        child: FaceThumbnailSquircleClip(
                          child: PetFaceWidget(
                            petClusterId: widget.clusterId,
                          ),
                        ),
                      ),
                      const SizedBox(height: 36),
                      TextFormField(
                        keyboardType: TextInputType.name,
                        textCapitalization: TextCapitalization.words,
                        autocorrect: false,
                        initialValue: _inputName,
                        onChanged: (value) {
                          if (_debounce?.isActive ?? false) {
                            _debounce?.cancel();
                          }
                          _debounce =
                              Timer(const Duration(milliseconds: 300), () {
                            setState(() => _inputName = value);
                          });
                        },
                        decoration: InputDecoration(
                          focusedBorder: OutlineInputBorder(
                            borderRadius: const BorderRadius.all(
                              Radius.circular(8.0),
                            ),
                            borderSide: BorderSide(
                              color: colorScheme.strokeMuted,
                            ),
                          ),
                          fillColor: colorScheme.fillFaint,
                          filled: true,
                          hintText: context.l10n.enterName,
                          hintStyle: textTheme.bodyFaint,
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
                            _selectedDate =
                                date?.toIso8601String().split("T").first;
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      ButtonWidget(
                        buttonType: ButtonType.primary,
                        labelText: context.l10n.save,
                        isDisabled: !_hasChanges || _inputName.trim().isEmpty,
                        onTap: () async => _save(),
                      ),
                      if (!widget.isEditing) ...[
                        const SizedBox(height: 24),
                        Align(
                          alignment: Alignment.center,
                          child: TextButton(
                            onPressed: _onMergeWithExisting,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              context.l10n.mergeWithExisting,
                              style: textTheme.small.copyWith(
                                fontWeight: FontWeight.w500,
                                color: colorScheme.primary500,
                                decoration: TextDecoration.underline,
                                decorationColor: colorScheme.primary500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final name = _inputName.trim();
    if (name.isEmpty) return;

    final mlDataDB =
        isOfflineMode ? MLDataDB.offlineInstance : MLDataDB.instance;
    final petService = PetService.instance;

    try {
      String petId;
      final resolvedPetId = widget.petId ??
          (await mlDataDB.getClusterToPetId())[widget.clusterId];

      if (resolvedPetId != null) {
        petId = resolvedPetId;
        final existingPet = await petService.getPet(petId);
        final updatedData = existingPet != null
            ? existingPet.data.copyWith(name: name, birthDate: _selectedDate)
            : PetData(
                name: name,
                species: widget.species,
                birthDate: _selectedDate,
              );
        await petService.updatePet(petId, updatedData);
      } else {
        final pet = await petService.addPet(
          PetData(
            name: name,
            species: widget.species,
            birthDate: _selectedDate,
          ),
        );
        petId = pet.remoteID;
      }

      await mlDataDB.setClusterPetId(widget.clusterId, petId);

      if (mounted) {
        Navigator.pop(context, name);
      }
    } catch (e) {
      _logger.severe("Error saving pet", e);
    }
  }

  Future<void> _onMergeWithExisting() async {
    final selection = await showMergePetPage(
      context,
      currentClusterId: widget.clusterId,
    );

    if (selection == null || !mounted) return;

    _logger.info(
      "Merge: merging cluster ${widget.clusterId} into pet ${selection.petId}",
    );
    try {
      final mlDataDB =
          isOfflineMode ? MLDataDB.offlineInstance : MLDataDB.instance;
      // Map this cluster to the selected pet
      await mlDataDB.setClusterPetId(widget.clusterId, selection.petId);
      Bus.instance.fire(PetsChangedEvent(source: "mergeIntoPet"));
      _logger.info("Merge: completed successfully");
      if (mounted) Navigator.pop(context);
    } catch (e, s) {
      _logger.severe("Merge failed", e, s);
    }
  }
}
