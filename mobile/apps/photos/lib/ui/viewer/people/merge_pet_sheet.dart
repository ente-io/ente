import "package:flutter/material.dart";
import "package:photos/db/ml/db.dart";
import "package:photos/l10n/l10n.dart";
import "package:photos/services/machine_learning/pet_ml/pet_clustering_service.dart";
import "package:photos/services/machine_learning/pet_ml/pet_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/viewer/people/face_thumbnail_squircle.dart";
import "package:photos/ui/viewer/people/pet_face_widget.dart";

class MergePetResult {
  final String petId;
  final String petName;
  MergePetResult(this.petId, this.petName);
}

/// Show a page to select an existing named pet to merge into.
Future<MergePetResult?> showMergePetPage(
  BuildContext context, {
  String? currentClusterId,
}) async {
  return Navigator.of(context).push<MergePetResult>(
    MaterialPageRoute(
      builder: (_) => _MergePetPage(currentClusterId: currentClusterId),
    ),
  );
}

class _MergePetPage extends StatefulWidget {
  final String? currentClusterId;
  const _MergePetPage({this.currentClusterId});

  @override
  State<_MergePetPage> createState() => _MergePetPageState();
}

class _MergePetPageState extends State<_MergePetPage> {
  List<_PetGridItem>? _pets;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPets();
  }

  Future<void> _loadPets() async {
    final pets = await PetService.instance.getPets();
    final clusterToPetId = await MLDataDB.instance.getClusterToPetId();

    // Find the current pet ID to exclude from the list
    final currentPetId = widget.currentClusterId != null
        ? clusterToPetId[widget.currentClusterId]
        : null;

    // Build a map of petId -> first clusterId for the thumbnail
    final petToCluster = <String, String>{};
    for (final entry in clusterToPetId.entries) {
      petToCluster.putIfAbsent(entry.value, () => entry.key);
    }

    final items = <_PetGridItem>[];
    for (final pet in pets) {
      if (pet.data.isIgnored) continue;
      if (pet.data.name.isEmpty) continue;
      if (pet.remoteID == currentPetId) continue;
      final clusterId = petToCluster[pet.remoteID];
      if (clusterId == null) continue;
      items.add(
        _PetGridItem(
          petId: pet.remoteID,
          name: pet.data.name,
          clusterId: clusterId,
        ),
      );
    }
    items.sort((a, b) => a.name.compareTo(b.name));

    if (mounted) {
      setState(() {
        _pets = items;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = getEnteTextTheme(context);
    final colorScheme = getEnteColorScheme(context);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.merge)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _pets == null || _pets!.isEmpty
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
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: _pets!.length,
                  itemBuilder: (context, index) {
                    final item = _pets![index];
                    return _PetGridTile(
                      item: item,
                      onTap: () => Navigator.pop(
                        context,
                        MergePetResult(item.petId, item.name),
                      ),
                    );
                  },
                ),
    );
  }
}

class _PetGridItem {
  final String petId;
  final String name;
  final String clusterId;
  _PetGridItem({
    required this.petId,
    required this.name,
    required this.clusterId,
  });
}

class _PetGridTile extends StatelessWidget {
  final _PetGridItem item;
  final VoidCallback onTap;
  const _PetGridTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final textTheme = getEnteTextTheme(context);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Expanded(
            child: AspectRatio(
              aspectRatio: 1,
              child: FaceThumbnailSquircleClip(
                child: PetFaceWidget(petClusterId: item.clusterId),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.name,
            style: textTheme.mini,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
