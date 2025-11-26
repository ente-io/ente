import "package:flutter/material.dart";
import "package:photos/models/collection/collection.dart";
import "package:photos/models/collection/collection_items.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/ui/activity/activity_screen.dart";
import "package:photos/ui/viewer/gallery/collection_page.dart";
import "package:photos/utils/navigation_util.dart";

class RitualCameraPage extends StatelessWidget {
  const RitualCameraPage({
    super.key,
    required this.ritualId,
    required this.albumId,
  });

  final String ritualId;
  final int? albumId;

  @override
  Widget build(BuildContext context) {
    if (!flagService.ritualsFlag) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Ritual capture"),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text("Rituals are currently limited to internal users."),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ritual capture"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<Collection?>(
          future: _loadCollection(),
          builder: (context, snapshot) {
            final collection = snapshot.data;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Ready to take today's ritual photo?",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Use your device camera to take a photo, then add it to the selected album. We will improve this with an in-app camera flow soon.",
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    if (collection != null) {
                      routeToPage(
                        context,
                        CollectionPage(
                          CollectionWithThumbnail(collection, null),
                        ),
                      );
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
                  icon: const Icon(Icons.photo_camera_rounded),
                  label: Text(
                    collection == null
                        ? "Open album"
                        : "Go to ${collection.displayName}",
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () {
                    routeToPage(context, const ActivityScreen());
                  },
                  child: const Text("View activity"),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<Collection?> _loadCollection() async {
    if (albumId == null) return null;
    return CollectionsService.instance.getCollectionByID(albumId!);
  }
}
