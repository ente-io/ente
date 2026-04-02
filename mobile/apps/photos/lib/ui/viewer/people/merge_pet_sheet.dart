import "package:ente_pure_utils/ente_pure_utils.dart";
import "package:flutter/material.dart";
import "package:photos/db/ml/db.dart";
import "package:photos/l10n/l10n.dart";
import "package:photos/models/ml/pet/pet_entity.dart";
import "package:photos/service_locator.dart" show isOfflineMode;
import "package:photos/services/machine_learning/pet_ml/pet_clustering_service.dart";
import "package:photos/services/machine_learning/pet_ml/pet_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/viewer/people/face_thumbnail_squircle.dart";
import "package:photos/ui/viewer/people/pet_face_widget.dart";

/// Result of the merge picker: the petId to merge into.
class MergePetSelectionResult {
  final String petId;
  final PetEntity pet;
  final String primaryClusterId;

  const MergePetSelectionResult({
    required this.petId,
    required this.pet,
    required this.primaryClusterId,
  });
}

/// Full-page picker for choosing an existing **named** pet to merge into.
/// Only shows pets that already have a name (matching person merge behavior).
/// Returns a [MergePetSelectionResult], or null if cancelled.
Future<MergePetSelectionResult?> showMergePetPage(
  BuildContext context, {
  required String currentClusterId,
}) {
  return routeToPage(
    context,
    _MergePetPage(currentClusterId: currentClusterId),
  );
}

class _MergePetPage extends StatefulWidget {
  final String currentClusterId;

  const _MergePetPage({required this.currentClusterId});

  @override
  State<_MergePetPage> createState() => _MergePetPageState();
}

class _MergePetPageState extends State<_MergePetPage> {
  List<_NamedPetInfo>? _namedPets;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadNamedPets();
  }

  Future<void> _loadNamedPets() async {
    final mlDataDB =
        isOfflineMode ? MLDataDB.offlineInstance : MLDataDB.instance;
    final clusterToPetId = await mlDataDB.getClusterToPetId();
    final petsMap = await PetService.instance.getPetsMap();
    final allClusters = await mlDataDB.getAllPetClustersWithInfo();
    final clusterInfoMap = {for (final c in allClusters) c.$1: c};

    // Find the current cluster's petId (if any) to exclude it
    final currentPetId = clusterToPetId[widget.currentClusterId];

    // Group clusters by petId, only include named pets
    final petIdToClusters = <String, List<String>>{};
    for (final entry in clusterToPetId.entries) {
      petIdToClusters.putIfAbsent(entry.value, () => []).add(entry.key);
    }

    final result = <_NamedPetInfo>[];
    for (final entry in petIdToClusters.entries) {
      final petId = entry.key;
      if (petId == currentPetId) continue; // skip self
      final pet = petsMap[petId];
      if (pet == null || pet.data.name.isEmpty) continue; // only named pets

      // Find the largest cluster for this pet (for thumbnail)
      final clusterIds = entry.value;
      String? primaryClusterId;
      int maxCount = 0;
      int totalCount = 0;
      for (final cid in clusterIds) {
        final info = clusterInfoMap[cid];
        if (info != null) {
          totalCount += info.$3;
          if (info.$3 > maxCount) {
            maxCount = info.$3;
            primaryClusterId = cid;
          }
        }
      }
      if (primaryClusterId == null) continue;

      result.add(
        _NamedPetInfo(
          petId: petId,
          pet: pet,
          primaryClusterId: primaryClusterId,
          totalFileCount: totalCount,
        ),
      );
    }

    // Sort by file count descending
    result.sort((a, b) => b.totalFileCount.compareTo(a.totalFileCount));

    if (mounted) {
      setState(() {
        _namedPets = result;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = getEnteTextTheme(context);
    final colorScheme = getEnteColorScheme(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.mergeWithExisting),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _namedPets == null || _namedPets!.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      context.l10n.noNamedPetsToMerge,
                      style:
                          textTheme.body.copyWith(color: colorScheme.textMuted),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: _namedPets!.length,
                  itemBuilder: (context, index) {
                    final info = _namedPets![index];
                    return ListTile(
                      leading: SizedBox(
                        width: 56,
                        height: 56,
                        child: FaceThumbnailSquircleClip(
                          child: PetFaceWidget(
                            petClusterId: info.primaryClusterId,
                          ),
                        ),
                      ),
                      title: Text(info.pet.data.name, style: textTheme.body),
                      subtitle: Text(
                        "${info.totalFileCount} photos",
                        style: textTheme.small
                            .copyWith(color: colorScheme.textMuted),
                      ),
                      onTap: () => Navigator.pop(
                        context,
                        MergePetSelectionResult(
                          petId: info.petId,
                          pet: info.pet,
                          primaryClusterId: info.primaryClusterId,
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class _NamedPetInfo {
  final String petId;
  final PetEntity pet;
  final String primaryClusterId;
  final int totalFileCount;

  const _NamedPetInfo({
    required this.petId,
    required this.pet,
    required this.primaryClusterId,
    required this.totalFileCount,
  });
}
