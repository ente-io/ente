import 'dart:async';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import "package:equatable/equatable.dart";
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:photo_manager/photo_manager.dart';
import "package:photos/image/in_memory_image_cache.dart";
import "package:photos/utils/standalone/task_queue.dart";

final thumbnailQueue = TaskQueue<String>(
  maxConcurrentTasks: 15,
  taskTimeout: const Duration(minutes: 1),
  maxQueueSize: 10000, // Limit the queue to 50 pending tasks
);

final mediumThumbnailQueue = TaskQueue<String>(
  maxConcurrentTasks: 5,
  taskTimeout: const Duration(minutes: 1),
  maxQueueSize: 10000, // Limit the queue to 50 pending tasks
);

class LocalThumbnailProvider extends ImageProvider<LocalThumbnailProviderKey> {
  final LocalThumbnailProviderKey key;

  LocalThumbnailProvider(this.key);

  @override
  Future<LocalThumbnailProviderKey> obtainKey(
    ImageConfiguration configuration,
  ) async {
    return SynchronousFuture<LocalThumbnailProviderKey>(key);
  }

  @override
  ImageStreamCompleter loadImage(
    LocalThumbnailProviderKey key,
    ImageDecoderCallback decode,
  ) {
    final chunkEvents = StreamController<ImageChunkEvent>();
    return MultiImageStreamCompleter(
      codec: _codec(key, decode, chunkEvents),
      scale: 1.0,
      chunkEvents: chunkEvents.stream,
      informationCollector: () sync* {
        yield ErrorDescription('id: ${key.asset.id} name :${key.asset.title}');
      },
    );
  }

  static Future<void> cancelRequest(LocalThumbnailProviderKey key) async {
    thumbnailQueue.removeTask('${key.asset.id}-small');
    mediumThumbnailQueue.removeTask('${key.asset.id}-medium');
  }

  Stream<ui.Codec> _codec(
    LocalThumbnailProviderKey key,
    ImageDecoderCallback decode,
    StreamController<ImageChunkEvent> chunkEvents,
  ) async* {
    final asset = key.asset;
    Uint8List? normalThumbBytes =
        enteImageCache.getThumbByID(asset.id, key.height);
    if (normalThumbBytes != null) {
      final buffer = await ui.ImmutableBuffer.fromUint8List(normalThumbBytes);
      final codec = await decode(buffer);
      yield codec;
      chunkEvents.close().ignore();
    }

    // todo: (neeraj) either cache or use
    // imageCache.statusForKey(key) to avoid refresh when zooming out
    Uint8List? thumbBytes =
        enteImageCache.getThumbByID(asset.id, key.smallThumbWidth);
    if (thumbBytes == null) {
      final Completer<Uint8List?> future = Completer();
      await thumbnailQueue.addTask('${asset.id}-small', () async {
        final thumbBytes = await asset.thumbnailDataWithSize(
          ThumbnailSize(key.smallThumbWidth, key.smallThumbHeight),
          quality: 75,
        );
        enteImageCache.putThumbByID(asset.id, thumbBytes, key.smallThumbWidth);
        future.complete(thumbBytes);
      });
      thumbBytes = await future.future;
      enteImageCache.putThumbByID(asset.id, thumbBytes, key.smallThumbWidth);
    }
    if (thumbBytes != null) {
      final buffer = await ui.ImmutableBuffer.fromUint8List(thumbBytes);
      final codec = await decode(buffer);
      yield codec;
    } else {
      debugPrint("$runtimeType smallThumb ${key.asset.title} failed");
    }

    if (normalThumbBytes == null) {
      final Completer<Uint8List?> future = Completer();
      await mediumThumbnailQueue.addTask('${asset.id}-medium', () async {
        normalThumbBytes = await asset.thumbnailDataWithSize(
          ThumbnailSize(key.width, key.height),
          quality: 50,
        );
        enteImageCache.putThumbByID(asset.id, normalThumbBytes, key.height);
        future.complete(normalThumbBytes);
      });
      normalThumbBytes = await future.future;
      enteImageCache.putThumbByID(asset.id, normalThumbBytes, key.height);
    }
    if (normalThumbBytes == null) {
      throw StateError(
        "$runtimeType biThumb ${asset.title} failed",
      );
    }
    final buffer = await ui.ImmutableBuffer.fromUint8List(normalThumbBytes!);
    final codec = await decode(buffer);
    yield codec;
    chunkEvents.close().ignore();
  }
}

@immutable
class LocalThumbnailProviderKey extends Equatable {
  final AssetEntity asset;
  final int height;
  final int width;
  final int smallThumbHeight;
  final int smallThumbWidth;

  @override
  List<Object?> get props => [
        asset.id,
        asset.modifiedDateSecond ?? 0,
        height,
        width,
        smallThumbHeight,
        smallThumbWidth,
      ];

  const LocalThumbnailProviderKey({
    required this.asset,
    this.height = 256,
    this.width = 256,
    this.smallThumbWidth = 32,
    this.smallThumbHeight = 32,
  });
}
