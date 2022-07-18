import 'dart:io';
import 'dart:typed_data';

import 'package:fl_assets_picker/src/asset_picker_view.dart';
import 'package:flutter/material.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:wechat_camera_picker/wechat_camera_picker.dart';

enum FileLoadType { network, file, assets }

enum ImageCompressionRatio {
  /// 最高画质
  high,

  /// 中等
  medium,

  ///最低
  low,
}

class FlAssetsPickerView extends StatefulWidget {
  const FlAssetsPickerView({Key? key}) : super(key: key);

  @override
  State<FlAssetsPickerView> createState() => _FlAssetsPickerViewState();
}

class _FlAssetsPickerViewState extends State<FlAssetsPickerView> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

typedef FlAssetsRepeatBuild = Future<File?> Function(AssetEntity entity);

class FlAssetsPickerController with ChangeNotifier {
  FlAssetsPickerController(
      {this.assetConfig = const AssetPickerConfig(),
      this.cameraConfig = const CameraPickerConfig()});

  final List<AssetEntry> currentAssetsEntry = [];

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

  /// 更新配置信息
  void updateConfig(
      {AssetPickerConfig? assetConfig, CameraPickerConfig? cameraConfig}) {
    if (assetConfig != null) this.assetConfig = assetConfig;
    if (cameraConfig != null) this.cameraConfig = cameraConfig;
  }

  /// 选择图片
  Future<List<AssetEntry>?> pickAssets(BuildContext context,
      {bool useRootNavigator = true,
      AssetPickerPageRouteBuilder<List<AssetEntity>>? pageRouteBuilder}) async {
    final List<AssetEntity>? assets = await AssetPicker.pickAssets(context,
        pickerConfig: assetConfig,
        useRootNavigator: useRootNavigator,
        pageRouteBuilder: pageRouteBuilder);
    if (assets != null && assets.isNotEmpty) {
      List<AssetEntry> assetsEntryList = [];
      for (var entity in assets) {
        final assetsEntry = await toAssetEntry(entity);
        assetsEntryList.add(assetsEntry);
        currentAssetsEntry.add(assetsEntry);
      }
      notifyListeners();
      return assetsEntryList;
    }
    return null;
  }

  /// 通过相机拍照
  Future<AssetEntry?> pickFromCamera(
    BuildContext context, {
    bool useRootNavigator = true,
    CameraPickerPageRouteBuilder<AssetEntity>? pageRouteBuilder,
  }) async {
    final AssetEntity? entity = await CameraPicker.pickFromCamera(context,
        pickerConfig: cameraConfig,
        useRootNavigator: useRootNavigator,
        pageRouteBuilder: pageRouteBuilder);
    if (entity != null) {
      final assetsEntry = await toAssetEntry(entity);
      currentAssetsEntry.add(assetsEntry);
      notifyListeners();
      return assetsEntry;
    }
    return null;
  }

  /// AssetEntity to AssetEntry;
  Future<AssetEntry> toAssetEntry(AssetEntity entity) async {
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
    return AssetEntry.fromEntity(entity,
        fileAsync: file,
        originFileAsync: originFile,
        originBytes: originBytes,
        thumbnailData: thumbnailData,
        compressPath: compressPath,
        videoCoverPath: videoCoverPath,
        imageCropPath: imageCropPath);
  }

  Future<void> showPickFromType(
    BuildContext context,
    bool mounted,
    List<FlAssetPickerFromRequestTypes> fromRequestTypes, {
    PickerFromRequestTypesBuilder? fromRequestTypesBuilder,
    bool useRootNavigator = true,
    CameraPickerPageRouteBuilder<AssetEntity>? pageRouteBuilderForCameraPicker,
    AssetPickerPageRouteBuilder<List<AssetEntity>>?
        pageRouteBuilderForAssetPicker,
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
    if (type == null) return;
    if (!mounted) return;
    switch (type.fromType) {
      case FlAssetPickerFromType.assets:
        pickAssets(context,
            useRootNavigator: useRootNavigator,
            pageRouteBuilder: pageRouteBuilderForAssetPicker);
        break;
      case FlAssetPickerFromType.camera:
        pickFromCamera(context,
            useRootNavigator: useRootNavigator,
            pageRouteBuilder: pageRouteBuilderForCameraPicker);
        break;
    }
  }
}

class AssetEntry extends AssetEntity {
  const AssetEntry({
    this.originBytesAsync,
    this.thumbnailDataAsync,
    this.compressPath,
    this.imageCropPath,
    this.fileAsync,
    this.originFileAsync,
    this.videoCoverPath,
    required String id,
    required int typeInt,
    required int width,
    required int height,
    int duration = 0,
    int orientation = 0,
    bool isFavorite = false,
    String? title,
    int? createDateSecond,
    int? modifiedDateSecond,
    String? relativePath,
    double? latitude,
    double? longitude,
    String? mimeType,
    int subtype = 0,
  }) : super(
            id: id,
            typeInt: typeInt,
            width: width,
            height: height,
            duration: duration,
            orientation: orientation,
            isFavorite: isFavorite,
            title: title,
            createDateSecond: createDateSecond,
            modifiedDateSecond: modifiedDateSecond,
            relativePath: relativePath,
            latitude: latitude,
            longitude: longitude,
            mimeType: mimeType,
            subtype: subtype);

  factory AssetEntry.fromEntity(
    AssetEntity entity, {
    File? compressPath,
    File? imageCropPath,
    File? videoCoverPath,
    File? fileAsync,
    File? originFileAsync,
    Uint8List? originBytes,
    Uint8List? thumbnailData,
  }) =>
      AssetEntry(
          originBytesAsync: originBytes,
          thumbnailDataAsync: thumbnailData,
          fileAsync: fileAsync,
          originFileAsync: originFileAsync,
          id: entity.id,
          typeInt: entity.typeInt,
          width: entity.width,
          height: entity.height,
          compressPath: compressPath,
          imageCropPath: imageCropPath,
          videoCoverPath: videoCoverPath,
          duration: entity.duration,
          orientation: entity.orientation,
          isFavorite: entity.isFavorite,
          title: entity.title,
          createDateSecond: entity.createDateSecond,
          modifiedDateSecond: entity.modifiedDateSecond,
          relativePath: entity.relativePath,
          latitude: entity.latitude,
          longitude: entity.longitude,
          mimeType: entity.mimeType,
          subtype: entity.subtype);

  final Uint8List? originBytesAsync;

  final Uint8List? thumbnailDataAsync;

  final File? fileAsync;

  final File? originFileAsync;

  /// 压缩后的路径
  final File? compressPath;

  /// 视频封面
  final File? videoCoverPath;

  /// 图片裁剪后的路径
  final File? imageCropPath;
}
