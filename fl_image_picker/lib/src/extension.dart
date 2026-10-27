part of '../fl_image_picker.dart';

typedef FlXFileRenovate = FutureOr<dynamic> Function(AssetType type, XFile file);

class FlXFile extends XFile {
  FlXFile.fromPreviewed(dynamic previewed, this.type)
    : previewed = previewed,
      renovated = null,
      isLocalData = false,
      super(_previewedPath(previewed));

  /// [previewed] 可能为 url、asset 路径、文件路径、[File]、[XFile]、[Uint8List]
  static String _previewedPath(dynamic previewed) {
    if (previewed is String) return previewed;
    if (previewed is File) return previewed.path;
    if (previewed is XFile) return previewed.path;
    return '';
  }

  FlXFile(
    super.path,
    this.type, {
    this.renovated,
    super.mimeType,
    super.bytes,
    super.lastModified,
    super.length,
    super.name,
  }) : isLocalData = true,
       previewed = null;

  final bool isLocalData;

  /// 资源类型
  final AssetType type;

  /// [previewed] 主要用于复显
  /// 支持 url， assetPath， file
  final dynamic previewed;

  /// 对选中的资源文件重新编辑，例如 压缩 裁剪 上传
  final dynamic renovated;

  /// previewed > renovated > path 中可转为字符串的值
  String? get realValueStr {
    final value = realValue;
    final String? result = value is String
        ? value
        : value is File
        ? value.path
        : value is XFile
        ? value.path
        : null;
    return result == null || result.isEmpty ? null : result;
  }

  /// previewed > renovated > path
  dynamic get realValue => previewed ?? renovated ?? path;
}

extension ExtensionFlXFile on FlXFile {
  Future<FlXFile> toRenovated(FlXFileRenovate? renovate) async {
    if (renovate == null) return this;
    return FlXFile(path, type, renovated: await renovate(type, this), mimeType: mimeType, name: name);
  }

  /// previewed > renovated > path
  ImageProvider? toImageProvider() {
    ImageProvider? provider;
    if (previewed != null) {
      provider = FlImagePicker.buildImageProvider(previewed);
    } else if (renovated != null) {
      provider = FlImagePicker.buildImageProvider(renovated);
    } else if (kIsWeb) {
      provider = FlImagePicker.buildImageProvider(path);
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
