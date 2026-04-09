import "package:flutter/material.dart";
import "package:photos/db/ml/db.dart";
import "package:photos/l10n/l10n.dart";
import "package:photos/service_locator.dart" show isOfflineMode;
import "package:photos/services/machine_learning/pet_ml/pet_clustering_service.dart";
import "package:photos/services/machine_learning/pet_ml/pet_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/viewer/people/face_thumbnail_squircle.dart";
import "package:photos/ui/viewer/people/pet_face_widget.dart";

/// Shows all clusters belonging to a pet. Mirrors [PersonClustersPage].
class PetClustersPage extends StatefulWidget {
  final String petId;
  final String petName;

  const PetClustersPage({
    required this.petId,
    required this.petName,
    super.key,
  });

  @override
  State<PetClustersPage> createState() => _PetClustersPageState();
}

class _PetClustersPageState extends State<PetClustersPage> {
  List<(String clusterId, int fileCount, int species)>? _clusters;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadClusters();
  }

  Future<void> _loadClusters() async {
    final mlDataDB =
        isOfflineMode ? MLDataDB.offlineInstance : MLDataDB.instance;
    final clusterToPetId = await mlDataDB.getClusterToPetId();
    final clusterIds = clusterToPetId.entries
        .where((e) => e.value == widget.petId)
        .map((e) => e.key)
        .toList();

    final allInfo = await mlDataDB.getAllPetClustersWithInfo();
    final infoMap = {for (final c in allInfo) c.$1: c};

    final result = <(String, int, int)>[];
    for (final cid in clusterIds) {
      final info = infoMap[cid];
      if (info != null) {
        result.add((cid, info.$3, info.$2));
      }
    }
    // Largest cluster first (primary)
    result.sort((a, b) => b.$2.compareTo(a.$2));
    if (mounted) {
      setState(() {
        _clusters = result;
        _loading = false;
      });
    }
  }

  Future<void> _removeCluster(String clusterId) async {
    await PetService.instance.removeClusterFromPet(
      petID: widget.petId,
      clusterID: clusterId,
    );
    await _loadClusters();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = getEnteTextTheme(context);
    final colorScheme = getEnteColorScheme(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.petName),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _clusters == null || _clusters!.isEmpty
              ? Center(
                  child: Text(
                    context.l10n.noClusters,
                    style:
                        textTheme.body.copyWith(color: colorScheme.textMuted),
                  ),
                )
              : ListView.builder(
                  itemCount: _clusters!.length,
                  itemBuilder: (context, index) {
                    final (clusterId, fileCount, _) = _clusters![index];
                    final canRemove =
                        !isOfflineMode && _clusters!.length > 1 && index != 0;
                    return ListTile(
                      leading: SizedBox(
                        width: 56,
                        height: 56,
                        child: FaceThumbnailSquircleClip(
                          child: PetFaceWidget(petClusterId: clusterId),
                        ),
                      ),
                      title: Text(
                        context.l10n.photosCount(count: fileCount),
                        style: textTheme.body,
                      ),
                      trailing: canRemove
                          ? IconButton(
                              icon: Icon(
                                Icons.remove_circle_outline,
                                color: colorScheme.warning500,
                              ),
                              onPressed: () => _removeCluster(clusterId),
                            )
                          : null,
                    );
                  },
                ),
    );
  }
}
