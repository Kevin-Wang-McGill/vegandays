import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// ImageProvider that forces a unique image stream per instance.
/// This avoids GIF animations syncing across multiple widgets.
class UniqueAssetImage extends ImageProvider<UniqueAssetImage> {
  final String assetName;
  final String uniqueId;
  final AssetBundle? bundle;
  final double scale;

  const UniqueAssetImage(
    this.assetName, {
    required this.uniqueId,
    this.bundle,
    this.scale = 1.0,
  });

  @override
  Future<UniqueAssetImage> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<UniqueAssetImage>(this);
  }

  @override
  ImageStreamCompleter loadImage(
    UniqueAssetImage key,
    ImageDecoderCallback decode,
  ) {
    final AssetBundle chosenBundle = bundle ?? rootBundle;
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(chosenBundle, key, decode),
      scale: key.scale,
    );
  }

  Future<ui.Codec> _loadAsync(
    AssetBundle bundle,
    UniqueAssetImage key,
    ImageDecoderCallback decode,
  ) async {
    final data = await bundle.load(key.assetName);
    if (data.lengthInBytes == 0) {
      throw StateError('Unable to load asset: ${key.assetName}.');
    }
    // Convert ByteData to ImmutableBuffer for ImageDecoderCallback
    final buffer = await ui.ImmutableBuffer.fromUint8List(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
    return decode(buffer);
  }

  @override
  bool operator ==(Object other) {
    return other is UniqueAssetImage &&
        other.assetName == assetName &&
        other.uniqueId == uniqueId &&
        other.scale == scale &&
        other.bundle == bundle;
  }

  @override
  int get hashCode => Object.hash(assetName, uniqueId, scale, bundle);
}

