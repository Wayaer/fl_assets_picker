part of '../fl_image_picker.dart';

typedef FlXFileRenovate = FutureOr<dynamic> Function(
    AssetType type, XFile file);

class FlXFile extends XFile {
  FlXFile.fromPreviewed(this.previewed, this.type)
      : renovated = null,
        isLocalData = false,
        super(previewed ?? '');

  FlXFile(
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
  final AssetType type;

  /// [previewed] 主要用于复显
  /// 支持 url， assetPath， file
  final dynamic previewed;

  /// 对选中的资源文件重新编辑，例如 压缩 裁剪 上传
  final dynamic renovated;

  /// previewed > path
  String? get realValueStr => previewed ?? path;

  /// previewed > renovated > path
  dynamic get realValue => previewed ?? renovated ?? path;
}

extension ExtensionFlXFile on FlXFile {
  Future<FlXFile> toRenovated(FlXFileRenovate? renovate) async =>
      FlXFile(path, type, renovated: await renovate?.call(type, this));

  /// previewed > renovated > path
  ImageProvider? toImageProvider() {
    ImageProvider? provider;
    if (previewed != null) {
      provider = FlImagePicker.buildImageProvider(previewed);
    } else if (renovated != null) {
      provider = FlImagePicker.buildImageProvider(renovated);
    } else {
      provider = FlImagePicker.buildImageProvider(File(path));
    }
    return provider;
  }
}

extension ExtensionXFile on XFile {
  ///  to [FlXFile] and renovate [XFile];
  FlXFile toExtended(AssetType type) => FlXFile(path, type);
}
