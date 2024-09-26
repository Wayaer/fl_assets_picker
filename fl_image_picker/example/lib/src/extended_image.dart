import 'dart:io';

import 'package:fl_image_picker/fl_image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ExtendedImageWithImagePicker {
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
    if (value is String) {
      if (value.startsWith('http') || value.startsWith('blob:http')) {
        return NetworkImage(value);
      } else {
        return AssetImage(value);
      }
    } else if (value is Uint8List) {
      return MemoryImage(value);
    } else if (value is File) {
      return FileImage(value);
    }
    return null;
  }
}
