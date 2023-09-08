import 'dart:io';
import 'dart:math';

import 'package:fl_image_picker/fl_image_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

part 'single_image_picker.dart';

part 'multiple_image_picker.dart';

typedef FlImagePickerCheckPermission = Future<bool> Function(
    PickerFromType fromType);

typedef PickerFromTypeBuilder = Widget Function(
    BuildContext context, List<PickerFromTypeItem> fromTypes);

enum AssetType {
  /// The asset is not an image, video
  other,

  /// The asset is an image file.
  image,

  /// The asset is a video file.
  video,
}

typedef FlAssetBuilder = Widget Function(
    ExtendedXFile entity, bool isThumbnail);

FlAssetBuilder _defaultFlAssetBuilder =
    (ExtendedXFile entity, bool isThumbnail) {
  Widget unsupported() => const Center(child: Text('No preview'));
  if (entity.type == AssetType.image) {
    final imageProvider = entity.toImageProvider();
    if (imageProvider != null) {
      return Image(
          image: imageProvider,
          fit: isThumbnail ? BoxFit.cover : BoxFit.contain);
    }
  }
  return unsupported();
};

PickerFromTypeBuilder _defaultFromTypesBuilder =
    (_, List<PickerFromTypeItem> fromTypes) => FlPickFromTypeBuilder(fromTypes);

FlPreviewAssetsBuilder _defaultPreviewBuilder = (context, entity, allEntity) =>
    FlPreviewGesturePageView(
        pageView: PageView.builder(
            controller: PageController(initialPage: allEntity.indexOf(entity)),
            itemCount: allEntity.length,
            itemBuilder: (_, int index) => Center(
                child: FlImagePicker.assetBuilder(allEntity[index], false))));

abstract class FlImagePicker extends StatefulWidget {
  /// image picker
  static ImagePicker imagePicker = ImagePicker();

  /// assetBuilder
  static FlAssetBuilder assetBuilder = _defaultFlAssetBuilder;

  /// 权限申请
  static FlImagePickerCheckPermission? checkPermission;

  /// 类型来源选择器
  static PickerFromTypeBuilder fromTypesBuilder = _defaultFromTypesBuilder;

  /// 资源预览UI [MultipleImagePicker] 使用
  static FlPreviewAssetsBuilder previewBuilder = _defaultPreviewBuilder;

  /// 资源预览UI全屏弹出渲染 [MultipleImagePicker] 使用
  static FlPreviewAssetsModalPopupBuilder previewModalPopup =
      (context, Widget widget) =>
          showCupertinoModalPopup(context: context, builder: (_) => widget);

  /// 错误消息回调
  static PickerErrorCallback? errorCallback;

  const FlImagePicker({
    super.key,
    this.renovate,
    required this.maxVideoCount,
    required this.maxCount,
    required this.fromTypes,
    this.itemConfig = const ImagePickerItemConfig(),
    this.enablePicker = true,
  });

  /// 最大选择视频数量
  final int maxVideoCount;

  /// 最多选择几个资源
  final int maxCount;

  /// 请求类型
  final List<PickerFromTypeItem> fromTypes;

  /// 是否开启 资源选择
  final bool enablePicker;

  final bool useRootNavigator = true;

  /// 资源重新编辑
  final FlAssetFileRenovate? renovate;

  ///
  final ImagePickerItemConfig itemConfig;

  static ImageProvider? buildImageProvider(dynamic value) {
    if (value is File) {
      return FileImage(value);
    } else if (value is String) {
      if (value.startsWith('http')) {
        return NetworkImage(value);
      } else {
        return AssetImage(value);
      }
    } else if (value is Uint8List) {
      return MemoryImage(value);
    }
    return null;
  }

  /// 选择图片或者视频
  static Future<ExtendedXFile?> showPickerWithFormType(
    BuildContext context, {
    /// 选择框提示item
    List<PickerFromTypeItem> fromTypes = defaultPickerFromTypeItem,

    /// 资源最大占用字节
    int maxBytes = 167772160,
  }) async {
    final config = await showPickerFromType(context, fromTypes);
    if (config == null) return null;
    final entity = await showPicker(config.fromType);
    if (entity == null) {
      errorCallback?.call('无法获取该资源');
      return null;
    }
    final fileBytes = await entity.readAsBytes();
    if (fileBytes.length > maxBytes) {
      errorCallback?.call('最大选择${_toSize(maxBytes)}');
      return null;
    }
    return entity;
  }

  /// 不同picker类型选择
  static Future<PickerFromTypeItem?> showPickerFromType(
      BuildContext context, List<PickerFromTypeItem> fromTypes) async {
    PickerFromTypeItem? type;
    if (fromTypes.length == 1 &&
        fromTypes.first.fromType != PickerFromType.cancel) {
      type = fromTypes.first;
    } else {
      type = await showCupertinoModalPopup<PickerFromTypeItem?>(
          context: context, builder: (_) => fromTypesBuilder(_, fromTypes));
    }
    return type;
  }

  /// show picker
  static Future<ExtendedXFile?> showPicker(PickerFromType fromType) async {
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
  static Future<List<XFile>?> showImagePickerMultiple() async {
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

class ImagePickerController with ChangeNotifier {
  List<ExtendedXFile> allEntity = [];

  late FlImagePicker _assetsPicker;

  set assetsPicker(FlImagePicker assetsPicker) {
    _assetsPicker = assetsPicker;
  }

  void delete(ExtendedXFile entity) {
    allEntity.remove(entity);
    notifyListeners();
  }

  /// 选择图片
  Future<ExtendedXFile?> pick(PickerFromType fromType) async {
    final entity = await FlImagePicker.showPicker(fromType);
    if (entity != null) {
      if (!allEntity.contains(entity)) {
        return entity.toRenovated(_assetsPicker.renovate);
      }
    }
    return null;
  }

  /// 弹窗选择类型
  Future<void> pickFromType(BuildContext context, {bool mounted = true}) async {
    if (_assetsPicker.maxCount > 1 &&
        allEntity.length >= _assetsPicker.maxCount) {
      FlImagePicker.errorCallback?.call('最多添加${_assetsPicker.maxCount}个资源');
      return;
    }
    final fromTypeConfig = await FlImagePicker.showPickerFromType(
        context, _assetsPicker.fromTypes);
    if (fromTypeConfig == null) return;
    final entity = await pick(fromTypeConfig.fromType);
    if (entity == null) return;
    if (_assetsPicker.maxCount > 1) {
      var videos = allEntity
          .where((element) => element.type == AssetType.video)
          .toList();
      if (videos.length >= _assetsPicker.maxVideoCount) {
        FlImagePicker.errorCallback
            ?.call('最多添加${_assetsPicker.maxVideoCount}个视频');
        return;
      } else {
        allEntity.add(entity);
      }
    } else {
      /// 单资源
      allEntity = [entity];
    }
    notifyListeners();
  }
}
