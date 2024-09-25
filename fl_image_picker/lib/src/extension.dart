import 'package:fl_image_picker/fl_image_picker.dart';
import 'package:flutter/material.dart';

typedef FlImageFileRenovate = Future<dynamic> Function(
    ImageType type, XFile file);

class ExtendedXFile extends XFile {
  ExtendedXFile.fromPreviewed(this.previewed, this.type)
      : renovated = null,
        isLocalData = false,
        super(previewed ?? '');

  ExtendedXFile(
    super.path,
    this.type, {
    this.renovated,
    super.bytes,
    super.lastModified,
    super.length,
    super.name,
  })  : isLocalData = true,
        previewed = null;

  final bool isLocalData;

  /// 资源类型
  final ImageType type;

  /// [previewed] 主要用于复显
  /// 支持 url， assetPath， file
  final dynamic previewed;

  /// 对选中的资源文件重新编辑，例如 压缩 裁剪 上传
  final dynamic renovated;

  String? get realValueStr => previewed ?? path;

  dynamic get realValue => previewed ?? renovated ?? path;
}

extension ExtensionExtendedXFile on ExtendedXFile {
  Future<ExtendedXFile> toRenovated(FlImageFileRenovate? renovate) async =>
      ExtendedXFile(path, type, renovated: await renovate?.call(type, this));

  /// previewed > renovated > path
  ImageProvider? toImageProvider() {
    ImageProvider? provider;
    if (previewed != null) {
      provider = FlImagePicker.buildImageProvider(previewed);
    } else if (renovated != null) {
      provider = FlImagePicker.buildImageProvider(renovated);
    } else {
      provider = FlImagePicker.buildImageProvider(path);
    }
    return provider;
  }
}

extension ExtensionXFile on XFile {
  ///  to [ExtendedXFile] and renovate [XFile];
  ExtendedXFile toExtended(ImageType type) => ExtendedXFile(path, type);
}

enum ImageCroppingQuality {
  /// 最高画质
  high,

  /// 中等
  medium,

  ///最低
  low,
}
