import "package:ente_pure_utils/ente_pure_utils.dart";
import "package:flutter/material.dart";
import "package:photos/db/ml/db.dart";
import "package:photos/l10n/l10n.dart";
import "package:photos/service_locator.dart" show isOfflineMode;
import "package:photos/services/machine_learning/pet_ml/pet_clustering_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/viewer/people/face_thumbnail_squircle.dart";
import "package:photos/ui/viewer/people/pet_face_widget.dart";

/// Full-page picker for choosing an existing pet cluster to merge into.
/// Returns the selected cluster ID, or null if cancelled.
Future<String?> showMergePetClusterPage(
  BuildContext context, {
  required String currentClusterId,
  required int species,
}) {
  return routeToPage(
    context,
    _MergePetClusterPage(
      currentClusterId: currentClusterId,
      species: species,
    ),
  );
}

class _MergePetClusterPage extends StatefulWidget {
  final String currentClusterId;
  final int species;

  const _MergePetClusterPage({
    required this.currentClusterId,
    required this.species,
  });

  @override
  State<_MergePetClusterPage> createState() => _MergePetClusterPageState();
}

class _MergePetClusterPageState extends State<_MergePetClusterPage> {
  late Future<List<(String, int, int, String?)>> _clustersFuture;

  @override
  void initState() {
    super.initState();
    _clustersFuture = _loadClusters();
  }

  Future<List<(String, int, int, String?)>> _loadClusters() async {
    final mlDataDB =
        isOfflineMode ? MLDataDB.offlineInstance : MLDataDB.instance;
    final clusters = await mlDataDB.getAllPetClustersWithInfo();
    return clusters
        .where(
          (c) => c.$1 != widget.currentClusterId && c.$2 == widget.species,
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = getEnteTextTheme(context);
    final colorScheme = getEnteColorScheme(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.mergeWithExisting),
      ),
      body: FutureBuilder<List<(String, int, int, String?)>>(
        future: _clustersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final clusters = snapshot.data ?? [];
          if (clusters.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  "No other pet clusters to merge with",
                  style: textTheme.body.copyWith(color: colorScheme.textMuted),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.builder(
            itemCount: clusters.length,
            itemBuilder: (context, index) {
              final (clusterId, species, count, name) = clusters[index];
              final speciesLabel = species == 0 ? "Dog" : "Cat";
              final label =
                  (name != null && name.isNotEmpty) ? name : speciesLabel;
              return ListTile(
                leading: SizedBox(
                  width: 56,
                  height: 56,
                  child: FaceThumbnailSquircleClip(
                    child: PetFaceWidget(petClusterId: clusterId),
                  ),
                ),
                title: Text(label, style: textTheme.body),
                subtitle: Text(
                  "$count photos",
                  style: textTheme.small.copyWith(color: colorScheme.textMuted),
                ),
                onTap: () => Navigator.pop(context, clusterId),
              );
            },
          );
        },
      ),
    );
  }
}
