import 'dart:io';
import 'dart:typed_data';

import 'package:fl_assets_picker/fl_assets_picker.dart';
import 'package:flutter/material.dart';

enum ImageCroppingQuality {
  /// 最高画质
  high,

  /// 中等
  medium,

  ///最低
  low,
}

typedef FlAssetsRepeatBuild = Future<File?> Function(AssetEntity entity);

class FlAssetsPickerController with ChangeNotifier {
  FlAssetsPickerController(
      {this.assetConfig = const AssetPickerConfig(),
      this.cameraConfig = const CameraPickerConfig()});

  final List<ExtendedAssetEntity> allAssetEntity = [];

  /// 资源选择器配置信息
  AssetPickerConfig assetConfig;

  /// 相机配置信息
  CameraPickerConfig cameraConfig;

  /// 压缩视频
  FlAssetsRepeatBuild? _videoCompress;

  /// 获取视频封面
  FlAssetsRepeatBuild? _videoCover;

  /// 压缩图片
  FlAssetsRepeatBuild? _imageCompress;

  /// 裁剪图片
  FlAssetsRepeatBuild? _imageCrop;

  /// 压缩音频
  FlAssetsRepeatBuild? _audioCompress;

  /// 设置 资源 压缩构造方法
  void setAssetBuild(
      {FlAssetsRepeatBuild? video,
      FlAssetsRepeatBuild? videoCover,
      FlAssetsRepeatBuild? image,
      FlAssetsRepeatBuild? imageCrop,
      FlAssetsRepeatBuild? audio}) {
    if (video != null) _videoCompress = video;
    if (videoCover != null) _videoCover = videoCover;
    if (image != null) _imageCompress = image;
    if (imageCrop != null) _imageCrop = imageCrop;
    if (audio != null) _audioCompress = audio;
  }

  late FlAssetPickerView _flAssetPickerView;

  void setWidget(FlAssetPickerView flAssetPickerView) {
    _flAssetPickerView = flAssetPickerView;
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
          list.add(await toExtendedAssetEntity(element));
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
    if (entity != null) return await toExtendedAssetEntity(entity);
    return null;
  }

  /// AssetEntity to ExtendedAssetEntity;
  Future<ExtendedAssetEntity> toExtendedAssetEntity(AssetEntity entity) async {
    File? compressPath;
    File? imageCropPath;
    File? videoCoverPath;
    if (entity.type == AssetType.image) {
      imageCropPath = await _imageCrop?.call(entity);
      compressPath = await _imageCompress?.call(entity);
    } else if (entity.type == AssetType.video) {
      compressPath = await _videoCompress?.call(entity);
      videoCoverPath = await _videoCover?.call(entity);
    } else if (entity.type == AssetType.audio) {
      compressPath = await _audioCompress?.call(entity);
    }
    final file = await entity.file;
    final originFile = await entity.originFile;
    final originBytes = await entity.originBytes;
    final thumbnailData = await entity.thumbnailData;
    return entity.toExtendedAssetEntity(
        fileAsync: file,
        originFileAsync: originFile,
        originBytes: originBytes,
        thumbnailData: thumbnailData,
        compressPath: compressPath,
        videoCoverPath: videoCoverPath,
        imageCropPath: imageCropPath);
  }

  /// 弹窗选择类型
  Future<void> pickFromType(BuildContext context, {bool mounted = true}) async {
    if (allAssetEntity.length >= _flAssetPickerView.maxCount) {
      _flAssetPickerView.errorCallback
          ?.call('最多添加${_flAssetPickerView.maxCount}个资源');
      return;
    }
    FlAssetPickerFromRequestTypes? type = await showPickFromType(
        context, _flAssetPickerView.fromRequestTypes,
        fromRequestTypesBuilder: _flAssetPickerView.fromRequestTypesBuilder,
        mounted: mounted);
    switch (type?.fromType) {
      case FlAssetPickerFromType.assets:
        if (!mounted) return;
        List<AssetEntity> selectedAssets =
            List.from(allAssetEntity.where((element) => element.isLocalData));
        final assetsEntryList = await pickAssets(context,
            pickerConfig: assetConfig.copyWith(
                maxAssets: _flAssetPickerView.maxCount - selectedAssets.length,
                requestType: type?.requestType,
                selectedAssets: selectedAssets),
            useRootNavigator: _flAssetPickerView.useRootNavigator,
            pageRouteBuilder:
                _flAssetPickerView.pageRouteBuilderForAssetPicker);
        if (assetsEntryList == null) return;
        if (assetsEntryList.length + allAssetEntity.length >
            _flAssetPickerView.maxCount) {
          _flAssetPickerView.errorCallback
              ?.call('最多添加${_flAssetPickerView.maxCount}个资源');
          return;
        }
        dynamic videos =
            allAssetEntity.where((element) => element.type == AssetType.video);
        for (var entity in assetsEntryList) {
          if (entity.type == AssetType.video) {
            videos = videos.toList().add(entity);
          }
          if (videos.length >= _flAssetPickerView.maxVideoCount) {
            _flAssetPickerView.errorCallback
                ?.call('最多添加${_flAssetPickerView.maxVideoCount}个视频');
            return;
          }
          allAssetEntity.add(entity);
        }
        notifyListeners();
        break;
      case FlAssetPickerFromType.camera:
        if (!mounted) return;
        if (type?.requestType?.containsImage() ?? false) {}
        final assetsEntry = await pickFromCamera(context,
            pickerConfig: cameraConfig.copyWith(
                enableRecording: (type?.requestType?.containsVideo() ?? false),
                onlyEnableRecording: type?.requestType == RequestType.video,
                enableAudio: (type?.requestType?.containsVideo() ?? false) ||
                    (type?.requestType?.containsAudio() ?? false)),
            useRootNavigator: _flAssetPickerView.useRootNavigator,
            pageRouteBuilder:
                _flAssetPickerView.pageRouteBuilderForCameraPicker);
        if (assetsEntry != null) {
          final videos = allAssetEntity
              .where((element) => element.type == AssetType.video);
          if (videos.length >= _flAssetPickerView.maxVideoCount) {
            _flAssetPickerView.errorCallback
                ?.call('最多添加${_flAssetPickerView.maxVideoCount}个视频');
            return;
          }
          allAssetEntity.add(assetsEntry);
          notifyListeners();
        }
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

/// show 选择弹窗
Future<FlAssetPickerFromRequestTypes?> showPickFromType(
  BuildContext context,
  List<FlAssetPickerFromRequestTypes> fromRequestTypes, {
  bool mounted = true,
  PickerFromRequestTypesBuilder? fromRequestTypesBuilder,
}) async {
  FlAssetPickerFromRequestTypes? type;
  if (fromRequestTypes.length == 1) {
    type = fromRequestTypes.first;
  } else {
    type = await showModalBottomSheet<FlAssetPickerFromRequestTypes?>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) =>
            fromRequestTypesBuilder?.call(context, fromRequestTypes) ??
            PickFromTypeBuild(fromRequestTypes));
  }
  if (type == null) return null;
  if (!mounted) return null;
  return type;
}

class ExtendedAssetEntity extends AssetEntity {
  ExtendedAssetEntity.fromUrl({
    this.url,
    super.width = 0,
    super.height = 0,
    required AssetType assetType,
  })  : originBytesAsync = null,
        thumbnailDataAsync = null,
        fileAsync = null,
        originFileAsync = null,
        compressPath = null,
        videoCoverPath = null,
        imageCropPath = null,
        path = null,
        isLocalData = false,
        super(typeInt: assetType.index, id: url.hashCode.toString());

  ExtendedAssetEntity.fromPath({
    this.path,
    super.width = 0,
    super.height = 0,
    required AssetType assetType,
  })  : originBytesAsync = null,
        thumbnailDataAsync = null,
        fileAsync = null,
        originFileAsync = null,
        compressPath = null,
        videoCoverPath = null,
        imageCropPath = null,
        url = null,
        isLocalData = false,
        super(typeInt: assetType.index, id: path.hashCode.toString());

  ExtendedAssetEntity.fromFile({
    required File file,
    super.width = 0,
    super.height = 0,
    required AssetType assetType,
  })  : originBytesAsync = null,
        thumbnailDataAsync = null,
        fileAsync = file,
        originFileAsync = null,
        compressPath = null,
        videoCoverPath = null,
        imageCropPath = null,
        path = null,
        url = null,
        isLocalData = false,
        super(typeInt: assetType.index, id: file.hashCode.toString());

  const ExtendedAssetEntity({
    this.originBytesAsync,
    this.thumbnailDataAsync,
    this.compressPath,
    this.imageCropPath,
    this.fileAsync,
    this.originFileAsync,
    this.videoCoverPath,
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
        url = null,
        path = null;

  final bool isLocalData;

  /// [url] 主要用于网络图片复显
  final String? url;

  ///  [path] 主要用于资源文件复显
  final String? path;

  /// 原始数据 bytes
  final Uint8List? originBytesAsync;

  /// 原始缩略图数据 bytes
  final Uint8List? thumbnailDataAsync;

  /// file
  final File? fileAsync;

  /// originFile
  final File? originFileAsync;

  /// 压缩后的路径
  /// 只有通过本地选择的资源 并添加了压缩方法
  final File? compressPath;

  /// 视频封面
  /// 只有通过本地选择的资源 并添加了获取封面的方法
  final File? videoCoverPath;

  /// 图片裁剪后的路径
  /// 只有通过本地选择的资源 并添加了裁剪的方法
  final File? imageCropPath;

  String? get realValueStr => url ?? path ?? fileAsync?.path;

  dynamic get realValue => url ?? path ?? fileAsync;
}
