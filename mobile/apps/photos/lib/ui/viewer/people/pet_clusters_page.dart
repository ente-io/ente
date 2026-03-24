import "package:flutter/material.dart";
import "package:logging/logging.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/db/ml/db.dart";
import "package:photos/events/pets_changed_event.dart";
import "package:photos/l10n/l10n.dart";
import "package:photos/service_locator.dart" show isOfflineMode;
import "package:photos/services/machine_learning/pet_ml/pet_cluster_feedback_service.dart";
import "package:photos/services/machine_learning/pet_ml/pet_clustering_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/viewer/people/face_thumbnail_squircle.dart";
import "package:photos/ui/viewer/people/pet_face_widget.dart";

/// Shows all clusters belonging to a pet, with the ability to unmerge
/// (remove a cluster from the pet). Mirrors [PersonClustersPage].
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
  final _logger = Logger("PetClustersPage");

  @override
  Widget build(BuildContext context) {
    final textTheme = getEnteTextTheme(context);
    final colorScheme = getEnteColorScheme(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.petName),
      ),
      body: FutureBuilder<List<(String clusterId, int fileCount, int species)>>(
        future: _loadClusters(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final clusters = snapshot.data ?? [];
          if (clusters.isEmpty) {
            return Center(
              child: Text(
                "No clusters",
                style: textTheme.body.copyWith(color: colorScheme.textMuted),
              ),
            );
          }
          return ListView.builder(
            itemCount: clusters.length,
            itemBuilder: (context, index) {
              final (clusterId, fileCount, _) = clusters[index];
              final isFirst = index == 0;
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
                trailing: !isFirst
                    ? GestureDetector(
                        onTap: () => _removeCluster(clusterId),
                        child: Icon(
                          Icons.remove_circle_outline,
                          color: colorScheme.strokeMuted,
                        ),
                      )
                    : null,
              );
            },
          );
        },
      ),
    );
  }

  Future<List<(String, int, int)>> _loadClusters() async {
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
    return result;
  }

  Future<void> _removeCluster(String clusterId) async {
    try {
      await PetClusterFeedbackService.instance.unmergePetCluster(clusterId);
      _logger.info("Unmerged cluster $clusterId from pet ${widget.petId}");
      Bus.instance.fire(PetsChangedEvent(source: "unmergePetCluster"));
      if (mounted) setState(() {});
    } catch (e) {
      _logger.severe("Failed to unmerge cluster", e);
    }
  }
}
