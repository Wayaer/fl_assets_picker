import 'package:extended_image/extended_image.dart';
import 'package:extended_image_library/extended_image_library.dart';
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
  static ImageProvider? imageEntityToImageProvider(ExtendedXFile xFile) {
    ImageProvider? provider;
    if (xFile.renovated != null) {
      provider =
          ExtendedImageWithImagePicker.buildImageProvider(xFile.renovated);
    } else if (xFile.previewed != null) {
      provider =
          ExtendedImageWithImagePicker.buildImageProvider(xFile.previewed);
    } else {
      provider =
          ExtendedImageWithImagePicker.buildImageProvider(File(xFile.path));
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
