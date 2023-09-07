import 'dart:math';

import 'package:fl_image_picker/fl_image_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

typedef FlImagePickerCheckPermission = Future<bool> Function(
    PickerFromType fromType);

typedef FlImagePickerErrorCallback = void Function(String erroe);

typedef PickerFromTypeBuilder = Widget Function(
    BuildContext context, List<PickerFromTypeItem> fromTypes);

typedef FlAssetFileRenovate<T> = Future<T> Function(
    AssetType assetType, XFile file);

enum ImageCroppingQuality {
  /// 最高画质
  high,

  /// 中等
  medium,

  ///最低
  low,
}

enum AssetType {
  /// The asset is not an image, video, or audio file.
  other,

  /// The asset is an image file.
  image,

  /// The asset is a video file.
  video,
}

enum PickerFromType {
  /// 仅图片
  image,

  /// 仅视频
  video,

  /// 拍照
  takePictures,

  /// 相机录像
  recording,

  /// 取消
  cancel,
}

class PickerFromTypeItem {
  const PickerFromTypeItem({required this.fromType, required this.text});

  /// 来源
  final PickerFromType fromType;

  /// 显示的文字
  final Widget text;
}

typedef DeletionConfirmation = Future<bool> Function(ExtendedXFile entity);

class AssetsPickerEntryConfig {
  const AssetsPickerEntryConfig(
      {this.color,
      this.fit = BoxFit.cover,
      this.previewFit = BoxFit.contain,
      this.borderRadius = const BorderRadius.all(Radius.circular(8)),
      this.size = const Size(65, 65),
      this.pick = const AssetPickIcon(),
      this.delete = const AssetDeleteIcon(),
      this.deletionConfirmation,
      this.play = const Icon(Icons.play_circle_outline,
          size: 30, color: Color(0x804D4D4D))});

  final Color? color;
  final Size size;
  final BorderRadiusGeometry? borderRadius;

  /// 视频预览 播放 icon
  final Widget play;

  /// 添加 框的
  final Widget pick;

  /// 删除按钮
  final Widget delete;

  /// 删除确认
  final DeletionConfirmation? deletionConfirmation;

  /// 缩略图fit
  final BoxFit fit;

  /// 预览画面fit
  final BoxFit previewFit;
}

const List<PickerFromTypeItem> defaultPickerFromTypeItem = [
  PickerFromTypeItem(fromType: PickerFromType.image, text: Text('选择图片')),
  PickerFromTypeItem(fromType: PickerFromType.video, text: Text('选择视频')),
  PickerFromTypeItem(fromType: PickerFromType.takePictures, text: Text('相机拍照')),
  PickerFromTypeItem(fromType: PickerFromType.recording, text: Text('相机录像')),
  PickerFromTypeItem(
      fromType: PickerFromType.cancel,
      text: Text('取消', style: TextStyle(color: Colors.red))),
];

abstract class FlImagePicker extends StatefulWidget {
  static ImagePicker imagePicker = ImagePicker();

  const FlImagePicker(
      {super.key,
      this.renovate,
      required this.maxVideoCount,
      required this.maxCount,
      required this.fromTypes,
      this.enablePicker = true,
      this.errorCallback,
      this.fromTypesBuilder,
      this.checkPermission});

  /// 最大选择视频数量
  final int maxVideoCount;

  /// 最多选择几个资源
  final int maxCount;

  /// 请求类型
  final List<PickerFromTypeItem> fromTypes;

  /// 是否开启 资源选择
  final bool enablePicker;

  /// 错误消息回调
  final PickerErrorCallback? errorCallback;

  /// 选择框 自定义
  final PickerFromTypeBuilder? fromTypesBuilder;

  final bool useRootNavigator = true;

  /// 资源重新编辑
  final FlAssetFileRenovate? renovate;

  /// 获取权限
  final FlImagePickerCheckPermission? checkPermission;

  /// 选择图片或者视频
  static Future<ExtendedXFile?> showPickerWithFormType(
    BuildContext context, {
    /// 选择框提示item
    List<PickerFromTypeItem> fromTypes = defaultPickerFromTypeItem,
    PickerFromTypeBuilder? fromTypesBuilder,

    /// 获取权限
    FlImagePickerCheckPermission? checkPermission,

    /// 错误提示
    FlImagePickerErrorCallback? errorCallback,

    /// 资源最大占用字节
    int maxBytes = 167772160,
  }) async {
    final config = await showPickerFromType(context, fromTypes,
        fromTypesBuilder: fromTypesBuilder);
    if (config == null) return null;
    final xFile = await showPicker(config.fromType);
    if (xFile == null) {
      errorCallback?.call('无法获取该资源');
      return null;
    }
    final fileBytes = await xFile.readAsBytes();
    if (fileBytes.length > maxBytes) {
      errorCallback?.call('最大选择${_toSize(maxBytes)}');
      return null;
    }
    return xFile;
  }

  /// show 选择弹窗
  static Future<PickerFromTypeItem?> showPickerFromType(
    BuildContext context,
    List<PickerFromTypeItem> fromTypes, {
    PickerFromTypeBuilder? fromTypesBuilder,
  }) async {
    PickerFromTypeItem? type;
    if (fromTypes.length == 1 &&
        fromTypes.first.fromType != PickerFromType.cancel) {
      type = fromTypes.first;
    } else {
      type = await showCupertinoModalPopup<PickerFromTypeItem?>(
          context: context,
          builder: (BuildContext context) =>
              fromTypesBuilder?.call(context, fromTypes) ??
              _PickFromTypeBuilderWidget(fromTypes));
    }
    return type;
  }

  /// show picker
  static Future<ExtendedXFile?> showPicker(
    PickerFromType fromType, {
    FlImagePickerCheckPermission? checkPermission,
  }) async {
    final permissionState = await checkPermission?.call(fromType) ?? true;
    XFile? file;
    AssetType assetType = AssetType.other;
    if (permissionState) {
      switch (fromType) {
        case PickerFromType.image:
          final ImagePickerPlatform imagePickerImplementation =
              ImagePickerPlatform.instance;
          if (imagePickerImplementation is ImagePickerAndroid) {
            imagePickerImplementation.useAndroidPhotoPicker = true;
          }
          file = await imagePicker.pickImage(source: ImageSource.gallery);
          assetType = AssetType.image;
          break;
        case PickerFromType.video:
          file = await imagePicker.pickVideo(source: ImageSource.gallery);
          assetType = AssetType.video;
          break;
        case PickerFromType.takePictures:
          file = await imagePicker.pickImage(source: ImageSource.camera);
          assetType = AssetType.image;
          break;
        case PickerFromType.recording:
          file = await imagePicker.pickVideo(source: ImageSource.camera);
          assetType = AssetType.video;
          break;
        case PickerFromType.cancel:
          break;
      }
      if (file != null) {
        final mimeType = lookupMimeType(file.path);
        if (mimeType != null) {
          if (mimeType.startsWith('video')) {
            assetType = AssetType.video;
          } else if (mimeType.startsWith('image')) {
            assetType = AssetType.image;
          }
        }
        return file.toExtended(assetType, mimeType: mimeType);
      }
    }
    return null;
  }

  /// show picker
  static Future<List<XFile>?> showImagePickerMultiple({
    FlImagePickerCheckPermission? checkPermission,
  }) async {
    final permissionState =
        await checkPermission?.call(PickerFromType.image) ?? true;
    if (permissionState) return await imagePicker.pickMultiImage();
    return null;
  }

  /// int 字节转 k MB GB
  static String _toSize(int size) {
    if (size < 1024) {
      return '${size}B';
    } else if (size >= 1024 && size < pow(1024, 2)) {
      size = (size / 10.24).round();
      return '${size / 100}KB';
    } else if (size >= pow(1024, 2) && size < pow(1024, 3)) {
      size = (size / (pow(1024, 2) * 0.01)).round();
      return '${size / 100}MB';
    } else if (size >= pow(1024, 3) && size < pow(1024, 4)) {
      size = (size / (pow(1024, 3) * 0.01)).round();
      return '${size / 100}GB';
    }
    return size.toString();
  }
}

class _PickFromTypeBuilderWidget extends StatelessWidget {
  const _PickFromTypeBuilderWidget(this.list);

  final List<PickerFromTypeItem> list;

  @override
  Widget build(BuildContext context) {
    List<Widget> actions = [];
    Widget? cancelButton;
    for (var element in list) {
      final entry = CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).maybePop(element),
          isDefaultAction: false,
          child: element.text);
      if (element.fromType != PickerFromType.cancel) {
        actions.add(entry);
      } else {
        cancelButton = entry;
      }
    }
    return CupertinoActionSheet(cancelButton: cancelButton, actions: actions);
  }
}

class AssetsPickerController with ChangeNotifier {
  List<ExtendedXFile> allXFile = [];

  late FlImagePicker _assetsPicker;

  set assetsPicker(FlImagePicker assetsPicker) {
    _assetsPicker = assetsPicker;
  }

  void deleteAsset(String path) {
    allXFile.removeWhere((element) => path == element.path);
    notifyListeners();
  }

  /// 选择图片
  Future<ExtendedXFile?> pick(PickerFromType fromType) async {
    final xFile = await FlImagePicker.showPicker(fromType,
        checkPermission: _assetsPicker.checkPermission);
    if (xFile != null) {
      if (!allXFile.contains(xFile)) {
        return xFile.toRenovated(_assetsPicker.renovate);
      }
    }
    return null;
  }

  /// 弹窗选择类型
  Future<void> pickFromType(BuildContext context, {bool mounted = true}) async {
    if (_assetsPicker.maxCount > 1 &&
        allXFile.length >= _assetsPicker.maxCount) {
      _assetsPicker.errorCallback?.call('最多添加${_assetsPicker.maxCount}个资源');
      return;
    }
    final fromTypeConfig = await FlImagePicker.showPickerFromType(
        context, _assetsPicker.fromTypes,
        fromTypesBuilder: _assetsPicker.fromTypesBuilder);
    if (fromTypeConfig == null) return;
    final entity = await pick(fromTypeConfig.fromType);
    if (entity == null) return;
    if (_assetsPicker.maxCount > 1) {
      var videos = allXFile
          .where((element) => element.assetType == AssetType.video)
          .toList();
      if (videos.length >= _assetsPicker.maxVideoCount) {
        _assetsPicker.errorCallback
            ?.call('最多添加${_assetsPicker.maxVideoCount}个视频');
        return;
      } else {
        allXFile.add(entity);
      }
    } else {
      /// 单资源
      allXFile = [entity];
    }
    notifyListeners();
  }
}
