import 'dart:io';

import 'package:extended_image/extended_image.dart';
import 'package:fl_assets_picker/fl_assets_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef ExtendedImageLoadStateBuilder = Widget Function(ExtendedImageState);

class ExtendedImageWithImagePicker extends ExtendedImage {
  ExtendedImageWithImagePicker(ImageProvider image,
      {super.key,
      super.mode,
      super.initGestureConfigHandler,
      super.fit = BoxFit.cover})
      : super(image: image, enableLoadState: true);

  /// renovated > fileAsync > previewed
  static ImageProvider? assetEntityToImageProvider(
      ExtendedAssetEntity assetEntity) {
    ImageProvider? provider;
    if (assetEntity.renovated != null) {
      provider = ExtendedImageWithImagePicker.buildImageProvider(
          assetEntity.renovated);
    } else if (assetEntity.fileAsync != null) {
      provider = ExtendedFileImageProvider(assetEntity.fileAsync!);
    } else if (assetEntity.previewed != null) {
      provider = ExtendedImageWithImagePicker.buildImageProvider(
          assetEntity.previewed);
    }
    return provider;
  }

  static ImageProvider? buildImageProvider(dynamic value) {
    if (value is File) {
      return ExtendedFileImageProvider(value);
    } else if (value is String && value.startsWith('http')) {
      if (value.startsWith('http')) {
        return ExtendedNetworkImageProvider(value);
      } else {
        return ExtendedAssetImageProvider(value);
      }
    } else if (value is Uint8List) {
      return ExtendedMemoryImageProvider(value);
    }
    return null;
  }
}
