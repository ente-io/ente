import 'dart:async';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import "package:equatable/equatable.dart";

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:photo_manager/photo_manager.dart';

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

  Stream<ui.Codec> _codec(
    LocalThumbnailProviderKey key,
    ImageDecoderCallback decode,
    StreamController<ImageChunkEvent> chunkEvents,
  ) async* {
    final asset = key.asset;
    final thumbBytes = await asset.thumbnailDataWithSize(
      ThumbnailSize(key.smallThumbWidth, key.smallThumbHeight),
      quality: 75,
    );
    if (thumbBytes != null) {
      final buffer = await ui.ImmutableBuffer.fromUint8List(thumbBytes);
      final codec = await decode(buffer);
      yield codec;
    } else {
      debugPrint("$runtimeType smallThum ${key.asset.title} failed");
    }
    final normalThumbBytes =
        await asset.thumbnailDataWithSize(ThumbnailSize(key.width, key.height));
    if (normalThumbBytes == null) {
      throw StateError(
        "$runtimeType bugThumb ${asset.title} failed",
      );
    }
    final buffer = await ui.ImmutableBuffer.fromUint8List(normalThumbBytes);
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
