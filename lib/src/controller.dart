import 'package:assets_picker/src/assets.dart';
import 'package:flutter/cupertino.dart';

enum AssetsType {
  image,
  video,
  audio,
  all,

  /// image and video
  common
}
enum FileLoadType { network, file, assets }

class AssetsEntry {
  AssetsEntry({
    required this.path,
    required this.assetsType,
    this.size,
    this.thumbnail,
  });

  String path;

  AssetsType assetsType;

  String? thumbnail;

  Size? size;
}

enum ImageCompressionRatio {
  /// 最高画质
  high,

  /// 中等
  medium,

  ///最低
  low,
}

class AssetsPickerController with ChangeNotifier {
  AssetsPickerController(
      {this.cropAspectRatio = 1,
      this.enableCrop = true,
      this.assetsType = AssetsType.image,
      this.canDelete = true,
      this.maxVideoCount = 1,
      this.maxCount = 9,
      this.minCount = 1,
      this.maxSinglePass = 3,
      this.compressionRatio = ImageCompressionRatio.medium});

  List<AssetsEntry> currentSelectAssets = [];

  /// 图片剪切宽高比
  final double cropAspectRatio;

  ///选择的类型
  final AssetsType assetsType;

  /// 仅显示的时候 是否可以删除 删除后无法恢复
  final bool canDelete;

  /// 初始显示的资源
  final List<AssetsEntry> assets = [];

  /// 最大选择视频数量
  final int maxVideoCount;

  /// 最多选择数量
  final int maxCount;

  /// 最少选择数量
  final int minCount;

  /// 单次最多选择几个资源
  final int maxSinglePass;

  /// 图片剪切压缩比
  final ImageCompressionRatio compressionRatio;

  /// 启动图片裁剪
  final bool enableCrop;
}
