import 'dart:io';

import 'package:fl_image_picker/fl_image_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

part 'single_image_picker.dart';

part 'multiple_image_picker.dart';

typedef FlImagePickerCheckPermission = Future<bool> Function(
    PickerOptionalActions action);

typedef PickerOptionalActionsBuilder = Widget Function(
    BuildContext context, List<PickerActions> actions);

typedef PickerErrorCallback = void Function(ErrorDes msg);

enum AssetType {
  /// The asset is not an image, video
  other,

  /// The asset is an image file.
  image,

  /// The asset is a video file.
  video,
}

enum ErrorDes {
  /// 超过最大字节
  maxBytes,

  /// 超过最大数量
  maxCount,

  /// 超过最大视频数量
  maxVideoCount,
}

typedef FlAssetBuilder = Widget Function(
    ExtendedXFile entity, bool isThumbnail);

typedef FlPreviewAssetsModalPopupBuilder = void Function(
    BuildContext context, Widget previewAssets);

typedef FlPreviewAssetsBuilder = Widget Function(
    BuildContext context, ExtendedXFile current, List<ExtendedXFile> entitys);

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

PickerOptionalActionsBuilder _defaultFromTypesBuilder =
    (_, List<PickerActions> actions) => FlPickerOptionalActionsBuilder(actions);

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
  static PickerOptionalActionsBuilder actionsBuilder = _defaultFromTypesBuilder;

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
    required this.actions,
    this.itemConfig = const ImagePickerItemConfig(),
    this.enablePicker = true,
  });

  /// 最大选择视频数量
  final int maxVideoCount;

  /// 最多选择几个资源
  final int maxCount;

  /// 请求类型
  final List<PickerActions> actions;

  /// 是否开启 资源选择
  final bool enablePicker;

  final bool useRootNavigator = true;

  /// 资源重新编辑
  final FlAssetFileRenovate? renovate;

  /// item 样式配置
  final ImagePickerItemConfig itemConfig;

  /// value 转换为 [ImageProvider]
  static ImageProvider? buildImageProvider(dynamic value) {
    if (value is File) {
      return FileImage(value);
    } else if (value is String) {
      if (value.startsWith('http') || value.startsWith('blob:http')) {
        return NetworkImage(value);
      } else {
        return AssetImage(value);
      }
    } else if (value is Uint8List) {
      return MemoryImage(value);
    }
    return null;
  }

  /// 从可选配置中选择
  static Future<ExtendedXFile?> showPickWithOptionalActions(
    BuildContext context, {
    /// 选择框提示item
    List<PickerActions> actions = defaultPickerActions,
    int maxBytes = 167772160,
  }) async {
    final config = await showPickActions(context, actions);
    if (config == null) return null;
    final entity = await showPick(config.action);
    if (entity == null) return null;
    final fileBytes = await entity.readAsBytes();
    if (fileBytes.length > maxBytes) {
      errorCallback?.call(ErrorDes.maxBytes);
      return null;
    }
    return entity;
  }

  /// 选择Actions
  static Future<PickerActions?> showPickActions(
      BuildContext context, List<PickerActions> actions) async {
    PickerActions? type;
    final types =
        actions.where((e) => e.action != PickerOptionalActions.cancel);
    if (types.length == 1) {
      type = types.first;
    } else {
      type = await showCupertinoModalPopup<PickerActions?>(
          context: context,
          builder: (BuildContext context) => actionsBuilder(context, actions));
    }
    return type;
  }

  /// show pick
  static Future<ExtendedXFile?> showPick(PickerOptionalActions action) async {
    final permissionState = await checkPermission?.call(action) ?? true;
    XFile? file;
    AssetType assetType = AssetType.other;
    if (permissionState) {
      switch (action) {
        case PickerOptionalActions.image:
          file = await imagePicker.pickImage(source: ImageSource.gallery);
          assetType = AssetType.image;
          break;
        case PickerOptionalActions.video:
          file = await imagePicker.pickVideo(source: ImageSource.gallery);
          assetType = AssetType.video;
          break;
        case PickerOptionalActions.takePictures:
          file = await imagePicker.pickImage(source: ImageSource.camera);
          assetType = AssetType.image;
          break;
        case PickerOptionalActions.recording:
          file = await imagePicker.pickVideo(source: ImageSource.camera);
          assetType = AssetType.video;
          break;
        case PickerOptionalActions.cancel:
          break;
      }
      if (file != null) {
        final mimeType = file.mimeType;
        if (mimeType?.startsWith('video') ?? false) {
          assetType = AssetType.video;
        } else if (mimeType?.startsWith('image') ?? false) {
          assetType = AssetType.image;
        }
        return file.toExtended(assetType);
      }
    }
    return null;
  }

  /// show pick multiple image
  static Future<List<XFile>?> showPickMultipleImage() async {
    final permissionState =
        await checkPermission?.call(PickerOptionalActions.image) ?? true;
    if (permissionState) return await imagePicker.pickMultiImage();
    return null;
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
  Future<ExtendedXFile?> pick(PickerOptionalActions action) async {
    final entity = await FlImagePicker.showPick(action);
    if (entity != null && !allEntity.contains(entity)) {
      return entity.toRenovated(_assetsPicker.renovate);
    }
    return null;
  }

  /// 弹窗选择类型
  Future<void> pickActions(BuildContext context) async {
    if (_assetsPicker.maxCount > 1 &&
        allEntity.length >= _assetsPicker.maxCount) {
      FlImagePicker.errorCallback?.call(ErrorDes.maxCount);
      return;
    }
    final actionConfig =
        await FlImagePicker.showPickActions(context, _assetsPicker.actions);
    if (actionConfig == null) return;
    final entity = await pick(actionConfig.action);
    if (entity == null) return;
    if (_assetsPicker.maxCount > 1) {
      var videos = allEntity
          .where((element) => element.type == AssetType.video)
          .toList();
      if (videos.length >= _assetsPicker.maxVideoCount) {
        FlImagePicker.errorCallback?.call(ErrorDes.maxVideoCount);
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
