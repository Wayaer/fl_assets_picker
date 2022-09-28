import 'dart:io';
import 'dart:typed_data';

import 'package:fl_assets_picker/fl_assets_picker.dart';
import 'package:flutter/material.dart';

typedef FlAssetRepeatBuilder = Future<File?> Function(AssetEntity entity);

class AssetRepeatBuilderConfig {
  const AssetRepeatBuilderConfig({
    this.videoCompress,
    this.videoCover,
    this.imageCompress,
    this.imageCrop,
    this.audioCompress,
  });

  /// 压缩视频
  final FlAssetRepeatBuilder? videoCompress;

  /// 获取视频封面
  final FlAssetRepeatBuilder? videoCover;

  /// 压缩图片
  final FlAssetRepeatBuilder? imageCompress;

  /// 裁剪图片
  final FlAssetRepeatBuilder? imageCrop;

  /// 压缩音频
  final FlAssetRepeatBuilder? audioCompress;

  AssetRepeatBuilderConfig merge(AssetRepeatBuilderConfig config) =>
      AssetRepeatBuilderConfig(
          videoCompress: config.videoCompress ?? videoCompress,
          videoCover: config.videoCover ?? videoCover,
          imageCompress: config.imageCompress ?? imageCompress,
          imageCrop: config.imageCrop ?? imageCrop,
          audioCompress: config.audioCompress ?? audioCompress);
}

class AssetsPickerController with ChangeNotifier {
  AssetsPickerController(
      {this.assetConfig = const AssetPickerConfig(),
      this.cameraConfig = const CameraPickerConfig()});

  List<ExtendedAssetEntity> allAssetEntity = [];

  /// 资源选择器配置信息
  AssetPickerConfig assetConfig;

  /// 相机配置信息
  CameraPickerConfig cameraConfig;

  /// 资源重新编辑
  AssetRepeatBuilderConfig repeatBuilderConfig =
      const AssetRepeatBuilderConfig();

  /// 设置 资源 压缩构造方法
  void setAssetBuilder(AssetRepeatBuilderConfig config) {
    repeatBuilderConfig.merge(config);
  }

  late FlAssetsPicker _assetsPicker;

  void setWidget(FlAssetsPicker assetsPicker) {
    _assetsPicker = assetsPicker;
  }

  void deleteAsset(String id) {
    allAssetEntity.removeWhere((element) => id == element.id);
    notifyListeners();
  }

  /// 更新配置信息
  void updateConfig(
      {AssetPickerConfig? assetConfig, CameraPickerConfig? cameraConfig}) {
    if (assetConfig != null) this.assetConfig = assetConfig;
    if (cameraConfig != null) this.cameraConfig = cameraConfig;
  }

  /// 选择图片
  Future<List<ExtendedAssetEntity>?> pickAssets(BuildContext context,
      {bool useRootNavigator = true,
      AssetPickerConfig? pickerConfig,
      AssetPickerPageRouteBuilder<List<AssetEntity>>? pageRouteBuilder}) async {
    final List<AssetEntity>? assets = await showPickerAssets(context,
        pickerConfig: pickerConfig ?? assetConfig,
        useRootNavigator: useRootNavigator,
        pageRouteBuilder: pageRouteBuilder);
    if (assets != null && assets.isNotEmpty) {
      List<ExtendedAssetEntity> list = [];
      for (var element in assets) {
        if (!allAssetEntity.contains(element)) {
          list.add(await element.repeatBuilder(repeatBuilderConfig));
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
    final AssetEntity? entity = await showPickerFromCamera(context,
        pickerConfig: pickerConfig ?? cameraConfig,
        useRootNavigator: useRootNavigator,
        pageRouteBuilder: pageRouteBuilder);
    if (entity != null) return await entity.repeatBuilder(repeatBuilderConfig);
    return null;
  }

  /// 弹窗选择类型
  Future<void> pickFromType(BuildContext context, {bool mounted = true}) async {
    if (_assetsPicker.maxCount > 1 &&
        allAssetEntity.length >= _assetsPicker.maxCount) {
      _assetsPicker.errorCallback?.call('最多添加${_assetsPicker.maxCount}个资源');
      return;
    }
    PickerFromTypeConfig? type = await showPickerFromType(
        context, _assetsPicker.fromRequestTypes,
        fromRequestTypesBuilder: _assetsPicker.fromRequestTypesBuilder);
    switch (type?.fromType) {
      case PickerFromType.assets:
        if (!mounted) return;
        List<AssetEntity> selectedAssets = [];
        int maxAssets = 1;
        if (_assetsPicker.maxCount > 1) {
          selectedAssets =
              List.from(allAssetEntity.where((element) => element.isLocalData));
          _assetsPicker.maxCount - selectedAssets.length;
        }
        final assetsEntryList = await pickAssets(context,
            pickerConfig: assetConfig.copyWith(
                maxAssets: maxAssets,
                requestType: type?.requestType,
                selectedAssets: selectedAssets),
            useRootNavigator: _assetsPicker.useRootNavigator,
            pageRouteBuilder: _assetsPicker.pageRouteBuilderForAssetPicker);
        if (assetsEntryList == null) return;
        if (_assetsPicker.maxCount > 1) {
          /// 多资源选择
          if (assetsEntryList.length + allAssetEntity.length >
              _assetsPicker.maxCount) {
            _assetsPicker.errorCallback
                ?.call('最多添加${_assetsPicker.maxCount}个资源');
            return;
          }
          dynamic videos = allAssetEntity
              .where((element) => element.type == AssetType.video);
          for (var entity in assetsEntryList) {
            if (entity.type == AssetType.video) {
              videos = videos.toList().add(entity);
            }
            if (videos.length >= _assetsPicker.maxVideoCount) {
              _assetsPicker.errorCallback
                  ?.call('最多添加${_assetsPicker.maxVideoCount}个视频');
              return;
            }
            allAssetEntity.add(entity);
          }
        } else {
          /// 单资源远着
          allAssetEntity = assetsEntryList;
        }
        notifyListeners();
        break;
      case PickerFromType.camera:
        if (!mounted) return;
        final assetsEntry = await pickFromCamera(context,
            pickerConfig: cameraConfig.copyWith(
                enableRecording: (type?.requestType?.containsVideo() ?? false),
                onlyEnableRecording: type?.requestType == RequestType.video,
                enableAudio: (type?.requestType?.containsVideo() ?? false) ||
                    (type?.requestType?.containsAudio() ?? false)),
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
        return;
    }
  }
}

/// 选择图片
Future<List<AssetEntity>?> showPickerAssets(BuildContext context,
        {bool useRootNavigator = true,
        AssetPickerConfig pickerConfig = const AssetPickerConfig(),
        AssetPickerPageRouteBuilder<List<AssetEntity>>? pageRouteBuilder}) =>
    AssetPicker.pickAssets(context,
        pickerConfig: pickerConfig,
        useRootNavigator: useRootNavigator,
        pageRouteBuilder: pageRouteBuilder);

/// 通过相机拍照
Future<AssetEntity?> showPickerFromCamera(
  BuildContext context, {
  bool useRootNavigator = true,
  CameraPickerConfig pickerConfig = const CameraPickerConfig(),
  CameraPickerPageRoute<AssetEntity> Function(Widget picker)? pageRouteBuilder,
}) =>
    CameraPicker.pickFromCamera(context,
        pickerConfig: pickerConfig,
        useRootNavigator: useRootNavigator,
        pageRouteBuilder: pageRouteBuilder);

class ExtendedAssetEntity extends AssetEntity {
  ExtendedAssetEntity.fromUrl({
    this.previewUrl,
    super.width = 0,
    super.height = 0,
    required AssetType assetType,
  })  : thumbnailDataAsync = null,
        fileAsync = null,
        compressFile = null,
        videoCoverFile = null,
        imageCropFile = null,
        previewPath = null,
        isLocalData = false,
        super(typeInt: assetType.index, id: previewUrl.hashCode.toString());

  ExtendedAssetEntity.fromPath({
    this.previewPath,
    super.width = 0,
    super.height = 0,
    required AssetType assetType,
  })  : thumbnailDataAsync = null,
        fileAsync = null,
        compressFile = null,
        videoCoverFile = null,
        imageCropFile = null,
        previewUrl = null,
        isLocalData = false,
        super(typeInt: assetType.index, id: previewPath.hashCode.toString());

  ExtendedAssetEntity.fromFile({
    required File file,
    super.width = 0,
    super.height = 0,
    required AssetType assetType,
  })  : thumbnailDataAsync = null,
        fileAsync = file,
        compressFile = null,
        videoCoverFile = null,
        imageCropFile = null,
        previewPath = null,
        previewUrl = null,
        isLocalData = false,
        super(typeInt: assetType.index, id: file.hashCode.toString());

  const ExtendedAssetEntity({
    this.thumbnailDataAsync,
    this.compressFile,
    this.imageCropFile,
    this.fileAsync,
    this.videoCoverFile,
    required super.id,
    required super.typeInt,
    required super.width,
    required super.height,
    super.duration = 0,
    super.orientation = 0,
    super.isFavorite = false,
    super.title,
    super.createDateSecond,
    super.modifiedDateSecond,
    super.relativePath,
    super.latitude,
    super.longitude,
    super.mimeType,
    super.subtype = 0,
  })  : isLocalData = true,
        previewUrl = null,
        previewPath = null;

  final bool isLocalData;

  /// [previewUrl] 主要用于网络图片复显
  final String? previewUrl;

  ///  [previewPath] 主要用于资源文件复显
  final String? previewPath;

  /// 原始缩略图数据 bytes
  final Uint8List? thumbnailDataAsync;

  /// file
  final File? fileAsync;

  /// 压缩后的路径
  /// 只有通过本地选择的资源 并添加了压缩方法
  final File? compressFile;

  /// 视频封面
  /// 只有通过本地选择的资源 并添加了获取封面的方法
  final File? videoCoverFile;

  /// 图片裁剪后的路径
  /// 只有通过本地选择的资源 并添加了裁剪的方法
  final File? imageCropFile;

  String? get realValueStr => previewUrl ?? previewPath ?? fileAsync?.path;

  dynamic get realValue => previewUrl ?? previewPath ?? fileAsync;
}
