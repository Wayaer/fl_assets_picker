import 'package:fl_assets_picker/fl_assets_picker.dart';
import 'package:flutter/material.dart';

class AssetsPickerController with ChangeNotifier {
  AssetsPickerController();

  List<ExtendedAssetEntity> allAssetEntity = [];

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

  void deleteAsset(String id) {
    allAssetEntity.removeWhere((element) => id == element.id);
    notifyListeners();
  }

  /// 选择图片
  Future<List<ExtendedAssetEntity>?> pickAssets(BuildContext context,
      {bool useRootNavigator = true,
      AssetPickerConfig? pickerConfig,
      AssetPickerPageRouteBuilder<List<AssetEntity>>? pageRouteBuilder}) async {
    final List<AssetEntity>? assets = await FlAssetsPicker.showPickerAssets(
        context,
        checkPermission: _assetsPicker.checkPermission,
        pickerConfig: pickerConfig ?? _assetConfig,
        useRootNavigator: useRootNavigator,
        pageRouteBuilder: pageRouteBuilder);
    if (assets != null && assets.isNotEmpty) {
      List<ExtendedAssetEntity> list = [];
      for (var element in assets) {
        if (!allAssetEntity.contains(element)) {
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
    final AssetEntity? entity = await FlAssetsPicker.showPickerFromCamera(
        context,
        checkPermission: _assetsPicker.checkPermission,
        pickerConfig: pickerConfig ?? _cameraConfig,
        useRootNavigator: useRootNavigator,
        pageRouteBuilder: pageRouteBuilder);
    if (entity != null) {
      return await entity.toExtended(renovate: _assetsPicker.renovate);
    }
    return null;
  }

  /// 弹窗选择类型
  Future<void> pickFromType(BuildContext context) async {
    if (_assetsPicker.maxCount > 1 &&
        allAssetEntity.length >= _assetsPicker.maxCount) {
      _assetsPicker.errorCallback?.call('最多添加${_assetsPicker.maxCount}个资源');
      return;
    }
    final type = await FlAssetsPicker.showPickerFromType(
        context, _assetsPicker.fromRequestTypes,
        fromTypesBuilder: _assetsPicker.fromTypesBuilder);
    switch (type?.fromType) {
      case PickerFromType.gallery:
        if (!context.mounted) return;
        List<AssetEntity> selectedAssets = [];
        int maxAssets = 1;
        if (_assetsPicker.maxCount > 1) {
          selectedAssets =
              List.from(allAssetEntity.where((element) => element.isLocalData));
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
          var videos = allAssetEntity
              .where((element) => element.type == AssetType.video)
              .toList();
          for (var entity in assetsEntryList) {
            if (entity.type == AssetType.video) videos.add(entity);
            if (videos.length > _assetsPicker.maxVideoCount) {
              _assetsPicker.errorCallback
                  ?.call('最多添加${_assetsPicker.maxVideoCount}个视频');
              continue;
            } else {
              allAssetEntity.add(entity);
            }
          }
        } else {
          /// 单资源远着
          allAssetEntity = assetsEntryList;
        }
        notifyListeners();
        break;
      case PickerFromType.camera:
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
            final videos = allAssetEntity
                .where((element) => element.type == AssetType.video);
            if (videos.length >= _assetsPicker.maxVideoCount) {
              _assetsPicker.errorCallback
                  ?.call('最多添加${_assetsPicker.maxVideoCount}个视频');
              return;
            }
            allAssetEntity.add(assetsEntry);
          } else {
            allAssetEntity = [assetsEntry];
          }
          notifyListeners();
        }
        break;
      case PickerFromType.cancel:
        break;
      default:
        break;
    }
  }
}
