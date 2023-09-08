import 'dart:io';

import 'package:extended_image/extended_image.dart';
import 'package:fl_image_picker/fl_image_picker.dart';
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

  /// fileAsync > previewUrl > previewPath
  static ImageProvider? assetEntityToImageProvider(ExtendedXFile assetEntity) {
    ImageProvider? provider;
    if (assetEntity.renovated != null) {
      provider = ExtendedImageWithImagePicker.buildImageProvider(
          assetEntity.renovated);
    } else if (assetEntity.fileAsync != null) {
      provider = ExtendedFileImageProvider(assetEntity.fileAsync!);
    } else if (assetEntity.previewed != null) {
      final previewed = assetEntity.previewed!;
      if (previewed.startsWith('http')) {
        provider = ExtendedNetworkImageProvider(previewed);
      } else {
        provider = ExtendedAssetImageProvider(previewed);
      }
    }
    return provider;
  }

  static ImageProvider? buildImageProvider(dynamic value) {
    if (value is File) {
      return ExtendedFileImageProvider(value);
    } else if (value is String && value.startsWith('http')) {
      return ExtendedNetworkImageProvider(value);
    } else if (value is Uint8List) {
      return ExtendedMemoryImageProvider(value);
    }
    return null;
  }
}
