import 'dart:io';

import 'package:fl_assets_picker/fl_assets_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

part 'multiple_asset_picker.dart';

part 'single_asset_picker.dart';

bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;

bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;

bool get _supportable => _isAndroid || _isIOS;

typedef FlAssetsPickerCheckPermission = Future<bool> Function(
    PickerOptionalActions action);

typedef FlAssetsPickerErrorCallback = void Function(ErrorDes des);

typedef PickerOptionalActionsBuilder = Widget Function(
    BuildContext context, List<PickerActions> actions);

typedef FlAssetFileRenovate = Future<dynamic> Function(AssetEntity entity);

typedef DeletionConfirmation = Future<bool> Function(
    ExtendedAssetEntity entity);

enum ErrorDes {
  /// 超过最大字节
  maxBytes,

  /// 超过最大数量
  maxCount,

  /// 超过最大视频数量
  maxVideoCount,

  /// 未读取到资源
  none,
}

class AssetsPickerItemConfig {
  const AssetsPickerItemConfig(
      {this.color,
      this.fit = BoxFit.cover,
      this.previewFit = BoxFit.contain,
      this.borderRadius = const BorderRadius.all(Radius.circular(8)),
      this.size = const Size(65, 65),
      this.pick = const DefaultPickIcon(),
      this.delete = const DefaultDeleteIcon(),
      this.deletionConfirmation,
      this.play = const Icon(Icons.play_circle_outline,
          size: 30, color: Color(0x804D4D4D))});

  final Color? color;
  final Size size;
  final BorderRadiusGeometry? borderRadius;

  /// 视频预览 播放 icon
  final Widget play;

  /// 添加选择item
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

typedef FlAssetBuilder = Widget Function(
    ExtendedAssetEntity entity, bool isThumbnail);

FlAssetBuilder _defaultFlAssetBuilder =
    (ExtendedAssetEntity entity, bool isThumbnail) {
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
                child: FlAssetsPicker.assetBuilder(allEntity[index], false))));

abstract class FlAssetsPicker extends StatefulWidget {
  /// assetBuilder
  static FlAssetBuilder assetBuilder = _defaultFlAssetBuilder;

  /// 权限申请
  static FlAssetsPickerCheckPermission? checkPermission;

  /// 类型来源选择器
  static PickerOptionalActionsBuilder actionsBuilder = _defaultFromTypesBuilder;

  /// 资源预览UI [MultipleImagePicker] 使用
  static FlPreviewAssetsBuilder previewBuilder = _defaultPreviewBuilder;

  /// 资源预览UI全屏弹出渲染 [MultipleImagePicker] 使用
  static FlPreviewAssetsModalPopupBuilder previewModalPopup =
      (context, Widget widget) =>
          showCupertinoModalPopup(context: context, builder: (_) => widget);

  /// 错误消息回调
  static FlAssetsPickerErrorCallback? errorCallback;

  const FlAssetsPicker({
    super.key,
    this.renovate,
    required this.maxVideoCount,
    required this.maxCount,
    required this.actions,
    this.itemConfig = const AssetsPickerItemConfig(),
    this.enablePicker = true,
    this.pageRouteBuilderForCameraPicker,
    this.pageRouteBuilderForAssetPicker,
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

  final CameraPickerPageRoute<AssetEntity> Function(Widget picker)?
      pageRouteBuilderForCameraPicker;

  final AssetPickerPageRouteBuilder<List<AssetEntity>>?
      pageRouteBuilderForAssetPicker;

  /// 资源重新编辑
  final FlAssetFileRenovate? renovate;

  /// item UI 样式配置
  final AssetsPickerItemConfig itemConfig;

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

  /// 从可选配置中选择
  static Future<ExtendedAssetEntity?> showPickWithOptionalActions(
    BuildContext context, {
    /// 选择框提示item
    List<PickerActions> actions = defaultPickerActions,

    /// 资源选择器配置信息
    AssetPickerConfig? assetPickerConfig,
    AssetPickerPageRouteBuilder<List<AssetEntity>>?
        pageRouteBuilderForAssetPicker,

    /// 相机配置信息
    CameraPickerConfig? cameraPickerConfig,
    CameraPickerPageRoute<AssetEntity> Function(Widget picker)?
        pageRouteBuilderForCameraPicker,

    /// 资源重编辑
    FlAssetFileRenovate? renovate,

    /// 资源最大占用字节
    int maxBytes = 167772160,
  }) async {
    if (!_supportable) return null;
    final pickerFromTypeConfig = await showPickActions(context, actions);
    if (pickerFromTypeConfig == null) return null;
    AssetEntity? entity;
    switch (pickerFromTypeConfig.action) {
      case PickerOptionalActions.gallery:
        if (context.mounted) {
          final assetsEntity = await showPickAssets(context,
              pageRouteBuilder: pageRouteBuilderForAssetPicker,
              pickerConfig: AssetPickerConfig(
                  maxAssets: 1,
                  requestType: pickerFromTypeConfig.requestType,
                  selectedAssets: []).merge(assetPickerConfig));
          if (assetsEntity == null || assetsEntity.isEmpty) return null;
          entity = assetsEntity.first;
        } else {
          return null;
        }
        break;
      case PickerOptionalActions.camera:
        if (context.mounted) {
          entity = await showPickFromCamera(context,
              pageRouteBuilder: pageRouteBuilderForCameraPicker,
              pickerConfig: const CameraPickerConfig(
                      resolutionPreset: ResolutionPreset.high)
                  .merge(cameraPickerConfig)
                  .copyWith(
                      enableRecording:
                          pickerFromTypeConfig.requestType.containsVideo(),
                      onlyEnableRecording:
                          pickerFromTypeConfig.requestType == RequestType.video,
                      enableAudio: pickerFromTypeConfig.requestType
                              .containsVideo() ||
                          pickerFromTypeConfig.requestType.containsAudio()));
        } else {
          return null;
        }
        break;
      default:
        return null;
    }
    if (entity == null) return null;
    final file = await entity.file;
    if (file == null) {
      errorCallback?.call(ErrorDes.maxBytes);
      return null;
    }
    final fileBytes = file.readAsBytesSync();
    if (fileBytes.length > maxBytes) {
      errorCallback?.call(ErrorDes.maxBytes);
      return null;
    }
    return await entity.toExtended(renovate: renovate);
  }

  /// show 选择弹窗
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

  /// 选择图片
  static Future<List<AssetEntity>?> showPickAssets(
    BuildContext context, {
    bool useRootNavigator = true,
    AssetPickerConfig pickerConfig = const AssetPickerConfig(),
    AssetPickerPageRouteBuilder<List<AssetEntity>>? pageRouteBuilder,
  }) async {
    final permissionState =
        await checkPermission?.call(PickerOptionalActions.gallery) ?? true;
    if (permissionState && context.mounted) {
      return await AssetPicker.pickAssets(context,
          pickerConfig: pickerConfig,
          useRootNavigator: useRootNavigator,
          pageRouteBuilder: pageRouteBuilder);
    }
    return null;
  }

  /// 选择图片
  static Future<List<Asset>?> showPickAssetsWithDelegate<Asset, Path,
      PickerProvider extends AssetPickerProvider<Asset, Path>>(
    BuildContext context, {
    required AssetPickerBuilderDelegate<Asset, Path> delegate,
    bool useRootNavigator = true,
    AssetPickerPageRouteBuilder<List<Asset>>? pageRouteBuilder,
  }) async {
    final permissionState =
        await checkPermission?.call(PickerOptionalActions.gallery) ?? true;
    if (context.mounted && permissionState) {
      return await AssetPicker.pickAssetsWithDelegate<Asset, Path,
              PickerProvider>(context,
          delegate: delegate,
          useRootNavigator: useRootNavigator,
          pageRouteBuilder: pageRouteBuilder);
    }
    return null;
  }

  /// 通过相机拍照
  static Future<AssetEntity?> showPickFromCamera(
    BuildContext context, {
    bool useRootNavigator = true,
    CameraPickerConfig pickerConfig = const CameraPickerConfig(),
    CameraPickerPageRoute<AssetEntity> Function(Widget picker)?
        pageRouteBuilder,
  }) async {
    final permissionState =
        await checkPermission?.call(PickerOptionalActions.camera) ?? true;
    if (context.mounted && permissionState) {
      return await CameraPicker.pickFromCamera(context,
          pickerConfig: pickerConfig,
          useRootNavigator: useRootNavigator,
          pageRouteBuilder: pageRouteBuilder);
    }
    return null;
  }
}

class AssetsPickerController with ChangeNotifier {
  AssetsPickerController();

  List<ExtendedAssetEntity> allEntity = [];

  /// 资源选择器配置信息
  AssetPickerConfig _assetConfig = const AssetPickerConfig();

  set assetConfig(AssetPickerConfig config) {
    _assetConfig = config;
  }

  /// 相机配置信息
  CameraPickerConfig _cameraConfig = const CameraPickerConfig();

  set cameraConfig(CameraPickerConfig config) {
    _cameraConfig = config;
  }

  late FlAssetsPicker _assetsPicker;

  set assetsPicker(FlAssetsPicker assetsPicker) {
    _assetsPicker = assetsPicker;
  }

  void delete(ExtendedAssetEntity entity) {
    allEntity.remove(entity);
    notifyListeners();
  }

  /// 选择图片
  Future<List<ExtendedAssetEntity>?> pickAssets(BuildContext context,
      {bool useRootNavigator = true,
      AssetPickerConfig? pickerConfig,
      AssetPickerPageRouteBuilder<List<AssetEntity>>? pageRouteBuilder}) async {
    final List<AssetEntity>? assets = await FlAssetsPicker.showPickAssets(
        context,
        pickerConfig: pickerConfig ?? _assetConfig,
        useRootNavigator: useRootNavigator,
        pageRouteBuilder: pageRouteBuilder);
    if (assets != null && assets.isNotEmpty) {
      List<ExtendedAssetEntity> list = [];
      for (var element in assets) {
        if (!allEntity.contains(element)) {
          list.add(await element.toExtended(renovate: _assetsPicker.renovate));
        }
      }
      return list;
    }
    return null;
  }

  /// 通过相机拍照
  Future<ExtendedAssetEntity?> pickFromCamera(BuildContext context,
      {bool useRootNavigator = true,
      CameraPickerConfig? pickerConfig,
      CameraPickerPageRoute<AssetEntity> Function(Widget picker)?
          pageRouteBuilder}) async {
    final AssetEntity? entity = await FlAssetsPicker.showPickFromCamera(context,
        pickerConfig: pickerConfig ?? _cameraConfig,
        useRootNavigator: useRootNavigator,
        pageRouteBuilder: pageRouteBuilder);
    if (entity != null) {
      return await entity.toExtended(renovate: _assetsPicker.renovate);
    }
    return null;
  }

  /// 弹窗选择类型
  Future<void> pickActions(BuildContext context) async {
    if (_assetsPicker.maxCount > 1 &&
        allEntity.length >= _assetsPicker.maxCount) {
      FlAssetsPicker.errorCallback?.call(ErrorDes.maxCount);
      return;
    }
    final type =
        await FlAssetsPicker.showPickActions(context, _assetsPicker.actions);
    switch (type?.action) {
      case PickerOptionalActions.gallery:
        if (!context.mounted) return;
        List<AssetEntity> selectedAssets = [];
        int maxAssets = 1;
        if (_assetsPicker.maxCount > 1) {
          selectedAssets =
              List.from(allEntity.where((element) => element.isLocalData));
          maxAssets = _assetsPicker.maxCount - selectedAssets.length;
        }
        final assetsEntryList = await pickAssets(context,
            pickerConfig: _assetConfig.copyWith(
                maxAssets: maxAssets,
                requestType: type?.requestType,
                selectedAssets: selectedAssets),
            useRootNavigator: _assetsPicker.useRootNavigator,
            pageRouteBuilder: _assetsPicker.pageRouteBuilderForAssetPicker);
        if (assetsEntryList == null) return;
        if (_assetsPicker.maxCount > 1) {
          var videos = allEntity
              .where((element) => element.type == AssetType.video)
              .toList();
          for (var entity in assetsEntryList) {
            if (entity.type == AssetType.video) videos.add(entity);
            if (videos.length > _assetsPicker.maxVideoCount) {
              FlAssetsPicker.errorCallback?.call(ErrorDes.maxVideoCount);
              continue;
            } else {
              allEntity.add(entity);
            }
          }
        } else {
          /// 单资源远着
          allEntity = assetsEntryList;
        }
        notifyListeners();
        break;
      case PickerOptionalActions.camera:
        if (!context.mounted) return;
        final assetsEntry = await pickFromCamera(context,
            pickerConfig: _cameraConfig.copyWith(
                enableRecording: type?.requestType.containsVideo(),
                onlyEnableRecording: type?.requestType == RequestType.video,
                enableAudio: (type?.requestType.containsVideo() ?? false) ||
                    (type?.requestType.containsAudio() ?? false)),
            useRootNavigator: _assetsPicker.useRootNavigator,
            pageRouteBuilder: _assetsPicker.pageRouteBuilderForCameraPicker);
        if (assetsEntry != null) {
          if (_assetsPicker.maxCount > 1) {
            final videos =
                allEntity.where((element) => element.type == AssetType.video);
            if (videos.length >= _assetsPicker.maxVideoCount) {
              FlAssetsPicker.errorCallback?.call(ErrorDes.maxVideoCount);
              return;
            }
            allEntity.add(assetsEntry);
          } else {
            allEntity = [assetsEntry];
          }
          notifyListeners();
        }
        break;
      case PickerOptionalActions.cancel:
        break;
      default:
        break;
    }
  }
}
