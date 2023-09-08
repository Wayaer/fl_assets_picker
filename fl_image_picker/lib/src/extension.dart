import 'dart:io';

import 'package:fl_image_picker/fl_image_picker.dart';
import 'package:flutter/material.dart';

typedef FlAssetFileRenovate<T> = Future<T> Function(AssetType type, XFile file);

class ExtendedXFile<T> extends XFile {
  ExtendedXFile.fromPreviewed(this.previewed, this.type)
      : fileAsync = null,
        renovated = null,
        isLocalData = false,
        super(previewed ?? '');

  ExtendedXFile(
    super.path,
    this.type, {
    this.renovated,
    this.fileAsync,
    super.bytes,
    super.lastModified,
    super.length,
    super.mimeType,
    super.name,
  })  : isLocalData = true,
        previewed = null;

  final bool isLocalData;

  /// 资源类型
  final AssetType type;

  /// [previewed] 主要用于复显 可使用url 或者 assetPath
  final String? previewed;

  /// file
  final File? fileAsync;

  /// 对选中的资源文件重新编辑，例如 压缩 裁剪 上传
  final T? renovated;

  String? get realValueStr => previewed ?? fileAsync?.path;

  dynamic get realValue => previewed ?? renovated ?? fileAsync;
}

extension ExtensionExtendedXFile on ExtendedXFile {
  Future<ExtendedXFile> toRenovated<T>(FlAssetFileRenovate<T>? renovate) async {
    return ExtendedXFile<T>(path, type,
        fileAsync: File(path), renovated: await renovate?.call(type, this));
  }

  ImageProvider? toImageProvider() {
    ImageProvider? provider;
    if (renovated != null) {
      provider = FlImagePicker.buildImageProvider(renovated);
    } else if (fileAsync != null) {
      provider = FileImage(fileAsync!);
    } else if (previewed != null) {
      provider = FlImagePicker.buildImageProvider(previewed);
    }
    return provider;
  }
}

extension ExtensionXFile on XFile {
  ///  to [ExtendedXFile] and renovate [XFile];
  ExtendedXFile toExtended<T>(AssetType type, {String? mimeType}) {
    return ExtendedXFile<T>(path, type,
        fileAsync: File(path), mimeType: mimeType);
  }
}

enum ImageCroppingQuality {
  /// 最高画质
  high,

  /// 中等
  medium,

  ///最低
  low,
}
