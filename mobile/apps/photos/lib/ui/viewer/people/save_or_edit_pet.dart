import "package:flutter/material.dart";
import "package:photos/db/ml/db.dart";
import "package:photos/generated/intl/app_localizations.dart";
import "package:photos/models/ml/pet/pet_entity.dart";
import "package:photos/service_locator.dart" show isOfflineMode;
import "package:photos/services/machine_learning/pet_ml/pet_clustering_service.dart";
import "package:photos/services/machine_learning/pet_ml/pet_service.dart";
import "package:photos/theme/ente_theme.dart";

/// Bottom sheet page for naming or renaming a pet cluster.
class SaveOrEditPet extends StatefulWidget {
  final String clusterId;
  final int species;
  final String? currentName;
  final String? petId;

  const SaveOrEditPet({
    required this.clusterId,
    required this.species,
    this.currentName,
    this.petId,
    super.key,
  });

  @override
  State<SaveOrEditPet> createState() => _SaveOrEditPetState();
}

class _SaveOrEditPetState extends State<SaveOrEditPet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentName ?? "");
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = getEnteTextTheme(context);
    final colorScheme = getEnteColorScheme(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.addName),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: l10n.addName,
                hintStyle: textTheme.body.copyWith(
                  color: colorScheme.textMuted,
                ),
                border: const UnderlineInputBorder(),
              ),
              style: textTheme.body,
              textCapitalization: TextCapitalization.words,
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                child: Text(l10n.save),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final name = _controller.text.trim();
    if (name.isEmpty) return;

    final mlDataDB =
        isOfflineMode ? MLDataDB.offlineInstance : MLDataDB.instance;
    final petService = PetService.instance;

    // Reuse existing pet ID if the cluster already has one, otherwise create.
    String petId;
    if (widget.petId != null) {
      petId = widget.petId!;
      await petService.updatePet(
        petId,
        PetData(name: name, species: widget.species),
      );
    } else {
      final existing = await mlDataDB.getClusterToPetId();
      final existingPetId = existing[widget.clusterId];
      if (existingPetId != null) {
        petId = existingPetId;
        await petService.updatePet(
          petId,
          PetData(name: name, species: widget.species),
        );
      } else {
        final pet = await petService.addPet(
          PetData(name: name, species: widget.species),
        );
        petId = pet.remoteID;
      }
    }

    await mlDataDB.setClusterPetId(widget.clusterId, petId);

    if (mounted) {
      Navigator.pop(context, name);
    }
  }
}
