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

  /// previewed > renovated > fileAsync
  static ImageProvider? assetEntityToImageProvider(ExtendedAssetEntity entity) {
    ImageProvider? provider;
    if (entity.previewed != null) {
      provider =
          ExtendedImageWithImagePicker.buildImageProvider(entity.previewed);
    } else if (entity.renovated != null) {
      provider =
          ExtendedImageWithImagePicker.buildImageProvider(entity.renovated);
    } else if (entity.fileAsync != null) {
      provider = ExtendedFileImageProvider(entity.fileAsync!);
    }
    return provider;
  }

  static ImageProvider? buildImageProvider(dynamic value) {
    if (value is File) {
      return ExtendedFileImageProvider(value);
    } else if (value is String) {
      if (value.startsWith('http') || value.startsWith('blob:http')) {
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
