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
  maxQueueSize: 200, // Limit the queue to 50 pending tasks
);

final mediumThumbnailQueue = TaskQueue<String>(
  maxConcurrentTasks: 5,
  taskTimeout: const Duration(minutes: 1),
  maxQueueSize: 200, // Limit the queue to 50 pending tasks
);

class LocalThumbnailProvider extends ImageProvider<LocalThumbnailProviderKey> {
  final LocalThumbnailProviderKey key;
  final int maxRetries;
  final Duration retryDelay;

  LocalThumbnailProvider(
    this.key, {
    this.maxRetries = 300,
    this.retryDelay = const Duration(milliseconds: 5),
  });

  @override
  Future<LocalThumbnailProviderKey> obtainKey(
    ImageConfiguration configuration,
  ) async {
    return SynchronousFuture<LocalThumbnailProviderKey>(key);
  }

  static cancelRequest(LocalThumbnailProviderKey key) {
    thumbnailQueue.removeTask('${key.asset.id}-small');
    mediumThumbnailQueue.removeTask('${key.asset.id}-medium');
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
        yield ErrorDescription('id: ${key.asset.id} name: ${key.asset.title}');
      },
    );
  }

  Stream<ui.Codec> _codec(
    LocalThumbnailProviderKey key,
    ImageDecoderCallback decode,
    StreamController<ImageChunkEvent> chunkEvents,
  ) async* {
    // First try to get from cache
    Uint8List? normalThumbBytes =
        enteImageCache.getThumbByID(key.asset.id, key.height);
    if (normalThumbBytes != null) {
      final buffer = await ui.ImmutableBuffer.fromUint8List(normalThumbBytes);
      final codec = await decode(buffer);
      yield codec;
      chunkEvents.close().ignore();
      return;
    }

    // Try to load small thumbnail with retry logic
    final Uint8List? thumbBytes = await _loadWithRetry(
      key: key,
      size: ThumbnailSize(key.smallThumbWidth, key.smallThumbHeight),
      quality: 75,
      cacheKey: '${key.asset.id}-small',
      queue: thumbnailQueue,
      cacheWidth: key.smallThumbWidth,
    );

    if (thumbBytes != null) {
      final buffer = await ui.ImmutableBuffer.fromUint8List(thumbBytes);
      final codec = await decode(buffer);
      yield codec;
    } else {
      debugPrint("$runtimeType smallThumb ${key.asset.title} failed");
    }

    // Try to load normal thumbnail with retry logic if not already in cache
    if (normalThumbBytes == null) {
      normalThumbBytes = await _loadWithRetry(
        key: key,
        size: ThumbnailSize(key.width, key.height),
        quality: 50,
        cacheKey: '${key.asset.id}-medium',
        queue: mediumThumbnailQueue,
        cacheWidth: key.height,
      );

      if (normalThumbBytes == null) {
        throw StateError("$runtimeType biThumb ${key.asset.title} failed");
      }

      final buffer = await ui.ImmutableBuffer.fromUint8List(normalThumbBytes);
      final codec = await decode(buffer);
      yield codec;
    }

    chunkEvents.close().ignore();
  }

  Future<Uint8List?> _loadWithRetry({
    required LocalThumbnailProviderKey key,
    required ThumbnailSize size,
    required int quality,
    required String cacheKey,
    required TaskQueue<String> queue,
    required int cacheWidth,
  }) async {
    int attempt = 0;
    Uint8List? result;

    while (attempt <= maxRetries) {
      try {
        // Check cache first on retry attempts
        if (attempt > 0) {
          result = enteImageCache.getThumbByID(key.asset.id, cacheWidth);
          if (result != null) return result;
        }

        final Completer<Uint8List?> future = Completer();
        await queue.addTask(cacheKey, () async {
          final bytes =
              await key.asset.thumbnailDataWithSize(size, quality: quality);
          enteImageCache.putThumbByID(key.asset.id, bytes, cacheWidth);
          future.complete(bytes);
        });
        result = await future.future;
        return result;
      } catch (e) {
        // Only retry on specific exceptions
        if (e is! TaskQueueOverflowException &&
            e is! TaskQueueTimeoutException &&
            e is! TaskQueueCancelledException) {
          rethrow;
        }

        attempt++;
        if (attempt <= maxRetries) {
          await Future.delayed(retryDelay * attempt); // Exponential backoff
        } else {
          rethrow;
        }
      }
    }
    return null;
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
