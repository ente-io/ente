import "dart:typed_data";

import "package:photos/image/provider/local_thumbnail_img.dart";
import "package:photos/utils/standalone/task_queue.dart";

class LocalThumbnailService {
  final thumbnailQueue = TaskQueue<String>(
    maxConcurrentTasks: 15,
    taskTimeout: const Duration(minutes: 1),
    maxQueueSize: 100, // Limit the queue to 50 pending tasks
  );

  Future<Uint8List?> _cached(LocalThumbnailProviderKey key) async {
    return null;
  }
}
